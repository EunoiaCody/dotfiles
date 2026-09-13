/**
 * byok/models.ts — 远程模型目录拉取、ProviderModelConfig 构建、provider 注册
 *
 * 该模块同时持有运行时状态：已成功注册的 BYOK provider（id -> ByokProvider）。
 * 供 index.ts（事件处理）与 wizard.ts（命令）共享，避免循环依赖。
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import type {
  ByokModel,
  ByokProvider,
  CompatPreset,
} from "./config";
import { normalizeBaseUrl, resolveValue } from "./config";

// ---------------------------------------------------------------------------
// 常量
// ---------------------------------------------------------------------------

export const DEFAULT_CONTEXT_WINDOW = 128_000;
export const DEFAULT_MAX_TOKENS = 16_384;
export const FETCH_TIMEOUT_MS = 10_000;

export interface RemoteModel {
  id: string;
  name?: string;
  context_window?: number;
  max_tokens?: number;
  supported_parameters?: string[];
}

// ---------------------------------------------------------------------------
// 运行时状态
// ---------------------------------------------------------------------------

/** 已成功注册到 pi 的 BYOK provider。 */
const registeredProviders = new Map<string, ByokProvider>();

export function getRegisteredProvider(id: string): ByokProvider | undefined {
  return registeredProviders.get(id);
}

export function getRegisteredProviderIds(): string[] {
  return [...registeredProviders.keys()];
}

export function isByokProvider(id: string | undefined): boolean {
  return !!id && registeredProviders.has(id);
}

// ---------------------------------------------------------------------------
// 模型目录
// ---------------------------------------------------------------------------

/** 计算模型目录地址：默认 `${baseUrl}/models`，baseUrl 不含版本号时补 /v1。 */
export function getModelsUrl(provider: ByokProvider): string {
  if (provider.modelsPath) {
    if (/^https?:\/\//i.test(provider.modelsPath)) return provider.modelsPath;
    const base = normalizeBaseUrl(provider.baseUrl);
    return `${base}${provider.modelsPath.startsWith("/") ? "" : "/"}${provider.modelsPath}`;
  }
  const base = normalizeBaseUrl(provider.baseUrl);
  // 已包含版本段（/v1、/v2 ...）或 /openai 风格时直接拼 /models
  if (/\/v\d+$/.test(base) || /\/openai$/.test(base)) return `${base}/models`;
  return `${base}/v1/models`;
}

/** GET /models，带 Bearer key 与自定义 headers；支持超时与外部 abort。 */
export async function fetchRemoteModels(
  provider: ByokProvider,
  signal?: AbortSignal,
): Promise<RemoteModel[]> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);
  const onAbort = () => controller.abort();
  signal?.addEventListener("abort", onAbort, { once: true });

  try {
    const headers: Record<string, string> = {
      Accept: "application/json",
      ...(provider.headers ?? {}),
    };
    for (const [k, v] of Object.entries(headers)) headers[k] = resolveValue(v);

    const apiKey = resolveValue(provider.apiKey);
    if (apiKey && !headers.Authorization && !headers.authorization) {
      headers.Authorization = `Bearer ${apiKey}`;
    }

    const res = await fetch(getModelsUrl(provider), {
      headers,
      signal: controller.signal,
    });
    if (!res.ok) {
      throw new Error(`HTTP ${res.status} ${res.statusText}`.trim());
    }
    const payload = (await res.json()) as { data?: RemoteModel[] };
    const list = Array.isArray(payload?.data) ? payload.data : [];
    return list.filter(
      (m): m is RemoteModel => !!m && typeof m.id === "string" && m.id.length > 0,
    );
  } finally {
    clearTimeout(timer);
    signal?.removeEventListener("abort", onAbort);
  }
}

// ---------------------------------------------------------------------------
// 模型映射
// ---------------------------------------------------------------------------

function isReasoningCapable(m: RemoteModel): boolean {
  const params = m.supported_parameters ?? [];
  return params.includes("reasoning_effort") || params.includes("reasoning");
}

/** 远程模型 → ByokModel（补齐默认值）。 */
export function remoteToByokModel(m: RemoteModel): ByokModel {
  return {
    id: m.id,
    name: m.name,
    reasoning: isReasoningCapable(m),
    input: ["text"],
    contextWindow: m.context_window,
    maxTokens: m.max_tokens,
  };
}

/** compat 预设 → provider 的 compat 对象。 */
export function compatFor(
  preset: CompatPreset | undefined,
): Record<string, unknown> | undefined {
  switch (preset) {
    case "openai-compat":
      return {
        supportsStore: false,
        supportsDeveloperRole: false,
        supportsReasoningEffort: false,
      };
    case "deepseek":
      return {
        thinkingFormat: "deepseek",
        supportsReasoningEffort: true,
      };
    case "openai":
    default:
      return undefined;
  }
}

/** ByokModel → pi ProviderModelConfig（补齐默认值并透传覆盖）。 */
export function toProviderModel(m: ByokModel): Record<string, unknown> {
  const contextWindow = m.contextWindow ?? DEFAULT_CONTEXT_WINDOW;
  const maxTokens =
    m.maxTokens ??
    Math.min(DEFAULT_MAX_TOKENS, Math.max(1024, Math.floor(contextWindow / 4)));
  return {
    id: m.id,
    name: m.name ?? m.id,
    reasoning: m.reasoning ?? false,
    input: m.input ?? ["text"],
    contextWindow,
    maxTokens,
    cost: m.cost ?? { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
  };
}

/** 构建注册用的完整模型列表。 */
export function buildProviderModels(
  provider: ByokProvider,
): Record<string, unknown>[] {
  const compat = compatFor(provider.compatPreset);
  return provider.models.map((m) => {
    const cfg = toProviderModel(m);
    if (compat) cfg.compat = compat;
    return cfg;
  });
}

// ---------------------------------------------------------------------------
// 注册 / 注销
// ---------------------------------------------------------------------------

/** 注册（或重新注册）BYOK provider；模型为空时返回 false。 */
export function registerByokProvider(
  pi: ExtensionAPI,
  id: string,
  provider: ByokProvider,
): boolean {
  const models = buildProviderModels(provider);
  if (models.length === 0) return false;

  try {
    pi.unregisterProvider(id);
  } catch {
    // 未注册过则忽略
  }

  try {
    pi.registerProvider(id, {
      name: provider.name || `BYOK (${id})`,
      baseUrl: normalizeBaseUrl(provider.baseUrl),
      apiKey: provider.apiKey,
      api: provider.api || "openai-completions",
      headers: provider.headers,
      models,
    });
  } catch (err) {
    // 单个 provider 注册失败不应中断扩展加载
    console.warn(
      `[byok] register provider "${id}" failed: ${err instanceof Error ? err.message : String(err)}`,
    );
    registeredProviders.delete(id);
    return false;
  }

  registeredProviders.set(id, provider);
  return true;
}

/** 注销 BYOK provider 并从运行时状态移除。 */
export function unregisterByokProvider(pi: ExtensionAPI, id: string): void {
  try {
    pi.unregisterProvider(id);
  } catch {
    // 忽略
  }
  registeredProviders.delete(id);
}
