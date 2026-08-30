/**
 * subagent.ts — Pi extension: Sub-agent system for parallel task delegation
 *
 * Allows the main agent to spawn focused sub-agents that work independently
 * on specific tasks. Each sub-agent runs in dedicated turns with its own
 * persona and task-specific instructions, then reports results back.
 *
 * Tools:
 *   task          — Spawn a sub-agent to work on a focused task
 *   task_status   — Check the status of one or all sub-agents
 *   task_result   — Retrieve a completed sub-agent's result
 *   task_cancel   — Cancel a running/pending sub-agent
 *   task_complete — (sub-agent only) Mark task as done with results
 *   task_report   — (sub-agent only) Send intermediate progress update
 *
 * Shortcut:
 *   Ctrl+Shift+H  — View sub-agent dashboard (list + details)
 *
 * User cannot directly prompt sub-agents. Only the main agent delegates.
 *
 * Auto-discovered from ~/.pi/agent/extensions/.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { StringEnum } from "@earendil-works/pi-ai";

// ---------------------------------------------------------------------------
// Sub-agent state machine
// ---------------------------------------------------------------------------

type SubAgentStatus = "pending" | "running" | "done" | "cancelled" | "failed";

interface SubAgent {
  id: string;
  name: string;
  prompt: string;
  contextFiles: string[];
  status: SubAgentStatus;
  result: string | null;
  reports: { text: string; timestamp: number }[];
  createdAt: number;
  startedAt: number | null;
  completedAt: number | null;
}

const subAgents = new Map<string, SubAgent>();
let activeSubAgentId: string | null = null;
let idCounter = 0;

// ---------------------------------------------------------------------------
// Protocol markers (embedded in user messages)
// ---------------------------------------------------------------------------

const MARKER_START = "🔀 SUBAGENT_START";
const MARKER_DONE = "🔀 SUBAGENT_DONE";

function encodeStartMessage(id: string, name: string, prompt: string): string {
  return `${MARKER_START}:${id}:${name}\n${prompt}`;
}

function encodeDoneMessage(id: string, name: string): string {
  return `${MARKER_DONE}:${id}:${name}\nSub-agent "${name}" has completed its task. Call task_result("${id}") to retrieve the full result.`;
}

function parseStartMarker(text: string): { id: string; name: string; prompt: string } | null {
  const re = new RegExp(`^${MARKER_START.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}:(\\S+):(.+?)\\n`);
  const m = text.match(re);
  if (!m) return null;
  return {
    id: m[1]!,
    name: m[2]!,
    prompt: text.slice(m[0].length),
  };
}

function parseDoneMarker(text: string): { id: string; name: string } | null {
  const re = new RegExp(`^${MARKER_DONE.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}:(\\S+):(.+?)\\n`);
  const m = text.match(re);
  if (!m) return null;
  return { id: m[1]!, name: m[2]! };
}

// ---------------------------------------------------------------------------
// System prompt augmentation
// ---------------------------------------------------------------------------

const SUBAGENT_SYSTEM_PROMPT = `
## ⚠️ YOU ARE A SUB-AGENT

You are currently operating as a **sub-agent** with a focused, single-purpose task.
Your only job is to complete the task assigned to you in the user message above.

### Rules for sub-agents:
1. **Stay focused**: Only work on the assigned task. Do not expand scope.
2. **Be autonomous**: Read files, run commands, make edits — whatever is needed.
3. **Report progress**: Use task_report() for significant milestones.
4. **Complete explicitly**: When done, call task_complete(result="...") with a clear summary.
5. **No chitchat**: Don't ask the user questions. Don't suggest follow-ups.
6. **One shot preferred**: Try to complete the task in as few turns as possible.
7. **Handle errors**: If you cannot complete the task, call task_complete with an error explanation.
`.trim();

const MAIN_AGENT_DELEGATION_GUIDELINES = `
## Sub-Agent Delegation

You have access to a sub-agent system via the **task** tool. Use it to delegate work.

### When to delegate:
- **Parallel work**: Multiple independent tasks (e.g., "fix bug A" + "add feature B")
- **Focused deep-dives**: Complex single-file analysis or refactoring
- **Research**: Searching docs, understanding unfamiliar code
- **Code generation**: Creating new modules from scratch
- **Cross-cutting changes**: Tasks touching many files (sub-agents can work through them systematically)

### How to delegate:
1. Call task(name="descriptive-name", prompt="specific instructions...")
2. Sub-agents run independently in dedicated turns
3. Check progress with task_status() or press Ctrl+Shift+H for the dashboard
4. Collect results with task_result(id="...") when complete

### Tips:
- Give sub-agents **specific, actionable prompts** (not vague requests)
- Include **file paths** the sub-agent should focus on via contextFiles
- Delegate **independent tasks in parallel** (spawn multiple before waiting)
- Sub-agents cannot ask you questions — make the prompt self-contained
`.trim();

// ---------------------------------------------------------------------------
// Helper: build dashboard text for the shortcut / status widget
// ---------------------------------------------------------------------------

function buildDashboard(): string {
  if (subAgents.size === 0) return "No sub-agents spawned yet.";

  const lines: string[] = [];
  const statusIcon: Record<SubAgentStatus, string> = {
    pending: "⏳",
    running: "🟢",
    done: "✅",
    cancelled: "🚫",
    failed: "❌",
  };

  for (const [id, sa] of subAgents) {
    const icon = statusIcon[sa.status];
    const active = id === activeSubAgentId ? " ◀ ACTIVE" : "";
    const time = new Date(sa.createdAt).toLocaleTimeString();
    lines.push(
      `${icon} **${sa.name}** [${sa.status}]${active} — ${time}` +
        (sa.reports.length > 0 ? ` (${sa.reports.length} reports)` : ""),
    );
  }

  const counts = { running: 0, done: 0, pending: 0, failed: 0, cancelled: 0 };
  for (const sa of subAgents.values()) counts[sa.status]++;

  return (
    `## Sub-Agents (${subAgents.size} total: ${counts.running} running, ${counts.done} done, ${counts.pending} pending)\n\n` +
    lines.join("\n")
  );
}

// ---------------------------------------------------------------------------
// Extension
// ---------------------------------------------------------------------------

export default function (pi: ExtensionAPI) {
  // -- task (spawn sub-agent) ---------------------------------------------

  pi.registerTool({
    name: "task",
    label: "Spawn Sub-Agent",
    description:
      "Spawn a focused sub-agent to work on a specific task independently. " +
      "The sub-agent runs in dedicated turns with isolated focus. Use for " +
      "parallel work, deep-dives, research, or code generation. Multiple " +
      "sub-agents can run concurrently.",
    promptSnippet:
      "Spawn a sub-agent to work on a focused task independently",
    promptGuidelines: [
      "Use task to delegate independent work to sub-agents. This is especially " +
        "effective for parallel tasks, focused code analysis, research, and " +
        "generating new modules. Give sub-agents specific, self-contained prompts " +
        "with clear deliverables. Spawn multiple sub-agents in parallel before " +
        "waiting for results.",
      "When you have several independent tasks, spawn multiple sub-agents at once " +
        "rather than working through them sequentially. Check their status with " +
        "task_status() and collect results with task_result() when complete.",
    ],
    parameters: Type.Object({
      name: Type.String({
        description:
          "Short descriptive name for the sub-agent (e.g., 'fix-login-bug', 'refactor-auth'). " +
          "Used in dashboards and status reports.",
      }),
      prompt: Type.String({
        description:
          "Detailed instructions for the sub-agent. Be specific about what to do, " +
          "which files to work on, what the expected output is, and any constraints. " +
          "The sub-agent cannot ask you questions — make it self-contained.",
      }),
      contextFiles: Type.Optional(
        Type.Array(Type.String(), {
          description:
            "Optional list of file paths the sub-agent should focus on. " +
            "The sub-agent will still have access to the full project.",
        }),
      ),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, _ctx) {
      const id = `sa_${++idCounter}`;
      const sa: SubAgent = {
        id,
        name: params.name,
        prompt: params.prompt,
        contextFiles: params.contextFiles ?? [],
        status: "pending",
        result: null,
        reports: [],
        createdAt: Date.now(),
        startedAt: null,
        completedAt: null,
      };
      subAgents.set(id, sa);

      // Queue the sub-agent task as an invisible follow-up message
      const msg = encodeStartMessage(id, params.name, params.prompt);
      pi.sendMessage(
        { customType: "subagent-start", content: msg, display: false },
        { triggerTurn: true, deliverAs: "followUp" },
      );

      return {
        content: [
          {
            type: "text",
            text:
              `🚀 Sub-agent **${params.name}** spawned (id: \`${id}\`).\n` +
              `Status: pending → will run as a follow-up turn.\n` +
              `Check progress with task_status() or Ctrl+Shift+H. Collect results with task_result("${id}") when done.\n` +
              `${(params.contextFiles ?? []).length > 0 ? `Focus files: ${(params.contextFiles ?? []).join(", ")}` : ""}`,
          },
        ],
        details: { id, name: params.name, status: "pending" },
      };
    },
  });

  // -- task_status --------------------------------------------------------

  pi.registerTool({
    name: "task_status",
    label: "Sub-Agent Status",
    description:
      "Check the status of sub-agents. Without arguments shows a dashboard " +
      "of all sub-agents. With an id, shows detailed status for one.",
    promptSnippet:
      "Check status of sub-agents (all or specific one)",
    promptGuidelines: [
      "Use task_status periodically to check on sub-agents you've spawned. " +
        "Call it without arguments for a quick dashboard, or with an id for details. " +
        "Press Ctrl+Shift+H in the TUI for an interactive dashboard.",
    ],
    parameters: Type.Object({
      id: Type.Optional(
        Type.String({
          description:
            "Sub-agent ID to check (from task() return). Omit to see all.",
        }),
      ),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate) {
      if (params.id) {
        const sa = subAgents.get(params.id);
        if (!sa) {
          return {
            content: [
              { type: "text", text: `Sub-agent "${params.id}" not found.` },
            ],
            details: { error: "not_found" },
          };
        }

        const lines = [
          `## Sub-Agent: **${sa.name}** (\`${sa.id}\`)`,
          `Status: **${sa.status}**`,
          `Created: ${new Date(sa.createdAt).toLocaleString()}`,
          sa.startedAt
            ? `Started: ${new Date(sa.startedAt).toLocaleString()}`
            : "",
          sa.completedAt
            ? `Completed: ${new Date(sa.completedAt).toLocaleString()}`
            : "",
          "",
          `**Task**: ${sa.prompt.substring(0, 200)}${sa.prompt.length > 200 ? "..." : ""}`,
          sa.contextFiles.length > 0
            ? `**Focus files**: ${sa.contextFiles.join(", ")}`
            : "",
          "",
        ].filter(Boolean);

        if (sa.reports.length > 0) {
          lines.push("### Progress Reports");
          for (const r of sa.reports) {
            lines.push(
              `- ${new Date(r.timestamp).toLocaleTimeString()}: ${r.text.substring(0, 150)}`,
            );
          }
        }

        if (sa.result) {
          lines.push(
            `### Result\n${sa.result.substring(0, 500)}${sa.result.length > 500 ? "\n...(truncated, use task_result for full)" : ""}`,
          );
        }

        return {
          content: [{ type: "text", text: lines.join("\n") }],
          details: {
            id: sa.id,
            name: sa.name,
            status: sa.status,
            reportCount: sa.reports.length,
            hasResult: sa.result !== null,
          },
        };
      }

      // Dashboard
      return {
        content: [{ type: "text", text: buildDashboard() }],
        details: {
          total: subAgents.size,
          agents: Array.from(subAgents.values()).map((s) => ({
            id: s.id,
            name: s.name,
            status: s.status,
          })),
        },
      };
    },
  });

  // -- task_result --------------------------------------------------------

  pi.registerTool({
    name: "task_result",
    label: "Get Sub-Agent Result",
    description:
      "Retrieve the full result of a completed sub-agent. Returns the " +
      "complete output text the sub-agent produced.",
    promptSnippet:
      "Get the full result from a completed sub-agent",
    parameters: Type.Object({
      id: Type.String({
        description: "Sub-agent ID to get the result from.",
      }),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate) {
      const sa = subAgents.get(params.id);
      if (!sa) {
        return {
          content: [
            { type: "text", text: `Sub-agent "${params.id}" not found.` },
          ],
          details: { error: "not_found" },
        };
      }

      if (sa.status !== "done") {
        return {
          content: [
            {
              type: "text",
              text:
                `Sub-agent **${sa.name}** is not done yet (status: ${sa.status}). ` +
                `Wait for it to complete, or check task_status("${sa.id}") for progress.`,
            },
          ],
          details: { id: sa.id, status: sa.status },
        };
      }

      return {
        content: [
          {
            type: "text",
            text:
              `## Result from sub-agent **${sa.name}**\n\n` +
              (sa.result ?? "(no result text)"),
          },
        ],
        details: {
          id: sa.id,
          name: sa.name,
          result: sa.result,
          reportCount: sa.reports.length,
        },
      };
    },
  });

  // -- task_cancel --------------------------------------------------------

  pi.registerTool({
    name: "task_cancel",
    label: "Cancel Sub-Agent",
    description:
      "Cancel a pending or running sub-agent. Completed sub-agents cannot be cancelled.",
    promptSnippet:
      "Cancel a pending or running sub-agent",
    parameters: Type.Object({
      id: Type.String({
        description: "Sub-agent ID to cancel.",
      }),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      const sa = subAgents.get(params.id);
      if (!sa) {
        return {
          content: [
            { type: "text", text: `Sub-agent "${params.id}" not found.` },
          ],
          details: { error: "not_found" },
        };
      }

      if (sa.status === "done" || sa.status === "cancelled") {
        return {
          content: [
            {
              type: "text",
              text: `Sub-agent **${sa.name}** is already ${sa.status} — cannot cancel.`,
            },
          ],
          details: { id: sa.id, status: sa.status },
        };
      }

      sa.status = "cancelled";
      sa.completedAt = Date.now();
      if (activeSubAgentId === sa.id) {
        activeSubAgentId = null;
        // Abort current turn
        ctx.abort();
      }

      return {
        content: [
          {
            type: "text",
            text: `🚫 Sub-agent **${sa.name}** cancelled.`,
          },
        ],
        details: { id: sa.id, status: "cancelled" },
      };
    },
  });

  // -- task_complete (sub-agent only) -------------------------------------

  pi.registerTool({
    name: "task_complete",
    label: "Complete Sub-Agent Task",
    description:
      "Called by a sub-agent to mark its task as complete and report results. " +
      "Only call this when you are operating as a sub-agent.",
    promptSnippet:
      "Mark sub-agent task as done and report results",
    promptGuidelines: [
      "When you are a sub-agent, call task_complete when you've finished " +
        "your assigned task. Include a clear, detailed summary of what you did, " +
        "what you found, and any important results. The main agent will read this.",
    ],
    parameters: Type.Object({
      result: Type.String({
        description:
          "Complete summary of what the sub-agent accomplished. Include key " +
          "findings, changes made, files modified, decisions taken, and any " +
          "follow-up notes for the main agent.",
      }),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate) {
      // Find the active sub-agent
      if (!activeSubAgentId) {
        return {
          content: [
            {
              type: "text",
              text: "⚠️ No active sub-agent. task_complete should only be called by a running sub-agent.",
            },
          ],
          details: { error: "no_active_subagent" },
        };
      }

      const sa = subAgents.get(activeSubAgentId);
      if (!sa) {
        return {
          content: [
            { type: "text", text: "Active sub-agent not found in registry." },
          ],
          details: { error: "not_found" },
        };
      }

      sa.status = "done";
      sa.result = params.result;
      sa.completedAt = Date.now();

      const doneId = activeSubAgentId;
      const doneName = sa.name;
      activeSubAgentId = null;

      // Notify the main agent that this sub-agent finished (invisible)
      const doneMsg = encodeDoneMessage(doneId, doneName);
      pi.sendMessage(
        { customType: "subagent-done", content: doneMsg, display: false },
        { triggerTurn: true, deliverAs: "followUp" },
      );

      return {
        content: [
          {
            type: "text",
            text: `✅ Sub-agent **${doneName}** completed. Result reported to main agent.`,
          },
        ],
        details: {
          id: doneId,
          name: doneName,
          status: "done",
          resultLength: params.result.length,
        },
      };
    },
  });

  // -- task_report (sub-agent only) ---------------------------------------

  pi.registerTool({
    name: "task_report",
    label: "Sub-Agent Progress Report",
    description:
      "Called by a sub-agent to send an intermediate progress update to the main agent.",
    promptSnippet:
      "Send a progress update from sub-agent to main agent",
    promptGuidelines: [
      "As a sub-agent, call task_report to notify the main agent of significant " +
        "milestones, blockers, or discoveries. Reports are visible in task_status.",
    ],
    parameters: Type.Object({
      text: Type.String({
        description:
          "Progress update text. What have you done so far? What's next? " +
          "Any blockers or discoveries?",
      }),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate) {
      if (!activeSubAgentId) {
        return {
          content: [
            {
              type: "text",
              text: "⚠️ No active sub-agent. task_report should only be called by a running sub-agent.",
            },
          ],
          details: { error: "no_active_subagent" },
        };
      }

      const sa = subAgents.get(activeSubAgentId);
      if (!sa) {
        return {
          content: [
            { type: "text", text: "Active sub-agent not found in registry." },
          ],
          details: { error: "not_found" },
        };
      }

      sa.reports.push({ text: params.text, timestamp: Date.now() });

      return {
        content: [
          {
            type: "text",
            text:
              `📢 Progress report from **${sa.name}** (#${sa.reports.length}):\n` +
              params.text,
          },
        ],
        details: {
          id: sa.id,
          name: sa.name,
          reportIndex: sa.reports.length,
        },
      };
    },
  });

  // -- before_agent_start: inject persona / return to main ---------------

  pi.on("before_agent_start", async (event, ctx) => {
    const text = event.prompt;

    // Check for sub-agent start marker (text-based or custom-type)
    const startMarker = parseStartMarker(text);
    const isCustomStart = (event as any).message?.customType === "subagent-start";

    if (startMarker || isCustomStart) {
      const markerId = startMarker?.id;
      const markerName = startMarker?.name ?? "unknown";
      const sa = markerId ? subAgents.get(markerId) : undefined;

      if (sa) {
        sa.status = "running";
        sa.startedAt = Date.now();
        activeSubAgentId = sa.id;
      }

      const fileList = sa?.contextFiles ?? [];
      const contextHint =
        fileList.length > 0
          ? `\n\n**Files to focus on**: ${fileList.join(", ")}\nRead these files first before taking any action.`
          : "";

      return {
        systemPrompt: event.systemPrompt + "\n\n" + SUBAGENT_SYSTEM_PROMPT + contextHint,
        message: {
          customType: "subagent-start",
          content: `Sub-agent **${markerName}** is now active.`,
          display: false,
        },
      };
    }

    // Check for sub-agent done marker (text-based or custom-type)
    const doneMarker = parseDoneMarker(text);
    const isCustomDone = (event as any).message?.customType === "subagent-done";

    if (doneMarker || isCustomDone) {
      const markerDoneId = doneMarker?.id;
      const markerDoneName = doneMarker?.name ?? "unknown";

      if (markerDoneId && activeSubAgentId === markerDoneId) {
        activeSubAgentId = null;
      }

      return {
        systemPrompt:
          event.systemPrompt +
          `\n\nA sub-agent ("${markerDoneName}") has completed its task. ` +
          `Call task_result("${markerDoneId ?? "unknown"}") to retrieve the full result ` +
          `and incorporate it into your work. Then continue with the main task.`,
      };
    }

    // Main agent mode — inject delegation encouragement (once per session)
    if (!activeSubAgentId) {
      return {
        systemPrompt: event.systemPrompt + "\n\n" + MAIN_AGENT_DELEGATION_GUIDELINES,
      };
    }
  });

  // -- Block user from prompting sub-agents -------------------------------

  pi.on("input", async (event, ctx) => {
    if (activeSubAgentId && event.source === "interactive") {
      // User is trying to type while a sub-agent is active
      const sa = subAgents.get(activeSubAgentId);
      const name = sa?.name ?? "unknown";

      const ok = await ctx.ui.confirm(
        "🤖 Sub-agent is active",
        `Sub-agent **${name}** is currently working.\n\n` +
          `Your input would interrupt it. Instead:\n` +
          `• Wait for the sub-agent to finish, or\n` +
          `• Cancel it with task_cancel("${activeSubAgentId}"), or\n` +
          `• Press Esc to abort the current turn.\n\n` +
          `Send your input anyway?`,
      );

      if (!ok) {
        return { action: "handled" };
      }
      // User confirmed — let input through, sub-agent context will be lost
      activeSubAgentId = null;
      return { action: "continue" };
    }
  });

  // -- Ctrl+Shift+H shortcut: sub-agent dashboard --------------------------

  pi.registerCommand("tasks", {
    description: "View sub-agent dashboard (also available via Ctrl+Shift+H)",
    handler: async (_args, ctx) => {
      await ctx.waitForIdle();

      if (subAgents.size === 0) {
        ctx.ui.notify("No sub-agents have been spawned yet.", "info");
        return;
      }

      const agentList = Array.from(subAgents.values());
      const statusIcon: Record<SubAgentStatus, string> = {
        pending: "⏳",
        running: "🟢",
        done: "✅",
        cancelled: "🚫",
        failed: "❌",
      };

      const options = agentList.map(
        (sa) =>
          `${statusIcon[sa.status]} ${sa.name} [${sa.status}]${sa.id === activeSubAgentId ? " ◀" : ""}`,
      );
      options.push("✖ Close");

      const choice = await ctx.ui.select("🤖 Sub-Agent Dashboard", options);

      if (!choice || choice === "✖ Close") return;

      // Find which agent was selected
      const idx = options.indexOf(choice);
      if (idx < 0 || idx >= agentList.length) return;

      const sa = agentList[idx]!;

      // Build detail view
      const detailLines = [
        `Name: ${sa.name}`,
        `ID: ${sa.id}`,
        `Status: ${sa.status}`,
        `Created: ${new Date(sa.createdAt).toLocaleString()}`,
        sa.startedAt ? `Started: ${new Date(sa.startedAt).toLocaleString()}` : "",
        sa.completedAt
          ? `Completed: ${new Date(sa.completedAt).toLocaleString()}`
          : "",
        "",
        `Task:`,
        sa.prompt,
        "",
      ].filter(Boolean);

      if (sa.reports.length > 0) {
        detailLines.push("--- Progress Reports ---");
        sa.reports.forEach((r) => {
          detailLines.push(
            `[${new Date(r.timestamp).toLocaleTimeString()}] ${r.text}`,
          );
        });
      }

      if (sa.result) {
        detailLines.push("--- Result ---");
        detailLines.push(sa.result.substring(0, 3000));
        if (sa.result.length > 3000) detailLines.push("...(truncated)");
      }

      // Show details as a multi-line notification (or better, a custom widget)
      // Since we can't show large text in a dialog, use the widget area
      if (ctx.hasUI) {
        ctx.ui.setWidget(
          "subagent-detail",
          detailLines,
        );
        ctx.ui.notify(
          `Showing details for sub-agent "${sa.name}". Widget will auto-clear on next turn.`,
          "info",
        );
      }
    },
  });

  // Also register as keyboard shortcut
  pi.registerShortcut("ctrl+shift+h", {
    description: "View sub-agent dashboard",
    handler: async (_event, ctx) => {
      // The shortcut handler receives the key event; queue the command
      pi.sendUserMessage("/tasks", { deliverAs: "followUp" });
      ctx.ui.notify("Opening sub-agent dashboard...", "info");
    },
  });

  // -- Tool execution hooks: track lifecycle ------------------------------

  pi.on("tool_execution_start", async (event) => {
    // Update widget with current status during sub-agent work
    if (activeSubAgentId) {
      const sa = subAgents.get(activeSubAgentId);
      if (sa) {
        // If this is task_complete, don't update
        if (event.toolName !== "task_complete" && event.toolName !== "task_report") {
          // Track that the sub-agent is using tools
        }
      }
    }
  });

  // -- Cleanup on session shutdown ----------------------------------------

  pi.on("session_shutdown", () => {
    subAgents.clear();
    activeSubAgentId = null;
    idCounter = 0;
  });

  // -- Startup notification -----------------------------------------------

  pi.on("session_start", async (_event, ctx) => {
    if (ctx.mode === "tui") {
      ctx.ui.notify(
        "Sub-agent system loaded: task, task_status, task_result — Ctrl+Shift+H for dashboard",
        "info",
      );
    }
  });
}
