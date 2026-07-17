/**
 * plan.ts — Pi extension: Plan Mode (plan-first, then execute)
 *
 * Forces the agent to create a detailed, structured plan BEFORE making any
 * changes. The user reviews and approves the plan, then the agent executes
 * step by step with automatic progress tracking.
 *
 * Commands:
 *   /plan [task]          — Enter plan mode (optionally with task description)
 *   /plan-approve         — Approve the current plan and begin execution
 *   /plan-reject          — Reject the plan, return to normal mode
 *   /plan-show            — Display the current plan
 *   /plan-revise <notes>  — Revise the plan with feedback
 *   /plan-done            — Mark plan execution as complete
 *
 * States: idle → planning → reviewing → executing → idle
 *
 * In planning phase: ALL write/edit/bash-mutation tools are BLOCKED.
 * In execution phase: plan steps sync to todo list, full tools available.
 *
 * Auto-discovered from ~/.pi/agent/extensions/.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { isToolCallEventType } from "@earendil-works/pi-coding-agent";
import { writeFileSync, readFileSync, existsSync, unlinkSync } from "node:fs";
import { join } from "node:path";

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
// Language detection
// ---------------------------------------------------------------------------

function detectLanguage(text: string): "zh" | "en" | "other" {
  // Count CJK characters (Chinese, Japanese, Korean)
  const cjkCount = (text.match(/[\u4e00-\u9fff\u3400-\u4dbf\uf900-\ufaff\u3000-\u303f\uff00-\uffef]/g) || []).length;
  const totalChars = text.replace(/\s/g, "").length;
  if (totalChars > 0 && cjkCount / totalChars > 0.15) return "zh";
  if (/[\u4e00-\u9fff]/.test(text)) return "zh";
  return "en";
}

/** Language-specific prompt snippets. */
const LANG: Record<string, { planRules: string; reviewInstruction: string; completeInstruction: string }> = {
  zh: {
    planRules: `\n**语言要求**: 用户使用中文交流。请用中文撰写整个计划，包括标题、概述、步骤描述和风险分析。`,
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
  return `
## 🟡 PLAN READY FOR REVIEW

A plan has been prepared and is awaiting user approval. ${LANG[lang].reviewInstruction}

The user can:
- \`/plan-approve\` — approve and start executing
- \`/plan-reject\` — discard the plan
- \`/plan-revise <notes>\` — request changes

Do NOT start executing the plan until the user explicitly approves.`;
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
5. **完成后**: 完成所有步骤后，调用 \`/plan-done\` 或告知用户计划已全部执行完毕。

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
5. **When done**: After completing all plan steps, call \`/plan-done\` or tell the user the plan is fully executed.

Use todo_list("plan") to see remaining steps at any time.`;
}

// ---------------------------------------------------------------------------
// Helper: block list for planning phase
// ---------------------------------------------------------------------------

/** Bash patterns that indicate mutation (blocked during planning). */
const MUTATION_PATTERNS = [
  /\brm\b/, /\bmv\b/, /\bcp\b/, /\bmkdir\b/, /\btouch\b/,
  /\bgit\s+commit\b/, /\bgit\s+add\b/, /\bgit\s+push\b/,
  /\bnpm\s+install\b/, /\bnpm\s+uninstall\b/, /\byarn\s+add\b/,
  /\bpip\s+install\b/, /\bcargo\s+add\b/, /\bgo\s+get\b/,
  /\bchmod\b/, /\bchown\b/, /\bsudo\b/,
  />\s*\//, /\|\s*tee\b/, /\bdd\b/,
];

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function parsePlanFromText(text: string): { title: string; steps: PlanStep[] } | null {
  // Extract title from "## Plan: <title>" or "# Plan: <title>"
  const titleMatch = text.match(/^#+\s*Plan:\s*(.+)$/m);
  const title = titleMatch ? titleMatch[1]!.trim() : "Untitled Plan";

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
      // Skip items that are clearly not steps
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

  if (steps.length === 0) return null; // no structured steps found

  return { title, steps };
}

function savePlanToFile(cwd: string, plan: Plan): void {
  const path = join(cwd, "plan.md");
  const titleLabel = userLanguage === "zh" ? `# 计划：${plan.title}` : `# Plan: ${plan.title}`;
  const createdLabel = userLanguage === "zh"
    ? `> 创建时间：${new Date(plan.createdAt).toLocaleString()}`
    : `> Created: ${new Date(plan.createdAt).toLocaleString()}`;
  const approvedLabel = plan.approvedAt
    ? (userLanguage === "zh"
        ? `> 批准时间：${new Date(plan.approvedAt).toLocaleString()}`
        : `> Approved: ${new Date(plan.approvedAt).toLocaleString()}`)
    : (userLanguage === "zh"
        ? `> 状态：${planState === "planning" ? "规划中" : planState === "reviewing" ? "审阅中" : planState === "executing" ? "执行中" : planState}`
        : `> Status: ${planState}`);
  const taskLabel = userLanguage === "zh" ? `## 任务` : `## Task`;
  const lines = [
    titleLabel,
    ``,
    createdLabel,
    approvedLabel,
    ``,
    taskLabel,
    plan.task,
    ``,
    plan.content,
  ];
  writeFileSync(path, lines.join("\n"), "utf-8");
}

function deletePlanFile(cwd: string): void {
  const path = join(cwd, "plan.md");
  try {
    if (existsSync(path)) unlinkSync(path);
  } catch {
    // ok
  }
}

// ---------------------------------------------------------------------------
// Extension
// ---------------------------------------------------------------------------

export default function (pi: ExtensionAPI) {
  // -- /plan-approve -----------------------------------------------------

  pi.registerCommand("plan-approve", {
    description: "Approve the current plan and begin execution",
    handler: async (_args, ctx) => {
      if (planState !== "reviewing" || !currentPlan) {
        ctx.ui.notify(
          userLanguage === "zh" ? "没有待审批的计划。" : "No plan is awaiting approval.",
          "warn",
        );
        return;
      }
      planState = "executing";
      currentPlan.approvedAt = Date.now();
      savePlanToFile(ctx.cwd, currentPlan);

      if (currentPlan.steps.length > 0) {
        const stepList = currentPlan.steps
          .map((s, i) => `${i + 1}. ${s.text}`)
          .join("\n");
        await ctx.waitForIdle();
        const approvedMsg = userLanguage === "zh"
          ? `计划 **"${currentPlan.title}"** 已批准！🟢\n\n` +
            `以下步骤已批准。请同步到 todo 列表（用 todo_write，list="plan"），然后开始执行：\n\n${stepList}\n\n` +
            `按顺序逐步执行计划。每完成一步就勾掉。用 todo_list("plan") 跟踪进度。`
          : `Plan **"${currentPlan.title}"** has been approved! 🟢\n\n` +
            `The following steps have been approved. Please sync them to the todo list (use todo_write with list="plan") and begin executing:\n\n${stepList}\n\n` +
            `Work through the plan step by step. Check off each step as you complete it. Use todo_list("plan") to track progress.`;
        pi.sendUserMessage(approvedMsg);
      } else {
        await ctx.waitForIdle();
        const approvedMsg2 = userLanguage === "zh"
          ? `计划 **"${currentPlan.title}"** 已批准！🟢\n\n开始执行计划。`
          : `Plan **"${currentPlan.title}"** has been approved! 🟢\n\n` +
            `Begin executing the plan now.`;
        pi.sendUserMessage(approvedMsg2);
      }

      ctx.ui.notify(
        userLanguage === "zh"
          ? `计划「${currentPlan.title}」已批准 — 开始执行。`
          : `Plan "${currentPlan.title}" approved — executing now.`,
        "info",
      );
    },
  });

  // -- /plan-reject ------------------------------------------------------

  pi.registerCommand("plan-reject", {
    description: "Reject the current plan and return to normal mode",
    handler: async (_args, ctx) => {
      if (planState !== "reviewing" || !currentPlan) {
        ctx.ui.notify(
          userLanguage === "zh" ? "没有待审批的计划。" : "No plan is awaiting review.",
          "warn",
        );
        return;
      }
      const title = currentPlan.title;
      deletePlanFile(ctx.cwd);
      currentPlan = null;
      planState = "idle";
      mainAgentGuidelinesInjected = false;
      const rejectMsg = userLanguage === "zh"
        ? `计划「${title}」已拒绝。`
        : `Plan "${title}" rejected.`;
      ctx.ui.notify(rejectMsg, "info");
    },
  });

  // -- /plan-show --------------------------------------------------------

  pi.registerCommand("plan-show", {
    description: "Display the current plan",
    handler: async (_args, ctx) => {
      if (!currentPlan) {
        const noPlanMsg = userLanguage === "zh"
          ? "没有计划。用 /plan <任务> 来创建。"
          : "No plan exists. Use /plan <task> to create one.";
        ctx.ui.notify(noPlanMsg, "info");
        return;
      }
      const statusLabel: Record<PlanState, string> = userLanguage === "zh"
        ? { idle: "空闲", planning: "🟡 规划中", reviewing: "🟡 审阅中", executing: "🟢 执行中" }
        : { idle: "Idle", planning: "🟡 Planning", reviewing: "🟡 Reviewing", executing: "🟢 Executing" };
      const preview = currentPlan.content.substring(0, 2000);
      if (ctx.hasUI) {
        ctx.ui.setWidget("plan-display", [
          `Plan: ${currentPlan.title}`,
          `Status: ${statusLabel[planState]}`,
          `Task: ${currentPlan.task.substring(0, 200)}`,
          `Steps: ${currentPlan.steps.length}`,
          ``,
          preview,
        ]);
        ctx.ui.notify(
          `Plan "${currentPlan.title}" — ${statusLabel[planState]} (${currentPlan.steps.length} steps)`,
          "info",
        );
      }
    },
  });

  // -- /plan-revise <notes> ----------------------------------------------

  pi.registerCommand("plan-revise", {
    description: "Request revisions to the current plan",
    handler: async (args, ctx) => {
      if (planState !== "reviewing" || !currentPlan) {
        ctx.ui.notify(
          userLanguage === "zh" ? "没有待审批的计划。" : "No plan is awaiting review.",
          "warn",
        );
        return;
      }
      const notes = args?.trim() ?? "";
      planState = "planning";
      const reviseMsg = userLanguage === "zh"
        ? `计划需要修改。用户反馈：\n\n${notes || "（无具体意见）"}\n\n` +
          `请根据反馈修改计划。完成后提交更新后的计划供审批。`
        : `The plan needs revision. User feedback:\n\n${notes || "(no specific notes)"}\n\n` +
          `Please revise the plan based on this feedback. When done, present the updated plan for approval.`;
      await ctx.waitForIdle();
      pi.sendUserMessage(reviseMsg);
      const reviseNotify = userLanguage === "zh"
        ? "计划修改请求已发送。代理将更新计划。"
        : "Plan revision requested. Agent will update the plan.";
      ctx.ui.notify(reviseNotify, "info");
    },
  });

  // -- /plan-done --------------------------------------------------------

  pi.registerCommand("plan-done", {
    description: "Mark plan execution as complete",
    handler: async (_args, ctx) => {
      if (planState !== "executing") {
        ctx.ui.notify(
          userLanguage === "zh" ? "不在计划执行模式中。" : "Not in plan execution mode.",
          "warn",
        );
        return;
      }
      const titleDone = currentPlan?.title ?? "Plan";
      deletePlanFile(ctx.cwd);
      currentPlan = null;
      planState = "idle";
      mainAgentGuidelinesInjected = false;
      const doneMsg = userLanguage === "zh"
        ? `✅ 计划「${titleDone}」完成。`
        : `✅ Plan "${titleDone}" complete.`;
      ctx.ui.notify(doneMsg, "info");
    },
  });

  // -- /plan [task] (start a new plan) -----------------------------------

  pi.registerCommand("plan", {
    description:
      "Enter plan mode with an optional task. Use /plan-approve, /plan-reject, /plan-show, /plan-revise, /plan-done to manage plans.",
    handler: async (args, ctx) => {
      const task = args?.trim() || "";

      // If already in planning and args is empty, just notify
      if (!task && planState === "planning") {
        ctx.ui.notify(
          userLanguage === "zh" ? "已在计划模式中。" : "Already in plan mode.",
          "info",
        );
        return;
      }

      // Detect user language from the task text
      userLanguage = detectLanguage(task);

      currentPlan = {
        title: "Planning...",
        task: task || "Analyze the current project and the user's request to create a plan.",
        content: "",
        steps: [],
        approvedAt: null,
        createdAt: Date.now(),
      };
      planState = "planning";
      mainAgentGuidelinesInjected = false;

      const zhIntro = userLanguage === "zh"
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

  // -- before_agent_start: inject plan mode system prompts ---------------

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

    // Normal mode — inject plan encouragement (once)
    if (!mainAgentGuidelinesInjected) {
      mainAgentGuidelinesInjected = true;
      const planHint = userLanguage === "zh"
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

  // -- tool_call: block write tools during planning -----------------------

  pi.on("tool_call", async (event, ctx) => {
    if (planState !== "planning") return; // only block in planning phase

    // write: allow .md files (plan documents), block everything else
    if (isToolCallEventType("write", event)) {
      const path = event.input.path ?? "";
      if (!path.endsWith(".md")) {
        const reasonWrite = userLanguage === "zh"
          ? `计划模式已激活 — write 仅允许 .md 文档。当前文件: ${path}。请先生成计划并获取批准后再修改代码文件。`
          : `Plan mode is active — write is only allowed for .md files. ` +
            `Target: ${path}. Create the plan first, then get approval before modifying code.`;
        return { block: true, reason: reasonWrite };
      }
      // Allow .md writes through (plan documents, research notes, etc.)
      return;
    }

    // edit: allow .md files, block everything else
    if (isToolCallEventType("edit", event)) {
      const path = event.input.path ?? "";
      if (!path.endsWith(".md")) {
        const reasonEdit = userLanguage === "zh"
          ? `计划模式已激活 — edit 仅允许 .md 文档。当前文件: ${path}。请先生成计划并获取批准后再修改代码文件。`
          : `Plan mode is active — edit is only allowed for .md files. ` +
            `Target: ${path}. Create the plan first, then get approval before modifying code.`;
        return { block: true, reason: reasonEdit };
      }
      return;
    }

    // Block other blocked tools (bash, task during planning)
    if (event.toolName === "task") {
      const reasonTask = userLanguage === "zh"
        ? `计划模式已激活 — 不允许创建子代理。请先完成计划。`
        : `Plan mode is active — spawning sub-agents is not allowed. Complete the plan first.`;
      return { block: true, reason: reasonTask };
    }

    // Block bash commands that mutate files
    if (isToolCallEventType("bash", event)) {
      const cmd = event.input.command ?? "";
      for (const pattern of MUTATION_PATTERNS) {
        if (pattern.test(cmd)) {
          const reasonBash = userLanguage === "zh"
            ? `计划模式已激活 — 此 bash 命令疑似修改文件。只允许只读分析。请先生成计划。`
            : `Plan mode is active — this bash command appears to modify files. ` +
              `Read-only analysis only. Create the plan first.`;
          return { block: true, reason: reasonBash };
        }
      }
    }
  });

  // -- message_end: detect plan completion from agent output --------------

  pi.on("message_end", async (event, ctx) => {
    if (planState !== "planning" || !currentPlan) return;
    if (event.message.role !== "assistant") return;

    // Extract text content from the message
    const textContent = event.message.content
      ?.filter((c: any) => c.type === "text")
      .map((c: any) => c.text)
      .join("\n") ?? "";

    // Detect plan completion markers
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
      // Parse the plan from the message
      const parsed = parsePlanFromText(textContent);
      if (parsed && parsed.steps.length > 0) {
        currentPlan.title = parsed.title;
        currentPlan.steps = parsed.steps;
        currentPlan.content = textContent;
        planState = "reviewing";
        savePlanToFile(ctx.cwd, currentPlan);

        // Let the agent know the plan is now in review (in user's language)
        const reviewMsg = userLanguage === "zh"
          ? `计划已捕获，进入 **审阅模式**。请用中文向用户总结计划，并提示用户：\n` +
            `• \`/plan-approve\` — 批准并执行\n` +
            `• \`/plan-reject\` — 放弃计划\n` +
            `• \`/plan-revise <意见>\` — 提出修改意见`
          : `Your plan has been captured and is now in **review mode**. ` +
            `Summarize it for the user and ask them to:\n` +
            `• \`/plan-approve\` — approve and start executing\n` +
            `• \`/plan-reject\` — discard the plan\n` +
            `• \`/plan-revise <notes>\` — request changes`;
        pi.sendUserMessage(reviewMsg, { deliverAs: "followUp" });
      } else {
        // Plan content didn't have checkboxes — still move to review
        currentPlan.content = textContent;
        planState = "reviewing";
        savePlanToFile(ctx.cwd, currentPlan);

        const reviewMsg2 = userLanguage === "zh"
          ? `计划已捕获，进入 **审阅模式**。请用中文向用户总结计划并请求审批。`
          : `Your plan has been captured and is now in **review mode**. ` +
            `Summarize it for the user and ask them to approve, reject, or revise.`;
        pi.sendUserMessage(reviewMsg2, { deliverAs: "followUp" });
      }
    }
  });

  // -- agent_settled: clear plan on idle completion in executing mode ----

  pi.on("agent_settled", async (event, ctx) => {
    if (planState === "executing" && ctx.isIdle()) {
      // Don't auto-exit, let the user explicitly /plan-done
    }
  });

  // -- session_start notification -----------------------------------------

  pi.on("session_start", async (_event, ctx) => {
    if (ctx.mode === "tui") {
      ctx.ui.notify(
        "Plan mode: /plan — analyze first, create a plan, get approval, then execute",
        "info",
      );
    }
  });

  // -- Cleanup on shutdown ------------------------------------------------

  pi.on("session_shutdown", () => {
    // Keep plans in memory for the session; they'll be cleaned up naturally
    planState = "idle";
    currentPlan = null;
    mainAgentGuidelinesInjected = false;
    planStepCounter = 0;
  });
}
