/**
 * explore.ts — Pi extension: /explore command for project discovery
 *
 * Usage:
 *   /explore          — Explore the current project directory
 *   /explore <path>   — Explore a specific subdirectory or path
 *
 * Gathers project structure, key config files, and detected tech stack,
 * then sends a structured prompt to the LLM for comprehensive analysis.
 *
 * Auto-discovered from ~/.pi/agent/extensions/.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { execSync } from "node:child_process";
import { readFileSync, existsSync, statSync } from "node:fs";
import { join, relative, basename, resolve } from "node:path";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Files to read and include in the exploration context (if they exist). */
const KEY_CONFIG_FILES = [
  // Node / JS / TS
  "package.json",
  "tsconfig.json",
  "tsconfig.build.json",
  "jsconfig.json",
  // Python
  "pyproject.toml",
  "setup.py",
  "setup.cfg",
  "requirements.txt",
  "requirements-dev.txt",
  "Pipfile",
  "Pipfile.lock",
  // Rust
  "Cargo.toml",
  "Cargo.lock",
  // Go
  "go.mod",
  "go.sum",
  // Ruby
  "Gemfile",
  "Gemfile.lock",
  // PHP
  "composer.json",
  "composer.lock",
  // Java / Kotlin / Scala
  "build.gradle",
  "build.gradle.kts",
  "settings.gradle",
  "settings.gradle.kts",
  "pom.xml",
  // C / C++
  "CMakeLists.txt",
  "Makefile",
  "configure.ac",
  // .NET
  "*.csproj",
  "*.fsproj",
  "*.sln",
  // General
  "README.md",
  "README",
  "CHANGELOG.md",
  "CONTRIBUTING.md",
  "LICENSE",
  "Dockerfile",
  "docker-compose.yml",
  "docker-compose.yaml",
  ".env.example",
  ".env",
  "Makefile",
  "justfile",
  // Frontend
  "vite.config.ts",
  "vite.config.js",
  "vite.config.mjs",
  "webpack.config.js",
  "webpack.config.ts",
  "next.config.js",
  "next.config.ts",
  "next.config.mjs",
  "nuxt.config.ts",
  "nuxt.config.js",
  "astro.config.mjs",
  "astro.config.ts",
  "svelte.config.js",
  "angular.json",
  "tailwind.config.ts",
  "tailwind.config.js",
  "tailwind.config.mjs",
  "postcss.config.js",
  "postcss.config.mjs",
  // Testing
  "jest.config.ts",
  "jest.config.js",
  "vitest.config.ts",
  "vitest.config.js",
  "playwright.config.ts",
  "playwright.config.js",
  // Lint / Format
  "eslint.config.js",
  "eslint.config.mjs",
  "eslint.config.ts",
  ".eslintrc.js",
  ".eslintrc.json",
  ".eslintrc.cjs",
  "prettier.config.js",
  ".prettierrc",
  ".prettierrc.json",
  "biome.json",
  "biome.jsonc",
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
  ".parcel-cache",
  ".astro",
  ".svelte-kit",
  "target",
  "vendor",
  ".venv",
  "venv",
  ".tox",
  ".eggs",
];

/**
 * Build a `tree`-like listing of the directory.
 * Falls back to `find` if `tree` is not installed.
 */
function getDirectoryTree(cwd: string, maxDepth: number = 3): string {
  const excludeArgs = EXCLUDE_DIRS.map((d) => `-I "${d}"`).join(" ");
  try {
    return execSync(
      `tree -L ${maxDepth} ${excludeArgs} --dirsfirst -a --noreport 2>/dev/null || echo ""`,
      { cwd, maxBuffer: 10 * 1024 * 1024, encoding: "utf-8", timeout: 5000 },
    ).trim();
  } catch {
    // tree not available, fallback to find
  }

  try {
    const pruneExpr = EXCLUDE_DIRS.map((d) => `-name "${d}"`).join(" -o ");
    const output = execSync(
      `find . -maxdepth ${maxDepth} \\( ${pruneExpr} \\) -prune -o -print 2>/dev/null | sort | head -300`,
      { cwd, maxBuffer: 10 * 1024 * 1024, encoding: "utf-8", timeout: 5000 },
    ).trim();
    return output;
  } catch {
    return "(could not list directory structure)";
  }
}

