/**
 * session-viewer.ts — Pi extension: cross-session conversation viewer
 *
 * Provides tools (for LLM) and commands (for user) to browse and read
 * conversation history from other pi sessions.
 *
 * Tools:
 *   list_sessions  — Enumerate all available sessions across projects
 *   view_session   — Read conversation history from a specific session
 *
 * Commands:
 *   /sessions      — Interactive session browser
 *   /peek <id>     — Quick peek at a session's conversation
 *
 * Auto-discovered from ~/.pi/agent/extensions/.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { readFileSync, existsSync, readdirSync, statSync } from "node:fs";
import { join, basename, resolve, dirname } from "node:path";
import { homedir } from "node:os";

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/** Pi agent config directory */
const PI_AGENT_DIR = process.env.PI_CODING_AGENT_DIR ?? join(homedir(), ".pi", "agent");

/** Sessions storage directory */
const SESSIONS_DIR = process.env.PI_CODING_AGENT_SESSION_DIR ?? join(PI_AGENT_DIR, "sessions");

/** Maximum characters for a single message in output */
const MAX_MESSAGE_LENGTH = 3000;

/** Maximum total output characters for view_session */
const MAX_OUTPUT_LENGTH = 80_000;

/** Maximum session files to scan in list_sessions */
const MAX_SCAN_FILES = 200;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface SessionHeader {
  id: string;
  version: number;
  timestamp: string;
  cwd: string;
  parentSession?: string;
}

