/**
 * byok/wizard.ts — /byok 命令与交互式设置向导
 */

import type { AutocompleteItem } from "@earendil-works/pi-tui";
import type { ExtensionAPI, ExtensionCommandContext } from "@earendil-works/pi-coding-agent";
import type { ByokConfig, ByokModel, ByokProvider, CompatPreset } from "./config";
import {
  escapeLiteral,
  isReservedProviderId,
  loadConfig,
  maskKey,
  normalizeBaseUrl,
  saveConfig,
  validateProvider,
  validateProviderId,
} from "./config";
import {
  DEFAULT_CONTEXT_WINDOW,
  fetchRemoteModels,
  registerByokProvider,
  remoteToByokModel,
  unregisterByokProvider,
  type RemoteModel,
} from "./models";

// ---------------------------------------------------------------------------
// 小工具
// ---------------------------------------------------------------------------

const SUBS = [
  "add",
  "list",
  "show",
  "edit",
  "remove",
  "use",
  "temp",
  "url",
  "key",
  "models",
  "meta",
  "test",
  "help",
] as const;

function requireUI(ctx: ExtensionCommandContext): boolean {
  if (ctx.hasUI) return true;
  try {
    console.log("[byok] 该操作需要交互式 TUI 环境。可用 /byok help 查看非交互用法。");
  } catch {
    // ignore
  }
  return false;
}

function errMessage(err: unknown): string {
  return err instanceof Error ? err.message : String(err);
}

/** 保存配置 + 注册/注销 + 写审计 entry。 */
function apply(
  pi: ExtensionAPI,
  cfg: ByokConfig,
  id: string,
  action: string,
): boolean {
  saveConfig(cfg);
  const provider = cfg.providers[id];
  let registered = false;
  if (provider) {
    registered = registerByokProvider(pi, id, provider);
  } else {
    unregisterByokProvider(pi, id);
  }
  try {
    pi.appendEntry("byok-change", { action, id, at: Date.now() });
  } catch {
    // appendEntry 在极少数上下文不可用，忽略
  }
  return registered;
}

/** 从输入解析 temperature/topP：空=null（关闭），数字=值。 */
function parseNumberOrOff(input: string): number | null {
  const t = input.trim().toLowerCase();
  if (t === "" || t === "off" || t === "none" || t === "null") return null;
  const n = Number(t);
  if (!Number.isFinite(n)) throw new Error(`无效数值：${input}`);
  return n;
}

function parseCompatChoice(choice: string | undefined): CompatPreset | undefined {
  if (!choice) return undefined;
  if (choice.startsWith("openai-compat")) return "openai-compat";
  if (choice.startsWith("deepseek")) return "deepseek";
  if (choice.startsWith("openai")) return "openai";
  return undefined;
}

function parseManualModels(input: string | undefined): ByokModel[] {
  if (!input) return [];
  return input
    .split(/[,\n]/)
    .map((s) => s.trim())
    .filter(Boolean)
    .map((id) => ({ id }));
}

function tempLabel(provider: ByokProvider): string {
  const t = provider.sampling?.temperature;
  if (typeof t === "number") return String(t);
  if (t === null) return "off";
  return "-";
}

function summaryLines(cfg: ByokConfig): string[] {
  const ids = Object.keys(cfg.providers);
  if (ids.length === 0) return ["（尚未配置任何 BYOK provider）", "使用 /byok add 添加"];
  return ids.map((id) => {
    const p = cfg.providers[id];
    return `${id} · ${p.api || "openai-completions"} · temp=${tempLabel(p)} · models=${p.models.length}\n    ${p.baseUrl}\n    key=${maskKey(p.apiKey)}`;
  });
}

async function pickProvider(
  ctx: ExtensionCommandContext,
  cfg: ByokConfig,
): Promise<string | undefined> {
  const ids = Object.keys(cfg.providers);
  if (ids.length === 0) {
    ctx.ui.notify("尚未配置任何 BYOK provider，请先 /byok add", "warning");
    return undefined;
  }
  if (ids.length === 1) return ids[0];
  return ctx.ui.select("选择 provider", ids);
}

// ---------------------------------------------------------------------------
// 模型属性编辑
// ---------------------------------------------------------------------------

function omitKey<T extends object, K extends keyof T>(obj: T, key: K): Omit<T, K> {
  const { [key]: _removed, ...rest } = obj;
  return rest;
}

