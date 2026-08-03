/**
 * freellmapi.ts — pi 扩展：FreeLLMAPI 自定义 Provider
 *
 * 把自建的 freellmapi 服务（OpenAI 兼容聚合路由，聚合多家免费 LLM 免费层）
 * 注册为 pi 的 provider，支持 /model 选择、流式输出、工具调用与推理（thinking）。
 *
 * 特性：
 * - 启动时动态拉取 /v1/models 目录，注册所有可用模型（约 60+ 个）
 * - 服务不可达时降级为内置静态核心模型列表，保证扩展始终可加载
 * - `auto` 模型置于首位（路由自动选最佳 + 限流/故障自动 fallover）
 * - 推理模型自动配置 DeepSeek 风格 thinking（reasoning_content）
 *
 * 使用：
 * - /model 选择 freellmapi/<model>，推荐 freellmapi/auto 或 freellmapi/deepseek-v4-flash
 * - /freellmapi-models 查看当前已注册的 freellmapi 模型列表
 * - /reload 重新拉取最新模型目录（freellmapi 目录每日自动更新两次）
 *
 * ⚠️ 注意事项（免费层特性，非 bug）：
 * - 慢速：TTFT 可能长达 50 秒+，单个请求最多等 1-2 分钟属正常现象
 * - 限流：免费层有 RPM/RPD 配额，429 时 router 会冷却并尝试下一个模型；
 *   pi 的 agent 级重试（默认 3 次退避）可兜底，或稍等片刻再试
 * - 上游不稳定：部分 provider 可能临时不可用（fetch failed / upstream_failed），
 *   建议优先使用 auto 或 deepseek-v4-flash（实测稳定）
 *
 * API Key：优先读取环境变量 FREELMAPI_API_KEY，未设置时使用下方默认值。
 * 若更换 key，直接改 DEFAULT_API_KEY 或 export FREELMAPI_API_KEY=xxx 后 /reload。
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// ---------------------------------------------------------------------------
// 常量与配置
// ---------------------------------------------------------------------------

const BASE_URL = "http://100.90.99.35:3001/v1";
const DEFAULT_API_KEY = "freellmapi-64a9cba12965017d04f2260dffe30dd53a55cb0774593776";

/** 服务不可达时的降级核心模型（实测稳定的模型优先） */
const FALLBACK_MODEL_IDS = [
  "auto",
  "deepseek-v4-flash",
  "kimi-k2.7-code",
  "gemini-3.5-flash",
];

/** 目录拉取超时：目录接口本身很快（~4s），15s 足够判定服务不可达 */
const CATALOG_FETCH_TIMEOUT_MS = 15000;

// ---------------------------------------------------------------------------
// 类型
// ---------------------------------------------------------------------------

interface RemoteModel {
  id: string;
  name?: string;
  context_window?: number;
  available?: boolean;
  supported_parameters?: string[];
}

interface ModelConfig {
  id: string;
  name: string;
  reasoning: boolean;
  input: string[];
  cost: { input: number; output: number; cacheRead: number; cacheWrite: number };
  contextWindow: number;
  maxTokens: number;
  compat?: Record<string, unknown>;
  thinkingLevelMap?: Record<string, string | null>;
}

// ---------------------------------------------------------------------------
// 工具函数
// ---------------------------------------------------------------------------

function getApiKey(): string {
  return process.env.FREELMAPI_API_KEY || DEFAULT_API_KEY;
}

async function fetchRemoteModels(): Promise<RemoteModel[]> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), CATALOG_FETCH_TIMEOUT_MS);
  try {
    const res = await fetch(`${BASE_URL}/models`, {
      headers: { Authorization: `Bearer ${getApiKey()}` },
      signal: controller.signal,
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const payload = (await res.json()) as { data?: RemoteModel[] };
    return payload.data ?? [];
  } finally {
    clearTimeout(timer);
  }
}

/** 远程模型 → pi ProviderModelConfig */
function toModelConfig(m: RemoteModel): ModelConfig {
  const supportsReasoningEffort = (m.supported_parameters ?? []).includes(
    "reasoning_effort",
  );
  const contextWindow = m.context_window ?? 128000;
  const maxTokens = Math.max(4096, Math.min(16384, Math.floor(contextWindow / 4)));

  const config: ModelConfig = {
    id: m.id,
    name: m.name ?? m.id,
    reasoning: supportsReasoningEffort,
    input: ["text"], // freellmapi 目录未声明 vision 能力，保守只开 text
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 }, // 免费层
    contextWindow,
    maxTokens,
    // 通用 OpenAI 兼容兼容项：大部分免费后端不认识 store/developer 角色，
    // max_tokens 比 max_completion_tokens 兼容面更广；
    // freellmapi 流式响应结尾带 usage（已实测），需显式开启解析
    compat: {
      supportsStore: false,
      supportsDeveloperRole: false,
      maxTokensField: "max_tokens",
      supportsUsageInStreaming: true,
    },
  };

  // 推理模型：DeepSeek 风格 thinking（返回 reasoning_content 字段）
  if (supportsReasoningEffort) {
    config.compat = {
      ...config.compat,
      thinkingFormat: "deepseek",
      supportsReasoningEffort: true,
      requiresReasoningContentOnAssistantMessages: true,
    };
  }

  return config;
}

