/**
 * Context-Aware Model Selection
 *
 * Auto-detects project complexity and suggests the optimal default model.
 *
 * Heuristics:
 *   Simple project (<30 files, single language) → DeepSeek V3 (fast, cheap)
 *   Complex project (50+ files, multi-language) → Claude Sonnet (capable)
 *   Known projects → use learned preferences
 *   Database/security projects → always Sonnet
 *
 * Model economics:
 *   Copilot Sonnet is subscription-based (no per-token cost to you)
 *   DeepSeek V3 has per-token pricing but is very cheap
 *   The agent system already routes heavy work to Sonnet regardless
 *
 * So for direct chat sessions where YOU are talking to the model:
 *   - Sonnet is the safe default (already paid for)
 *   - DeepSeek is better for quick/simple one-off questions
 *
 * Commands:
 *   /context-model  — analyze current project and recommend model
 *   /fast           — suggestion to switch to budget model
 *   /deep           — suggestion to switch to premium model
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import * as fs from "node:fs";
import * as path from "node:path";

interface ProjectProfile {
  fileCount: number;
  totalLines: number;
  languages: Set<string>;
  hasDatabase: boolean;
  hasDocker: boolean;
  hasTests: boolean;
  isMonorepo: boolean;
  hasCLAUDE: boolean;
  complexity: "simple" | "medium" | "complex";
}

// Projects the user knows intimately — OK to use cheaper models
const FAMILIAR_PROJECTS = [
  ".dotfiles",
  "notes",
  "bgovault",
];

// Projects that always want Sonnet for interactive work
const PREMIUM_PROJECTS = [
  "gas",
  "tos",
  "skjalftalisa",
  "epos",
  "gnss",
  "metrics",
];

function detectLanguage(file: string): string | null {
  const ext = path.extname(file).toLowerCase();
  const map: Record<string, string> = {
    ".ts": "TypeScript",
    ".tsx": "TypeScript/React",
    ".js": "JavaScript",
    ".jsx": "JavaScript/React",
    ".py": "Python",
    ".rs": "Rust",
    ".go": "Go",
    ".sql": "SQL",
    ".sh": "Shell",
    ".bash": "Shell",
    ".zsh": "Shell",
    ".lua": "Lua",
    ".yaml": "YAML",
    ".yml": "YAML",
    ".json": "JSON",
    ".toml": "TOML",
    ".md": "Markdown",
    ".css": "CSS",
    ".html": "HTML",
    ".dockerfile": "Docker",
    ".nix": "Nix",
    ".r": "R",
    ".jl": "Julia",
    ".c": "C",
    ".cpp": "C++",
    ".h": "C/C++ Header",
    ".java": "Java",
    ".rb": "Ruby",
    ".php": "PHP",
  };
  return map[ext] || null;
}

function analyzeProject(cwd: string): ProjectProfile | null {
  try {
    const profile: ProjectProfile = {
      fileCount: 0,
      totalLines: 0,
      languages: new Set(),
      hasDatabase: false,
      hasDocker: false,
      hasTests: false,
      isMonorepo: false,
      hasCLAUDE: false,
      complexity: "simple",
    };

    // Check for key files first
    const entries = fs.readdirSync(cwd, { withFileTypes: true });
    for (const entry of entries) {
      const name = entry.name.toLowerCase();

      if (name === "claude.md" || name === "agents.md") {
        profile.hasCLAUDE = true;
      }
      if (name.includes("docker") || name === "docker-compose.yml" || name === "docker-compose.yaml") {
        profile.hasDocker = true;
      }
      if (name.includes("test") || name === "tests" || name === "__tests__" || name === "spec") {
        profile.hasTests = true;
      }
      if (name.includes("database") || name.includes("migration") || name === "schema") {
        profile.hasDatabase = true;
      }
      if (name === "packages" || name === "apps" || name === "modules") {
        profile.isMonorepo = true;
      }
      if (name === "docker-compose.yml" || name === "docker-compose.yaml" || name === "dockerfile") {
        profile.hasDocker = true;
      }
    }

    // Walk source files (non-recursive for dirs, just first level)
    const walkDir = (dir: string, depth: number = 0) => {
      if (depth > 3) return; // Don't go too deep
      try {
        const items = fs.readdirSync(dir, { withFileTypes: true });
        for (const item of items) {
          // Skip hidden, node_modules, .git
          if (item.name.startsWith(".") && item.name !== ".github") continue;
          if (item.name === "node_modules" || item.name === "__pycache__" || item.name === "target" || item.name === "dist" || item.name === "build") continue;

          const fullPath = path.join(dir, item.name);
          if (item.isFile()) {
            profile.fileCount++;
            const lang = detectLanguage(item.name);
            if (lang) profile.languages.add(lang);

            // Quick line count for files < 100KB
            try {
              const stat = fs.statSync(fullPath);
              if (stat.size < 100_000) {
                const content = fs.readFileSync(fullPath, "utf-8");
                profile.totalLines += content.split("\n").length;
              } else {
                profile.totalLines += 500; // Estimate for large files
              }
            } catch {
              // Binary or unreadable — skip
            }
          } else if (item.isDirectory()) {
            walkDir(fullPath, depth + 1);
          }
        }
      } catch {
        // Permission denied or other error
      }
    };

    walkDir(cwd);

    // Classify complexity
    if (
      profile.fileCount > 100 ||
      profile.totalLines > 20000 ||
      profile.languages.size > 3 ||
      profile.isMonorepo
    ) {
      profile.complexity = "complex";
    } else if (
      profile.fileCount > 30 ||
      profile.totalLines > 5000 ||
      profile.languages.size > 1 ||
      profile.hasDocker
    ) {
      profile.complexity = "medium";
    }

    // Special case: .dotfiles has many files but user knows it well
    const basename = path.basename(cwd);
    if (FAMILIAR_PROJECTS.includes(basename)) {
      profile.complexity = "simple";
    }
    if (PREMIUM_PROJECTS.some((p) => cwd.includes(p))) {
      profile.complexity = "complex";
    }

    return profile;
  } catch {
    return null;
  }
}

function recommendModel(profile: ProjectProfile | null, cwd: string): {
  model: string;
  provider: string;
  reasoning: string;
  modelName: string;
} {
  const basename = path.basename(cwd);

  // Known production projects → always Sonnet
  if (PREMIUM_PROJECTS.some((p) => cwd.includes(p))) {
    return {
      model: "claude-sonnet-4-6",
      provider: "copilot",
      modelName: "Claude Sonnet 4.6",
      reasoning: "Production/work project — use the most capable model. Copilot subscription means no per-token cost.",
    };
  }

  // Known familiar projects → DeepSeek is fine
  if (FAMILIAR_PROJECTS.includes(basename)) {
    return {
      model: "deepseek-v4-pro",
      provider: "deepseek",
      modelName: "DeepSeek V4 Pro",
      reasoning: "You know this codebase intimately. DeepSeek is fast and sufficient for config/docs changes.",
    };
  }

  if (!profile) {
    return {
      model: "claude-sonnet-4-6",
      provider: "copilot",
      modelName: "Claude Sonnet 4.6",
      reasoning: "Couldn't analyze project — defaulting to Sonnet to be safe.",
    };
  }

  switch (profile.complexity) {
    case "simple":
      return {
        model: "deepseek-v4-pro",
        provider: "deepseek",
        modelName: "DeepSeek V4 Pro",
        reasoning: `Simple project (${profile.fileCount} files, ${profile.totalLines} LOC, ${profile.languages.size} language(s)). DeepSeek is fast and sufficient.`,
      };
    case "medium":
      return {
        model: "claude-sonnet-4-6",
        provider: "copilot",
        modelName: "Claude Sonnet 4.6",
        reasoning: `Medium project (${profile.fileCount} files, ${profile.totalLines} LOC, ${profile.languages.size} languages). Sonnet gives better accuracy for multi-file work.`,
      };
    case "complex":
      return {
        model: "claude-sonnet-4-6",
        provider: "copilot",
        modelName: "Claude Sonnet 4.6",
        reasoning: `Complex project (${profile.fileCount} files, ${profile.totalLines} LOC, ${profile.languages.size} languages${profile.hasDatabase ? ", has database" : ""}${profile.isMonorepo ? ", monorepo" : ""}). Definitely Sonnet.`,
      };
  }
}

function formatProfile(profile: ProjectProfile): string[] {
  const lines: string[] = [];
  lines.push(`  Files: ${profile.fileCount}`);
  lines.push(`  Lines: ~${profile.totalLines.toLocaleString()}`);
  lines.push(`  Languages: ${[...profile.languages].join(", ") || "unknown"}`);
  lines.push(`  Has CLAUDE.md: ${profile.hasCLAUDE ? "yes" : "no"}`);
  lines.push(`  Has database: ${profile.hasDatabase ? "yes" : "no"}`);
  lines.push(`  Has Docker: ${profile.hasDocker ? "yes" : "no"}`);
  lines.push(`  Has tests: ${profile.hasTests ? "yes" : "no"}`);
  lines.push(`  Monorepo: ${profile.isMonorepo ? "yes" : "no"}`);
  lines.push(`  Complexity: ${profile.complexity.toUpperCase()}`);
  return lines;
}

export default function (pi: ExtensionAPI) {
  let lastRecommendation: ReturnType<typeof recommendModel> | null = null;

  pi.on("session_start", async (_event, ctx) => {
    const cwd = ctx.cwd;
    const profile = analyzeProject(cwd);
    const rec = recommendModel(profile, cwd);
    lastRecommendation = rec;

    // Notify if recommendation differs from the default (Sonnet 4.6)
    if (rec.model === "deepseek-v4-pro") {
      ctx.ui.notify(
        `Simple project detected — consider /fast to switch to DeepSeek for speed. Run /context-model for details.`,
        "info"
      );
    }
  });

  pi.registerCommand("context-model", {
    description: "Analyze current project and recommend optimal model",
    handler: async (_args, ctx) => {
      const cwd = ctx.cwd;
      const profile = analyzeProject(cwd);
      const rec = recommendModel(profile, cwd);
      lastRecommendation = rec;

      const lines: string[] = [];
      lines.push("## Project Analysis");
      lines.push("");

      if (profile) {
        lines.push(...formatProfile(profile));
      } else {
        lines.push("  Could not analyze (empty or inaccessible directory)");
      }
      lines.push("");

      lines.push(`### Recommendation: ${rec.modelName}`);
      lines.push(`  Provider: ${rec.provider}`);
      lines.push(`  Why: ${rec.reasoning}`);
      lines.push("");

      // Show agent routing for this project type
      lines.push("### Suggested workflows for this project:");
      if (profile && profile.complexity === "simple") {
        lines.push("  Simple changes → /quick");
        lines.push("  Features → /implement (scout on DeepSeek, worker on Sonnet)");
      } else {
        lines.push("  Simple changes → /quick");
        lines.push("  Standard features → /implement");
        lines.push("  Complex/security → /implement-deep");
      }
      if (profile?.hasDatabase) {
        lines.push("  Database work → /db-analyze");
      }
      lines.push("");

      const basename = path.basename(cwd);
      if (FAMILIAR_PROJECTS.includes(basename)) {
        lines.push("💡 This is a familiar project — cheap models are fine for direct chat.");
      }
      if (PREMIUM_PROJECTS.some((p) => cwd.includes(p))) {
        lines.push("🔒 This is a production/work project — using premium models is recommended.");
      }

      lines.push("");
      lines.push(`To switch model: /model (then select "${rec.modelName}")`);

      ctx.ui.notify(`Recommended: ${rec.modelName}`, "info");
    },
  });
}
