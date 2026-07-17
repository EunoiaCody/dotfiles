/**
 * init.ts — Pi extension: /init command for AGENTS.md management
 *
 * Usage:
 *   /init          — Create AGENTS.md if missing, or update the existing one
 *
 * Gathers project structure, config files, and tech stack, then instructs
 * the LLM to create or refine an AGENTS.md tailored for AI coding agents
 * (pi, Copilot, Cursor, Claude, etc.).
 *
 * Auto-discovered from ~/.pi/agent/extensions/.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { execSync } from "node:child_process";
import { readFileSync, existsSync, statSync } from "node:fs";
import { join, basename } from "node:path";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Files to read and include for AGENTS.md context. */
const KEY_CONFIG_FILES = [
  "package.json",
  "tsconfig.json",
  "tsconfig.build.json",
  "pyproject.toml",
  "Cargo.toml",
  "go.mod",
  "Makefile",
  "README.md",
  "Dockerfile",
  "docker-compose.yml",
  "docker-compose.yaml",
  ".env.example",
  "vite.config.ts",
  "vite.config.js",
  "vite.config.mjs",
  "next.config.js",
  "next.config.ts",
  "next.config.mjs",
  "nuxt.config.ts",
  "astro.config.mjs",
  "tailwind.config.ts",
  "tailwind.config.js",
  "jest.config.ts",
  "vitest.config.ts",
  "playwright.config.ts",
  "eslint.config.js",
  "eslint.config.mjs",
  ".eslintrc.js",
  ".eslintrc.json",
  "biome.json",
  ".prettierrc",
  ".prettierrc.json",
];

/** Directories to exclude from tree output. */
const EXCLUDE_DIRS = [
  "node_modules",
  ".git",
  "dist",
  "build",
  "__pycache__",
  ".next",
  ".nuxt",
  ".turbo",
  "coverage",
  ".cache",
  "target",
  "vendor",
  ".venv",
  "venv",
];

/**
 * Get a `tree`-like listing (falls back to `find`).
 */
function getDirectoryTree(cwd: string, maxDepth: number = 3): string {
  const excludeArgs = EXCLUDE_DIRS.map((d) => `-I "${d}"`).join(" ");
  try {
    return execSync(
      `tree -L ${maxDepth} ${excludeArgs} --dirsfirst -a --noreport 2>/dev/null || echo ""`,
      { cwd, maxBuffer: 10 * 1024 * 1024, encoding: "utf-8", timeout: 5000 },
    ).trim();
  } catch {
    // tree not available
  }

  try {
    const pruneExpr = EXCLUDE_DIRS.map((d) => `-name "${d}"`).join(" -o ");
    return execSync(
      `find . -maxdepth ${maxDepth} \\( ${pruneExpr} \\) -prune -o -print 2>/dev/null | sort | head -300`,
      { cwd, maxBuffer: 10 * 1024 * 1024, encoding: "utf-8", timeout: 5000 },
    ).trim();
  } catch {
    return "(could not list directory structure)";
  }
}

/**
 * Read key config files, truncating long ones.
 */
function gatherConfigFiles(cwd: string): string[] {
  const sections: string[] = [];

  for (const file of KEY_CONFIG_FILES) {
    const filePath = join(cwd, file);
    if (!existsSync(filePath)) continue;
    try {
      if (statSync(filePath).isDirectory()) continue;
      const raw = readFileSync(filePath, "utf-8");
      const truncated =
        raw.length > 3000
          ? raw.substring(0, 3000) + "\n... (truncated)"
          : raw;
      sections.push(`### ${file}\n\`\`\`\n${truncated}\n\`\`\``);
    } catch {
      // skip unreadable file
    }
  }

  return sections;
}

/**
 * Quick tech-stack detection.
 */
function detectTechStack(cwd: string): string[] {
  const indicators: string[] = [];
  const checks: [string, string][] = [
    ["package.json", "Node.js / JavaScript / TypeScript"],
    ["tsconfig.json", "TypeScript"],
    ["Cargo.toml", "Rust"],
    ["go.mod", "Go"],
    ["pyproject.toml", "Python"],
    ["setup.py", "Python"],
    ["requirements.txt", "Python"],
    ["Gemfile", "Ruby"],
    ["composer.json", "PHP"],
    ["pom.xml", "Java (Maven)"],
    ["build.gradle", "Java / Kotlin (Gradle)"],
    ["build.gradle.kts", "Java / Kotlin (Gradle Kotlin DSL)"],
    ["CMakeLists.txt", "C / C++ (CMake)"],
    ["Dockerfile", "Docker"],
    ["docker-compose.yml", "Docker Compose"],
    ["docker-compose.yaml", "Docker Compose"],
    ["next.config.js", "Next.js"],
    ["next.config.ts", "Next.js"],
    ["nuxt.config.ts", "Nuxt"],
    ["astro.config.mjs", "Astro"],
    ["svelte.config.js", "SvelteKit"],
    ["angular.json", "Angular"],
    ["vite.config.ts", "Vite"],
    ["vite.config.js", "Vite"],
    ["tailwind.config.ts", "Tailwind CSS"],
    ["tailwind.config.js", "Tailwind CSS"],
    ["eslint.config.js", "ESLint"],
    ["biome.json", "Biome"],
    ["jest.config.ts", "Jest"],
    ["vitest.config.ts", "Vitest"],
    ["playwright.config.ts", "Playwright"],
  ];

  for (const [file, label] of checks) {
    if (existsSync(join(cwd, file)) && !indicators.includes(label)) {
      indicators.push(label);
    }
  }

  return indicators;
}

