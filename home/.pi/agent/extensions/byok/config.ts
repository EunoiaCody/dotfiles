/**
 * byok/config.ts — 配置类型、读写与工具函数
 *
 * 配置持久化到 `${PI_CODING_AGENT_DIR:-~/.pi/agent}/byok.json`，权限 0600。
 * 该模块不依赖 pi 运行时，便于单元测试。
 */

import {
  chmodSync,
  existsSync,
  mkdirSync,
  readFileSync,
  renameSync,
  writeFileSync,
} from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";

// ---------------------------------------------------------------------------
// 类型
// ---------------------------------------------------------------------------

export interface ByokSampling {
  /** 有限数字表示注入；null/undefined 表示不注入（使用上游默认值）。 */
  temperature?: number | null;
  /** 映射为请求体的 top_p；null/undefined 表示不注入。 */
  topP?: number | null;
}

export interface ByokModel {
  id: string;
  name?: string;
  reasoning?: boolean;
  input?: ("text" | "image")[];
  contextWindow?: number;
  maxTokens?: number;
  cost?: { input: number; output: number; cacheRead: number; cacheWrite: number };
}

export type CompatPreset = "openai" | "openai-compat" | "deepseek";

export interface ByokProvider {
  /** 展示名，默认 `BYOK (<id>)`。 */
  name?: string;
  /** API 端点，例如 https://api.example.com/v1 */
  baseUrl: string;
  /** API Key 字面值、`$ENV_VAR` 引用或 `!command`（内部 fetch 不执行命令）。 */
  apiKey: string;
  /** pi 的 api 类型，默认 openai-completions。 */
  api?: string;
  /** 额外请求头，值同样支持 `$ENV_VAR`。 */
  headers?: Record<string, string>;
  /** 采样参数。 */
  sampling?: ByokSampling;
  /** 兼容性预设，映射为每个模型的 compat。 */
  compatPreset?: CompatPreset;
  /** 覆盖模型目录地址（相对 baseUrl 或绝对 URL）。 */
  modelsPath?: string;
  /** 已注册模型。 */
  models: ByokModel[];
  /** 最近一次通过 /byok use 选择的模型。 */
  lastModel?: string;
}

export interface ByokConfig {
  version: 1;
  providers: Record<string, ByokProvider>;
}

// ---------------------------------------------------------------------------
// 路径
// ---------------------------------------------------------------------------

export const CONFIG_FILENAME = "byok.json";

/** 配置目录：优先 PI_CODING_AGENT_DIR，否则 ~/.pi/agent。 */
export function getConfigDir(): string {
  return process.env.PI_CODING_AGENT_DIR || join(homedir(), ".pi", "agent");
}

export function getConfigPath(): string {
  return join(getConfigDir(), CONFIG_FILENAME);
}

// ---------------------------------------------------------------------------
// 读写
// ---------------------------------------------------------------------------

export function emptyConfig(): ByokConfig {
  return { version: 1, providers: {} };
}

/** 读取配置；文件缺失或损坏时返回空配置，不抛错。 */
export function loadConfig(): ByokConfig {
  try {
    const path = getConfigPath();
    if (!existsSync(path)) return emptyConfig();
    const parsed = JSON.parse(readFileSync(path, "utf-8")) as unknown;
    if (
      !parsed ||
      typeof parsed !== "object" ||
      Array.isArray(parsed) ||
      typeof (parsed as { providers?: unknown }).providers !== "object" ||
      (parsed as { providers?: unknown }).providers === null
    ) {
      return emptyConfig();
    }
    return {
      version: 1,
      providers: (parsed as { providers: Record<string, ByokProvider> }).providers,
    };
  } catch {
    return emptyConfig();
  }
}

/** 原子写入配置（临时文件 + rename），并强制 0600 权限。 */
export function saveConfig(config: ByokConfig): void {
  const dir = getConfigDir();
  mkdirSync(dir, { recursive: true });
  const target = getConfigPath();
  const tmp = join(
    dirname(target),
    `.${CONFIG_FILENAME}.tmp-${process.pid}-${Date.now()}`,
  );
  writeFileSync(tmp, `${JSON.stringify(config, null, 2)}\n`, {
    encoding: "utf-8",
    mode: 0o600,
  });
  renameSync(tmp, target);
  try {
    chmodSync(target, 0o600);
  } catch {
    // 某些文件系统不支持 chmod，忽略
  }
}

