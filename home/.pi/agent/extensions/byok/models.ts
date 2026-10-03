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

/**
 * `/models` 返回的条目。不同服务商字段名各不相同，这里把常见变体都列出来，
 * 提取时按优先级回退（OpenAI / OpenRouter / vLLM / LiteLLM / Together 等）。
 */
export interface RemoteModel {
  id: string;
  name?: string;
  display_name?: string;
  description?: string;
  object?: string;
  owned_by?: string;
  created?: number;
  reasoning?: boolean;
  // 上下文窗口候选字段
  context_window?: number;
  context_length?: number;
  max_context_length?: number;
  max_model_len?: number;
  max_input_length?: number;
  // 最大输出候选字段
  max_tokens?: number;
  max_completion_tokens?: number;
  max_output_tokens?: number;
  max_output_length?: number;
  top_provider?: { context_length?: number; max_completion_tokens?: number };
  // LiteLLM 风格
  model_info?: {
    max_input_tokens?: number;
    max_output_tokens?: number;
    supports_vision?: boolean;
    supports_reasoning?: boolean;
    mode?: string;
    input_cost_per_token?: number;
    output_cost_per_token?: number;
    input_cost_per_million_tokens?: number;
    output_cost_per_million_tokens?: number;
    [k: string]: unknown;
  };
  // OpenRouter 价格（$/token 字符串）
  pricing?: {
    prompt?: string | number;
    completion?: string | number;
    input?: string | number;
    output?: string | number;
    input_cache_read?: string | number;
    input_cache_write?: string | number;
    [k: string]: unknown;
  };
  architecture?: {
    input_modalities?: string[];
    output_modalities?: string[];
    modality?: string;
  };
  input_modalities?: string[];
  modalities?: string[] | { input?: string[] };
  capabilities?: Record<string, unknown> | string[];
  supported_parameters?: string[];
  supported_sampling_parameters?: string[];
  supported_features?: string[];
  [k: string]: unknown;
}

// ---------------------------------------------------------------------------
// 远程字段提取（兼容多种服务商命名）
// ---------------------------------------------------------------------------

function asRecord(value: unknown): Record<string, unknown> | undefined {
  return value && typeof value === "object" && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : undefined;
}

function asStringArray(value: unknown): string[] {
  if (Array.isArray(value)) {
    return value.filter((x): x is string => typeof x === "string");
  }
  if (typeof value === "string") {
    return value
      .split(/[,+|]/)
      .map((s) => s.trim())
      .filter(Boolean);
  }
  return [];
}

function firstPositiveInt(...values: unknown[]): number | undefined {
  for (const v of values) {
    const n = typeof v === "string" ? Number(v) : v;
    if (typeof n === "number" && Number.isFinite(n) && n > 0) {
      return Math.round(n);
    }
  }
  return undefined;
}

/** 汇总所有“支持的采样参数 / 特性”列表（兼容 OpenRouter / SenseNova 等命名）。 */
function collectCapabilityLists(m: RemoteModel): string[] {
  return [
    ...(m.supported_parameters ?? []),
    ...(m.supported_sampling_parameters ?? []),
    ...(m.supported_features ?? []),
  ]
    .filter((x): x is string => typeof x === "string")
    .map((x) => x.toLowerCase());
}

/** 从各种命名中提取模型上下文窗口。 */
export function extractContextWindow(m: RemoteModel): number | undefined {
  const info = m.model_info;
  const top = m.top_provider;
  return firstPositiveInt(
    m.context_window,
    m.context_length,
    m.max_context_length,
    m.max_model_len,
    m.max_input_length,
    top?.context_length,
    info?.max_input_tokens,
  );
}

/** 从各种命名中提取模型最大输出 token 数。 */
export function extractMaxTokens(m: RemoteModel): number | undefined {
  const info = m.model_info;
  const top = m.top_provider;
  return firstPositiveInt(
    m.max_completion_tokens,
    m.max_output_tokens,
    m.max_output_length,
    m.max_tokens,
    top?.max_completion_tokens,
    info?.max_output_tokens,
  );
}

/** 判断是否支持推理/思维链。 */
export function extractReasoning(m: RemoteModel): boolean | undefined {
  const caps = collectCapabilityLists(m);
  if (
    caps.some((p) =>
      ["reasoning", "reasoning_effort", "include_reasoning", "thinking"].includes(p),
    )
  ) {
    return true;
  }
  if (m.model_info?.supports_reasoning === true) return true;
  const cap = asRecord(m.capabilities);
  if (cap?.reasoning === true || cap?.thinking === true) return true;
  if (Array.isArray(m.capabilities) && m.capabilities.includes("reasoning")) return true;
  if (typeof m.reasoning === "boolean") return m.reasoning;
  return undefined;
}