/** 解析 token 数：数字 / 128k / 1m；reset/default/off 返回 null（清除）。 */
function parseTokenCount(input: string): number | null {
  const t = input.trim().toLowerCase();
  if (["", "reset", "clear", "default", "auto", "off", "none"].includes(t)) {
    return null;
  }
  const m = t.match(/^(\d+(?:\.\d+)?)\s*([kmg])?$/);
  if (!m) throw new Error(`无效数值：${input}（示例：128000 / 128k / 1m）`);
  const mult = m[2] === "k" ? 1_000 : m[2] === "m" ? 1_000_000 : m[2] === "g" ? 1_000_000_000 : 1;
  const n = Math.round(Number(m[1]) * mult);
  if (!Number.isFinite(n) || n <= 0) throw new Error(`无效数值：${input}`);
  return n;
}

function modelMetaLabel(m: ByokModel): string {
  const ctx = m.contextWindow ?? DEFAULT_CONTEXT_WINDOW;
  const ctxLabel = `${Math.round(ctx / 1000)}k${m.contextWindow === undefined ? "(默认)" : ""}`;
  const maxLabel = typeof m.maxTokens === "number" ? String(m.maxTokens) : "auto";
  const flags: string[] = [];
  if (m.reasoning) flags.push("reasoning");
  if ((m.input ?? ["text"]).includes("image")) flags.push("image");
  if (m.cost) flags.push("cost");
  return `${m.id} · ctx=${ctxLabel} · max=${maxLabel}${flags.length ? " · " + flags.join("+") : ""}`;
}

async function promptTokenCount(
  ctx: ExtensionCommandContext,
  title: string,
  current: number | undefined,
): Promise<number | null | undefined> {
  const v = await ctx.ui.input(
    `${title}（当前 ${current ?? "未设置"}；留空=保持，reset=清除，支持 128k/1m）`,
    current !== undefined ? String(current) : "128k",
  );
  if (v === undefined || v.trim() === "") return undefined; // 保持
  return parseTokenCount(v);
}

async function editOneModelMeta(
  ctx: ExtensionCommandContext,
  m: ByokModel,
): Promise<ByokModel | undefined> {
  const field = await ctx.ui.select(`编辑模型 ${m.id}`, [
    `name：${m.name ?? m.id}`,
    `contextWindow：${m.contextWindow ?? "未设置（pi 默认 128000）"}`,
    `maxTokens：${m.maxTokens ?? "未设置（自动）"}`,
    `reasoning：${m.reasoning ? "是" : "否"}`,
    `input：${(m.input ?? ["text"]).join("+")}`,
    `cost：${m.cost ? JSON.stringify(m.cost) : "未设置（全 0）"}`,
    "↩ 返回",
  ]);
  if (!field || field.startsWith("↩")) return undefined;

  if (field.startsWith("name")) {
    const v = await ctx.ui.input("name（留空=使用 id）", m.name ?? "");
    if (v === undefined) return undefined;
    return v.trim() ? { ...m, name: v.trim() } : omitKey(m, "name");
  }
  if (field.startsWith("contextWindow") || field.startsWith("maxTokens")) {
    const key = field.startsWith("contextWindow") ? "contextWindow" : "maxTokens";
    let n: number | null | undefined;
    try {
      n = await promptTokenCount(ctx, key, m[key]);
    } catch (err) {
      ctx.ui.notify(errMessage(err), "error");
      return undefined;
    }
    if (n === undefined) return undefined;
    return n === null ? omitKey(m, key) : ({ ...m, [key]: n } as ByokModel);
  }
  if (field.startsWith("reasoning")) {
    const v = await ctx.ui.select("reasoning", ["是（支持推理/思维链）", "否", "↩ 返回"]);
    if (!v || v.startsWith("↩")) return undefined;
    return { ...m, reasoning: v.startsWith("是") };
  }
  if (field.startsWith("input")) {
    const v = await ctx.ui.select("input", [
      "text（仅文本）",
      "text+image（支持图片）",
      "↩ 返回",
    ]);
    if (!v || v.startsWith("↩")) return undefined;
    return { ...m, input: v.startsWith("text+image") ? ["text", "image"] : ["text"] };
  }
  if (field.startsWith("cost")) {
    const v = await ctx.ui.editor(
      "cost JSON（$/百万 token；留空=清除）",
      m.cost
        ? JSON.stringify(m.cost, null, 2)
        : JSON.stringify({ input: 0, output: 0, cacheRead: 0, cacheWrite: 0 }, null, 2),
    );
    if (v === undefined) return undefined;
    if (!v.trim()) return omitKey(m, "cost");
    try {
      const parsed = JSON.parse(v) as Record<string, unknown>;
      if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
        throw new Error("cost 需为 JSON 对象");
      }
      const num = (k: string): number => {
        const x = parsed[k];
        return typeof x === "number" && Number.isFinite(x) ? x : 0;
      };
      return {
        ...m,
        cost: {
          input: num("input"),
          output: num("output"),
          cacheRead: num("cacheRead"),
          cacheWrite: num("cacheWrite"),
        },
      };
    } catch (err) {
      ctx.ui.notify(`解析失败：${errMessage(err)}`, "error");
      return undefined;
    }
  }
  return undefined;
}