/** 生成注册用模型列表：auto/fusion 置首，其余按 id 排序 */
function buildModels(remote: RemoteModel[]): ModelConfig[] {
  const usable = remote.filter((m) => m.available !== false);
  const byId = new Map(usable.map((m) => [m.id, m]));

  const ordered: RemoteModel[] = [];
  for (const special of ["auto", "fusion"]) {
    const m = byId.get(special);
    if (m) {
      ordered.push(m);
      byId.delete(special);
    }
  }
  const rest = [...byId.values()].sort((a, b) => a.id.localeCompare(b.id));
  ordered.push(...rest);

  return ordered.map((m) => {
    const cfg = toModelConfig(m);
    if (m.id === "auto") {
      cfg.name = `${cfg.name}（推荐：自动路由最佳可用模型，故障自动切换）`;
    } else if (m.id === "fusion") {
      cfg.name = `${cfg.name}（多模型并行合成，速度较慢）`;
    }
    return cfg;
  });
}

/** 服务不可达时的静态核心模型降级列表 */
function buildFallbackModels(): ModelConfig[] {
  const known: Record<string, { ctx: number; reasoning: boolean }> = {
    auto: { ctx: 1048576, reasoning: false },
    "deepseek-v4-flash": { ctx: 131072, reasoning: true },
    "kimi-k2.7-code": { ctx: 262144, reasoning: false },
    "gemini-3.5-flash": { ctx: 1048576, reasoning: true },
  };
  return FALLBACK_MODEL_IDS.map((id) =>
    toModelConfig({
      id,
      name: id,
      context_window: known[id]?.ctx ?? 128000,
      supported_parameters: known[id]?.reasoning ? ["reasoning_effort"] : [],
      available: true,
    }),
  );
}

// ---------------------------------------------------------------------------
// 扩展入口（异步 factory：启动时先拉取模型目录，再注册 provider）
// ---------------------------------------------------------------------------

export default async function (pi: ExtensionAPI) {
  let models: ModelConfig[];
  let catalogSource: "remote" | "fallback";

  try {
    const remote = await fetchRemoteModels();
    if (remote.length === 0) throw new Error("empty catalog");
    models = buildModels(remote);
    catalogSource = "remote";
  } catch (err) {
    console.warn(
      `[freellmapi] catalog fetch failed (${err instanceof Error ? err.message : String(err)}), using fallback models`,
    );
    models = buildFallbackModels();
    catalogSource = "fallback";
  }

  pi.registerProvider("freellmapi", {
    name: "FreeLLMAPI",
    baseUrl: BASE_URL,
    apiKey: DEFAULT_API_KEY,
    api: "openai-completions",
    models,
  });

  pi.registerCommand("freellmapi-models", {
    description: "List FreeLLMAPI registered models",
    handler: async (_args, ctx) => {
      const all = ctx.modelRegistry.getAvailable();
      const fm = all.filter((m) => m.provider === "freellmapi");
      const lines = [
        `FreeLLMAPI 模型（${fm.length} 个，来源：${catalogSource}）`,
        "用 /reload 可重新拉取最新模型目录",
        "---",
        ...fm.map((m) =>
          `- ${m.id}${m.reasoning ? "（推理）" : ""} ctx=${m.contextWindow} max=${m.maxTokens}`,
        ),
      ];
      await ctx.ui.select("FreeLLMAPI models", lines);
    },
  });

  console.log(
    `[freellmapi] registered ${models.length} models (source: ${catalogSource})`,
  );
}