// ---------------------------------------------------------------------------
// 值解析 / 脱敏
// ---------------------------------------------------------------------------

/**
 * 解析 `$VAR`、`${VAR}` 环境变量引用（供扩展内部 fetch 使用）。
 * `$$` → 字面 `$`，`$!` → 字面 `!`。
 * 以 `!` 开头表示命令，扩展内部不执行（已知限制），原样返回。
 */
export function resolveValue(value: string): string {
  if (!value) return value;
  if (value.startsWith("!")) return value;
  const dollar = "\u0000";
  const bang = "\u0001";
  const out = value
    .replace(/\$\$/g, dollar)
    .replace(/\$!/g, bang)
    .replace(/\$\{([A-Za-z_][A-Za-z0-9_]*)\}/g, (_m, name: string) => process.env[name] ?? "")
    .replace(/\$([A-Za-z_][A-Za-z0-9_]*)/g, (_m, name: string) => process.env[name] ?? "")
    .replace(/\u0000/g, () => "$")
    .replace(/\u0001/g, () => "!");
  return out;
}

/**
 * 把用户输入的字面 key 中的 `$` 转义为 `$$`，避免 pi 在请求时误当作环境变量。
 * 已经是 `$ENV_VAR` / `${ENV_VAR}` / `!command` 形式的输入保持不变。
 */
export function escapeLiteral(value: string): string {
  if (!value) return value;
  if (value.startsWith("!")) return value;
  if (/^\$\{?[A-Za-z_]/.test(value)) return value;
  return value.replace(/\$/g, () => "$$");
}

/** 脱敏显示：保留前 4 / 后 4 位。env 引用原样显示，命令只显示标记。 */
export function maskKey(key: string): string {
  if (!key) return "";
  if (key.startsWith("!")) return "!<command>";
  if (/^\$\{?[A-Za-z_]/.test(key)) return key;
  const raw = key.replace(/\$\$/g, "$");
  if (raw.length <= 8) return "*".repeat(raw.length);
  return `${raw.slice(0, 4)}${"*".repeat(Math.max(4, raw.length - 8))}${raw.slice(-4)}`;
}

// ---------------------------------------------------------------------------
// 校验
// ---------------------------------------------------------------------------

/** 与 pi 内置 provider 重名时可能覆盖其模型，注册前需警告。 */
export const RESERVED_PROVIDER_IDS = new Set([
  "anthropic",
  "openai",
  "google",
  "google-vertex",
  "deepseek",
  "mistral",
  "xai",
  "groq",
  "openrouter",
  "azure",
  "azure-openai",
  "bedrock",
  "amazon-bedrock",
  "ollama",
  "cerebras",
  "nvidia",
  "cloudflare",
  "together",
  "fireworks",
  "baseten",
  "zai",
  "moonshot",
  "kimi",
  "qwen",
  "dashscope",
]);

export function validateProviderId(id: string): string | null {
  if (!id) return "provider id 不能为空";
  if (!/^[a-z0-9][a-z0-9-_]*$/.test(id)) {
    return "provider id 只能包含小写字母、数字、-、_，且需以字母或数字开头";
  }
  return null;
}

export function isReservedProviderId(id: string): boolean {
  return RESERVED_PROVIDER_IDS.has(id);
}

export function normalizeBaseUrl(url: string): string {
  return url.trim().replace(/\/+$/, "");
}

/** 返回错误信息或 null（通过）。 */
export function validateProvider(provider: ByokProvider): string | null {
  if (!provider.baseUrl || !/^https?:\/\//i.test(provider.baseUrl)) {
    return "baseUrl 必填且需以 http:// 或 https:// 开头";
  }
  if (!provider.apiKey) return "apiKey 必填";
  if (!Array.isArray(provider.models) || provider.models.length === 0) {
    return "至少需要 1 个模型";
  }
  return null;
}