/** 逐模型/批量编辑模型元数据；返回更新后的数组。 */
async function editModelsMeta(
  ctx: ExtensionCommandContext,
  models: ByokModel[],
): Promise<ByokModel[]> {
  const list = models.map((m) => ({ ...m }));
  while (true) {
    const action = await ctx.ui.select(`模型属性（共 ${list.length} 个模型）`, [
      "逐个编辑模型",
      "批量设置 contextWindow",
      "批量设置 maxTokens",
      "完成",
    ]);
    if (!action || action === "完成") return list;

    if (action === "批量设置 contextWindow" || action === "批量设置 maxTokens") {
      const key = action.includes("contextWindow") ? "contextWindow" : "maxTokens";
      let n: number | null | undefined;
      try {
        n = await promptTokenCount(ctx, `批量 ${key}`, undefined);
      } catch (err) {
        ctx.ui.notify(errMessage(err), "error");
        continue;
      }
      if (n === undefined) continue;
      for (const m of list) {
        if (n === null) delete (m as Record<string, unknown>)[key];
        else (m as Record<string, unknown>)[key] = n;
      }
      ctx.ui.notify(`已${n === null ? "清除" : "设置"}全部模型的 ${key}`, "info");
      continue;
    }

    while (true) {
      const labels = list.map((m, i) => `${i + 1}. ${modelMetaLabel(m)}`);
      const choice = await ctx.ui.select("选择要编辑的模型", [...labels, "↩ 返回"]);
      if (!choice || choice.startsWith("↩")) break;
      const idx = labels.indexOf(choice);
      if (idx < 0) break;
      const updated = await editOneModelMeta(ctx, list[idx]);
      if (updated) list[idx] = updated;
    }
  }
}

// ---------------------------------------------------------------------------
// 子命令
// ---------------------------------------------------------------------------

