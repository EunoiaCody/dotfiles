/**
 * tmp-session - Temporary conversation session
 *
 * Usage:
 *   /tmp              - Enter a new temporary session with empty editor
 *   /tmp <message>    - Enter a new temporary session with the message pre-filled
 *
 * Once in a temporary session, you cannot switch back to a normal session,
 * fork into a normal session, or navigate the tree into normal territory.
 * The temporary session is a one-way door — work freely, then quit.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const TMP_MARKER = "tmp-session-marker";

export default function (pi: ExtensionAPI) {
  let isTmpSession = false;

  // Detect if this session is a temporary session on startup
  pi.on("session_start", async (_event, ctx) => {
    isTmpSession = false;
    for (const entry of ctx.sessionManager.getEntries()) {
      if (entry.type === "custom" && entry.customType === TMP_MARKER) {
        isTmpSession = true;

        // Update status line to show temp indicator
        ctx.ui.setStatus("tmp", "🔸 TEMP");
        break;
      }
    }
  });

  // Block leaving a temporary session
  pi.on("session_before_switch", async (event, ctx) => {
    if (!isTmpSession) return;

    // Allow switching within temp sessions only if the target is also temp.
    // For now, block all switches from a temp session to prevent
    // accidentally merging temp work into normal sessions.
    ctx.ui.notify(
      "Cannot switch sessions from a temporary session. Use /quit to exit.",
      "warning",
    );
    return { cancel: true };
  });

  // Block forking from a temporary session into normal territory
  pi.on("session_before_fork", async (_event, ctx) => {
    if (!isTmpSession) return;

    ctx.ui.notify(
      "Cannot fork from a temporary session. Use /quit to exit.",
      "warning",
    );
    return { cancel: true };
  });

  // Register the /tmp command
  pi.registerCommand("tmp", {
    description: "Enter a new temporary conversation session",
    handler: async (args, ctx) => {
      if (ctx.mode !== "tui") {
        ctx.ui.notify("/tmp requires interactive mode", "error");
        return;
      }

      // Don't allow nesting temp sessions (already in one)
      if (isTmpSession) {
        ctx.ui.notify("Already in a temporary session.", "info");
        return;
      }

      const message = args.trim();
      const currentSessionFile = ctx.sessionManager.getSessionFile();

      // Create a new session with parent tracking
      const result = await ctx.newSession({
        parentSession: currentSessionFile,
        setup: (sm) => {
          // Mark the new session as temporary
          sm.appendCustomEntry(TMP_MARKER, {
            createdAt: Date.now(),
            parentSession: currentSessionFile,
          });
        },
        withSession: async (replacementCtx) => {
          if (message) {
            replacementCtx.ui.setEditorText(message);
          }
          replacementCtx.ui.setStatus("tmp", "🔸 TEMP");
          replacementCtx.ui.notify(
            "Entered temporary session. Work here is isolated. /quit to exit.",
            "info",
          );
        },
      });

      if (result.cancelled) {
        ctx.ui.notify("Temporary session cancelled.", "info");
      }
    },
  });

  // Clean up status on shutdown
  pi.on("session_shutdown", async (_event, ctx) => {
    ctx.ui.setStatus("tmp", undefined);
  });
}
