/**
 * guard.ts — Pi extension: Permission gates for dangerous operations
 *
 * Intercepts tool calls that match dangerous patterns and asks the user
 * to confirm before execution. Supports:
 *
 *   ✅ Allow once       — just this time
 *   🔁 Allow in session — skip prompt for same risk this session
 *   🌐 Allow globally   — never prompt again (persisted)
 *   ❌ Deny             — block execution
 *
 * Auto-discovered from ~/.pi/agent/extensions/.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { isToolCallEventType } from "@earendil-works/pi-coding-agent";
import { readFileSync, writeFileSync, existsSync, mkdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { homedir } from "node:os";

// ---------------------------------------------------------------------------
// Allowlist persistence
// ---------------------------------------------------------------------------

const GLOBAL_ALLOWLIST_PATH = join(
  homedir(),
  ".pi",
  "agent",
  "guard-allowlist.json",
);

/** Load globally allowed danger labels from disk. */
function loadGlobalAllowlist(): Set<string> {
  try {
    if (existsSync(GLOBAL_ALLOWLIST_PATH)) {
      const raw = readFileSync(GLOBAL_ALLOWLIST_PATH, "utf-8");
      const data = JSON.parse(raw);
      return new Set(data.labels ?? []);
    }
  } catch {
    // corrupted or missing — start fresh
  }
  return new Set();
}

/** Persist globally allowed danger labels to disk. */
function saveGlobalAllowlist(labels: Set<string>): void {
  try {
    const dir = dirname(GLOBAL_ALLOWLIST_PATH);
    if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
    writeFileSync(
      GLOBAL_ALLOWLIST_PATH,
      JSON.stringify({ labels: Array.from(labels) }, null, 2),
      "utf-8",
    );
  } catch {
    // silently fail — permission issue
  }
}

// ---------------------------------------------------------------------------
// In-memory state
// ---------------------------------------------------------------------------

const globalAllowlist = loadGlobalAllowlist();
const sessionAllowlist = new Set<string>();

// ---------------------------------------------------------------------------
// Dangerous command patterns
// ---------------------------------------------------------------------------