async function addWizard(pi: ExtensionAPI, ctx: ExtensionCommandContext): Promise<void> {
  if (!requireUI(ctx)) return;
  const cfg = loadConfig();

  const rawId = await ctx.ui.input("BYOK provider id", "例如 my-openai");
  if (rawId === undefined) return;
  const id = rawId.trim();
  const idErr = validateProviderId(id);
  if (idErr) {
    ctx.ui.notify(idErr, "error");
    return;
  }
  if (cfg.providers[id]) {
    ctx.ui.notify(`"${id}" 已存在，请用 /byok edit ${id}`, "warning");
    return;
  }
  if (isReservedProviderId(id)) {
    const ok = await ctx.ui.confirm(
      "内置 provider 名称",
      `"${id}" 与 pi 内置 provider 同名，注册后可能覆盖其模型。继续？`,
    );
    if (!ok) return;
  }

  const rawUrl = await ctx.ui.input("Base URL", "https://api.example.com/v1");
  if (rawUrl === undefined || !rawUrl.trim()) return;
  const baseUrl = normalizeBaseUrl(rawUrl);
  if (!/^https?:\/\//i.test(baseUrl)) {
    ctx.ui.notify("Base URL 需以 http:// 或 https:// 开头", "error");
    return;
  }

  const rawKey = await ctx.ui.input("API Key（可填 $ENV_VAR）", "sk-... 或 $MY_API_KEY");
  if (rawKey === undefined || !rawKey.trim()) return;
  const apiKey = escapeLiteral(rawKey.trim());

  const api =
    (await ctx.ui.select("API 类型", [
      "openai-completions",
      "anthropic-messages",
      "openai-responses",
      "google-generative-ai",
    ])) ?? "openai-completions";

  const compatPreset = parseCompatChoice(
    await ctx.ui.select("兼容预设", [
      "openai（默认，不设置 compat）",
      "openai-compat（Ollama / vLLM / 通用兼容）",
      "deepseek（DeepSeek 风格 thinking）",
    ]),
  );

  const rawTemp = await ctx.ui.input(
    "Temperature（留空/off=不注入，使用上游默认）",
    "0.7",
  );
  let sampling: ByokProvider["sampling"];
  if (rawTemp !== undefined && rawTemp.trim() !== "") {
    try {
      sampling = { temperature: parseNumberOrOff(rawTemp) };
    } catch (err) {
      ctx.ui.notify(errMessage(err), "error");
      return;
    }
  }

  const draft: ByokProvider = {
    baseUrl,
    apiKey,
    api,
    compatPreset,
    sampling,
    models: [],
  };

  // 拉取模型目录
  let models: ByokModel[] = [];
  try {
    const remote = await fetchRemoteModels(draft, ctx.signal);
    if (remote.length > 0) {
      models = await chooseModels(ctx, remote);
    } else {
      ctx.ui.notify("模型目录为空，改为手动输入", "warning");
      models = parseManualModels(await ctx.ui.editor("输入模型 ID（逗号或换行分隔）", ""));
    }
  } catch (err) {
    ctx.ui.notify(`拉取模型目录失败：${errMessage(err)}，改为手动输入`, "warning");
    models = parseManualModels(await ctx.ui.editor("输入模型 ID（逗号或换行分隔）", ""));
  }

  if (models.length === 0) {
    ctx.ui.notify("未添加任何模型，已取消保存。可稍后用 /byok models 设置。", "warning");
    return;
  }

  const adjust = await ctx.ui.confirm(
    "调整模型属性",
    `已识别 ${models.length} 个模型。是否现在调整 contextWindow / maxTokens / reasoning / 图片输入 / 价格？\n（可稍后用 /byok edit 或 /byok meta 修改）`,
  );
  if (adjust) models = await editModelsMeta(ctx, models);

  draft.models = models;
  const validation = validateProvider(draft);
  if (validation) {
    ctx.ui.notify(validation, "error");
    return;
  }

  cfg.providers[id] = draft;
  const registered = apply(pi, cfg, id, "add");
  ctx.ui.notify(
    `已保存 provider "${id}"${registered ? " 并注册" : "（未注册）"}。用 /model 选择 ${id}/<model>`,
    "info",
  );
}

async function chooseModels(
  ctx: ExtensionCommandContext,
  remote: RemoteModel[],
): Promise<ByokModel[]> {
  const choice = await ctx.ui.select(`发现 ${remote.length} 个模型`, [
    "注册全部",
    "选择子集（逗号分隔）",
    "手动输入模型 ID",
    "取消，不添加模型",
  ]);
  if (!choice || choice.startsWith("取消")) return [];

  if (choice === "注册全部") return remote.map(remoteToByokModel);

  if (choice.startsWith("选择子集")) {
    const csv = await ctx.ui.editor(
      "输入要注册的模型 ID（逗号分隔）",
      remote.map((m) => m.id).join(", "),
    );
    const wanted = new Set((csv ?? "").split(/[,\s]+/).filter(Boolean));
    return remote.filter((m) => wanted.has(m.id)).map(remoteToByokModel);
  }

  return parseManualModels(
    await ctx.ui.editor("输入模型 ID（逗号或换行分隔）", ""),
  );
}

async function listCmd(ctx: ExtensionCommandContext): Promise<void> {
  const cfg = loadConfig();
  const lines = summaryLines(cfg);
  if (ctx.hasUI) {
    await ctx.ui.select("BYOK providers", lines);
  } else {
    for (const line of lines) console.log(line);
  }
}

