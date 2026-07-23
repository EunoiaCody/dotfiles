/**
 * plan.ts — Pi extension: Plan Mode (plan-first, then execute)
 *
 * Forces the agent to create a detailed, structured plan BEFORE making any
 * changes. The user reviews and approves the plan, then the agent executes
 * step by step with automatic progress tracking.
 *
 * Commands:
 *   /plan [task]              — Enter plan mode (optionally with task description)
 *   /plan approve [name]      — Approve a plan and begin execution
 *   /plan reject [name]       — Reject a plan, return to normal mode
 *   /plan show [name]         — Display a plan
 *   /plan revise <notes>      — Revise the plan with feedback
 *   /plan done                — Mark plan execution as complete
 *   /plan list                — List all saved plans
 *
 * Legacy aliases (still work):
 *   /plan-approve, /plan-reject, /plan-show, /plan-revise, /plan-done
 *
 * States: idle → planning → reviewing → executing → idle
 *
 * Plans are persisted to <cwd>/.pi/plan/ as JSON for reliability across
 * sessions, plus a human-readable plan.md for each plan.
 *
 * In planning & reviewing phases: ALL write/edit/bash-mutation tools are BLOCKED.
 * In execution phase: plan steps sync to todo list, full tools available.
 *
 * Auto-discovered from ~/.pi/agent/extensions/.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { isToolCallEventType } from "@earendil-works/pi-coding-agent";
import {
  writeFileSync,
  readFileSync,
  existsSync,
  unlinkSync,
  mkdirSync,
  readdirSync,
} from "node:fs";
import { join, basename } from "node:path";

// ---------------------------------------------------------------------------
// Plan mode state machine
// ---------------------------------------------------------------------------

type PlanState = "idle" | "planning" | "reviewing" | "executing";

interface PlanStep {
  id: number;
  text: string;
  done: boolean;
}

interface Plan {
  name: string; // sanitized filename-safe name
  title: string;
  task: string;
  content: string; // markdown plan body
  steps: PlanStep[];
  approvedAt: number | null;
  createdAt: number;
}

let planState: PlanState = "idle";
let currentPlan: Plan | null = null;
let planStepCounter = 0;
let userLanguage: "zh" | "en" | "other" = "en";

// To avoid re-injecting delegation instructions on every turn (they'd stack)
let mainAgentGuidelinesInjected = false;

// ---------------------------------------------------------------------------
// Plan directory & file helpers
// ---------------------------------------------------------------------------

const PLAN_DIR_NAME = ".pi/plan";

function planDir(cwd: string): string {
  return join(cwd, PLAN_DIR_NAME);
}

function ensurePlanDir(cwd: string): string {
  const dir = planDir(cwd);
  if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
  return dir;
}

function currentPlanPath(cwd: string): string {
  return join(ensurePlanDir(cwd), "current.json");
}

function planPathByName(cwd: string, name: string): string {
  return join(ensurePlanDir(cwd), `${name}.json`);
}

function planMarkdownPath(cwd: string, name: string): string {
  return join(ensurePlanDir(cwd), `${name}.md`);
}

/** Sanitize a title into a filename-safe plan name. */
function sanitizePlanName(title: string): string {
  const sanitized = title
    .replace(/[\s/\\?%*:|"<>]+/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "")
    .toLowerCase()
    .slice(0, 64);
  // Avoid "untitled" / "untitled-plan" collisions by appending timestamp
  if (!sanitized || sanitized === "untitled" || sanitized.startsWith("untitled-")) {
    return `plan-${Date.now()}`;
  }
  return sanitized;
}

// ---------------------------------------------------------------------------
// Persist & load plans
// ---------------------------------------------------------------------------

function saveCurrentPlanState(cwd: string): void {
  if (!currentPlan) {
    // Remove stale current.json if plan was cleared
    try {
      const p = currentPlanPath(cwd);
      if (existsSync(p)) unlinkSync(p);
    } catch { /* ok */ }
    return;
  }
  const payload = {
    name: currentPlan.name,
    title: currentPlan.title,
    task: currentPlan.task,
    content: currentPlan.content,
    steps: currentPlan.steps,
    approvedAt: currentPlan.approvedAt,
    createdAt: currentPlan.createdAt,
    state: planState,
    language: userLanguage,
  };
  writeFileSync(currentPlanPath(cwd), JSON.stringify(payload, null, 2), "utf-8");
}

function savePlanToFile(cwd: string, plan: Plan): void {
  ensurePlanDir(cwd);

  // Save JSON
  const jsonPath = planPathByName(cwd, plan.name);
  writeFileSync(
    jsonPath,
    JSON.stringify(
      {
        name: plan.name,
        title: plan.title,
        task: plan.task,
        content: plan.content,
        steps: plan.steps,
        approvedAt: plan.approvedAt,
        createdAt: plan.createdAt,
      },
      null,
      2,
    ),
    "utf-8",
  );

  // Save markdown
  const mdPath = planMarkdownPath(cwd, plan.name);
  const titleLabel =
    userLanguage === "zh" ? `# 计划：${plan.title}` : `# Plan: ${plan.title}`;
  const createdLabel =
    userLanguage === "zh"
      ? `> 创建时间：${new Date(plan.createdAt).toLocaleString()}`
      : `> Created: ${new Date(plan.createdAt).toLocaleString()}`;
  const approvedLabel = plan.approvedAt
    ? userLanguage === "zh"
      ? `> 批准时间：${new Date(plan.approvedAt).toLocaleString()}`
      : `> Approved: ${new Date(plan.approvedAt).toLocaleString()}`
    : userLanguage === "zh"
      ? `> 状态：${planState === "planning" ? "规划中" : planState === "reviewing" ? "审阅中" : planState === "executing" ? "执行中" : planState}`
      : `> Status: ${planState}`;
  const taskLabel = userLanguage === "zh" ? `## 任务` : `## Task`;

  writeFileSync(
    mdPath,
    [titleLabel, ``, createdLabel, approvedLabel, ``, taskLabel, plan.task, ``, plan.content].join(
      "\n",
    ),
    "utf-8",
  );

  // Also save current state
  saveCurrentPlanState(cwd);
}

function loadPlanFromFile(cwd: string, name: string): Plan | null {
  const jsonPath = planPathByName(cwd, name);
  if (!existsSync(jsonPath)) return null;
  try {
    const raw = JSON.parse(readFileSync(jsonPath, "utf-8"));
    return {
      name: raw.name || name,
      title: raw.title || name,
      task: raw.task || "",
      content: raw.content || "",
      steps: raw.steps || [],
      approvedAt: raw.approvedAt ?? null,
      createdAt: raw.createdAt || Date.now(),
    };
  } catch {
    return null;
  }
}

function loadCurrentPlanState(cwd: string): {
  plan: Plan;
  state: PlanState;
  language: "zh" | "en" | "other";
} | null {
  const p = currentPlanPath(cwd);
  if (!existsSync(p)) return null;
  try {
    const raw = JSON.parse(readFileSync(p, "utf-8"));
    const plan: Plan = {
      name: raw.name || "current",
      title: raw.title || "Untitled",
      task: raw.task || "",
      content: raw.content || "",
      steps: raw.steps || [],
      approvedAt: raw.approvedAt ?? null,
      createdAt: raw.createdAt || Date.now(),
    };
    return {
      plan,
      state: raw.state || "reviewing",
      language: raw.language || "en",
    };
  } catch {
    return null;
  }
}

function deletePlanFiles(cwd: string, name: string): void {
  try {
    const jp = planPathByName(cwd, name);
    if (existsSync(jp)) unlinkSync(jp);
    const mp = planMarkdownPath(cwd, name);
    if (existsSync(mp)) unlinkSync(mp);
  } catch { /* ok */ }
}

function listSavedPlans(cwd: string): Array<{ name: string; title: string; createdAt: number }> {
  const dir = planDir(cwd);
  if (!existsSync(dir)) return [];
  const result: Array<{ name: string; title: string; createdAt: number }> = [];
  try {
    for (const entry of readdirSync(dir)) {
      if (entry.endsWith(".json") && entry !== "current.json") {
        const name = entry.slice(0, -5); // remove .json
        const plan = loadPlanFromFile(cwd, name);
        if (plan) {
          result.push({ name: plan.name, title: plan.title, createdAt: plan.createdAt });
        }
      }
    }
  } catch { /* ok */ }
  result.sort((a, b) => b.createdAt - a.createdAt);
  return result;
}

// ---------------------------------------------------------------------------
// Language detection
// ---------------------------------------------------------------------------

function detectLanguage(text: string): "zh" | "en" | "other" {
  const cjkCount = (
    text.match(/[\u4e00-\u9fff\u3400-\u4dbf\uf900-\ufaff\u3000-\u303f\uff00-\uffef]/g) || []
  ).length;
  const totalChars = text.replace(/\s/g, "").length;
  if (totalChars > 0 && cjkCount / totalChars > 0.15) return "zh";
  if (/[\u4e00-\u9fff]/.test(text)) return "zh";
  return "en";
}

/** Language-specific prompt snippets. */
const LANG: Record<
  string,
  { planRules: string; reviewInstruction: string; completeInstruction: string }
> = {
  zh: {
    planRules: `\n**语言要求**: 用户使用中文交流。请用中文撰写整个计划，包括标题、概述、步骤描述和风险分析。\n**标题格式**: 计划第一行必须使用 \`## Plan: <标题>\` 或 \`## 计划：<标题>\` 作为标题（支持中英文冒号），以便系统正确解析计划名称。`,
    reviewInstruction: `用中文向用户总结计划要点，请求审批。`,
    completeInstruction: `用中文确认计划已完成。`,
  },
  en: {
    planRules: ``,
    reviewInstruction: `Summarize the plan for the user and ask them to approve, reject, or revise.`,
    completeInstruction: `Confirm the plan is complete.`,
  },
  other: {
    planRules: `\n**Language**: Match the user's language in your plan output.`,
    reviewInstruction: `Summarize the plan for the user in their language.`,
    completeInstruction: `Confirm plan completion in the user's language.`,
  },
};

// ---------------------------------------------------------------------------
// System prompts for each phase
// ---------------------------------------------------------------------------

function planModePrompt(lang: "zh" | "en" | "other"): string {
  return `
## 🔵 PLAN MODE ACTIVE — READ ONLY

You are in **planning mode**. Your ENTIRE job right now is to analyze the task
and produce a thorough, actionable plan. You MUST NOT make any changes yet.
${LANG[lang].planRules}

### Rules:
1. **READ ONLY (except .md)**: Do NOT use write or edit on non-.md files.
   You may use: read, bash (read-only), web_search, web_fetch, task_status, todo_list.
   You MAY use write/edit for .md files (plan documents, research notes, analysis).
2. **Analyze first**: Read relevant files to understand the codebase before planning.
3. **Structure your plan** in clear Markdown using this format:

\`\`\`markdown
## Plan: <title>

### Overview
2-3 sentences summarizing the approach.

### Affected Files
- \`path/to/file1\` — what will change
- \`path/to/file2\` — what will change

### Step-by-Step Plan

#### Phase 1: <phase name>
- [ ] Step 1 description (specific, actionable)
- [ ] Step 2 description

#### Phase 2: <phase name>
- [ ] Step 3 description
...

### Risks & Considerations
- Risk 1 and how to mitigate
- Risk 2

### Estimated Impact
- Files to create: N
- Files to modify: N
- Files to delete: N
\`\`\`

4. **Be specific**: Each step must be concrete (edit which file, add what function, etc.).
5. **Think about order**: Dependencies between steps. What must happen first?
6. **When done**, state clearly "PLAN COMPLETE" so the user can review and approve it.

After the user approves, you will enter execution mode and follow the plan step by step.`;
}

function reviewPrompt(lang: "zh" | "en" | "other"): string {
  if (lang === "zh") {
    return `
## 🟡 计划审阅中 — 等待批准

计划已生成，正在等待用户审批。**严格禁止**执行任何修改操作。

你的任务：向用户总结计划内容，并请用户选择：
- \`/plan approve\` — 批准并开始执行
- \`/plan reject\` — 放弃计划
- \`/plan revise <意见>\` — 提出修改意见

**重要：** 在用户明确批准之前，所有写入/编辑/bash 修改工具均被硬性阻止。你只能进行只读分析。不要尝试执行计划中的任何步骤。`;
  }
  return `
## 🟡 PLAN READY FOR REVIEW — AWAITING APPROVAL

A plan has been prepared and is awaiting user approval. **Strictly NO modifications allowed.**

Your task: summarize the plan for the user and let them choose:
- \`/plan approve\` — approve and start executing
- \`/plan reject\` — discard the plan
- \`/plan revise <notes>\` — request changes

**Important:** All write/edit/bash-mutation tools are HARD-BLOCKED until the user explicitly approves. You may only perform read-only analysis. Do NOT attempt to execute any plan steps.`;
}

function executionPrompt(lang: "zh" | "en" | "other"): string {
  if (lang === "zh") {
    return `
## 🟢 计划执行模式

计划已**批准**，开始执行。按照计划逐步推进。

### 执行规则：
1. **遵循计划**: 按计划顺序逐步完成。
2. **跟踪进度**: 用 todo_write 在完成每步时勾掉。步骤已同步到名为 "plan" 的 todo 列表。
3. **不偏离**: 除非用户要求，不要超出已批准的范围。
4. **处理问题**: 如果某步无法按计划完成，报告原因并建议替代方案。
5. **完成后**: 完成所有步骤后，调用 \`/plan done\` 或告知用户计划已全部执行完毕。

随时用 todo_list("plan") 查看剩余步骤。`;
  }
  return `
## 🟢 PLAN EXECUTION MODE

A plan has been **approved** and you are now executing it. Follow the plan
step by step, in order.

### Execution Rules:
1. **Follow the plan**: Work through the steps in the planned order.
2. **Track progress**: Call todo_write to check off each step as you complete it.
   The plan steps have been synced to a todo list named "plan".
3. **Stay on track**: Do not add scope beyond the approved plan unless the user asks.
4. **Handle issues**: If a step cannot be completed as planned, report why and suggest alternatives.
5. **When done**: After completing all plan steps, call \`/plan done\` or tell the user the plan is fully executed.

Use todo_list("plan") to see remaining steps at any time.`;
}

// ---------------------------------------------------------------------------
// Helper: block list for planning phase
// ---------------------------------------------------------------------------

const MUTATION_PATTERNS = [
  /\brm\b/,
  /\bmv\b/,
  /\bcp\b/,
  /\bmkdir\b/,
  /\btouch\b/,
  /\bgit\s+commit\b/,
  /\bgit\s+add\b/,
  /\bgit\s+push\b/,
  /\bnpm\s+install\b/,
  /\bnpm\s+uninstall\b/,
  /\byarn\s+add\b/,
  /\bpip\s+install\b/,
  /\bcargo\s+add\b/,
  /\bgo\s+get\b/,
  /\bchmod\b/,
  /\bchown\b/,
  /\bsudo\b/,
  />\s*\//,
  /\|\s*tee\b/,
  /\bdd\b/,
];

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function parsePlanFromText(text: string): { title: string; steps: PlanStep[] } | null {
  // Extract title from "## Plan: <title>", "## 计划：<title>", "## Plan - <title>", etc.
  // Supports English & Chinese, case-insensitive, colon (:/：) and dash (–/—) separators
  const titleMatch = text.match(/^#+\s*(?:Plan|计划|方案)\s*[:：\-–—]\s*(.+)$/im);
  const title = titleMatch ? titleMatch[1]!.trim() : "";

  // Extract checkbox steps like "- [ ] Step description"
  const stepRe = /^[-*]\s+\[ \]\s+(.+)$/gm;
  const steps: PlanStep[] = [];
  let match: RegExpExecArray | null;
  while ((match = stepRe.exec(text)) !== null) {
    steps.push({
      id: ++planStepCounter,
      text: match[1]!.trim(),
      done: false,
    });
  }

  if (steps.length === 0) {
    // Try "Phase" based structure: treat each phase as a section,
    // and any list items under it as steps (without checkboxes)
    const phaseStepRe = /^[-*]\s+(.+)$/gm;
    while ((match = phaseStepRe.exec(text)) !== null) {
      const stepText = match[1]!.trim();
      if (
        stepText.startsWith("Risk") ||
        stepText.startsWith("Estimated") ||
        stepText.startsWith("`") ||
        stepText.length < 5
      )
        continue;
      steps.push({
        id: ++planStepCounter,
        text: stepText,
        done: false,
      });
    }
  }

  if (steps.length === 0) return null;

  return { title, steps };
}

// ---------------------------------------------------------------------------
// Helper: perform approve (shared between /plan approve and /plan-approve)
// ---------------------------------------------------------------------------

async function doApprove(
  pi: ExtensionAPI,
  ctx: any,
  planName: string | null,
): Promise<void> {
  if (planName) {
    // Load named plan
    const loaded = loadPlanFromFile(ctx.cwd, planName);
    if (!loaded) {
      ctx.ui.notify(
        userLanguage === "zh"
          ? `未找到计划「${planName}」。用 /plan list 查看所有已保存的计划。`
          : `Plan "${planName}" not found. Use /plan list to see all saved plans.`,
        "warn",
      );
      return;
    }
    if (loaded.approvedAt) {
      ctx.ui.notify(
        userLanguage === "zh"
          ? `计划「${loaded.title}」已经批准过了。`
          : `Plan "${loaded.title}" has already been approved.`,
        "warn",
      );
      return;
    }
    // If there's a current plan in reviewing state that's different, warn
    if (currentPlan && planState === "reviewing" && currentPlan.name !== planName) {
      currentPlan = null;
    }
    currentPlan = loaded;
    planState = "reviewing";
  }

  if (planState !== "reviewing" || !currentPlan) {
    ctx.ui.notify(
      userLanguage === "zh"
        ? "没有待审批的计划。用 /plan <任务> 创建新计划，或用 /plan list 查看已保存的计划。"
        : "No plan is awaiting approval. Use /plan <task> to create one, or /plan list to see saved plans.",
      "warn",
    );
    return;
  }

  planState = "executing";
  currentPlan.approvedAt = Date.now();
  savePlanToFile(ctx.cwd, currentPlan);

  if (currentPlan.steps.length > 0) {
    const stepList = currentPlan.steps.map((s, i) => `${i + 1}. ${s.text}`).join("\n");
    await ctx.waitForIdle();
    const approvedMsg =
      userLanguage === "zh"
        ? `计划 **"${currentPlan.title}"** 已批准！🟢\n\n` +
          `以下步骤已批准。请同步到 todo 列表（用 todo_write，list="plan"），然后开始执行：\n\n${stepList}\n\n` +
          `按顺序逐步执行计划。每完成一步就勾掉。用 todo_list("plan") 跟踪进度。`
        : `Plan **"${currentPlan.title}"** has been approved! 🟢\n\n` +
          `The following steps have been approved. Please sync them to the todo list (use todo_write with list="plan") and begin executing:\n\n${stepList}\n\n` +
          `Work through the plan step by step. Check off each step as you complete it. Use todo_list("plan") to track progress.`;
    pi.sendUserMessage(approvedMsg);
  } else {
    await ctx.waitForIdle();
    const approvedMsg2 =
      userLanguage === "zh"
        ? `计划 **"${currentPlan.title}"** 已批准！🟢\n\n开始执行计划。`
        : `Plan **"${currentPlan.title}"** has been approved! 🟢\n\nBegin executing the plan now.`;
    pi.sendUserMessage(approvedMsg2);
  }

  ctx.ui.notify(
    userLanguage === "zh"
      ? `计划「${currentPlan.title}」已批准 — 开始执行。`
      : `Plan "${currentPlan.title}" approved — executing now.`,
    "info",
  );
}

// ---------------------------------------------------------------------------
// Extension
// ---------------------------------------------------------------------------

export default function (pi: ExtensionAPI) {
  // =========================================================================
  // /plan — main subcommand dispatcher
  // =========================================================================

  pi.registerCommand("plan", {
    description:
      "Plan mode. Subcommands: approve [name], reject [name], show [name], revise <notes>, done, list. " +
      "Without a subcommand, starts a new plan for the given task.",
    handler: async (args, ctx) => {
      const raw = args?.trim() ?? "";
      const parts = raw.split(/\s+/);
      const subcmd = parts[0]?.toLowerCase();
      const rest = parts.slice(1).join(" ");

      // --- /plan approve [name] ---
      if (subcmd === "approve" || subcmd === "accept" || subcmd === "ok") {
        return doApprove(pi, ctx, rest || null);
      }

      // --- /plan reject [name] ---
      if (subcmd === "reject" || subcmd === "no" || subcmd === "deny") {
        const targetName = rest || null;

        if (targetName) {
          const loaded = loadPlanFromFile(ctx.cwd, targetName);
          if (!loaded) {
            ctx.ui.notify(
              userLanguage === "zh"
                ? `未找到计划「${targetName}」。`
                : `Plan "${targetName}" not found.`,
              "warn",
            );
            return;
          }
          deletePlanFiles(ctx.cwd, targetName);
          ctx.ui.notify(
            userLanguage === "zh"
              ? `计划「${loaded.title}」已删除。`
              : `Plan "${loaded.title}" deleted.`,
            "info",
          );
          // If it was the current plan, reset
          if (currentPlan && currentPlan.name === targetName) {
            currentPlan = null;
            planState = "idle";
            mainAgentGuidelinesInjected = false;
            saveCurrentPlanState(ctx.cwd);
          }
          return;
        }

        if (planState !== "reviewing" || !currentPlan) {
          ctx.ui.notify(
            userLanguage === "zh" ? "没有待审批的计划。" : "No plan is awaiting review.",
            "warn",
          );
          return;
        }
        const rTitle = currentPlan.title;
        deletePlanFiles(ctx.cwd, currentPlan.name);
        currentPlan = null;
        planState = "idle";
        mainAgentGuidelinesInjected = false;
        saveCurrentPlanState(ctx.cwd);
        ctx.ui.notify(
          userLanguage === "zh" ? `计划「${rTitle}」已拒绝。` : `Plan "${rTitle}" rejected.`,
          "info",
        );
        return;
      }

      // --- /plan show [name] ---
      if (subcmd === "show" || subcmd === "view" || subcmd === "display") {
        const targetName = rest || currentPlan?.name || null;

        let planToShow: Plan | null = null;
        if (targetName) {
          planToShow = loadPlanFromFile(ctx.cwd, targetName);
        }
        if (!planToShow && currentPlan) {
          planToShow = currentPlan;
          // if name was specified but not found
          if (targetName && currentPlan.name !== targetName) {
            ctx.ui.notify(
              userLanguage === "zh"
                ? `未找到计划「${targetName}」，显示当前计划。`
                : `Plan "${targetName}" not found, showing current plan.`,
              "warn",
            );
          }
        }
        if (!planToShow) {
          ctx.ui.notify(
            userLanguage === "zh"
              ? "没有计划。用 /plan <任务> 来创建，或用 /plan list 查看已保存的计划。"
              : "No plan exists. Use /plan <task> to create one, or /plan list to see saved plans.",
            "info",
          );
          return;
        }

        const statusLabel: Record<PlanState, string> =
          userLanguage === "zh"
            ? {
                idle: "空闲",
                planning: "🟡 规划中",
                reviewing: "🟡 审阅中",
                executing: "🟢 执行中",
              }
            : {
                idle: "Idle",
                planning: "🟡 Planning",
                reviewing: "🟡 Reviewing",
                executing: "🟢 Executing",
              };
        const preview = planToShow.content.substring(0, 3000);
        if (ctx.hasUI) {
          ctx.ui.setWidget("plan-display", [
            `Plan: ${planToShow.title}`,
            `Name: ${planToShow.name}`,
            `Status: ${statusLabel[planToShow === currentPlan ? planState : "idle"]}`,
            `Task: ${planToShow.task.substring(0, 200)}`,
            `Steps: ${planToShow.steps.length}`,
            ``,
            preview,
          ]);
          ctx.ui.notify(
            `Plan "${planToShow.title}" (${planToShow.name}) — ${planToShow.steps.length} steps (saved in .pi/plan/)`,
            "info",
          );
        }
        return;
      }

      // --- /plan revise <notes> ---
      if (subcmd === "revise" || subcmd === "edit" || subcmd === "update") {
        if (planState !== "reviewing" || !currentPlan) {
          ctx.ui.notify(
            userLanguage === "zh"
              ? "没有待审批的计划可供修改。"
              : "No plan is awaiting review to revise.",
            "warn",
          );
          return;
        }
        const notes = rest;
        planState = "planning";
        saveCurrentPlanState(ctx.cwd);
        const reviseMsg =
          userLanguage === "zh"
            ? `计划需要修改。用户反馈：\n\n${notes || "（无具体意见）"}\n\n请根据反馈修改计划。完成后提交更新后的计划供审批。`
            : `The plan needs revision. User feedback:\n\n${notes || "(no specific notes)"}\n\nPlease revise the plan based on this feedback. When done, present the updated plan for approval.`;
        await ctx.waitForIdle();
        pi.sendUserMessage(reviseMsg);
        ctx.ui.notify(
          userLanguage === "zh"
            ? "计划修改请求已发送。代理将更新计划。"
            : "Plan revision requested. Agent will update the plan.",
          "info",
        );
        return;
      }

      // --- /plan done ---
      if (subcmd === "done" || subcmd === "complete" || subcmd === "finish") {
        if (planState !== "executing") {
          ctx.ui.notify(
            userLanguage === "zh"
              ? "不在计划执行模式中。"
              : "Not in plan execution mode.",
            "warn",
          );
          return;
        }
        const titleDone = currentPlan?.title ?? "Plan";
        const nameDone = currentPlan?.name ?? "";
        // Keep the plan saved as record; just reset state
        currentPlan = null;
        planState = "idle";
        mainAgentGuidelinesInjected = false;
        saveCurrentPlanState(ctx.cwd);
        ctx.ui.notify(
          userLanguage === "zh"
            ? `✅ 计划「${titleDone}」完成。文件保留在 .pi/plan/${nameDone}.md`
            : `✅ Plan "${titleDone}" complete. Files kept at .pi/plan/${nameDone}.md`,
          "info",
        );
        return;
      }

      // --- /plan list ---
      if (subcmd === "list" || subcmd === "ls") {
        const plans = listSavedPlans(ctx.cwd);
        if (plans.length === 0) {
          ctx.ui.notify(
            userLanguage === "zh"
              ? ".pi/plan/ 中没有保存的计划。"
              : "No saved plans in .pi/plan/.",
            "info",
          );
          return;
        }
        const planDirDisplay = planDir(ctx.cwd);
        const lines = plans.map(
          (p) =>
            `- **${p.title}** (\`${p.name}\`) — ${new Date(p.createdAt).toLocaleString()}`,
        );
        const header =
          userLanguage === "zh"
            ? `## 已保存的计划（${plans.length} 个）\n> 存储位置：${planDirDisplay}\n`
            : `## Saved Plans (${plans.length})\n> Location: ${planDirDisplay}\n`;
        const currentHint =
          currentPlan
            ? userLanguage === "zh"
              ? `\n当前活动计划：**${currentPlan.title}** (\`${currentPlan.name}\`)\n用 \`/plan approve ${currentPlan.name}\` 批准执行。`
              : `\nCurrent active plan: **${currentPlan.title}** (\`${currentPlan.name}\`)\nUse \`/plan approve ${currentPlan.name}\` to approve it.`
            : userLanguage === "zh"
              ? `\n没有当前活动计划。用 \`/plan approve <name>\` 批准某个已保存的计划。`
              : `\nNo active plan. Use \`/plan approve <name>\` to approve a saved plan.`;

        if (ctx.hasUI) {
          ctx.ui.setWidget("plan-list", [header, ...lines, currentHint]);
        }
        ctx.ui.notify(
          userLanguage === "zh"
            ? `${plans.length} 个计划已保存`
            : `${plans.length} plan(s) saved`,
          "info",
        );
        return;
      }

      // --- No subcommand → start new plan ---
      const task = raw || "";

      if (!task && planState === "planning") {
        ctx.ui.notify(
          userLanguage === "zh"
            ? "已在计划模式中。使用 /plan show 查看当前计划，/plan approve 批准，/plan reject 拒绝。"
            : "Already in plan mode. Use /plan show, /plan approve, or /plan reject.",
          "info",
        );
        return;
      }

      if (!task && planState === "reviewing") {
        ctx.ui.notify(
          userLanguage === "zh"
            ? "当前有待审批的计划。使用 /plan approve 批准，/plan reject 拒绝，或 /plan show 查看。"
            : "A plan is awaiting review. Use /plan approve, /plan reject, or /plan show.",
          "info",
        );
        return;
      }

      // Detect user language from the task text
      userLanguage = detectLanguage(task);

      currentPlan = {
        name: "planning", // temporary, replaced when plan is parsed
        title: "Planning...",
        task: task || "Analyze the current project and the user's request to create a plan.",
        content: "",
        steps: [],
        approvedAt: null,
        createdAt: Date.now(),
      };
      planState = "planning";
      mainAgentGuidelinesInjected = false;
      saveCurrentPlanState(ctx.cwd);

      const zhIntro =
        userLanguage === "zh"
          ? `## 🔵 计划模式：${currentPlan.task}\n\n` +
            `请分析代码库并创建一个详细结构化的计划。` +
            `当前为 **只读模式** — 除 .md 文档外不允许修改文件。\n\n` +
            `用清晰的阶段和检查清单步骤来组织计划。` +
            `计划完成后请注明「PLAN COMPLETE」以便用户审阅。`
          : `## 🔵 Plan Mode: ${currentPlan.task}\n\n` +
            `Please analyze the codebase and create a detailed, structured plan. ` +
            `You are in READ-ONLY mode — only .md files may be modified.\n\n` +
            `Format the plan with clear phases and checklist steps. ` +
            `When the plan is complete, state "PLAN COMPLETE" so the user can review.`;

      await ctx.waitForIdle();
      pi.sendUserMessage(zhIntro);

      ctx.ui.notify(
        userLanguage === "zh"
          ? "🔵 计划模式：只读分析，请先生成计划。"
          : "🔵 Plan mode: read-only analysis. Create a plan first.",
        "info",
      );
    },
  });

  // =========================================================================
  // Legacy standalone commands (backward compatible)
  // =========================================================================

  pi.registerCommand("plan-approve", {
    description: "Approve the current plan (legacy alias for /plan approve)",
    handler: async (_args, ctx) => {
      return doApprove(pi, ctx, null);
    },
  });

  pi.registerCommand("plan-reject", {
    description: "Reject the current plan (legacy alias for /plan reject)",
    handler: async (_args, ctx) => {
      if (planState !== "reviewing" || !currentPlan) {
        ctx.ui.notify(
          userLanguage === "zh" ? "没有待审批的计划。" : "No plan is awaiting review.",
          "warn",
        );
        return;
      }
      const rTitle = currentPlan.title;
      deletePlanFiles(ctx.cwd, currentPlan.name);
      currentPlan = null;
      planState = "idle";
      mainAgentGuidelinesInjected = false;
      saveCurrentPlanState(ctx.cwd);
      ctx.ui.notify(
        userLanguage === "zh" ? `计划「${rTitle}」已拒绝。` : `Plan "${rTitle}" rejected.`,
        "info",
      );
    },
  });

  pi.registerCommand("plan-show", {
    description: "Display the current plan (legacy alias for /plan show)",
    handler: async (_args, ctx) => {
      if (!currentPlan) {
        const noPlanMsg =
          userLanguage === "zh"
            ? "没有计划。用 /plan <任务> 来创建，或用 /plan list 查看已保存的计划。"
            : "No plan exists. Use /plan <task> to create one, or /plan list to see all saved plans.";
        ctx.ui.notify(noPlanMsg, "info");
        return;
      }
      const statusLabel: Record<PlanState, string> =
        userLanguage === "zh"
          ? {
              idle: "空闲",
              planning: "🟡 规划中",
              reviewing: "🟡 审阅中",
              executing: "🟢 执行中",
            }
          : {
              idle: "Idle",
              planning: "🟡 Planning",
              reviewing: "🟡 Reviewing",
              executing: "🟢 Executing",
            };
      const preview = currentPlan.content.substring(0, 3000);
      if (ctx.hasUI) {
        ctx.ui.setWidget("plan-display", [
          `Plan: ${currentPlan.title}`,
          `Name: ${currentPlan.name}`,
          `Status: ${statusLabel[planState]}`,
          `Task: ${currentPlan.task.substring(0, 200)}`,
          `Steps: ${currentPlan.steps.length}`,
          ``,
          preview,
        ]);
        ctx.ui.notify(
          `Plan "${currentPlan.title}" — ${statusLabel[planState]} (${currentPlan.steps.length} steps, saved in .pi/plan/)`,
          "info",
        );
      }
    },
  });

  pi.registerCommand("plan-revise", {
    description: "Request revisions to the current plan (legacy alias for /plan revise)",
    handler: async (args, ctx) => {
      if (planState !== "reviewing" || !currentPlan) {
        ctx.ui.notify(
          userLanguage === "zh"
            ? "没有待审批的计划可供修改。"
            : "No plan is awaiting review to revise.",
          "warn",
        );
        return;
      }
      const notes = args?.trim() ?? "";
      planState = "planning";
      saveCurrentPlanState(ctx.cwd);
      const reviseMsg =
        userLanguage === "zh"
          ? `计划需要修改。用户反馈：\n\n${notes || "（无具体意见）"}\n\n请根据反馈修改计划。完成后提交更新后的计划供审批。`
          : `The plan needs revision. User feedback:\n\n${notes || "(no specific notes)"}\n\nPlease revise the plan based on this feedback. When done, present the updated plan for approval.`;
      await ctx.waitForIdle();
      pi.sendUserMessage(reviseMsg);
      ctx.ui.notify(
        userLanguage === "zh"
          ? "计划修改请求已发送。代理将更新计划。"
          : "Plan revision requested. Agent will update the plan.",
        "info",
      );
    },
  });

  pi.registerCommand("plan-done", {
    description: "Mark plan execution as complete (legacy alias for /plan done)",
    handler: async (_args, ctx) => {
      if (planState !== "executing") {
        ctx.ui.notify(
          userLanguage === "zh"
            ? "不在计划执行模式中。"
            : "Not in plan execution mode.",
          "warn",
        );
        return;
      }
      const titleDone = currentPlan?.title ?? "Plan";
      // Keep plan saved; just reset in-memory state
      currentPlan = null;
      planState = "idle";
      mainAgentGuidelinesInjected = false;
      saveCurrentPlanState(ctx.cwd);
      ctx.ui.notify(
        userLanguage === "zh"
          ? `✅ 计划「${titleDone}」完成。`
          : `✅ Plan "${titleDone}" complete.`,
        "info",
      );
    },
  });

  // =========================================================================
  // before_agent_start: inject plan mode system prompts
  // =========================================================================

  pi.on("before_agent_start", async (event, ctx) => {
    if (planState === "planning") {
      return {
        systemPrompt: event.systemPrompt + "\n\n" + planModePrompt(userLanguage),
      };
    }

    if (planState === "reviewing") {
      return {
        systemPrompt: event.systemPrompt + "\n\n" + reviewPrompt(userLanguage),
      };
    }

    if (planState === "executing") {
      return {
        systemPrompt: event.systemPrompt + "\n\n" + executionPrompt(userLanguage),
      };
    }

    // Normal mode — inject plan encouragement (once per session)
    if (!mainAgentGuidelinesInjected) {
      mainAgentGuidelinesInjected = true;
      const planHint =
        userLanguage === "zh"
          ? `\n## 计划模式可用\n` +
            `你可以使用计划模式。在执行任何修改之前，先用 \`/plan <任务>\` 进入只读规划阶段。` +
            `在计划模式下，先分析，创建结构化计划，获得用户批准后再逐步执行。` +
            `强烈建议对多步骤、复杂或高风险变更使用计划模式。` +
            `用户也可以输入 \`/plan <任务>\` 来启动计划模式。`
          : `\n## Plan Mode Available\n` +
            `You have access to plan mode. Use \`/plan <task>\` to enter a read-only ` +
            `planning phase before making any changes. In plan mode you analyze first, ` +
            `create a structured plan, get user approval, then execute step by step. ` +
            `This is strongly recommended for multi-step, complex, or risky changes. ` +
            `The user can also initiate plan mode by typing \`/plan <task>\`.`;
      return {
        systemPrompt: event.systemPrompt + planHint,
      };
    }
  });

  // =========================================================================
  // tool_call: block write tools during planning AND reviewing
  // =========================================================================

  pi.on("tool_call", async (event, ctx) => {
    // Block mutation tools during both planning and reviewing.
    // Only allow after explicit user approval (executing state).
    if (planState !== "planning" && planState !== "reviewing") return;

    const phaseLabel =
      planState === "reviewing"
        ? userLanguage === "zh"
          ? "审阅模式"
          : "Review mode"
        : userLanguage === "zh"
          ? "计划模式"
          : "Plan mode";

    // write: allow .md files (plan documents), block everything else
    if (isToolCallEventType("write", event)) {
      const path = event.input.path ?? "";
      if (!path.endsWith(".md")) {
        const reasonWrite =
          userLanguage === "zh"
            ? `${phaseLabel}已激活 — write 仅允许 .md 文档。当前文件: ${path}。请先获取计划批准后再修改代码文件。`
            : `${phaseLabel} is active — write is only allowed for .md files. Target: ${path}. Get the plan approved before modifying code.`;
        return { block: true, reason: reasonWrite };
      }
      return;
    }

    // edit: allow .md files, block everything else
    if (isToolCallEventType("edit", event)) {
      const path = event.input.path ?? "";
      if (!path.endsWith(".md")) {
        const reasonEdit =
          userLanguage === "zh"
            ? `${phaseLabel}已激活 — edit 仅允许 .md 文档。当前文件: ${path}。请先获取计划批准后再修改代码文件。`
            : `${phaseLabel} is active — edit is only allowed for .md files. Target: ${path}. Get the plan approved before modifying code.`;
        return { block: true, reason: reasonEdit };
      }
      return;
    }

    if (event.toolName === "task") {
      const reasonTask =
        userLanguage === "zh"
          ? `${phaseLabel}已激活 — 不允许创建子代理。请先获取计划批准。`
          : `${phaseLabel} is active — spawning sub-agents is not allowed. Get the plan approved first.`;
      return { block: true, reason: reasonTask };
    }

    if (isToolCallEventType("bash", event)) {
      const cmd = event.input.command ?? "";
      for (const pattern of MUTATION_PATTERNS) {
        if (pattern.test(cmd)) {
          const reasonBash =
            userLanguage === "zh"
              ? `${phaseLabel}已激活 — 此 bash 命令疑似修改文件。只允许只读分析。请先获取计划批准。`
              : `${phaseLabel} is active — this bash command appears to modify files. Read-only analysis only. Get the plan approved first.`;
          return { block: true, reason: reasonBash };
        }
      }
    }
  });

  // =========================================================================
  // message_end: detect plan completion from agent output
  // =========================================================================

  pi.on("message_end", async (event, ctx) => {
    if (planState !== "planning" || !currentPlan) return;
    if (event.message.role !== "assistant") return;

    const textContent =
      event.message.content
        ?.filter((c: any) => c.type === "text")
        .map((c: any) => c.text)
        .join("\n") ?? "";

    const completeMarkers = [
      /PLAN\s*COMPLETE/i,
      /plan\s+is\s+complete/i,
      /plan\s+is\s+ready/i,
      /ready\s+for\s+review/i,
      /awaiting\s+(your\s+)?approval/i,
      /please\s+review\s+the\s+plan/i,
      /以上是.*计划/i,
      /计划.*完成/i,
    ];

    const isComplete = completeMarkers.some((re) => re.test(textContent));

    if (isComplete) {
      const parsed = parsePlanFromText(textContent);
      if (parsed && parsed.steps.length > 0) {
        // Use parsed title; fall back to task text or a timestamp label if empty
        currentPlan.title = parsed.title || currentPlan.task.slice(0, 80) || `Plan ${new Date().toLocaleString()}`;
        currentPlan.steps = parsed.steps;
        currentPlan.name = sanitizePlanName(currentPlan.title);
      } else {
        // Still capture content even without structured steps
        const fallbackTitle = currentPlan.title !== "Planning..." ? currentPlan.title : currentPlan.task || "plan";
        currentPlan.name = sanitizePlanName(fallbackTitle);
      }
      currentPlan.content = textContent;
      planState = "reviewing";
      savePlanToFile(ctx.cwd, currentPlan);

      const reviewMsg =
        userLanguage === "zh"
          ? `计划已保存为 **"${currentPlan.title}"** (\`${currentPlan.name}\`)，进入 **审阅模式**。\n` +
            `文件保存在 \`.pi/plan/${currentPlan.name}.md\`\n\n` +
            `请选择：\n` +
            `• \`/plan approve ${currentPlan.name}\` — 批准并执行\n` +
            `• \`/plan reject\` — 放弃计划\n` +
            `• \`/plan revise <意见>\` — 提出修改意见\n` +
            `• \`/plan list\` — 查看所有已保存的计划`
          : `Plan saved as **"${currentPlan.title}"** (\`${currentPlan.name}\`), now in **review mode**.\n` +
            `Files saved at \`.pi/plan/${currentPlan.name}.md\`\n\n` +
            `Choose:\n` +
            `• \`/plan approve ${currentPlan.name}\` — approve and start executing\n` +
            `• \`/plan reject\` — discard the plan\n` +
            `• \`/plan revise <notes>\` — request changes\n` +
            `• \`/plan list\` — see all saved plans`;
      pi.sendUserMessage(reviewMsg, { deliverAs: "followUp" });
    }
  });

  // =========================================================================
  // session_start: restore plan state from disk
  // =========================================================================

  pi.on("session_start", async (_event, ctx) => {
    // Try to restore plan state from previous session
    const restored = loadCurrentPlanState(ctx.cwd);
    if (restored) {
      currentPlan = restored.plan;
      planState = restored.state;
      userLanguage = restored.language;

      const stateLabel =
        userLanguage === "zh"
          ? restored.state === "planning"
            ? "规划中"
            : restored.state === "reviewing"
              ? "审阅中"
              : restored.state === "executing"
                ? "执行中"
                : restored.state
          : restored.state;

      ctx.ui.notify(
        userLanguage === "zh"
          ? `📋 已恢复计划「${restored.plan.title}」（${stateLabel}）。使用 /plan show 查看，/plan approve 批准。`
          : `📋 Restored plan "${restored.plan.title}" (${stateLabel}). Use /plan show to view, /plan approve to approve.`,
        "info",
      );
    }

    if (ctx.mode === "tui") {
      ctx.ui.notify(
        "Plan mode: /plan — analyze first, create a plan, get approval, then execute",
        "info",
      );
    }
  });

  // =========================================================================
  // session_shutdown: cleanup
  // =========================================================================

  pi.on("session_shutdown", () => {
    // Keep persisted files; just clear memory
    planState = "idle";
    currentPlan = null;
    mainAgentGuidelinesInjected = false;
    planStepCounter = 0;
  });
}
