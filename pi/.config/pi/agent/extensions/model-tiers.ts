/**
 * Model Tiers — cost-aware model switching with key shortcuts.
 *
 * Tier ladder (ordered by marginal cost to you):
 *
 *   Tier  Key     Model                            Cost
 *   ----  ------  -------------------------------  --------------------------
 *   free  Ctrl+5  kimi-coding/k3 (1M)              $0 (Kimi subscription)
 *   std   Ctrl+1  github-copilot/claude-sonnet-5   $0 (Copilot subscription) ← session default
 *   deep  Ctrl+4  zai/glm-5.3-highspeed            $0 (per models.json)
 *   fast  Ctrl+2  deepseek/deepseek-flash          ~$0.30/$1.20 per M tok (cheap paid)
 *   pro   Ctrl+3  deepseek/deepseek-v4-pro         ~$1.32/$3.96 per M tok (paid, special occasions)
 *   glm   Ctrl+6  zai/glm-5.3                      paid flagship GLM (1M ctx)
 *   local /local  ollama/llama3.1:8b               $0 (on-device, offline/private)
 *
 * Philosophy:
 *   - Default is Copilot Sonnet 5: subscription = $0 marginal, newest Sonnet.
 *     (Anthropic models are otherwise used mostly via Claude Code — in pi the
 *     free "think harder" lane is GLM, not Opus.)
 *   - DeepSeek Flash is the sanctioned "alternative default" for high-volume or
 *     familiar-codebase work.
 *   - DeepSeek Pro is for special occasions (hard problem, want DeepSeek's best).
 *   - GLM-5.3-Highspeed is the free "think harder" escape hatch; /glm for the
 *     paid flagship when highspeed quality isn't enough.
 *
 * Suggest-only automation (never auto-switches)... EXCEPT quota fallback:
 *   - Trivial prompt (test/hi/one-liner) on a PAID model → notify once per session
 *     that Ctrl+1 (free) or Ctrl+2 (cheap) would do.
 *   - Heavy-looking prompt (long, refactor/security/architecture keywords) while on
 *     Flash or a local model → notify once per session that Ctrl+1/Ctrl+4 exist.
 *   - Manual model picks are always respected; suggestions never switch anything.
 *
 * Quota / rate-limit fallback (the one automatic switch):
 *   Subscription providers (github-copilot, kimi-coding) can return
 *     402 quota_exceeded  → monthly premium budget gone (won't reset soon)
 *     429 rate limited   → transient
 *   On either, we switch to DeepSeek V4.1 Flash so work continues, remember what
 *   we came from, and:
 *     - 402: no auto-restore this session (persisted to disk so new sessions
 *            don't burn a request rediscovering the exhausted quota)
 *     - 429: auto-restore attempted after a 10m cooldown (doubling to max 60m
 *            on repeat failures)
 *   `/quota` shows state · `/quota restore` force-returns · `/quota clear` forgets.
 *
 * Commands:
 *   /fast    → DeepSeek V4.1 Flash   (cheap paid workhorse)
 *   /pro     → DeepSeek V4 Pro       (special occasions)
 *   /deep    → GLM-5.3-Highspeed     (free strong reasoning, 1M ctx)
 *   /glm     → GLM-5.3               (paid flagship GLM, Ctrl+6)
 *   /free    → Kimi K3 (1M)          (free subscription, biggest context)
 *   /std     → Claude Sonnet 5       (back to default)
 *   /local   → Llama 3.1 8B          (on-device)
 *   /tier    → show tier table + current model
 *
 * Interplay with mode-router: switches done here fire model_select with a normal
 * (non-restore) source, so mode-router adopts them as your manual baseline — no
 * fighting between the two extensions.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

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
    id: "claude-sonnet-5",
    label: "Claude Sonnet 5",
    cost: "$0 (Copilot)",
    paid: false,
    blurb: "Session default — newest Sonnet, subscription",
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
    provider: "zai",
    id: "glm-5.3-highspeed",
    label: "GLM-5.3 Highspeed",
    cost: "$0 (per models.json)",
    paid: false,
    blurb: "Free strong reasoning — hard bugs, delicate refactors, 1M ctx",
  },
  {
    key: "glm",
    shortcut: "ctrl+6",
    provider: "zai",
    id: "glm-5.3",
    label: "GLM-5.3",
    cost: "~$1.40/$4.40 M tok",
    paid: true,
    blurb: "Paid flagship GLM — when Highspeed quality isn't enough",
  },
  {
    key: "free",
    shortcut: "ctrl+5",
    provider: "kimi-coding",
    id: "k3",
    label: "Kimi K3 (1M)",
    cost: "$0 (Kimi sub)",
    paid: false,
    blurb: "Free largest-context — research, scouting, many-file analysis",
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

// Exceptions: free-tier models on otherwise-paid providers (per models.json cost=0).
const FREE_MODEL_OVERRIDES = new Set([
  "zai/glm-5.2-highspeed",
  "zai/glm-5.3-highspeed",
  "zai-coding-cn/glm-5.3-highspeed",
]);

function isPaidModel(provider: string, id: string): boolean {
  if (FREE_MODEL_OVERRIDES.has(`${provider}/${id}`)) return false;
  return PAID_PROVIDERS.has(provider);
}

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

// ---- Quota / rate-limit fallback ------------------------------------------

const QUOTA_FALLBACK = { provider: "deepseek", id: "deepseek-flash" };
const SUBSCRIPTION_PROVIDERS = new Set(["github-copilot", "kimi-coding"]);
const RATE_LIMIT_COOLDOWN_MS = 10 * 60_000;
const MAX_COOLDOWN_MS = 60 * 60_000;

interface QuotaState {
  provider: string;
  id: string;
  reason: "quota" | "rate-limit";
  at: number;
  /** ms until an auto-restore attempt; absent = never (quota resets monthly) */
  cooldownMs?: number;
}