async function showCmd(
  ctx: ExtensionCommandContext,
  idArg?: string,
): Promise<void> {
  const cfg = loadConfig();
  const id = idArg ?? (await pickProvider(ctx, cfg));
  if (!id) return;
  const p = cfg.providers[id];
  if (!p) {
    ctx.ui.notify(`找不到 provider "${id}"`, "error");
    return;
  }
  const detail = [
    `id: ${id}`,
    `name: ${p.name ?? `BYOK (${id})`}`,
    `baseUrl: ${p.baseUrl}`,
    `api: ${p.api || "openai-completions"}`,
    `apiKey: ${maskKey(p.apiKey)}`,
    `temperature: ${tempLabel(p)}`,
    `topP: ${typeof p.sampling?.topP === "number" ? p.sampling.topP : "-"}`,
    `compat: ${p.compatPreset ?? "openai(default)"}`,
    `modelsPath: ${p.modelsPath ?? "(auto)"}`,
    `headers: ${p.headers ? JSON.stringify(p.headers) : "-"}`,
    `models(${p.models.length}): ${p.models.map((m) => m.id).join(", ") || "-"}`,
    `lastModel: ${p.lastModel ?? "-"}`,
  ].join("\n");
  if (ctx.hasUI) {
    await ctx.ui.select(`BYOK / ${id}`, [detail]);
  } else {
    console.log(detail);
  }
}

async function editWizard(
  pi: ExtensionAPI,
  ctx: ExtensionCommandContext,
  idArg?: string,
): Promise<void> {
  if (!requireUI(ctx)) return;
  const cfg = loadConfig();
  const id = idArg ?? (await pickProvider(ctx, cfg));
  if (!id) return;
  const p = cfg.providers[id];
  if (!p) {
    ctx.ui.notify(`找不到 provider "${id}"`, "error");
    return;
  }

  const field = await ctx.ui.select(`编辑 ${id}`, [
    "baseUrl",
    "apiKey",
    "api 类型",
    "temperature",
    "topP",
    "兼容预设",
    "模型列表（重新拉取）",
    "模型属性（contextWindow/maxTokens 等）",
    "headers (JSON)",
    "modelsPath",
    "lastModel",
  ]);
  if (!field) return;

  if (field === "baseUrl") {
    const v = await ctx.ui.input("Base URL", p.baseUrl);
    if (v === undefined || !v.trim()) return;
    const normalized = normalizeBaseUrl(v);
    if (!/^https?:\/\//i.test(normalized)) {
      ctx.ui.notify("Base URL 需以 http:// 或 https:// 开头", "error");
      return;
    }
    p.baseUrl = normalized;
  } else if (field === "apiKey") {
    const v = await ctx.ui.input("API Key（可填 $ENV_VAR）", maskKey(p.apiKey));
    if (v === undefined || !v.trim()) return;
    p.apiKey = escapeLiteral(v.trim());
  } else if (field === "api 类型") {
    const v = await ctx.ui.select("API 类型", [
      "openai-completions",
      "anthropic-messages",
      "openai-responses",
      "google-generative-ai",
    ]);
    if (!v) return;
    p.api = v;
  } else if (field === "temperature") {
    const v = await ctx.ui.input(
      `temperature（当前 ${tempLabel(p)}，留空=保持，off=关闭）`,
      "0.7",
    );
    if (v === undefined || v.trim() === "") return;
    try {
      p.sampling = { ...(p.sampling ?? {}), temperature: parseNumberOrOff(v) };
    } catch (err) {
      ctx.ui.notify(errMessage(err), "error");
      return;
    }
  } else if (field === "topP") {
    const cur = p.sampling?.topP;
    const v = await ctx.ui.input(
      `topP（当前 ${typeof cur === "number" ? cur : "-"}，留空=保持，off=关闭）`,
      "0.95",
    );
    if (v === undefined || v.trim() === "") return;
    try {
      p.sampling = { ...(p.sampling ?? {}), topP: parseNumberOrOff(v) };
    } catch (err) {
      ctx.ui.notify(errMessage(err), "error");
      return;
    }
  } else if (field === "兼容预设") {
    const v = await ctx.ui.select("兼容预设", [
      "openai（默认）",
      "openai-compat（Ollama / vLLM）",
      "deepseek",
    ]);
    if (!v) return;
    p.compatPreset = parseCompatChoice(v);
  } else if (field.startsWith("模型列表")) {
    await refreshModels(pi, ctx, cfg, id);
    return;
  } else if (field.startsWith("模型属性")) {
    p.models = await editModelsMeta(ctx, p.models);
  } else if (field.startsWith("headers")) {
    const v = await ctx.ui.editor(
      "headers JSON（例如 {\"X-Api-Version\":\"1\"}）",
      p.headers ? JSON.stringify(p.headers, null, 2) : "{}",
    );
    if (v === undefined) return;
    try {
      const parsed = JSON.parse(v);
      if (parsed && typeof parsed === "object" && !Array.isArray(parsed)) {
        p.headers = Object.keys(parsed).length > 0 ? parsed : undefined;
      } else {
        throw new Error("headers 需为 JSON 对象");
      }
    } catch (err) {
      ctx.ui.notify(`解析失败：${errMessage(err)}`, "error");
      return;
    }
  } else if (field === "modelsPath") {
    const v = await ctx.ui.input("modelsPath（留空=自动）", p.modelsPath ?? "");
    if (v === undefined) return;
    p.modelsPath = v.trim() || undefined;
  } else if (field === "lastModel") {
    const v = await ctx.ui.input("lastModel", p.lastModel ?? "");
    if (v === undefined) return;
    p.lastModel = v.trim() || undefined;
  }

  const validation = validateProvider(p);
  if (validation) {
    ctx.ui.notify(validation, "error");
    return;
  }
  const registered = apply(pi, cfg, id, "edit");
  ctx.ui.notify(`已保存 ${id}${registered ? " 并重新注册" : ""}`, "info");
}

