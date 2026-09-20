/**
 * Model Tiers — cost-aware model switching with key shortcuts.
 *
 * Tier ladder (ordered by marginal cost to you):
 *
 *   Tier  Key     Model                            Cost
 *   ----  ------  -------------------------------  --------------------------
 *   free  Ctrl+5  kimi-coding/k3-256k              $0 (Kimi subscription)
 *   std   Ctrl+1  github-copilot/claude-sonnet-4.6 $0 (Copilot subscription) ← session default
 *   deep  Ctrl+4  github-copilot/claude-opus-4.8   $0 (Copilot subscription)
 *   fast  Ctrl+2  deepseek/deepseek-flash          ~$0.30/$1.20 per M tok (cheap paid)
 *   pro   Ctrl+3  deepseek/deepseek-v4-pro         ~$1.32/$3.96 per M tok (paid, special occasions)
 *   local /local  ollama/llama3.1:8b               $0 (on-device, offline/private)
 *
 * Philosophy:
 *   - Default is Copilot Sonnet 4.6: subscription = $0 marginal, strong all-rounder.
 *   - DeepSeek Flash is the sanctioned "alternative default" for high-volume or
 *     familiar-codebase work where its speed/price beats context-switching to Kimi.
 *   - DeepSeek Pro is for special occasions (hard problem, want DeepSeek's best).
 *   - Opus 4.8 is the free "think harder" escape hatch — prefer it over Pro
 *     unless you specifically want DeepSeek.
 *
 * Suggest-only automation (never auto-switches):
 *   - Trivial prompt (test/hi/one-liner) on a PAID model → notify once per session
 *     that Ctrl+1 (free) or Ctrl+2 (cheap) would do.
 *   - Heavy-looking prompt (long, refactor/security/architecture keywords) while on
 *     Flash or a local model → notify once per session that Ctrl+1/Ctrl+4 exist.
 *   - Manual model picks are always respected; this extension only ever suggests.
 *
 * Commands:
 *   /fast    → DeepSeek V4.1 Flash   (cheap paid workhorse)
 *   /pro     → DeepSeek V4 Pro       (special occasions)
 *   /deep    → Claude Opus 4.8       (free premium reasoning)
 *   /free    → Kimi K3 256K          (free subscription, big context)
 *   /std     → Claude Sonnet 4.6     (back to default)
 *   /local   → Llama 3.1 8B          (on-device)
 *   /tier    → show tier table + current model
 *
 * Interplay with mode-router: switches done here fire model_select with a normal
 * (non-restore) source, so mode-router adopts them as your manual baseline — no
 * fighting between the two extensions.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// ---- Tier table ----------------------------------------------------------

interface Tier {
  key: string; // command name, also /key
  shortcut?: string; // ctrl+N binding
  provider: string;
  id: string;
  label: string;
  cost: string; // human-readable cost class
  paid: boolean; // per-token cost to you?
  blurb: string; // when to use
}

const TIERS: Tier[] = [
  {
    key: "std",
    shortcut: "ctrl+1",
    provider: "github-copilot",
    id: "claude-sonnet-4.6",
    label: "Claude Sonnet 4.6",
    cost: "$0 (Copilot)",
    paid: false,
    blurb: "Session default — strong all-rounder, subscription",
  },
  {
    key: "fast",
    shortcut: "ctrl+2",
    provider: "deepseek",
    id: "deepseek-flash",
    label: "DeepSeek V4.1 Flash",
    cost: "~$0.30/$1.20 M tok",
    paid: true,
    blurb: "Alternative default — very cheap, fast, 1M ctx, high-volume work",
  },
  {
    key: "pro",
    shortcut: "ctrl+3",
    provider: "deepseek",
    id: "deepseek-v4-pro",
    label: "DeepSeek V4 Pro",
    cost: "~$1.32/$3.96 M tok",
    paid: true,
    blurb: "Special occasions — DeepSeek's best, parallel subagent fanout",
  },
  {
    key: "deep",
    shortcut: "ctrl+4",
    provider: "github-copilot",
    id: "claude-opus-4.8",
    label: "Claude Opus 4.8",
    cost: "$0 (Copilot)",
    paid: false,
    blurb: "Free premium reasoning — hard bugs, audits, delicate refactors",
  },
  {
    key: "free",
    shortcut: "ctrl+5",
    provider: "kimi-coding",
    id: "k3-256k",
    label: "Kimi K3 (256K)",
    cost: "$0 (Kimi sub)",
    paid: false,
    blurb: "Free large-context — research, scouting, many-file analysis",
  },
  {
    key: "local",
    provider: "ollama",
    id: "llama3.1:8b",
    label: "Llama 3.1 8B",
    cost: "$0 (on-device)",
    paid: false,
    blurb: "Offline/private — fastest confirmed local tool-caller",
  },
];

const DEFAULT_TIER = "std";

// Providers that cost per-token money regardless of model (used by suggester).
const PAID_PROVIDERS = new Set([
  "deepseek",
  "zai",
  "zai-coding-cn",
  "kimi-cn",
  "openrouter",
  "google",
  "anthropic",
]);

// ---- Suggestion heuristics ------------------------------------------------

const TRIVIAL_RE =
  /^(test|hi|hello|hey|ok|okay|yes|no|y|n|thanks|thank you|ping|say hi|are you (there|active)|continue|go on|sure|nope|lol)\W*$/i;

const HEAVY_RE =
  /refactor|security|vulnerabilit|architect|migrat|audit|redesign|optimi[sz]e|race condition|deadlock|memory leak/i;

function isTrivial(prompt: string): boolean {
  const p = prompt.trim();
  if (TRIVIAL_RE.test(p)) return true;
  // Short, no code symbols, no paths, no question substance
  if (p.length < 30 && !/[{}()=<>`/\\[\]]/.test(p) && p.split(/\s+/).length <= 5) return true;
  return false;
}

function isHeavy(prompt: string): boolean {
  const p = prompt.trim();
  return p.length > 800 || HEAVY_RE.test(p);
}

// ---- Extension ------------------------------------------------------------

export default function (pi: ExtensionAPI) {
  // One-shot suggestion latches (reset each session)
  let suggestedCheaper = false;
  let suggestedStronger = false;

  function findTier(ctx: any, tier: Tier) {
    return ctx.modelRegistry?.find?.(tier.provider, tier.id) ?? null;
  }

  async function activate(ctx: any, tier: Tier) {
    const model = findTier(ctx, tier);
    if (!model) {
      ctx.ui.notify(
        `❌ ${tier.label} not found in registry (${tier.provider}/${tier.id}). Check auth/provider config.`,
        "error"
      );
      return;
    }
    const ok = await pi.setModel(model);
    ctx.ui.notify(
      ok
        ? `${tier.paid ? "💸" : "✅"} ${tier.label} — ${tier.cost}\n   ${tier.blurb}`
        : `❌ Failed to switch to ${tier.label}`,
      ok ? "info" : "error"
    );
  }

  // Commands (/fast, /pro, /deep, /free, /std, /local)
  for (const tier of TIERS) {
    pi.registerCommand(tier.key, {
      description: `Switch to ${tier.label} (${tier.cost}) — ${tier.blurb}`,
      handler: async (_args, ctx) => activate(ctx, tier),
    });
    // Key shortcuts (Ctrl+1..5) where assigned
    if (tier.shortcut) {
      pi.registerShortcut(tier.shortcut, {
        description: `Switch model: ${tier.label}`,
        handler: async (ctx) => activate(ctx, tier),
      });
    }
  }

  pi.registerCommand("tier", {
    description: "Show model tier table and current model",
    handler: async (_args, ctx) => {
      const cur = ctx.model;
      const lines: string[] = [];
      lines.push("## Model Tiers (cost-aware switching)");
      lines.push("");
      for (const t of TIERS) {
        const active =
          cur && cur.provider === t.provider && cur.id === t.id ? " ← ACTIVE" : "";
        const key = t.shortcut ? t.shortcut.replace("ctrl+", "Ctrl+") : `/${t.key}`;
        lines.push(
          `  ${key.padEnd(7)} /${t.key.padEnd(6)} ${t.label.padEnd(24)} ${t.cost.padEnd(22)} ${t.blurb}${active}`
        );
      }
      lines.push("");
      lines.push(
        "Rule of thumb: Sonnet (Ctrl+1) for everything · Flash (Ctrl+2) for volume · Opus (Ctrl+4) for hard · Pro (Ctrl+3) only when you specifically want DeepSeek's best."
      );
      ctx.ui.notify(lines.join("\n"), "info");
    },
  });

  // Suggest-only hints (never switches anything itself)
  pi.on("before_agent_start", async (event, ctx) => {
    const prompt = (event as any).prompt;
    if (typeof prompt !== "string" || !prompt.trim()) return;
    const cur = ctx.model;
    if (!cur) return;

    // On a paid model with a trivial prompt → suggest cheaper
    if (!suggestedCheaper && PAID_PROVIDERS.has(cur.provider) && isTrivial(prompt)) {
      suggestedCheaper = true;
      ctx.ui.notify(
        `💡 Trivial prompt on paid model ${cur.provider}/${cur.id}. Ctrl+1 = free Sonnet, Ctrl+2 = cheap Flash. (Once-per-session hint.)`,
        "info"
      );
      return;
    }

    // On flash/local with a heavy-looking prompt → suggest stronger
    const onCheapLane =
      (cur.provider === "deepseek" && cur.id.includes("flash")) ||
      cur.provider === "ollama";
    if (!suggestedStronger && onCheapLane && isHeavy(prompt)) {
      suggestedStronger = true;
      ctx.ui.notify(
        `💡 Heavy-looking prompt on ${cur.id}. Ctrl+1 = Sonnet (free), Ctrl+4 = Opus 4.8 (free, strongest). (Once-per-session hint.)`,
        "info"
      );
    }
  });

  // New session on a paid default → gentle one-time nudge
  pi.on("session_start", async (_event, ctx) => {
    const cur = ctx.model;
    if (cur && PAID_PROVIDERS.has(cur.provider) && !suggestedCheaper) {
      suggestedCheaper = true;
      ctx.ui.notify(
        `💸 Session started on paid model ${cur.provider}/${cur.id}. Ctrl+1 = Sonnet ($0), Ctrl+2 = Flash (cheap). /tier for the ladder.`,
        "info"
      );
    }
  });
}