/**
 * Build the full prompt for creating/updating AGENTS.md.
 */
function buildInitPrompt(
  projectName: string,
  isUpdate: boolean,
  existingContent: string | null,
  treeOutput: string,
  techStack: string[],
  configSections: string[],
): string {
  const contextParts: string[] = [];

  if (treeOutput) {
    contextParts.push(
      `## Project Structure\n\`\`\`\n${treeOutput.substring(0, 8000)}\n\`\`\``,
    );
  }

  if (techStack.length > 0) {
    contextParts.push(
      `## Detected Technologies\n${techStack.map((t) => `- ${t}`).join("\n")}`,
    );
  }

  if (configSections.length > 0) {
    contextParts.push(
      "## Key Configuration Files\n" + configSections.join("\n\n"),
    );
  }

  const contextBlock = contextParts.join("\n\n");

  const existingBlock = isUpdate
    ? `\n\n## Current AGENTS.md (to be updated)\n\`\`\`markdown\n${existingContent!.substring(0, 8000)}${existingContent!.length > 8000 ? "\n... (truncated)" : ""}\n\`\`\``
    : "";

  const action = isUpdate
    ? "update and improve the existing AGENTS.md"
    : "create a new AGENTS.md";

  return `Please ${action} for the project **${projectName}**.

${contextBlock}${existingBlock}

---

## Instructions for AGENTS.md

${isUpdate ? "Carefully review the current AGENTS.md above. Keep what is still accurate, remove stale information, and add missing details based on the project context provided." : "Generate a comprehensive AGENTS.md from scratch based on the project context above."}

The file must be written to \`AGENTS.md\` in the project root.

### Required Sections

1. **Project Overview** — 2-3 sentences about what this project does, who it's for, and its core purpose.
2. **Tech Stack** — Languages, frameworks, runtimes, key libraries with versions where known.
3. **Project Structure** — What each top-level directory contains and why.
4. **Build, Run, Test** — Exact commands to build, run, and test the project (from package.json scripts, Makefile, etc.).
5. **Code Conventions** — Naming, file organization, formatting, linting rules. Reference actual config files (eslint, prettier, biome, etc.).
6. **Architecture Patterns** — Key design patterns, data flow, how components/modules communicate.
7. **Entry Points** — Where execution starts (main files, CLI entry, server bootstrap, build scripts).
8. **Key Dependencies** — Most important external packages and what each is used for.
9. **Environment & Config** — Required env vars, config files, and how to set them up.
10. **Testing Strategy** — How tests are organized, frameworks used, coverage expectations.
11. **Deployment** — How to build for production, deployment targets, Docker usage.

### Writing Guidelines

- Write for AI coding agents (pi, Copilot, Cursor, Claude) as the primary audience.
- Be **concise and specific** — avoid fluff. Every sentence should convey actionable info.
- Use **exact commands** for build/run/test (copy from config files, not generic).
- Reference **real paths** and file names from the actual project.
- Use **markdown** formatting: headers, code blocks, bullet lists.
- If the project has a README.md, don't duplicate it — cross-reference it for general project info and focus AGENTS.md on developer/agent-specific details.
- Keep the file under ~500 lines. Be comprehensive but don't bloat.
- ${isUpdate ? "Preserve any custom sections the existing AGENTS.md has that don't fit the template above." : "Add any additional sections that seem relevant for this specific project."}

After writing AGENTS.md, briefly summarize what you created or changed.`;
}

// ---------------------------------------------------------------------------
// Extension
// ---------------------------------------------------------------------------

export default function (pi: ExtensionAPI) {
  pi.registerCommand("init", {
    description:
      "Create or update AGENTS.md — AI coding agent context file for the current project",
    handler: async (_args, ctx) => {
      const cwd = ctx.cwd;
      const projectName = basename(cwd);

      // Check if AGENTS.md exists
      const agentMdPath = join(cwd, "AGENTS.md");
      let existingContent: string | null = null;
      let isUpdate = false;

      if (existsSync(agentMdPath)) {
        try {
          existingContent = readFileSync(agentMdPath, "utf-8");
          isUpdate = true;
        } catch {
          ctx.ui.notify("Cannot read AGENTS.md — will create a new one", "warn");
        }
      }

      const actionLabel = isUpdate ? "Updating AGENTS.md" : "Creating AGENTS.md";
      ctx.ui.notify(`${actionLabel} for ${projectName}...`, "info");

      // Gather project context
      const treeOutput = getDirectoryTree(cwd, 4);
      const techStack = detectTechStack(cwd);
      const configSections = gatherConfigFiles(cwd);

      // Build the prompt
      const prompt = buildInitPrompt(
        projectName,
        isUpdate,
        existingContent,
        treeOutput,
        techStack,
        configSections,
      );

      // Wait for agent to be idle, then send as a user message
      await ctx.waitForIdle();
      pi.sendUserMessage(prompt);
    },
  });

  // Log on startup
  pi.on("session_start", async (_event, ctx) => {
    if (ctx.mode === "tui") {
      ctx.ui.notify(
        "Extension loaded: /init — create or update AGENTS.md",
        "info",
      );
    }
  });
}