async function refreshModels(
  pi: ExtensionAPI,
  ctx: ExtensionCommandContext,
  cfg: ByokConfig,
  id: string,
): Promise<void> {
  const p = cfg.providers[id];
  if (!p) return;
  try {
    const remote = await fetchRemoteModels(p, ctx.signal);
    if (remote.length === 0) {
      ctx.ui.notify("模型目录为空，保持原列表", "warning");
      return;
    }
    const models = await chooseModels(ctx, remote);
    if (models.length === 0) return;
    const adjust = await ctx.ui.confirm(
      "调整模型属性",
      `已识别 ${models.length} 个模型。是否现在调整 contextWindow / maxTokens / reasoning / 图片输入 / 价格？`,
    );
    p.models = adjust ? await editModelsMeta(ctx, models) : models;
    const registered = apply(pi, cfg, id, "models");
    ctx.ui.notify(
      `已更新 ${id} 的模型列表（${models.length} 个）${registered ? "" : "，未注册（列表为空？）"}`,
      "info",
    );
  } catch (err) {
    ctx.ui.notify(`拉取失败：${errMessage(err)}`, "error");
  }
}

async function removeCmd(
  pi: ExtensionAPI,
  ctx: ExtensionCommandContext,
  idArg?: string,
): Promise<void> {
  const cfg = loadConfig();
  const id = idArg ?? (await pickProvider(ctx, cfg));
  if (!id) return;
  if (!cfg.providers[id]) {
    ctx.ui.notify(`找不到 provider "${id}"`, "error");
    return;
  }
  if (ctx.hasUI) {
    const ok = await ctx.ui.confirm(
      "删除 BYOK provider",
      `确认删除 "${id}"？其自定义模型将不可用（内置 provider 会恢复）。`,
    );
    if (!ok) return;
  }
  delete cfg.providers[id];
  apply(pi, cfg, id, "remove");
  ctx.ui.notify(`已删除 "${id}"`, "info");
}

async function useCmd(
  pi: ExtensionAPI,
  ctx: ExtensionCommandContext,
  idArg?: string,
  modelArg?: string,
): Promise<void> {
  const cfg = loadConfig();
  const id = idArg ?? (await pickProvider(ctx, cfg));
  if (!id) return;
  const p = cfg.providers[id];
  if (!p) {
    ctx.ui.notify(`找不到 provider "${id}"`, "error");
    return;
  }
  let modelId = modelArg || p.lastModel || p.models[0]?.id;
  if (!modelArg && p.models.length > 1 && ctx.hasUI) {
    const choice = await ctx.ui.select(
      `选择模型（${id}）`,
      p.models.map((m) => m.id),
    );
    if (!choice) return;
    modelId = choice;
  }
  if (!modelId) {
    ctx.ui.notify(`"${id}" 没有可用模型，请先 /byok models ${id}`, "error");
    return;
  }
  const model = ctx.modelRegistry.find(id, modelId);
  if (!model) {
    ctx.ui.notify(
      `在模型注册表中找不到 ${id}/${modelId}。请尝试 /byok models ${id} 刷新后重试。`,
      "error",
    );
    return;
  }
  const ok = await pi.setModel(model);
  if (!ok) {
    ctx.ui.notify(`切换失败：${id} 未配置有效认证`, "error");
    return;
  }
  p.lastModel = modelId;
  saveConfig(cfg);
  ctx.ui.notify(`已切换到 ${id}/${modelId}`, "info");
}