const DANGEROUS_PATTERNS: { pattern: RegExp; label: string }[] = [
  {
    pattern: /\brm\s+(-[a-z]*r[a-z]*f[a-z]*|-rf\s|--recursive)/i,
    label: "rm -rf (recursive delete)",
  },
  { pattern: /\bsudo\b/i, label: "sudo (superuser)" },
  { pattern: /\bchmod\s+.*777/i, label: "chmod 777 (world-writable)" },
  { pattern: /\bchown\b/i, label: "chown (change ownership)" },
  { pattern: /curl.*\|\s*(ba)?sh/i, label: "curl piped to shell" },
  { pattern: /wget.*\|\s*(ba)?sh/i, label: "wget piped to shell" },
  { pattern: /\bdd\s+if=/i, label: "dd (disk copy)" },
  { pattern: /\bmkfs\./i, label: "mkfs (format filesystem)" },
  { pattern: /\bfdisk\b/i, label: "fdisk (partition)" },
  { pattern: />\s*\/dev\/sd[a-z]/i, label: "write to raw disk device" },
  {
    pattern: /\bgit\s+push\s+(-f|--force)/i,
    label: "git push --force",
  },
  { pattern: /\bgit\s+reset\s+--hard\b/i, label: "git reset --hard" },
  {
    pattern: /\bdocker\s+(rm|rmi|prune)\b/i,
    label: "docker remove/prune",
  },
  {
    pattern: /\bdocker\s+system\s+prune\b/i,
    label: "docker system prune",
  },
  {
    pattern: /\bnpm\s+(unpublish|deprecate)\b/i,
    label: "npm unpublish/deprecate",
  },
  { pattern: /\bkubectl\s+delete\b/i, label: "kubectl delete" },
  {
    pattern: /\bDROP\s+(TABLE|DATABASE)\b/i,
    label: "SQL DROP TABLE/DATABASE",
  },
  { pattern: /\bTRUNCATE\b/i, label: "SQL TRUNCATE" },
  {
    pattern: /\bDELETE\s+FROM\b(?!.*\bWHERE\b)/i,
    label: "SQL DELETE without WHERE",
  },
  { pattern: /\bshutdown\b/i, label: "system shutdown" },
  { pattern: /\breboot\b/i, label: "system reboot" },
  { pattern: /\b:\(\)\s*\{/i, label: "fork bomb pattern" },
  {
    pattern: /\/dev\/null.*>|>.*\/dev\/null/i,
    label: "device redirect",
  },
  { pattern: /\beval\s+/i, label: "eval (arbitrary execution)" },
  { pattern: /\bsource\s+\/dev\//i, label: "source from /dev" },
];

const PROTECTED_PATH_PATTERNS: { pattern: RegExp; label: string }[] = [
  {
    pattern: /\.env(\..*)?$/i,
    label: "environment variable file",
  },
  { pattern: /credentials/i, label: "credentials file" },
  { pattern: /\.htpasswd$/i, label: "htpasswd file" },
  { pattern: /\.pem$/i, label: "PEM key" },
  { pattern: /id_rsa/i, label: "SSH private key" },
  { pattern: /id_ed25519/i, label: "SSH private key" },
  { pattern: /\.git\/config$/i, label: ".git/config" },
  { pattern: /\.npmrc$/i, label: ".npmrc" },
  { pattern: /\.aws\//i, label: "AWS config" },
  { pattern: /\.gcloud\//i, label: "GCloud config" },
  { pattern: /\.kube\//i, label: "Kubernetes config" },
  { pattern: /\/etc\//, label: "system config (/etc)" },
  {
    pattern: /secrets?\.(ya?ml|json|toml)/i,
    label: "secrets file",
  },
  { pattern: /secrets?$/i, label: "secrets path" },
];

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function checkBashDanger(command: string): string | null {
  for (const { pattern, label } of DANGEROUS_PATTERNS) {
    if (pattern.test(command)) return label;
  }
  return null;
}

function checkPathDanger(filePath: string): string | null {
  for (const { pattern, label } of PROTECTED_PATH_PATTERNS) {
    if (pattern.test(filePath)) return label;
  }
  return null;
}

/**
 * Ask the user with 4 options: allow once, session, globally, or deny.
 * Returns null if denied, or the choice string if allowed.
 */
async function askGuard(
  ctx: any,
  title: string,
  preview: string,
  danger: string,
): Promise<"once" | "session" | "global" | null> {
  const options = [
    "✅ Allow once        — just this time",
    "🔁 Allow in session   — skip prompt for this risk this session",
    "🌐 Allow globally     — never ask again (persisted)",
    "❌ Deny               — block execution",
  ];

  const choice = await ctx.ui.select(
    `⚠️  ${title}\n\n${preview}\n\nRisk: ${danger}`,
    options,
  );

  if (!choice) return null;
  if (choice.startsWith("❌")) return null;
  if (choice.startsWith("🔁")) return "session";
  if (choice.startsWith("🌐")) return "global";
  return "once"; // "✅"
}

// ---------------------------------------------------------------------------
// Extension
// ---------------------------------------------------------------------------

export default function (pi: ExtensionAPI) {
  // -- Guard bash commands ------------------------------------------------

  pi.on("tool_call", async (event, ctx) => {
    if (!isToolCallEventType("bash", event)) return;

    const command = event.input.command ?? "";
    const danger = checkBashDanger(command);
    if (!danger) return; // safe

    // Already allowed globally or this session?
    if (globalAllowlist.has(danger)) return;
    if (sessionAllowlist.has(danger)) return;

    const preview =
      command.length > 150
        ? command.substring(0, 147) + "..."
        : command;

    const result = await askGuard(
      ctx,
      "Dangerous command detected",
      `The agent wants to run:\n  ${preview}`,
      danger,
    );

    if (result === null) {
      return {
        block: true,
        reason: `Blocked dangerous command (${danger}): user denied`,
      };
    }

    if (result === "session") {
      sessionAllowlist.add(danger);
      ctx.ui.notify(
        `Allowed "${danger}" for this session.`,
        "info",
      );
    }

    if (result === "global") {
      globalAllowlist.add(danger);
      sessionAllowlist.add(danger);
      saveGlobalAllowlist(globalAllowlist);
      ctx.ui.notify(
        `Allowed "${danger}" globally (persisted).`,
        "info",
      );
    }
  });

  // -- Guard write / edit to protected paths ------------------------------

  pi.on("tool_call", async (event, ctx) => {
    // write
    if (isToolCallEventType("write", event)) {
      const path = event.input.path ?? "";
      const danger = checkPathDanger(path);
      if (!danger) return;
      if (globalAllowlist.has(danger)) return;
      if (sessionAllowlist.has(danger)) return;

      const result = await askGuard(
        ctx,
        "Protected file write",
        `The agent wants to write to:\n  ${path}`,
        danger + " (protected path)",
      );

      if (result === null) {
        return {
          block: true,
          reason: `Blocked write to protected path (${danger}): user denied`,
        };
      }

      if (result === "session") {
        sessionAllowlist.add(danger);
        ctx.ui.notify(
          `Allowed writes to "${danger}" for this session.`,
          "info",
        );
      }
      if (result === "global") {
        globalAllowlist.add(danger);
        sessionAllowlist.add(danger);
        saveGlobalAllowlist(globalAllowlist);
        ctx.ui.notify(
          `Allowed writes to "${danger}" globally.`,
          "info",
        );
      }
      return;
    }

    // edit
    if (isToolCallEventType("edit", event)) {
      const path = event.input.path ?? "";
      const danger = checkPathDanger(path);
      if (!danger) return;
      if (globalAllowlist.has(danger)) return;
      if (sessionAllowlist.has(danger)) return;

      const result = await askGuard(
        ctx,
        "Protected file edit",
        `The agent wants to edit:\n  ${path}`,
        danger + " (protected path)",
      );

      if (result === null) {
        return {
          block: true,
          reason: `Blocked edit to protected path (${danger}): user denied`,
        };
      }

      if (result === "session") {
        sessionAllowlist.add(danger);
        ctx.ui.notify(
          `Allowed edits to "${danger}" for this session.`,
          "info",
        );
      }
      if (result === "global") {
        globalAllowlist.add(danger);
        sessionAllowlist.add(danger);
        saveGlobalAllowlist(globalAllowlist);
        ctx.ui.notify(
          `Allowed edits to "${danger}" globally.`,
          "info",
        );
      }
      return;
    }
  });

  // -- Cleanup on session shutdown ----------------------------------------

  pi.on("session_shutdown", () => {
    sessionAllowlist.clear();
  });

  // -- Startup notification -----------------------------------------------

  pi.on("session_start", async (_event, ctx) => {
    if (ctx.mode === "tui") {
      const globalCount = globalAllowlist.size;
      ctx.ui.notify(
        `Guard active: ${DANGEROUS_PATTERNS.length} dangerous patterns + ${PROTECTED_PATH_PATTERNS.length} protected paths` +
          (globalCount > 0
            ? ` (${globalCount} globally allowed)`
            : ""),
        "info",
      );
    }
  });
}