function quotaStatePath(): string {
  const base = process.env.XDG_STATE_HOME || path.join(os.homedir(), ".local", "state");
  return path.join(base, "pi", "model-quota-state.json");
}

function loadQuotaState(): QuotaState | null {
  try {
    const raw = fs.readFileSync(quotaStatePath(), "utf8");
    const parsed = JSON.parse(raw) as QuotaState;
    if (parsed && typeof parsed.provider === "string" && typeof parsed.id === "string") {
      return parsed;
    }
    return null;
  } catch {
    return null; // missing/corrupt state is not an error
  }
}

function saveQuotaState(state: QuotaState | null): void {
  const file = quotaStatePath();
  try {
    if (state === null) {
      fs.rmSync(file, { force: true });
      return;
    }
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.writeFileSync(file, JSON.stringify(state, null, 2));
  } catch {
    // Best-effort only — never break the session over state persistence.
  }
}

// ---- Extension ------------------------------------------------------------

export default function (pi: ExtensionAPI) {
  // One-shot suggestion latches (reset each session)
  let suggestedCheaper = false;
  let suggestedStronger = false;

  // Quota fallback state (persisted so new sessions don't re-burn an exhausted quota)
  let quotaState: QuotaState | null = loadQuotaState();

  function restoreAt(): number {
    if (!quotaState || quotaState.cooldownMs === undefined) return Infinity;
    return quotaState.at + quotaState.cooldownMs;
  }

  async function fallbackToFlash(ctx: any, reason: "quota" | "rate-limit", from: { provider: string; id: string }) {
    const model = ctx.modelRegistry?.find?.(QUOTA_FALLBACK.provider, QUOTA_FALLBACK.id);
    if (!model) {
      ctx.ui.notify(
        `❌ ${from.provider}/${from.id} hit a ${reason === "quota" ? "quota" : "rate limit"} error, and ${QUOTA_FALLBACK.provider}/${QUOTA_FALLBACK.id} is not in the registry. Switch manually (/tier).`,
        "error"
      );
      return;
    }
    quotaState = {
      provider: from.provider,
      id: from.id,
      reason,
      at: Date.now(),
      cooldownMs: reason === "rate-limit" ? RATE_LIMIT_COOLDOWN_MS : undefined,
    };
    saveQuotaState(quotaState);
    const ok = await pi.setModel(model);
    if (!ok) {
      ctx.ui.notify("❌ Quota fallback failed to switch model — pick one manually (/tier).", "error");
      return;
    }
    const eta =
      reason === "rate-limit"
        ? `auto-restore attempt in ${Math.round(RATE_LIMIT_COOLDOWN_MS / 60_000)}m`
        : "quota resets monthly — use /quota restore when it's back";
    ctx.ui.notify(
      `💸 ${from.provider}/${from.id} → ${reason === "quota" ? "quota exhausted (402)" : "rate limited (429)"}.\n   Switched to DeepSeek V4.1 Flash (cheap). ${eta}.`,
      "warning"
    );
  }

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
      handler: async (_args: any, ctx: any) => activate(ctx, tier),
    });
    // Key shortcuts (Ctrl+1..5) where assigned
    if (tier.shortcut) {
      pi.registerShortcut(tier.shortcut, {
        description: `Switch model: ${tier.label}`,
        handler: async (ctx: any) => activate(ctx, tier),
      });
    }
  }

  pi.registerCommand("tier", {
    description: "Show model tier table and current model",
    handler: async (_args: any, ctx: any) => {
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
        "Rule of thumb: Sonnet 5 (Ctrl+1) for everything · Flash (Ctrl+2) for volume · GLM-5.3-HS (Ctrl+4) for hard · Kimi K3 (Ctrl+5) for huge context · Pro (Ctrl+3) only when you specifically want DeepSeek's best."
      );
      ctx.ui.notify(lines.join("\n"), "info");
    },
  });

  pi.registerCommand("quota", {
    description: "Show/clear the Copilot/Kimi quota fallback state (usage: /quota [restore|clear])",
    handler: async (args: any, ctx: any) => {
      const arg = String(args ?? "").trim().toLowerCase();

      if (arg === "clear") {
        quotaState = null;
        saveQuotaState(null);
        ctx.ui.notify("✅ Quota fallback state cleared.", "info");
        return;
      }

      if (arg === "restore") {
        if (!quotaState) {
          ctx.ui.notify("No quota fallback recorded — nothing to restore.", "info");
          return;
        }
        const model = ctx.modelRegistry?.find?.(quotaState.provider, quotaState.id);
        if (!model) {
          ctx.ui.notify(`❌ ${quotaState.provider}/${quotaState.id} not in registry.`, "error");
          return;
        }
        const ok = await pi.setModel(model);
        if (ok) {
          ctx.ui.notify(`↩️ Restored ${quotaState.provider}/${quotaState.id}.`, "info");
          quotaState = null;
          saveQuotaState(null);
        } else {
          ctx.ui.notify("❌ Restore failed — the quota may still be exhausted.", "error");
        }
        return;
      }

      const cur = ctx.model;
      const lines: string[] = ["## Quota Fallback"];
      lines.push(`  Active model: ${cur ? `${cur.provider}/${cur.id}` : "unknown"}`);
      if (!quotaState) {
        lines.push("  State:        none (no recent quota/rate-limit trip)");
      } else {
        const when = new Date(quotaState.at).toLocaleString();
        lines.push(`  Tripped:      ${quotaState.provider}/${quotaState.id}`);
        lines.push(`  Reason:       ${quotaState.reason === "quota" ? "quota exhausted (402)" : "rate limited (429)"}`);
        lines.push(`  When:         ${when}`);
        if (quotaState.cooldownMs === undefined) {
          lines.push("  Auto-restore: no (quota resets monthly — /quota restore when available)");
        } else {
          const remaining = Math.max(0, restoreAt() - Date.now());
          lines.push(`  Auto-restore: in ${Math.ceil(remaining / 60_000)}m`);
        }
      }
      lines.push("  Fallback:     deepseek/deepseek-flash (cheap, continues work)");
      lines.push("");
      lines.push("  /quota restore   switch back to the tripped model now");
      lines.push("  /quota clear     forget the state (no restore)");
      ctx.ui.notify(lines.join("\n"), "info");
    },
  });

  // Quota / rate-limit detection → automatic DeepSeek Flash fallback.
  // 402 = monthly premium quota exhausted (durable), 429 = transient rate limit.
  pi.on("after_provider_response", async (event: any, ctx: any) => {
    const status = event?.status;
    if (status !== 402 && status !== 429) return;
    const cur = ctx.model;
    if (!cur || !SUBSCRIPTION_PROVIDERS.has(cur.provider)) return;

    const reason: "quota" | "rate-limit" = status === 402 ? "quota" : "rate-limit";

    // Don't re-trip on the same provider we already fell back from.
    if (quotaState && quotaState.provider === cur.provider && quotaState.reason === reason) return;

    await fallbackToFlash(ctx, reason, { provider: cur.provider, id: cur.id });
  });

  // Suggest-only hints (never switches anything itself)
  pi.on("before_agent_start", async (event: any, ctx: any) => {
    // Auto-restore after a rate-limit cooldown (never for a monthly quota trip).
    const at = restoreAt();
    if (quotaState && at !== Infinity && Date.now() >= at) {
      const back = ctx.modelRegistry?.find?.(quotaState.provider, quotaState.id);
      if (back) {
        const ok = await pi.setModel(back);
        if (ok) {
          ctx.ui.notify(`↩️ Rate limit cleared — restored ${quotaState.provider}/${quotaState.id}.`, "info");
          quotaState = null;
          saveQuotaState(null);
        } else {
          // Still limited — back off (double, cap 60m)
          const next = Math.min((quotaState.cooldownMs ?? RATE_LIMIT_COOLDOWN_MS) * 2, MAX_COOLDOWN_MS);
          quotaState = { ...quotaState, at: Date.now(), cooldownMs: next };
          saveQuotaState(quotaState);
          ctx.ui.notify(
            `⏳ Still rate limited on ${quotaState.provider}/${quotaState.id} — next retry in ${Math.round(next / 60_000)}m.`,
            "warning"
          );
        }
      }
    }

    const prompt = (event as any).prompt;
    if (typeof prompt !== "string" || !prompt.trim()) return;
    const cur = ctx.model;
    if (!cur) return;

    // On a paid model with a trivial prompt → suggest cheaper
    if (!suggestedCheaper && isPaidModel(cur.provider, cur.id) && isTrivial(prompt)) {
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
        `💡 Heavy-looking prompt on ${cur.id}. Ctrl+1 = Sonnet 5 (free), Ctrl+4 = GLM-5.3-Highspeed (free, strong). (Once-per-session hint.)`,
        "info"
      );
    }
  });

  // New session on a paid default → gentle one-time nudge
  pi.on("session_start", async (_event: any, ctx: any) => {
    const cur = ctx.model;
    if (!cur) return;

    // Respect a persisted quota trip from an earlier session: if we're back on the
    // exhausted model, fall straight through to Flash without burning a request.
    if (quotaState && quotaState.reason === "quota" && cur.provider === quotaState.provider && cur.id === quotaState.id) {
      await fallbackToFlash(ctx, "quota", { provider: cur.provider, id: cur.id });
      return;
    }
    if (quotaState && cur.provider === QUOTA_FALLBACK.provider && cur.id === QUOTA_FALLBACK.id) {
      ctx.ui.notify(
        `💸 On DeepSeek Flash due to ${quotaState.reason === "quota" ? "Copilot quota exhaustion" : "a rate limit"} (${quotaState.provider}/${quotaState.id}). /quota for details.`,
        "info"
      );
      return;
    }

    if (isPaidModel(cur.provider, cur.id) && !suggestedCheaper) {
      suggestedCheaper = true;
      ctx.ui.notify(
        `💸 Session started on paid model ${cur.provider}/${cur.id}. Ctrl+1 = Sonnet ($0), Ctrl+2 = Flash (cheap). /tier for the ladder.`,
        "info"
      );
    }
  });
}