/** 提取输入模态；默认返回 undefined（即仅文本）。 */
export function extractInput(m: RemoteModel): ("text" | "image")[] | undefined {
  const mods = new Set<string>();
  for (const raw of [
    m.input_modalities,
    m.architecture?.input_modalities,
    Array.isArray(m.modalities) ? m.modalities : m.modalities?.input,
    Array.isArray(m.capabilities) ? m.capabilities : undefined,
  ]) {
    for (const x of asStringArray(raw)) mods.add(x.toLowerCase());
  }
  for (const x of collectCapabilityLists(m)) mods.add(x);
  const modality = m.architecture?.modality?.toLowerCase();
  if (modality) {
    if (modality.includes("image")) mods.add("image");
    if (modality.includes("text")) mods.add("text");
  }
  if (m.model_info?.supports_vision === true) mods.add("image");
  const cap = asRecord(m.capabilities);
  if (cap?.vision === true || cap?.image === true) mods.add("image");

  const wantsImage = [...mods].some((x) =>
    ["image", "vision", "multimodal", "image_url"].includes(x),
  );
  return wantsImage ? ["text", "image"] : undefined;
}

/** 提取展示名。 */
export function extractName(m: RemoteModel): string | undefined {
  const name = m.name ?? m.display_name;
  return typeof name === "string" && name.trim() ? name.trim() : undefined;
}

/**
 * 提取价格。
 * - OpenRouter 的 `pricing.*` 是“每 token 美元”的字符串，乘以 1e6 转为 pi 的每百万 token。
 * - 数字形式的 `pricing.*` 视为已经是每百万 token 单价（避免出现离奇数值）。
 * - LiteLLM 等 `*_cost_per_token` 按每 token 处理，`*_cost_per_million*` 按每百万处理。
 * 无法识别时返回 undefined。
 */
export function extractCost(m: RemoteModel): ByokModel["cost"] | undefined {
  const p = m.pricing;
  const info = m.model_info;
  if (!p && !info) return undefined;

  const toPerMillion = (value: unknown, perToken: boolean): number | undefined => {
    const n = typeof value === "string" ? Number(value) : typeof value === "number" ? value : undefined;
    if (typeof n !== "number" || !Number.isFinite(n) || n < 0) return undefined;
    return perToken ? n * 1_000_000 : n;
  };

  const input =
    toPerMillion(
      p?.input_cost_per_million ?? p?.input_cost_per_1m ?? info?.input_cost_per_million_tokens,
      false,
    ) ??
    toPerMillion(p?.prompt, typeof p?.prompt === "string") ??
    toPerMillion(p?.input, typeof p?.input === "string") ??
    toPerMillion(info?.input_cost_per_token, true);

  const output =
    toPerMillion(
      p?.output_cost_per_million ?? p?.output_cost_per_1m ?? info?.output_cost_per_million_tokens,
      false,
    ) ??
    toPerMillion(p?.completion, typeof p?.completion === "string") ??
    toPerMillion(p?.output, typeof p?.output === "string") ??
    toPerMillion(info?.output_cost_per_token, true);

  const cacheRead = toPerMillion(
    p?.input_cache_read ?? p?.cache_read ?? p?.cacheRead,
    typeof (p?.input_cache_read ?? p?.cache_read ?? p?.cacheRead) === "string",
  );
  const cacheWrite = toPerMillion(
    p?.input_cache_write ?? p?.cache_write ?? p?.cacheWrite,
    typeof (p?.input_cache_write ?? p?.cache_write ?? p?.cacheWrite) === "string",
  );

  if ([input, output, cacheRead, cacheWrite].every((v) => v === undefined)) {
    return undefined;
  }
  return {
    input: input ?? 0,
    output: output ?? 0,
    cacheRead: cacheRead ?? 0,
    cacheWrite: cacheWrite ?? 0,
  };
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

/** 远程模型 → ByokModel；只写入服务端确实提供的字段，缺失项留给 pi 默认值。 */
export function remoteToByokModel(m: RemoteModel): ByokModel {
  const model: ByokModel = { id: m.id };
  const name = extractName(m);
  if (name) model.name = name;
  const reasoning = extractReasoning(m);
  if (reasoning !== undefined) model.reasoning = reasoning;
  const input = extractInput(m);
  if (input) model.input = input;
  const contextWindow = extractContextWindow(m);
  if (contextWindow) model.contextWindow = contextWindow;
  const maxTokens = extractMaxTokens(m);
  if (maxTokens) model.maxTokens = maxTokens;
  const cost = extractCost(m);
  if (cost) model.cost = cost;
  return model;
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
