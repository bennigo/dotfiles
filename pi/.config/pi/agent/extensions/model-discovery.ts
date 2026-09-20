/**
 * Model Discovery Extension
 *
 * Auto-discovers local Ollama models, tracks available providers,
 * and provides commands to refresh the model registry at runtime.
 *
 * Features:
 * - On startup: queries Ollama for installed models
 * - `/models-discover`: manually refresh and see what's available
 * - `/models-status`: show all models and which agents use them
 * - Suggests agent assignments when new models are found
 *
 * Future-expandable: add similar discovery for other local providers
 * (vLLM, LM Studio, LocalAI) by adding provider checkers.
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

interface OllamaModel {
  name: string;
  modified_at: string;
  size: number;
  details?: {
    parameter_size?: string;
    family?: string;
    families?: string[];
    quantization_level?: string;
  };
}

interface DiscoveredModel {
  id: string;
  name: string;
  provider: string;
  parameterSize?: string;
  family?: string;
  alreadyConfigured: boolean;
}

interface AgentModelMap {
  agent: string;
  model: string;
}

function costTierFor(model: string): string {
  if (model.startsWith("ollama/")) return "Free (local)";
  if (model.startsWith("github-copilot/")) return "Subscription ($0)";
  if (model.startsWith("kimi-coding/")) return "Subscription ($0)";
  if (model.includes("flash")) return "Budget (very cheap)";
  return "Paid";
}

// Static agent→model map from our agent definitions (keep in sync with agents/*.md)
const AGENT_MODELS: AgentModelMap[] = [
  { agent: "scout", model: "kimi-coding/k3" },
  { agent: "deep-scout", model: "kimi-coding/k3" },
  { agent: "quick-worker", model: "deepseek/deepseek-flash" },
  { agent: "auditor", model: "github-copilot/claude-opus-4.8" },
  { agent: "docs-writer", model: "kimi-coding/k3" },
  { agent: "db-analyst", model: "kimi-coding/k3" },
  { agent: "researcher", model: "kimi-coding/k3" },
  { agent: "architect", model: "github-copilot/gpt-5.3-codex" },
  { agent: "router", model: "kimi-coding/k3" },
  { agent: "fallback-worker", model: "ollama/llama3.1:8b" },
  { agent: "orchestrator", model: "github-copilot/claude-sonnet-5" },
  { agent: "planner", model: "github-copilot/claude-opus-4.8" },
  { agent: "reviewer", model: "github-copilot/claude-opus-4.8" },
  { agent: "worker", model: "github-copilot/claude-sonnet-5" },
  { agent: "read-image", model: "google/gemini-2.5-flash" },
];

// Size thresholds for model capability hints
function classifyModelSize(paramSize: string | undefined): string {
  if (!paramSize) return "unknown";
  const num = parseFloat(paramSize);
  if (isNaN(num)) return paramSize;
  if (num >= 30) return "large (strong reasoning, use for complex work)";
  if (num >= 10) return "medium (good general purpose, use for standard tasks)";
  if (num >= 5) return "small (fast but limited, use for simple tasks/fallback)";
  return "tiny (not recommended for coding)";
}

async function discoverOllamaModels(baseUrl: string): Promise<DiscoveredModel[]> {
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 3000);
    const response = await fetch(`${baseUrl}/api/tags`, {
      signal: controller.signal,
    });
    clearTimeout(timeout);

    if (!response.ok) return [];

    const data = (await response.json()) as { models: OllamaModel[] };
    return data.models.map((m) => ({
      id: m.name,
      name: m.name,
      provider: "ollama",
      parameterSize: m.details?.parameter_size,
      family: m.details?.family || m.details?.families?.[0],
      alreadyConfigured: false, // We'll check this against configured models
    }));
  } catch {
    return [];
  }
}

export default function (pi: ExtensionAPI) {
  let discoveredOllamaModels: DiscoveredModel[] = [];

  // Discover on startup
  pi.on("resources_discover", async (_event, _ctx) => {
    try {
      discoveredOllamaModels = await discoverOllamaModels(
        "http://localhost:11434"
      );
    } catch {
      // Ollama not running — that's fine
    }
  });

  // Register /models-discover command
  pi.registerCommand("models-discover", {
    description:
      "Scan for newly installed local models (Ollama) and suggest agent assignments",
    handler: async (_args, ctx) => {
      ctx.ui.notify("Scanning for local models...", "info");

      try {
        discoveredOllamaModels = await discoverOllamaModels(
          "http://localhost:11434"
        );

        if (discoveredOllamaModels.length === 0) {
          ctx.ui.notify(
            "No Ollama models found. Is Ollama running?",
            "warning"
          );
          return;
        }

        const lines: string[] = [];
        lines.push(`Found ${discoveredOllamaModels.length} Ollama models:`);
        lines.push("");

        for (const model of discoveredOllamaModels) {
          const size = model.parameterSize || "?";
          const family = model.family || "unknown";
          const capability = classifyModelSize(model.parameterSize);

          lines.push(
            `  ${model.id} — ${size} params, ${family} family`
          );
          lines.push(`    Capability: ${capability}`);

          // Suggest agent assignment based on model properties
          const paramNum = parseFloat(model.parameterSize || "0");
          if (paramNum >= 10) {
            lines.push(
              `    💡 Good for: quick-worker or fallback-worker agent`
            );
          } else if (paramNum >= 5) {
            lines.push(`    💡 Good for: fallback-worker (simple tasks only)`);
          }

          if (family === "qwen3" || family === "qwen35") {
            lines.push(
              `    🏷 Qwen family — strong at instruction following, good for coding`
            );
          }
          if (family === "deepseek2" || model.id.includes("deepseek-coder")) {
            lines.push(
              `    🏷 DeepSeek Coder — code-specialized, excellent for implementation`
            );
          }
          if (family === "llama" || family === "phi2" || family === "phi3") {
            lines.push(
              `    🏷 General-purpose model — adequate for simple tasks`
            );
          }

          lines.push("");
        }

        lines.push("To use a discovered model:");
        lines.push("  1. Add it to models.json if not already there");
        lines.push("  2. Create or update an agent to use it");
        lines.push("  3. Or switch to it interactively: /model");
        lines.push("");
        lines.push(
          "Already configured models: qwen3.5, qwen2.5-coder:7b, deepseek-coder-v2:16b, deepseek-r1:8b"
        );

        ctx.ui.notify(
          `Discovered ${discoveredOllamaModels.length} models. See output above.`,
          "success"
        );
      } catch (e) {
        ctx.ui.notify(
          `Discovery failed: ${e instanceof Error ? e.message : String(e)}`,
          "error"
        );
      }
    },
  });

  // Register /models-status command
  pi.registerCommand("models-status", {
    description: "Show all configured models and which agents use them",
    handler: async (_args, ctx) => {
      const lines: string[] = [];
      lines.push("## Model → Agent Mapping");
      lines.push("");
      lines.push("| Agent | Model | Cost Tier |");
      lines.push("|-------|-------|-----------|");
      for (const m of AGENT_MODELS) {
        lines.push(`| ${m.agent} | ${m.model} | ${costTierFor(m.model)} |`);
      }
      lines.push("");
      lines.push("Session default: github-copilot/claude-sonnet-4.6 (Ctrl+1). See /tier for the switching ladder.");
      lines.push("");
      lines.push("### Local Models (Ollama)");
      lines.push("| Model | Size | Best For |");
      lines.push("|-------|------|----------|");
      lines.push("| qwen3.5:latest | 9.7B | General coding, fallback |");
      lines.push("| qwen2.5-coder:7b | 7.6B | Code-specific tasks |");
      lines.push("| deepseek-coder-v2:16b | 15.7B | Best local coding |");
      lines.push("| deepseek-r1:8b | 8.2B | Reasoning tasks |");
      lines.push("");
      lines.push(
        `Discovered but not configured: ${discoveredOllamaModels.length > 0 ? discoveredOllamaModels.filter((m) => !["qwen3.5:latest", "qwen2.5-coder:7b", "deepseek-coder-v2:16b", "deepseek-r1:8b"].includes(m.id)).length : 0}`
      );
      lines.push("Run /models-discover to refresh.");

      ctx.ui.notify("Model status shown above", "info");
    },
  });

  pi.on("session_start", async (_event, ctx: ExtensionContext) => {
    // Quietly discover models on session start
    try {
      discoveredOllamaModels = await discoverOllamaModels(
        "http://localhost:11434"
      );

      const unconfigured = discoveredOllamaModels.filter(
        (m) =>
          ![
            "qwen3.5:latest",
            "qwen2.5-coder:7b",
            "deepseek-coder-v2:16b",
            "deepseek-r1:8b",
          ].includes(m.id)
      );

      if (unconfigured.length > 0) {
        const names = unconfigured.map((m) => m.id).join(", ");
        ctx.ui.notify(
          `Unconfigured local models found: ${names}. Run /models-discover to review.`,
          "info"
        );
      }
    } catch {
      // Ollama not running — no notification needed
    }
  });
}
