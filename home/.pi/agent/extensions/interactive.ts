/**
 * interactive.ts — Pi extension: Interactive user-facing tools
 *
 * Registers tools the LLM can call to ask the user questions, confirm
 * actions, or present choice dialogs. This turns the agent from a
 * one-way executor into a two-way collaborator.
 *
 * Tools:
 *   ask_user      — Free-text question, returns user's response
 *   confirm       — Yes/No confirmation dialog
 *   select_option — Single choice from a list
 *   multi_select  — Multiple choices from a list
 *
 * Usage:
 *   The LLM will call these tools automatically when it needs user input.
 *   No manual commands required.
 *
 * Auto-discovered from ~/.pi/agent/extensions/.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

export default function (pi: ExtensionAPI) {
  // -- ask_user -----------------------------------------------------------

  pi.registerTool({
    name: "ask_user",
    label: "Ask User",
    description:
      "Ask the user a question and return their text response. " +
      "Use when you need clarification, requirements, preferences, " +
      "or any other textual input from the user.",
    promptSnippet: "Ask the user a question and get their free-text response",
    promptGuidelines: [
      "Use ask_user when you need the user to clarify requirements, " +
        "choose between options not suited for a simple list, or provide " +
        "information you cannot infer from the codebase.",
    ],
    parameters: Type.Object({
      question: Type.String({
        description:
          "The question to ask the user. Be clear and specific about what you need.",
      }),
      placeholder: Type.Optional(
        Type.String({
          description:
            "Placeholder text shown in the input field (optional hint).",
        }),
      ),
      default: Type.Optional(
        Type.String({
          description: "Default answer if the user submits empty input.",
        }),
      ),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      const answer = await ctx.ui.input(
        params.question,
        params.placeholder,
        params.default,
      );

      if (answer === undefined || answer === null) {
        return {
          content: [
            {
              type: "text",
              text: "User cancelled the input (ESC was pressed).",
            },
          ],
          details: { cancelled: true },
        };
      }

      return {
        content: [
          {
            type: "text",
            text: answer.trim() === ""
              ? "(user provided empty answer)"
              : answer,
          },
        ],
        details: { answer },
      };
    },
  });

  // -- confirm ------------------------------------------------------------

  pi.registerTool({
    name: "confirm",
    label: "Confirm Action",
    description:
      "Ask the user to confirm (Yes/No) an action before proceeding. " +
      "Use before destructive or irreversible operations.",
    promptSnippet: "Ask the user to confirm an action (yes/no)",
    promptGuidelines: [
      "Use confirm before irreversible or destructive actions. " +
        "Always explain what will happen if the user says yes.",
    ],
    parameters: Type.Object({
      title: Type.String({
        description:
          "Brief title for the confirmation dialog (e.g., 'Delete files?').",
      }),
      message: Type.String({
        description:
          "Detailed explanation of what action is being confirmed and its consequences.",
      }),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      const ok = await ctx.ui.confirm(params.title, params.message);

      return {
        content: [
          {
            type: "text",
            text: ok
              ? "✅ User confirmed: YES — proceed with the action."
              : "❌ User denied: NO — do NOT proceed.",
          },
        ],
        details: { confirmed: ok },
      };
    },
  });

  // -- select_option ------------------------------------------------------

  pi.registerTool({
    name: "select_option",
    label: "Select Option",
    description:
      "Present the user with a list of options and let them pick one. " +
      "Returns the selected option, or null if cancelled.",
    promptSnippet:
      "Ask the user to pick one option from a list",
    promptGuidelines: [
      "Use select_option when the user needs to choose between mutually exclusive options. " +
        "Keep the option list concise (max ~15 items).",
    ],
    parameters: Type.Object({
      title: Type.String({
        description:
          "Prompt shown above the list (e.g., 'Which package manager?').",
      }),
      options: Type.Array(Type.String(), {
        description: "List of options for the user to choose from.",
      }),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      const choice = await ctx.ui.select(params.title, params.options);

      if (choice === undefined || choice === null) {
        return {
          content: [
            {
              type: "text",
              text: "User cancelled the selection (ESC was pressed).",
            },
          ],
          details: { selected: null, cancelled: true },
        };
      }

      return {
        content: [
          {
            type: "text",
            text: `User selected: **${choice}**`,
          },
        ],
        details: { selected: choice, index: params.options.indexOf(choice) },
      };
    },
  });

  // -- multi_select -------------------------------------------------------

  pi.registerTool({
    name: "multi_select",
    label: "Multi Select",
    description:
      "Present the user with a list of options and let them pick multiple. " +
      "Returns the selected options array, or empty if cancelled/none.",
    promptSnippet:
      "Ask the user to pick multiple options from a list",
    promptGuidelines: [
      "Use multi_select when the user needs to select multiple items " +
        "(e.g., which features to implement, which files to include).",
    ],
    parameters: Type.Object({
      title: Type.String({
        description:
          "Prompt shown above the list (e.g., 'Select features to add:').",
      }),
      options: Type.Array(Type.String(), {
        description: "List of options the user can pick from.",
      }),
      minSelect: Type.Optional(
        Type.Integer({
          minimum: 1,
          description:
            "Minimum number of options the user must select (default: 0).",
        }),
      ),
      maxSelect: Type.Optional(
        Type.Integer({
          minimum: 1,
          description:
            "Maximum number of options the user can select (default: unlimited).",
        }),
      ),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      // Note: ctx.ui doesn't have a native multi_select.
      // We work around it by using repeated select calls,
      // or by using ctx.ui.custom() for a richer experience.
      //
      // Since custom() is complex, we use a simpler approach:
      // present a combined label in the select dialog that includes
      // checkboxes, then parse.

      // Build display labels with checkboxes
      const displayOptions = params.options.map((opt) => `☐ ${opt}`);
      displayOptions.push("✅ Done selecting");

      const selected: string[] = [];
      let done = false;

      while (!done) {
        const remainingOptions = params.options
          .filter((o) => !selected.includes(o))
          .map((o) => `☐ ${o}`);

        if (remainingOptions.length === 0) {
          done = true;
          break;
        }

        const allOptions = [...remainingOptions, "✅ Done selecting"];
        const choice = await ctx.ui.select(
          `${params.title}\n${selected.length > 0 ? `Selected (${selected.length}): ${selected.join(", ")}` : "None selected yet"}`,
          allOptions,
        );

        if (choice === undefined || choice === null || choice === "✅ Done selecting") {
          done = true;
        } else {
          const chosen = choice.replace(/^☐ /, "");
          if (!selected.includes(chosen)) {
            selected.push(chosen);
          }
        }

        // Check max
        if (params.maxSelect && selected.length >= params.maxSelect) {
          done = true;
        }
      }

      // Check min
      if (params.minSelect && selected.length < params.minSelect) {
        return {
          content: [
            {
              type: "text",
              text: `User selected fewer than the minimum required (${params.minSelect}). Selected: ${selected.length === 0 ? "(none)" : selected.join(", ")}`,
            },
          ],
          details: { selected, belowMin: true },
        };
      }

      if (selected.length === 0) {
        return {
          content: [
            {
              type: "text",
              text: "User selected no options.",
            },
          ],
          details: { selected: [] },
        };
      }

      return {
        content: [
          {
            type: "text",
            text: `User selected (${selected.length}):\n${selected.map((s) => `- ${s}`).join("\n")}`,
          },
        ],
        details: { selected },
      };
    },
  });

  // -- Log ----------------------------------------------------------------

  pi.on("session_start", async (_event, ctx) => {
    if (ctx.mode === "tui") {
      ctx.ui.notify(
        "Interactive tools loaded: ask_user, confirm, select_option, multi_select",
        "info",
      );
    }
  });
}