/**
 * Gather key config file contents, truncated to a reasonable size.
 */
function gatherConfigFiles(cwd: string): string[] {
  const sections: string[] = [];

  for (const pattern of KEY_CONFIG_FILES) {
    // Handle glob patterns like "*.csproj", "*.fsproj", "*.sln"
    if (pattern.includes("*")) {
      try {
        const found = execSync(
          `find . -maxdepth 2 -name "${pattern}" -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | head -3`,
          { cwd, maxBuffer: 64 * 1024, encoding: "utf-8", timeout: 3000 },
        )
          .trim()
          .split("\n")
          .filter(Boolean);

        for (const file of found) {
          try {
            const path = join(cwd, file);
            if (statSync(path).isDirectory()) continue;
            const raw = readFileSync(path, "utf-8");
            const truncated =
              raw.length > 3000
                ? raw.substring(0, 3000) + "\n... (truncated)"
                : raw;
            sections.push(
              `### ${file.replace(/^\.\//, "")}\n\`\`\`\n${truncated}\n\`\`\``,
            );
          } catch {
            // skip unreadable files
          }
        }
      } catch {
        // skip if find fails
      }
      continue;
    }

    // Direct file check
    const filePath = join(cwd, pattern);
    if (existsSync(filePath)) {
      try {
        if (statSync(filePath).isDirectory()) continue;
        const raw = readFileSync(filePath, "utf-8");
        const truncated =
          raw.length > 3000
            ? raw.substring(0, 3000) + "\n... (truncated)"
            : raw;
        sections.push(
          `### ${pattern}\n\`\`\`\n${truncated}\n\`\`\``,
        );
      } catch {
        // skip unreadable files
      }
    }
  }

  return sections;
}

/** Quick detection of project type and tech stack from config files. */
function detectProjectType(cwd: string): string[] {
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
    ["Makefile", "C / C++ / General (Make)"],
    ["Dockerfile", "Docker"],
    ["docker-compose.yml", "Docker Compose"],
    ["docker-compose.yaml", "Docker Compose"],
    ["next.config.js", "Next.js"],
    ["next.config.ts", "Next.js"],
    ["next.config.mjs", "Next.js"],
    ["nuxt.config.ts", "Nuxt"],
    ["astro.config.mjs", "Astro"],
    ["svelte.config.js", "SvelteKit"],
    ["angular.json", "Angular"],
    ["vite.config.ts", "Vite"],
    ["vite.config.js", "Vite"],
    ["tailwind.config.ts", "Tailwind CSS"],
    ["tailwind.config.js", "Tailwind CSS"],
    [".eslintrc.js", "ESLint"],
    ["eslint.config.js", "ESLint"],
    ["biome.json", "Biome"],
    ["jest.config.ts", "Jest"],
    ["vitest.config.ts", "Vitest"],
    ["playwright.config.ts", "Playwright"],
  ];

  for (const [file, label] of checks) {
    if (existsSync(join(cwd, file))) {
      if (!indicators.includes(label)) {
        indicators.push(label);
      }
    }
  }

  return indicators;
}

// ---------------------------------------------------------------------------
// Prompt builders
// ---------------------------------------------------------------------------

function buildOverviewPrompt(
  projectName: string,
  relativePath: string,
  context: string,
): string {
  return `Please thoroughly explore and analyze this project:

**Project**: \`${projectName}\` at \`${relativePath}\`

${context}

---

Please provide a comprehensive codebase overview covering:

1. **Tech Stack Summary**: What languages, frameworks, runtimes, and key libraries are used?
2. **Project Purpose & Domain**: What problem does this project solve? Who is it for?
3. **Architecture & Design**: How is the code organized? What are the key architectural patterns (monolith, microservices, layered, modular, etc.)?
4. **Directory Map**: What lives in each top-level directory and why?
5. **Entry Points**: Where does execution start? Main files, CLI entry, server bootstrap, build scripts, etc.
6. **Key Dependencies**: Most important external dependencies and their roles.
7. **Data Flow**: How does data move through the system? Request lifecycle, pipeline stages, etc.
8. **Testing & Quality**: Testing frameworks, linting setup, CI indicators.
9. **Deployment & Operations**: How is it built, run, deployed? Docker, configs, environments.
10. **Onboarding Guide**: Concrete steps to set up, build, and run this project locally.
11. **Notable Patterns & Conventions**: Code style, naming conventions, file organization patterns.
12. **Potential Concerns**: Anything that stands out (missing docs, complex areas, deprecated patterns).

Be thorough but concise. Structure the response clearly so a new developer can understand the codebase in minutes.`;
}

