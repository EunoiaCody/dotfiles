/**
 * byok/index.ts — BYOK 扩展入口
 *
 * 功能：
 * - 从 `~/.pi/agent/byok.json`（或 PI_CODING_AGENT_DIR）读取配置
 * - 启动时把每个已配置 provider 注册到 pi（可用 /model 选择）
 * - 通过 `before_provider_request` 注入 temperature / top_p
 * - 通过 `/byok` 提供交互式设置向导
 *
 * 已知限制：
 * - `apiKey` 支持 `$ENV_VAR`，但以 `!` 开头的命令不会被扩展内部执行（仅由 pi 解析）。
 * - Google Generative AI 的采样参数位于 generationConfig，本扩展不做注入。
 * - 其他扩展若在同名事件中改写 payload，按扩展加载顺序可能覆盖本扩展的注入。
 */

import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { loadConfig } from "./config";
import {
  buildProviderModels,
  getRegisteredProvider,
  isByokProvider,
  registerByokProvider,
} from "./models";
import { registerByokCommands } from "./wizard";

// ---------------------------------------------------------------------------
// 状态展示
// ---------------------------------------------------------------------------

function updateStatus(ctx: ExtensionContext): void {
  if (!ctx.hasUI) return;
  const model = ctx.model;
  if (!model || !isByokProvider(model.provider)) {
    ctx.ui.setStatus("byok", undefined);
    return;
  }
  const provider = getRegisteredProvider(model.provider);
  const temp = provider?.sampling?.temperature;
  const suffix = typeof temp === "number" ? ` · temp=${temp}` : "";
  ctx.ui.setStatus("byok", `BYOK: ${model.provider}${suffix}`);
}

// ---------------------------------------------------------------------------
// 扩展入口
// ---------------------------------------------------------------------------

export default async function (pi: ExtensionAPI): Promise<void> {
  // 1) 读取配置并注册 provider（无配置则静默跳过）
  const config = loadConfig();
  let registeredCount = 0;
  for (const [id, provider] of Object.entries(config.providers)) {
    if (buildProviderModels(provider).length === 0) continue;
    if (registerByokProvider(pi, id, provider)) registeredCount += 1;
  }
  if (registeredCount > 0) {
    console.log(`[byok] registered ${registeredCount} provider(s) from ${"byok.json"}`);
  }

  // 2) 采样参数注入（仅对已注册的 BYOK provider 生效）
  pi.on("before_provider_request", (event, ctx) => {
    const providerId = ctx.model?.provider;
    if (!providerId || !isByokProvider(providerId)) return;

    const provider = getRegisteredProvider(providerId);
    const sampling = provider?.sampling;
    if (!sampling) return;

    const api = provider?.api || "openai-completions";
    // Google 系列使用 generationConfig，顶层注入会错误
    if (api === "google-generative-ai" || api === "google-vertex") return;

    const payload = event.payload;
    if (!payload || typeof payload !== "object" || Array.isArray(payload)) return;

    const patch: Record<string, unknown> = {};
    if (typeof sampling.temperature === "number" && Number.isFinite(sampling.temperature)) {
      patch.temperature = sampling.temperature;
    }
    if (typeof sampling.topP === "number" && Number.isFinite(sampling.topP)) {
      patch.top_p = sampling.topP;
    }
    if (Object.keys(patch).length === 0) return;

    return { ...(payload as Record<string, unknown>), ...patch };
  });

  // 3) 命令
  registerByokCommands(pi);

  // 4) 状态与清理
  pi.on("session_start", (_event, ctx) => {
    updateStatus(ctx);
  });
  pi.on("model_select", (_event, ctx) => {
    updateStatus(ctx);
  });
  pi.on("session_shutdown", (_event, ctx) => {
    if (ctx.hasUI) ctx.ui.setStatus("byok", undefined);
  });
}