interface SessionInfo {
  file: string;
  id: string;
  cwd: string;
  timestamp: string;
  name?: string;
  messageCount: number;
  firstUserMessage?: string;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/**
 * Parse the first line (session header) of a JSONL session file.
 */
function parseSessionHeader(line: string): SessionHeader | null {
  try {
    const obj = JSON.parse(line);
    if (obj.type === "session") {
      return {
        id: obj.id ?? "",
        version: obj.version ?? 1,
        timestamp: obj.timestamp ?? "",
        cwd: obj.cwd ?? "",
        parentSession: obj.parentSession,
      };
    }
  } catch {
    // Not valid JSON or not a session header
  }
  return null;
}

/**
 * Extract display text from a message content field.
 * Content can be a string or an array of content blocks.
 */
function extractMessageText(content: unknown): string {
  if (typeof content === "string") {
    return content;
  }
  if (Array.isArray(content)) {
    const parts: string[] = [];
    for (const block of content) {
      if (block && typeof block === "object") {
        if (block.type === "text" && typeof block.text === "string") {
          parts.push(block.text);
        } else if (block.type === "thinking" && typeof block.thinking === "string") {
          parts.push(`<thinking>${block.thinking}</thinking>`);
        } else if (block.type === "toolCall") {
          const tc = block as any;
          parts.push(`[toolCall: ${tc.name ?? "?"}]`);
        }
      }
    }
    return parts.join("\n");
  }
  return "";
}

/**
 * Truncate a string to maxLen characters, appending indicator if truncated.
 */
function truncate(text: string, maxLen: number): string {
  if (text.length <= maxLen) return text;
  return text.slice(0, maxLen) + `\n... (truncated ${text.length - maxLen} more chars)`;
}

/**
 * Format a single session entry as a human-readable line.
 */
function formatEntry(
  entry: Record<string, any>,
  includeToolResults: boolean,
): string | null {
  // Only handle message entries
  if (entry.type !== "message") return null;

  const msg = entry.message;
  if (!msg) return null;

  const role = msg.role;

  switch (role) {
    case "user": {
      const text = extractMessageText(msg.content);
      return `**👤 User:** ${text}`;
    }

    case "assistant": {
      const parts: string[] = [];
      const content = Array.isArray(msg.content) ? msg.content : [];

      for (const block of content) {
        if (!block || typeof block !== "object") continue;
        if (block.type === "text" && typeof block.text === "string") {
          parts.push(block.text);
        } else if (block.type === "toolCall") {
          parts.push(`🔧 _calls \`${block.name}\`_`);
        }
        // Skip thinking blocks in main output (verbose)
      }

      const text = parts.join("\n");
      if (!text) return null;
      return `**🤖 Assistant:** ${text}`;
    }

    case "toolResult": {
      if (!includeToolResults) return null;
      const toolName = msg.toolName ?? "unknown";
      const text = extractMessageText(msg.content);
      const shortText = truncate(text, 500);
      return `  📎 _${toolName}_: ${shortText}`;
    }

    default:
      return null;
  }
}

/**
 * Get relative time string from ISO timestamp.
 */
function relativeTime(isoTimestamp: string): string {
  try {
    const date = new Date(isoTimestamp);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffDays = Math.floor(diffMs / 86400000);

    if (diffDays === 0) return "今天";
    if (diffDays === 1) return "昨天";
    if (diffDays < 7) return `${diffDays} 天前`;
    if (diffDays < 30) return `${Math.floor(diffDays / 7)} 周前`;
    if (diffDays < 365) return `${Math.floor(diffDays / 30)} 月前`;
    return `${Math.floor(diffDays / 365)} 年前`;
  } catch {
    return isoTimestamp.slice(0, 10);
  }
}

/**
 * Walk sessions directory and return all .jsonl session file paths.
 */
function findAllSessionFiles(): string[] {
  const files: string[] = [];

  if (!existsSync(SESSIONS_DIR)) return files;

  try {
    const projectDirs = readdirSync(SESSIONS_DIR);
    for (const dirName of projectDirs) {
      const dirPath = join(SESSIONS_DIR, dirName);
      let stat;
      try {
        stat = statSync(dirPath);
      } catch {
        continue;
      }
      if (!stat.isDirectory()) continue;

      const sessionFiles = readdirSync(dirPath);
      for (const fileName of sessionFiles) {
        if (fileName.endsWith(".jsonl")) {
          files.push(join(dirPath, fileName));
          if (files.length >= MAX_SCAN_FILES) return files;
        }
      }
    }
  } catch {
    // Permission errors, etc.
  }

  return files;
}

/**
 * Find a session file by UUID (full or partial match) or by file path.
 * Returns the first match.
 */
function findSessionFile(sessionId: string): string | null {
  // Normalize: remove trailing .jsonl if present
  const cleanId = sessionId.replace(/\.jsonl$/, "");

  // 1. Try as direct file path
  if (existsSync(sessionId) && sessionId.endsWith(".jsonl")) {
    return sessionId;
  }
  // Also try with .jsonl appended
  const withExt = sessionId + ".jsonl";
  if (existsSync(withExt)) {
    return withExt;
  }

  // 2. Search by UUID (exact or partial match) in sessions directory
  const allFiles = findAllSessionFiles();
  for (const file of allFiles) {
    const base = basename(file, ".jsonl");
    // The filename format is: <timestamp>_<uuid>.jsonl
    // Check if the uuid portion matches
    if (base.includes(cleanId)) {
      return file;
    }

    // Also try reading the header to match session.id
    try {
      const firstLine = readFirstLine(file);
      const header = parseSessionHeader(firstLine);
      if (header && header.id === cleanId) {
        return file;
      }
      if (header && header.id.includes(cleanId)) {
        return file;
      }
    } catch {
      // skip
    }
  }

  // 3. Search by session name (via session_info entries)
  for (const file of allFiles) {
    try {
      const info = readSessionInfo(file);
      if (info?.name && info.name.toLowerCase().includes(cleanId.toLowerCase())) {
        return file;
      }
    } catch {
      // skip
    }
  }

  return null;
}

/**
 * Read just the first line of a file efficiently.
 */
function readFirstLine(filePath: string): string {
  const fd = readFileSync(filePath, "utf8");
  const newlineIdx = fd.indexOf("\n");
  return newlineIdx >= 0 ? fd.slice(0, newlineIdx) : fd;
}

/**
 * Read session metadata without loading the whole file.
 */
function readSessionInfo(filePath: string): SessionInfo | null {
  try {
    const content = readFileSync(filePath, "utf8");
    const lines = content.trim().split("\n");
    if (lines.length === 0) return null;

    const header = parseSessionHeader(lines[0]);
    if (!header) return null;

    let name: string | undefined;
    let firstUserMessage: string | undefined;
    let messageCount = 0;

    for (let i = 1; i < lines.length; i++) {
      try {
        const entry = JSON.parse(lines[i]);
        if (entry.type === "session_info" && entry.name) {
          name = entry.name;
        }
        if (entry.type === "message") {
          messageCount++;
          if (!firstUserMessage && entry.message?.role === "user") {
            const text = extractMessageText(entry.message.content);
            firstUserMessage = truncate(text, 120);
          }
        }
      } catch {
        // skip broken lines
      }
    }

    return {
      file: filePath,
      id: header.id,
      cwd: header.cwd,
      timestamp: header.timestamp,
      name,
      messageCount,
      firstUserMessage,
    };
  } catch {
    return null;
  }
}

/**
 * Validate that a file path is within the sessions directory (security check).
 */
function isWithinSessionsDir(filePath: string): boolean {
  const resolved = resolve(filePath);
  const sessionsResolved = resolve(SESSIONS_DIR);
  return resolved.startsWith(sessionsResolved);
}

// ---------------------------------------------------------------------------
// Extension
// ---------------------------------------------------------------------------

export default function (pi: ExtensionAPI) {
  // --- session_start: notify extension is loaded ---
  pi.on("session_start", async (_event, ctx) => {
    if (ctx.mode === "tui") {
      // Silent load — extension is always ready
    }
  });

  // =========================================================================
  // Tool: list_sessions
  // =========================================================================
  pi.registerTool({
    name: "list_sessions",
    label: "List Sessions",
    description:
      "列出所有可用的 pi 会话记录。返回会话 ID、项目路径、时间、消息数量等信息。" +
      "当用户询问「之前的对话」「其他会话」「查看历史记录」时使用此工具。",
    promptSnippet: "列出所有可用的 pi 会话记录",
    promptGuidelines: [
      "当用户想查看或引用其他 pi 会话的历史对话时，先用 list_sessions 获取可用会话列表。",
      "list_sessions 返回会话的元信息（ID、项目、时间、消息数），不包含对话内容。获取到会话 ID 后再用 view_session 查看对话内容。",
    ],
    parameters: Type.Object({
      project: Type.Optional(
        Type.String({
          description: "按项目路径过滤，只返回该项目的会话。例如 '/home/user/myproject'",
        }),
      ),
      limit: Type.Optional(
        Type.Number({
          description: "最大返回条数，默认 20",
          default: 20,
        }),
      ),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      const limit = Math.min(Math.max(params.limit ?? 20, 1), 50);
      const projectFilter = params.project?.trim();

      const currentSessionFile = ctx.sessionManager.getSessionFile();
      const allFiles = findAllSessionFiles();

      // Read info for each file
      const infos: SessionInfo[] = [];
      for (const file of allFiles) {
        // Skip current session
        if (currentSessionFile && resolve(file) === resolve(currentSessionFile)) {
          continue;
        }

        const info = readSessionInfo(file);
        if (!info) continue;

        // Apply project filter
        if (projectFilter && !info.cwd.includes(projectFilter)) {
          continue;
        }

        infos.push(info);
        if (infos.length >= MAX_SCAN_FILES) break;
      }

      // Sort by timestamp descending (newest first)
      infos.sort((a, b) => b.timestamp.localeCompare(a.timestamp));

      // Take top N
      const top = infos.slice(0, limit);

      if (top.length === 0) {
        return {
          content: [
            {
              type: "text",
              text: projectFilter
                ? `未找到项目 "${projectFilter}" 的会话记录。`
                : "未找到任何会话记录。",
            },
          ],
        };
      }

      // Format as Markdown table
      const lines: string[] = [
        `共有 ${infos.length} 个会话，显示前 ${top.length} 个：`,
        "",
        "| # | 会话 ID | 项目 | 时间 | 消息数 | 名称 / 首条消息 |",
        "|---|---------|------|------|--------|-----------------|",
      ];

      for (let i = 0; i < top.length; i++) {
        const info = top[i];
        const shortId = info.id.slice(0, 12) + "...";
        const shortCwd = info.cwd.replace(homedir(), "~");
        const displayName = info.name
          ? info.name
          : (info.firstUserMessage ?? "-");
        const escapedName = displayName.replace(/\|/g, "\\|").replace(/\n/g, " ");

        lines.push(
          `| ${i + 1} | \`${shortId}\` | ${shortCwd} | ${relativeTime(info.timestamp)} | ${info.messageCount} | ${escapedName} |`,
        );
      }

      lines.push("");
      lines.push(
        "使用 `view_session` 工具并指定「会话 ID」列的 UUID 即可查看对应会话的对话记录。",
      );

      return {
        content: [{ type: "text", text: lines.join("\n") }],
        details: { count: top.length, total: infos.length },
      };
    },
  });

  // =========================================================================
  // Tool: view_session
  // =========================================================================
  pi.registerTool({
    name: "view_session",
    label: "View Session",
    description:
      "查看指定会话的对话记录，返回用户和助手的对话历史。先使用 list_sessions 获取可用会话列表，" +
      "然后用此工具读取具体会话内容。",
    promptSnippet: "查看指定 pi 会话的对话历史记录",
    promptGuidelines: [
      "先用 list_sessions 获取会话列表，再用 view_session 查看具体对话内容。",
      "view_session 默认只返回用户和助手消息（不含工具调用结果），除非用户明确要求查看工具输出。",
      "使用 maxMessages 参数限制返回的消息数量，避免输出过长。",
    ],
    parameters: Type.Object({
      session: Type.String({
        description:
          "会话的 UUID 或文件路径（支持部分匹配）。从 list_sessions 的「会话 ID」列获取。",
      }),
      maxMessages: Type.Optional(
        Type.Number({
          description: "最大返回消息数，默认 40",
          default: 40,
        }),
      ),
      includeToolResults: Type.Optional(
        Type.Boolean({
          description: "是否包含工具调用结果，默认 false。工具结果通常很长，仅在用户明确要求时开启。",
          default: false,
        }),
      ),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      const maxMessages = Math.min(Math.max(params.maxMessages ?? 40, 1), 100);
      const includeToolResults = params.includeToolResults ?? false;
      const sessionId = params.session.trim();

      // Find the session file
      const filePath = findSessionFile(sessionId);
      if (!filePath) {
        const allFiles = findAllSessionFiles();
        const suggestions = allFiles.slice(0, 10).map((f) => {
          const info = readSessionInfo(f);
          return info ? `- \`${info.id.slice(0, 16)}...\` — ${info.cwd}` : `- ${basename(f)}`;
        });

        return {
          content: [
            {
              type: "text",
              text:
                `❌ 未找到会话 "${sessionId}"。\n\n` +
                `可用的会话（前 ${suggestions.length} 个）：\n${suggestions.join("\n")}\n\n` +
                `提示：先用 \`list_sessions\` 工具查看完整列表。`,
            },
          ],
          details: { error: "session_not_found", query: sessionId },
        };
      }

      // Security: ensure file is within sessions directory
      if (!isWithinSessionsDir(filePath)) {
        return {
          content: [
            {
              type: "text",
              text: `❌ 安全限制：只能读取 pi 会话目录下的文件。请求的路径 "${sessionId}" 不在允许范围内。`,
            },
          ],
          details: { error: "path_not_allowed" },
        };
      }

      // Read the session
      const currentSessionFile = ctx.sessionManager.getSessionFile();
      try {
        const content = readFileSync(filePath, "utf8");
        const lines = content.trim().split("\n");
        if (lines.length < 2) {
          return {
            content: [{ type: "text", text: "该会话文件为空或只包含头部信息。" }],
          };
        }

        // Parse header
        const header = parseSessionHeader(lines[0]);
        const info = readSessionInfo(filePath);

        // Parse message entries (skip header line)
        const formattedLines: string[] = [];
        let messageCount = 0;

        // Walk from end to get most recent messages first
        for (let i = lines.length - 1; i >= 1 && messageCount < maxMessages; i--) {
          let entry: Record<string, any>;
          try {
            entry = JSON.parse(lines[i]);
          } catch {
            continue;
          }

          if (entry.type !== "message") continue;

          const formatted = formatEntry(entry, includeToolResults);
          if (formatted) {
            formattedLines.unshift(formatted);
            messageCount++;
          }
        }

        if (formattedLines.length === 0) {
          return {
            content: [{ type: "text", text: "该会话没有可显示的消息记录。" }],
          };
        }

        // Build header section
        const headerSection: string[] = [];
        headerSection.push(`## 会话记录: ${info?.name ?? basename(filePath, ".jsonl")}`);
        headerSection.push("");
        headerSection.push(`- **会话 ID**: \`${header?.id ?? "unknown"}\``);
        headerSection.push(`- **项目路径**: ${header?.cwd ?? "unknown"}`);
        headerSection.push(`- **创建时间**: ${header?.timestamp ?? "unknown"}`);
        headerSection.push(`- **总消息数**: ${info?.messageCount ?? "?"}`);
        if (currentSessionFile && resolve(filePath) === resolve(currentSessionFile)) {
          headerSection.push(`- ⚠️ 这是**当前**会话`);
        }
        headerSection.push("");
        headerSection.push(
          `---\n显示最近 ${formattedLines.length} 条消息${includeToolResults ? "（含工具结果）" : ""}：`,
        );
        headerSection.push("");

        // Combine
        const fullText = headerSection.join("\n") + formattedLines.join("\n\n");

        // Truncate if too long
        const finalText = truncate(fullText, MAX_OUTPUT_LENGTH);

        return {
          content: [{ type: "text", text: finalText }],
          details: {
            sessionId: header?.id,
            file: filePath,
            totalMessages: info?.messageCount,
            shownMessages: formattedLines.length,
            truncated: finalText.length < fullText.length,
          },
        };
      } catch (err: any) {
        return {
          content: [
            {
              type: "text",
              text: `❌ 读取会话文件失败: ${err?.message ?? "未知错误"}`,
            },
          ],
          details: { error: "read_error", message: err?.message },
        };
      }
    },
  });

  // =========================================================================
  // Command: /sessions
  // =========================================================================
  pi.registerCommand("sessions", {
    description: "列出所有可用的 pi 会话记录",
    handler: async (_args, ctx) => {
      if (ctx.mode !== "tui") {
        ctx.ui.notify("/sessions 需要交互模式", "warning");
        return;
      }

      const currentSessionFile = ctx.sessionManager.getSessionFile();
      const allFiles = findAllSessionFiles();

      // Collect and sort
      const items: { label: string; sessionFile: string }[] = [];

      for (const file of allFiles) {
        if (currentSessionFile && resolve(file) === resolve(currentSessionFile)) {
          // Mark current session
        }
        const info = readSessionInfo(file);
        if (!info) continue;

        const shortCwd = info.cwd.replace(homedir(), "~");
        const name = info.name ?? info.firstUserMessage ?? "(无内容)";
        const label = `${relativeTime(info.timestamp)} | ${shortCwd} | ${name} (${info.messageCount} msgs)`;
        items.push({ label, sessionFile: file });
      }

      items.sort((a, b) => b.label.localeCompare(a.label));
      const labels = items.map((item) => item.label);

      if (labels.length === 0) {
        ctx.ui.notify("未找到任何会话记录。", "info");
        return;
      }

      const choice = await ctx.ui.select("选择一个会话 (Enter 查看, Esc 取消):", labels);
      if (choice) {
        const idx = labels.indexOf(choice);
        if (idx >= 0) {
          const sessionFile = items[idx].sessionFile;
          // Show a quick peek
          const info = readSessionInfo(sessionFile);
          if (info) {
            const lines = [
              `会话 ID: ${info.id}`,
              `项目: ${info.cwd}`,
              `时间: ${info.timestamp}`,
              `消息数: ${info.messageCount}`,
              `名称: ${info.name ?? "(未命名)"}`,
              `首条消息: ${info.firstUserMessage ?? "(无)"}`,
              "",
              `输入 /peek ${info.id.slice(0, 16)} 查看完整对话`,
            ];
            ctx.ui.notify(lines.join("\n"), "info");
          }
        }
      }
    },
  });

  // =========================================================================
  // Command: /peek
  // =========================================================================
  pi.registerCommand("peek", {
    description: "查看指定会话的对话记录。用法: /peek <session-id>",
    handler: async (args, ctx) => {
      const sessionId = args.trim();
      if (!sessionId) {
        ctx.ui.notify("用法: /peek <session-id>。先用 /sessions 查看可用会话。", "warning");
        return;
      }

      const filePath = findSessionFile(sessionId);
      if (!filePath) {
        ctx.ui.notify(`未找到会话 "${sessionId}"。试试 /sessions 查看列表。`, "error");
        return;
      }

      if (!isWithinSessionsDir(filePath)) {
        ctx.ui.notify("安全限制：只能读取 pi 会话目录下的文件。", "error");
        return;
      }

      try {
        const content = readFileSync(filePath, "utf8");
        const lines = content.trim().split("\n");
        const header = parseSessionHeader(lines[0]);
        const info = readSessionInfo(filePath);

        // Format last 30 messages
        const formattedLines: string[] = [];
        let count = 0;
        for (let i = lines.length - 1; i >= 1 && count < 30; i--) {
          let entry: Record<string, any>;
          try {
            entry = JSON.parse(lines[i]);
          } catch {
            continue;
          }
          if (entry.type !== "message") continue;

          const formatted = formatEntry(entry, false);
          if (formatted) {
            formattedLines.unshift(formatted);
            count++;
          }
        }

        const output = [
          `=== 会话: ${info?.name ?? basename(filePath, ".jsonl")} ===`,
          `ID: ${header?.id ?? "?"} | 项目: ${header?.cwd ?? "?"} | 消息: ${info?.messageCount ?? "?"}`,
          "",
          ...formattedLines,
        ];

        // Use notify for short output; for longer, inject as message
        const fullText = output.join("\n");
        if (fullText.length < 5000) {
          ctx.ui.notify(fullText, "info");
        } else {
          // For longer output, inject into chat context
          pi.sendMessage({
            customType: "session-viewer",
            content: fullText,
            display: true,
            details: { sessionId: header?.id, file: filePath },
          });
          ctx.ui.notify(
            `已将会话 "${info?.name ?? header?.id}" 的对话记录注入当前上下文 (${formattedLines.length} 条消息)。`,
            "info",
          );
        }
      } catch (err: any) {
        ctx.ui.notify(`读取失败: ${err?.message ?? "未知错误"}`, "error");
      }
    },
  });
}