function buildTopicPrompt(
  projectName: string,
  relativePath: string,
  topic: string,
  context: string,
): string {
  return `Explore the topic **"${topic}"** in the project \`${projectName}\` at \`${relativePath}\`.

${context}

---

Please provide a focused analysis of how **${topic}** is handled in this project:

1. **Where is it?** — Which files, directories, and modules deal with ${topic}? Map the relevant code locations.
2. **How does it work?** — Explain the architecture, data structures, algorithms, and flow related to ${topic}.
3. **Key Interfaces** — What are the main functions, classes, APIs, or components that implement or interact with ${topic}?
4. **Dependencies** — What external libraries or internal modules does ${topic} depend on?
5. **Configuration** — Are there config files, env vars, or build settings specific to ${topic}?
6. **Data Flow** — Trace how data related to ${topic} moves through the system.
7. **Edge Cases & Limitations** — Are there known constraints, TODOs, or potential issues?
8. **How to Modify** — If someone wanted to change or extend ${topic}-related functionality, where should they start?

Be specific. Reference real file paths, function names, and code patterns. Use code snippets where helpful.`;
}

/**
 * Search for files and code relevant to a topic.
 * Uses find + grep to locate files by name and content.
 */
function searchTopic(cwd: string, topic: string): string {
  const parts: string[] = [];
  const excludeDirArgs =
    `-not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/dist/*" ` +
    `-not -path "*/build/*" -not -path "*/target/*" -not -path "*/.next/*"`;

  // 1. Search for files whose name contains the topic
  try {
    const lcTopic = topic.toLowerCase();
    const nameResults = execSync(
      `find . -maxdepth 5 ${excludeDirArgs} -iname "*${lcTopic}*" -type f 2>/dev/null | head -20`,
      { cwd, maxBuffer: 256 * 1024, encoding: "utf-8", timeout: 5000 },
    ).trim();
    if (nameResults) {
      parts.push(`### Files matching "${topic}" by name\n\`\`\`\n${nameResults}\n\`\`\``);
    }
  } catch {
    // find failed
  }

  // 2. Search file contents for the topic (grep)
  try {
    const grepResults = execSync(
      `grep -rI --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" ` +
        `--include="*.py" --include="*.rs" --include="*.go" --include="*.java" ` +
        `--include="*.vue" --include="*.svelte" --include="*.css" --include="*.json" ` +
        `--include="*.md" --include="*.yaml" --include="*.yml" --include="*.toml" ` +
        `-i -l "${topic.replace(/"/g, '\\"')}" . ` +
        `--exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=build ` +
        `--exclude-dir=target --exclude-dir=.next --exclude-dir=coverage ` +
        `--exclude-dir=__pycache__ 2>/dev/null | head -30`,
      { cwd, maxBuffer: 512 * 1024, encoding: "utf-8", timeout: 8000 },
    ).trim();
    if (grepResults) {
      parts.push(
        `### Files containing "${topic}" by content\n\`\`\`\n${grepResults}\n\`\`\``,
      );
    }
  } catch {
    // grep failed or no results
  }

  // 3. Show key matches with context (first 10 matches, 2 lines of context)
  try {
    const contextResults = execSync(
      `grep -rI --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" ` +
        `--include="*.py" --include="*.rs" --include="*.go" --include="*.java" ` +
        `--include="*.vue" --include="*.svelte" ` +
        `-i -n -C 1 "${topic.replace(/"/g, '\\"')}" . ` +
        `--exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=build ` +
        `--exclude-dir=target --exclude-dir=.next --exclude-dir=coverage ` +
        `--exclude-dir=__pycache__ 2>/dev/null | head -80`,
      { cwd, maxBuffer: 512 * 1024, encoding: "utf-8", timeout: 8000 },
    ).trim();
    if (contextResults) {
      const truncated =
        contextResults.length > 4000
          ? contextResults.substring(0, 4000) + "\n... (truncated)"
          : contextResults;
      parts.push(
        `### Code snippets matching "${topic}"\n\`\`\`\n${truncated}\n\`\`\``,
      );
    }
  } catch {
    // no results
  }

  if (parts.length === 0) {
    parts.push(
      `(No files or code found directly matching "${topic}". ` +
        `The agent should infer from the project structure and config above.)`,
    );
  }

  return parts.join("\n\n");
}