async function tempCmd(
  pi: ExtensionAPI,
  ctx: ExtensionCommandContext,
  idArg?: string,
  value?: string,
): Promise<void> {
  const cfg = loadConfig();
  const id = idArg ?? (await pickProvider(ctx, cfg));
  if (!id) return;
  const p = cfg.providers[id];
  if (!p) {
    ctx.ui.notify(`找不到 provider "${id}"`, "error");
    return;
  }
  let raw = value;
  if (raw === undefined || raw.trim() === "") {
    if (!requireUI(ctx)) return;
    raw = await ctx.ui.input(`temperature（当前 ${tempLabel(p)}，off=关闭）`, "0.7");
    if (raw === undefined || raw.trim() === "") return;
  }
  try {
    p.sampling = { ...(p.sampling ?? {}), temperature: parseNumberOrOff(raw) };
  } catch (err) {
    ctx.ui.notify(errMessage(err), "error");
    return;
  }
  apply(pi, cfg, id, "temp");
  ctx.ui.notify(`${id} temperature = ${tempLabel(p)}`, "info");
}

async function urlCmd(
  pi: ExtensionAPI,
  ctx: ExtensionCommandContext,
  idArg?: string,
  value?: string,
): Promise<void> {
  const cfg = loadConfig();
  const id = idArg ?? (await pickProvider(ctx, cfg));
  if (!id) return;
  const p = cfg.providers[id];
  if (!p) {
    ctx.ui.notify(`找不到 provider "${id}"`, "error");
    return;
  }
  let raw = value;
  if (raw === undefined || raw.trim() === "") {
    if (!requireUI(ctx)) return;
    raw = await ctx.ui.input("Base URL", p.baseUrl);
    if (raw === undefined || raw.trim() === "") return;
  }
  const normalized = normalizeBaseUrl(raw);
  if (!/^https?:\/\//i.test(normalized)) {
    ctx.ui.notify("Base URL 需以 http:// 或 https:// 开头", "error");
    return;
  }
  p.baseUrl = normalized;
  apply(pi, cfg, id, "url");
  ctx.ui.notify(`${id} baseUrl = ${p.baseUrl}`, "info");
}

async function keyCmd(
  pi: ExtensionAPI,
  ctx: ExtensionCommandContext,
  idArg?: string,
  value?: string,
): Promise<void> {
  const cfg = loadConfig();
  const id = idArg ?? (await pickProvider(ctx, cfg));
  if (!id) return;
  const p = cfg.providers[id];
  if (!p) {
    ctx.ui.notify(`找不到 provider "${id}"`, "error");
    return;
  }
  let raw = value;
  if (raw === undefined || raw.trim() === "") {
    if (!requireUI(ctx)) return;
    raw = await ctx.ui.input("API Key（可填 $ENV_VAR）", maskKey(p.apiKey));
    if (raw === undefined || raw.trim() === "") return;
  }
  p.apiKey = escapeLiteral(raw.trim());
  apply(pi, cfg, id, "key");
  ctx.ui.notify(`${id} apiKey = ${maskKey(p.apiKey)}`, "info");
}

async function testCmd(
  ctx: ExtensionCommandContext,
  idArg?: string,
): Promise<void> {
  const cfg = loadConfig();
  const id = idArg ?? (await pickProvider(ctx, cfg));
  if (!id) return;
  const p = cfg.providers[id];
  if (!p) {
    ctx.ui.notify(`找不到 provider "${id}"`, "error");
    return;
  }
  try {
    const remote = await fetchRemoteModels(p, ctx.signal);
    ctx.ui.notify(`连通成功：${id} 返回 ${remote.length} 个模型`, "info");
  } catch (err) {
    ctx.ui.notify(`连接失败：${errMessage(err)}`, "error");
  }
}

async function helpCmd(ctx: ExtensionCommandContext): Promise<void> {
  const lines = [
    "用法：",
    "  /byok                     打开主菜单",
    "  /byok add                 新增 provider（向导）",
    "  /byok list                查看已配置 provider",
    "  /byok show [id]           查看详情",
    "  /byok edit [id]           编辑 provider",
    "  /byok remove [id]         删除 provider",
    "  /byok use <id> [model]    切换会话模型",
    "  /byok temp <id> <n|off>   设置 temperature",
    "  /byok url <id> <baseUrl>  修改 Base URL",
    "  /byok key <id> <key>      修改 API Key",
    "  /byok models <id>         刷新模型列表",
    "  /byok meta <id>           编辑模型属性（上下文窗口/最大输出/价格等）",
    "  /byok test <id>           测试连通性",
  ];
  if (ctx.hasUI) {
    await ctx.ui.select("BYOK 帮助", lines);
  } else {
    for (const line of lines) console.log(line);
  }
}

