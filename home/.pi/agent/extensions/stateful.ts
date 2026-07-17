/**
 * stateful.ts — Pi extension: Stateful tools (todo, counters, bookmarks)
 *
 * Registers session-persistent tools the LLM can use to track progress
 * across multiple turns. State lives in memory for the session lifetime.
 *
 * Tools:
 *   todo_write    — Create/manage a structured task list (add, check, reorder)
 *   todo_list     — View current todos with status
 *   bookmark      — Save a named checkpoint with note (for navigating back)
 *   bookmarks     — List all saved bookmarks
 *   counter       — Named integer counters (increment, decrement, set, get)
 *
 * Usage:
 *   The LLM can call these tools to self-organize during complex multi-step
 *   tasks. All state resets when the session ends or is reloaded.
 *
 * Auto-discovered from ~/.pi/agent/extensions/.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { StringEnum } from "@earendil-works/pi-ai";

// ---------------------------------------------------------------------------
// In-memory stores (session lifetime)
// ---------------------------------------------------------------------------

interface TodoItem {
  id: number;
  text: string;
  done: boolean;
  createdAt: number;
}

const todoStore = new Map<string, TodoItem[]>(); // keyed by list name, default: "default"
let nextTodoId = 1;

interface BookmarkEntry {
  name: string;
  note: string;
  timestamp: number;
}

const bookmarks: BookmarkEntry[] = [];

const counterStore = new Map<string, number>();

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function getTodos(list: string): TodoItem[] {
  if (!todoStore.has(list)) todoStore.set(list, []);
  return todoStore.get(list)!;
}

// ---------------------------------------------------------------------------
// Extension
// ---------------------------------------------------------------------------

export default function (pi: ExtensionAPI) {
  // -- todo_write ---------------------------------------------------------

  pi.registerTool({
    name: "todo_write",
    label: "Todo Write",
    description:
      "Create and manage a structured task list for your current coding session. " +
      "Use to track progress across complex multi-step tasks. Actions: add, check, " +
      "uncheck, remove, reorder, clear.",
    promptSnippet:
      "Manage a structured task list: add, check, uncheck, remove, reorder, clear",
    promptGuidelines: [
      "Use todo_write to track your progress on complex multi-step tasks. " +
        "Break down large tasks into specific, actionable items. " +
        "Check items as you complete them so the user can see your progress. " +
        "Use different list names for distinct work streams.",
      "When you start a multi-step task, call todo_write first to add the steps, " +
        "then check them off as you go. Call todo_list to review status.",
    ],
    parameters: Type.Object({
      action: StringEnum([
        "add",
        "check",
        "uncheck",
        "remove",
        "reorder",
        "clear",
      ] as const),
      list: Type.Optional(
        Type.String({
          default: "default",
          description:
            "Name of the todo list (default: 'default'). Use different names for separate work streams.",
        }),
      ),
      text: Type.Optional(
        Type.String({
          description:
            "For 'add': the task description. For other actions: ignored.",
        }),
      ),
      ids: Type.Optional(
        Type.Array(Type.Integer(), {
          description:
            "For 'check', 'uncheck', 'remove': which todo IDs to affect. " +
            "For 'reorder': the new order of all IDs in this list. " +
            "For 'add', 'clear': ignored.",
        }),
      ),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate) {
      const list = params.list ?? "default";
      const todos = getTodos(list);
      const action = params.action;

      switch (action) {
        case "add": {
          if (!params.text?.trim()) {
            return {
              content: [
                { type: "text", text: "Error: 'text' is required for 'add' action." },
              ],
              details: { error: "missing_text" },
            };
          }
          const item: TodoItem = {
            id: nextTodoId++,
            text: params.text.trim(),
            done: false,
            createdAt: Date.now(),
          };
          todos.push(item);
          return {
            content: [
              {
                type: "text",
                text: `✅ Added todo #${item.id}: "${item.text}" to list "${list}" (${todos.length} total, ${todos.filter((t) => !t.done).length} pending)`,
              },
            ],
            details: { action: "add", item, list, total: todos.length },
          };
        }

        case "check": {
          if (!params.ids || params.ids.length === 0) {
            return {
              content: [
                {
                  type: "text",
                  text: "Error: 'ids' is required for 'check' action.",
                },
              ],
              details: { error: "missing_ids" },
            };
          }
          const checked: number[] = [];
          for (const id of params.ids) {
            const todo = todos.find((t) => t.id === id);
            if (todo && !todo.done) {
              todo.done = true;
              checked.push(id);
            }
          }
          return {
            content: [
              {
                type: "text",
                text: checked.length > 0
                  ? `✅ Checked ${checked.length} todo(s): [${checked.join(", ")}] in list "${list}"`
                  : "No todos were checked (already done or not found).",
              },
            ],
            details: { action: "check", checked, list },
          };
        }

        case "uncheck": {
          if (!params.ids || params.ids.length === 0) {
            return {
              content: [
                {
                  type: "text",
                  text: "Error: 'ids' is required for 'uncheck' action.",
                },
              ],
              details: { error: "missing_ids" },
            };
          }
          const unchecked: number[] = [];
          for (const id of params.ids) {
            const todo = todos.find((t) => t.id === id);
            if (todo && todo.done) {
              todo.done = false;
              unchecked.push(id);
            }
          }
          return {
            content: [
              {
                type: "text",
                text: unchecked.length > 0
                  ? `🔄 Unchecked ${unchecked.length} todo(s): [${unchecked.join(", ")}] in list "${list}"`
                  : "No todos were unchecked (already pending or not found).",
              },
            ],
            details: { action: "uncheck", unchecked, list },
          };
        }

        case "remove": {
          if (!params.ids || params.ids.length === 0) {
            return {
              content: [
                {
                  type: "text",
                  text: "Error: 'ids' is required for 'remove' action.",
                },
              ],
              details: { error: "missing_ids" },
            };
          }
          const removed: number[] = [];
          for (const id of params.ids) {
            const idx = todos.findIndex((t) => t.id === id);
            if (idx !== -1) {
              todos.splice(idx, 1);
              removed.push(id);
            }
          }
          return {
            content: [
              {
                type: "text",
                text: removed.length > 0
                  ? `🗑 Removed ${removed.length} todo(s): [${removed.join(", ")}] from list "${list}" (${todos.length} remaining)`
                  : "No todos were removed (not found).",
              },
            ],
            details: { action: "remove", removed, list, remaining: todos.length },
          };
        }

        case "reorder": {
          if (!params.ids || params.ids.length === 0) {
            return {
              content: [
                {
                  type: "text",
                  text: "Error: 'ids' is required for 'reorder' action. Provide all IDs in the new order.",
                },
              ],
              details: { error: "missing_ids" },
            };
          }
          const idSet = new Set(params.ids);
          if (idSet.size !== params.ids.length || idSet.size !== todos.length) {
            return {
              content: [
                {
                  type: "text",
                  text: `Error: 'ids' must contain each todo ID exactly once. Expected ${todos.length} unique IDs, got ${idSet.size}.`,
                },
              ],
              details: { error: "invalid_reorder_ids" },
            };
          }
          const reordered = params.ids
            .map((id) => todos.find((t) => t.id === id)!)
            .filter(Boolean);
          todoStore.set(list, reordered);
          return {
            content: [
              {
                type: "text",
                text: `📋 Reordered ${todos.length} todo(s) in list "${list}".`,
              },
            ],
            details: { action: "reorder", list, total: todos.length },
          };
        }

        case "clear": {
          const count = todos.length;
          todoStore.set(list, []);
          return {
            content: [
              {
                type: "text",
                text: `🧹 Cleared ${count} todo(s) from list "${list}".`,
              },
            ],
            details: { action: "clear", list, removed: count },
          };
        }

        default:
          return {
            content: [
              {
                type: "text",
                text: `Unknown action: ${action}`,
              },
            ],
            details: { error: "unknown_action" },
          };
      }
    },
  });

  // -- todo_list ----------------------------------------------------------

  pi.registerTool({
    name: "todo_list",
    label: "Todo List",
    description:
      "View the current state of your todo list(s). Shows all items with " +
      "their status (pending/done), IDs, and summary counts.",
    promptSnippet: "View current todo list(s) with status and counts",
    promptGuidelines: [
      "Use todo_list to review your progress. Call it before starting work " +
        "to see what's pending, and after finishing tasks to confirm completion.",
    ],
    parameters: Type.Object({
      list: Type.Optional(
        Type.String({
          description:
            "Name of the list to view. Omit to see all lists.",
        }),
      ),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate) {
      if (params.list) {
        const todos = getTodos(params.list);
        if (todos.length === 0) {
          return {
            content: [
              {
                type: "text",
                text: `List "${params.list}" is empty.`,
              },
            ],
            details: { list: params.list, todos: [], total: 0, done: 0, pending: 0 },
          };
        }

        const done = todos.filter((t) => t.done).length;
        const pending = todos.length - done;
        const lines = todos.map(
          (t) => `  ${t.done ? "✅" : "⬜"} #${t.id} ${t.text}`,
        );

        return {
          content: [
            {
              type: "text",
              text:
                `## Todo List: "${params.list}"\n` +
                `${done}/${todos.length} done, ${pending} pending\n\n` +
                lines.join("\n"),
            },
          ],
          details: { list: params.list, todos, total: todos.length, done, pending },
        };
      }

      // Show all lists
      const allLists = Array.from(todoStore.entries());
      if (allLists.length === 0) {
        return {
          content: [
            { type: "text", text: "No todo lists exist yet. Use todo_write to create one." },
          ],
          details: { lists: [] },
        };
      }

      const sections: string[] = [];
      let grandTotal = 0;
      let grandDone = 0;

      for (const [name, todos] of allLists) {
        if (todos.length === 0) continue;
        const done = todos.filter((t) => t.done).length;
        grandTotal += todos.length;
        grandDone += done;

        const lines = todos.map(
          (t) => `  ${t.done ? "✅" : "⬜"} #${t.id} ${t.text}`,
        );
        sections.push(
          `### ${name} (${done}/${todos.length})\n${lines.join("\n")}`,
        );
      }

      return {
        content: [
          {
            type: "text",
            text:
              `## All Todo Lists (${grandDone}/${grandTotal} overall)\n\n` +
              sections.join("\n\n"),
          },
        ],
        details: {
          lists: allLists.map(([name, todos]) => ({
            name,
            todos,
            total: todos.length,
            done: todos.filter((t) => t.done).length,
          })),
          grandTotal,
          grandDone,
        },
      };
    },
  });

  // -- bookmark -----------------------------------------------------------

  pi.registerTool({
    name: "bookmark",
    label: "Bookmark",
    description:
      "Save a named checkpoint with a note. Use to mark important points " +
      "in a session (e.g., 'before refactor', 'after fixing bug X').",
    promptSnippet: "Save a named bookmark/checkpoint with an optional note",
    promptGuidelines: [
      "Use bookmark to save checkpoints during complex work. " +
        "This helps you (and the user) navigate back to key decision points.",
    ],
    parameters: Type.Object({
      name: Type.String({
        description: "Short name for the bookmark (e.g., 'before-refactor').",
      }),
      note: Type.Optional(
        Type.String({
          description: "Optional note describing what happened at this point.",
        }),
      ),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate) {
      const entry: BookmarkEntry = {
        name: params.name,
        note: params.note ?? "",
        timestamp: Date.now(),
      };
      bookmarks.push(entry);

      return {
        content: [
          {
            type: "text",
            text: `🔖 Bookmarked: **${params.name}** (${bookmarks.length} total bookmarks)${params.note ? ` — ${params.note}` : ""}`,
          },
        ],
        details: { bookmark: entry, total: bookmarks.length },
      };
    },
  });

  // -- bookmarks ----------------------------------------------------------

  pi.registerTool({
    name: "bookmarks",
    label: "List Bookmarks",
    description: "List all saved bookmarks with their notes and timestamps.",
    promptSnippet: "List all saved bookmarks",
    parameters: Type.Object({}),
    async execute(_toolCallId, _params, _signal, _onUpdate) {
      if (bookmarks.length === 0) {
        return {
          content: [
            { type: "text", text: "No bookmarks saved yet. Use the bookmark tool to create one." },
          ],
          details: { bookmarks: [] },
        };
      }

      const lines = bookmarks.map(
        (b, i) =>
          `  ${i + 1}. **${b.name}** — ${b.note || "(no note)"} — ${new Date(b.timestamp).toLocaleTimeString()}`,
      );

      return {
        content: [
          {
            type: "text",
            text: `## Bookmarks (${bookmarks.length})\n${lines.join("\n")}`,
          },
        ],
        details: { bookmarks },
      };
    },
  });

  // -- counter ------------------------------------------------------------

  pi.registerTool({
    name: "counter",
    label: "Counter",
    description:
      "Named integer counters for tracking counts across turns. " +
      "Operations: get, set, increment, decrement, reset, list.",
    promptSnippet:
      "Manage named integer counters: get, set, inc, dec, reset, list",
    promptGuidelines: [
      "Use counter to track metrics across turns (e.g., files processed, " +
        "errors encountered, retry attempts). Name counters descriptively.",
    ],
    parameters: Type.Object({
      action: StringEnum([
        "get",
        "set",
        "increment",
        "decrement",
        "reset",
        "list",
      ] as const),
      name: Type.Optional(
        Type.String({
          description:
            "Counter name. Required for all actions except 'list'.",
        }),
      ),
      value: Type.Optional(
        Type.Integer({
          description:
            "For 'set': the value to set. For 'increment'/'decrement': " +
            "the amount (default: 1).",
        }),
      ),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate) {
      const action = params.action;

      if (action === "list") {
        if (counterStore.size === 0) {
          return {
            content: [
              { type: "text", text: "No counters defined." },
            ],
            details: { counters: {} },
          };
        }
        const entries = Array.from(counterStore.entries())
          .sort(([a], [b]) => a.localeCompare(b))
          .map(([k, v]) => `  ${k} = ${v}`);
        return {
          content: [
            {
              type: "text",
              text: `## Counters\n${entries.join("\n")}`,
            },
          ],
          details: { counters: Object.fromEntries(counterStore) },
        };
      }

      if (!params.name) {
        return {
          content: [
            {
              type: "text",
              text: `Error: 'name' is required for action '${action}'.`,
            },
          ],
          details: { error: "missing_name" },
        };
      }

      const name = params.name;

      switch (action) {
        case "get": {
          const val = counterStore.get(name) ?? 0;
          return {
            content: [
              { type: "text", text: `Counter "${name}" = ${val}` },
            ],
            details: { name, value: val },
          };
        }

        case "set": {
          if (params.value === undefined) {
            return {
              content: [
                {
                  type: "text",
                  text: "Error: 'value' is required for 'set' action.",
                },
              ],
              details: { error: "missing_value" },
            };
          }
          const prev = counterStore.get(name);
          counterStore.set(name, params.value);
          return {
            content: [
              {
                type: "text",
                text: `Counter "${name}": ${prev ?? "(none)"} → ${params.value}`,
              },
            ],
            details: { name, previous: prev, current: params.value },
          };
        }

        case "increment": {
          const delta = params.value ?? 1;
          const current = (counterStore.get(name) ?? 0) + delta;
          counterStore.set(name, current);
          return {
            content: [
              {
                type: "text",
                text: `Counter "${name}" +${delta} → ${current}`,
              },
            ],
            details: { name, delta, current },
          };
        }

        case "decrement": {
          const delta = params.value ?? 1;
          const current = (counterStore.get(name) ?? 0) - delta;
          counterStore.set(name, current);
          return {
            content: [
              {
                type: "text",
                text: `Counter "${name}" -${delta} → ${current}`,
              },
            ],
            details: { name, delta: -delta, current },
          };
        }

        case "reset": {
          counterStore.delete(name);
          return {
            content: [
              {
                type: "text",
                text: `Counter "${name}" reset (removed).`,
              },
            ],
            details: { name, action: "reset" },
          };
        }

        default:
          return {
            content: [
              { type: "text", text: `Unknown action: ${action}` },
            ],
            details: { error: "unknown_action" },
          };
      }
    },
  });

  // -- Reset state on session shutdown ------------------------------------

  pi.on("session_shutdown", () => {
    todoStore.clear();
    bookmarks.length = 0;
    counterStore.clear();
    nextTodoId = 1;
  });

  // -- Log ----------------------------------------------------------------

  pi.on("session_start", async (_event, ctx) => {
    if (ctx.mode === "tui") {
      ctx.ui.notify(
        "Stateful tools loaded: todo_write, todo_list, bookmark, bookmarks, counter",
        "info",
      );
    }
  });
}