// ---------------------------------------------------------------------------
// Extension
// ---------------------------------------------------------------------------

export default function (pi: ExtensionAPI) {
  pi.registerCommand("explore", {
    description:
      "Explore and analyze the current project: use /explore for an overview, " +
      "or /explore <topic> to deep-dive a specific aspect (e.g. /explore lyrics). " +
      "You can also /explore <path> to target a subdirectory.",
    handler: async (args, ctx) => {
      const input = args?.trim() ?? "";
      let targetDir = ctx.cwd;
      let topic: string | null = null;

      // Determine: path or topic?
      if (input.length > 0) {
        // Check if it looks like a path
        const looksLikePath =
          input.includes("/") ||
          input === "." ||
          input === "..";
        const resolvedPath = resolve(ctx.cwd, input);
        const pathExists = existsSync(resolvedPath);

        if (looksLikePath || pathExists) {
          // Path mode
          targetDir = resolvedPath;
          if (!pathExists) {
            ctx.ui.notify(`Directory not found: ${targetDir}`, "error");
            return;
          }
          try {
            if (!statSync(targetDir).isDirectory()) {
              ctx.ui.notify(`Not a directory: ${targetDir}`, "error");
              return;
            }
          } catch {
            ctx.ui.notify(`Cannot access: ${targetDir}`, "error");
            return;
          }
        } else {
          // Topic mode — explore the project through the lens of this topic
          topic = input;
        }
      }

      const projectName = basename(targetDir);
      const relativePath = relative(ctx.cwd, targetDir) || ".";

      const label = topic
        ? `topic "${topic}" in ${relativePath}`
        : relativePath;
      ctx.ui.notify(`Exploring ${label}...`, "info");

      // Gather project context
      const contextParts: string[] = [];

      // 1. Directory structure
      const tree = getDirectoryTree(targetDir, topic ? 5 : 4);
      if (tree) {
        contextParts.push(
          `## Project Structure (${relativePath})\n\`\`\`\n${tree.substring(0, 10000)}\n\`\`\``,
        );
      }

      // 2. Detected tech stack
      const techStack = detectProjectType(targetDir);
      if (techStack.length > 0) {
        contextParts.push(
          `## Detected Technologies\n${techStack.map((t) => `- ${t}`).join("\n")}`,
        );
      }

      // 3. Key configuration files
      const configSections = gatherConfigFiles(targetDir);
      if (configSections.length > 0) {
        contextParts.push(
          "## Key Configuration Files\n" + configSections.join("\n\n"),
        );
      }

      // 4. If topic mode: search for relevant files and code
      if (topic) {
        contextParts.push(`\n## Topic: \`${topic}\` — Relevant Files & Code\n`);
        contextParts.push(searchTopic(targetDir, topic));
      }

      const explorationContext = contextParts.join("\n\n");

      // Build prompt
      const prompt = topic
        ? buildTopicPrompt(projectName, relativePath, topic, explorationContext)
        : buildOverviewPrompt(projectName, relativePath, explorationContext);

      await ctx.waitForIdle();
      pi.sendUserMessage(prompt);
    },
  });

  // Log on startup
  pi.on("session_start", async (_event, ctx) => {
    if (ctx.mode === "tui") {
      ctx.ui.notify(
        "Extension loaded: /explore — overview or /explore <topic> for focused deep-dive",
        "info",
      );
    }
  });
}