async function menu(pi: ExtensionAPI, ctx: ExtensionCommandContext): Promise<void> {
  if (!requireUI(ctx)) return;
  const cfg = loadConfig();
  const count = Object.keys(cfg.providers).length;
  const choice = await ctx.ui.select(`BYOK（已配置 ${count} 个 provider）`, [
    "add — 新增 provider",
    "list — 查看已配置",
    "edit — 编辑 provider",
    "remove — 删除 provider",
    "use — 切换模型",
    "models — 刷新模型列表",
    "meta — 编辑模型属性（上下文/最大输出/价格）",
    "temp — 设置 temperature",
    "url — 修改 Base URL",
    "key — 修改 API Key",
    "test — 测试连通性",
    "help — 帮助",
  ]);
  if (!choice) return;
  const sub = choice.split(" ")[0];
  await dispatch(pi, ctx, sub, []);
}

async function dispatch(
  pi: ExtensionAPI,
  ctx: ExtensionCommandContext,
  sub: string | undefined,
  rest: string[],
): Promise<void> {
  switch (sub ?? "") {
    case "":
      return menu(pi, ctx);
    case "add":
      return addWizard(pi, ctx);
    case "list":
      return listCmd(ctx);
    case "show":
      return showCmd(ctx, rest[0]);
    case "edit":
      return editWizard(pi, ctx, rest[0]);
    case "remove":
      return removeCmd(pi, ctx, rest[0]);
    case "use":
      return useCmd(pi, ctx, rest[0], rest[1]);
    case "temp":
      return tempCmd(pi, ctx, rest[0], rest.slice(1).join(" "));
    case "url":
      return urlCmd(pi, ctx, rest[0], rest.slice(1).join(" "));
    case "key":
      return keyCmd(pi, ctx, rest[0], rest.slice(1).join(" "));
    case "models":
      return (async () => {
        const cfg = loadConfig();
        const id = rest[0] ?? (await pickProvider(ctx, cfg));
        if (!id) return;
        if (!cfg.providers[id]) {
          ctx.ui.notify(`找不到 provider "${id}"`, "error");
          return;
        }
        if (!requireUI(ctx)) return;
        await refreshModels(pi, ctx, cfg, id);
      })();
    case "meta":
      return (async () => {
        const cfg = loadConfig();
        const id = rest[0] ?? (await pickProvider(ctx, cfg));
        if (!id) return;
        const p = cfg.providers[id];
        if (!p) {
          ctx.ui.notify(`找不到 provider "${id}"`, "error");
          return;
        }
        if (!requireUI(ctx)) return;
        p.models = await editModelsMeta(ctx, p.models);
        const registered = apply(pi, cfg, id, "meta");
        ctx.ui.notify(
          `已更新 ${id} 的模型属性（${p.models.length} 个）${registered ? "" : "，未注册"}`,
          "info",
        );
      })();
    case "test":
      return testCmd(ctx, rest[0]);
    case "help":
      return helpCmd(ctx);
    default:
      ctx.ui.notify(
        `未知子命令 "${sub}"。可用：${SUBS.join(", ")}`,
        "warning",
      );
  }
}

// ---------------------------------------------------------------------------
// 注册
// ---------------------------------------------------------------------------

export function registerByokCommands(pi: ExtensionAPI): void {
  pi.registerCommand("byok", {
    description: "管理 BYOK 自定义 provider（base_url / api_key / 模型 / temperature）",
    getArgumentCompletions: (prefix: string): AutocompleteItem[] | null => {
      const cfg = loadConfig();
      const items: AutocompleteItem[] = [
        ...SUBS.map((s) => ({ value: s, label: s })),
        ...Object.keys(cfg.providers).map((id) => ({
          value: id,
          label: `provider: ${id}`,
        })),
      ];
      const filtered = items.filter((i) => i.value.startsWith(prefix));
      return filtered.length > 0 ? filtered : null;
    },
    handler: async (args, ctx) => {
      const parts = (args ?? "").trim().split(/\s+/).filter(Boolean);
      const [sub, ...rest] = parts;
      await dispatch(pi, ctx, sub, rest);
    },
  });
}
