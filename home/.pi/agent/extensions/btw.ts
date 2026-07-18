/**
 * btw - "By The Way" side-channel question
 *
 * Usage:
 *   /btw <question>   - Ask a question without affecting the current session
 *
 * The question and its answer are shown in a popup dialog. Nothing is added
 * to the conversation history — your main workflow continues undisturbed.
 * Useful for quick lookups, fact checks, or tangent questions while working.
 *
 * How it works:
 * - Runs an isolated, standalone LLM call using the current model
 * - Displays the answer in a scrollable select-list overlay
 * - The Q&A pair never enters the session or agent context
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { complete, type Message } from "@earendil-works/pi-ai/compat";
import { BorderedLoader } from "@earendil-works/pi-coding-agent";

const BTW_SYSTEM_PROMPT = `You are a helpful assistant answering a quick, incidental question. 
The user is in the middle of other work and just needs a concise, accurate answer.

Rules:
- Answer concisely but thoroughly
- Do NOT ask follow-up questions or offer to help further
- Do NOT use any tools — just answer from your knowledge
- If you genuinely don't know, say so briefly
- Format your answer to be self-contained and immediately useful`;

export default function (pi: ExtensionAPI) {
  pi.registerCommand("btw", {
    description: "Ask a quick side question (does not affect the session)",
    handler: async (args, ctx) => {
      if (ctx.mode !== "tui") {
        ctx.ui.notify("/btw requires interactive mode", "error");
        return;
      }

      const question = args.trim();
      if (!question) {
        ctx.ui.notify("Usage: /btw <question>", "warning");
        return;
      }

      if (!ctx.model) {
        ctx.ui.notify("No model selected", "error");
        return;
      }

      // Show a loading overlay while the LLM responds
      const answer = await ctx.ui.custom<string | null>(
        (tui, theme, _kb, done) => {
          const loader = new BorderedLoader(
            tui,
            theme,
            `Asking: ${question.slice(0, 60)}...`,
          );
          loader.onAbort = () => done(null);

          const doQuery = async () => {
            try {
              const auth = await ctx.modelRegistry.getApiKeyAndHeaders(ctx.model!);
              if (!auth.ok || !auth.apiKey) {
                throw new Error(auth.ok ? `No API key for ${ctx.model!.provider}` : auth.error);
              }

              const userMessage: Message = {
                role: "user",
                content: [{ type: "text", text: question }],
                timestamp: Date.now(),
              };

              const response = await complete(
                ctx.model!,
                { systemPrompt: BTW_SYSTEM_PROMPT, messages: [userMessage] },
                {
                  apiKey: auth.apiKey,
                  headers: auth.headers,
                  env: auth.env,
                  signal: loader.signal,
                },
              );

              if (response.stopReason === "aborted") {
                done(null);
                return;
              }

              const text = response.content
                .filter((c): c is { type: "text"; text: string } => c.type === "text")
                .map((c) => c.text)
                .join("\n");

              done(text || "(no response)");
            } catch (err) {
              console.error("btw failed:", err);
              done(null);
            }
          };

          doQuery();
          return loader;
        },
      );

      if (answer === null) {
        ctx.ui.notify("Cancelled", "info");
        return;
      }

      // Show the answer in a scrollable selector-style dialog.
      // We split the answer into lines so the user can scroll.
      const lines = answer.split("\n");
      const title = `💬 BTW: ${question.slice(0, 50)}${question.length > 50 ? "..." : ""}`;

      // Show result as a selectable (scrollable) list
      await ctx.ui.select(title, lines);
    },
  });
}
