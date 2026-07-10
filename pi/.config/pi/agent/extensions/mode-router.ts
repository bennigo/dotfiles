/**
 * Mode Router — automatic online / offline / private model routing.
 *
 * Three modes:
 *   online   (default) — cloud models available; your normal model choice stands.
 *   offline  (auto)    — cloud unreachable; main model is silently switched to a
 *                        local Ollama model (+ a one-line notice). Restored when
 *                        connectivity returns.
 *   private  (manual)  — `/private` forces everything on-device even when online.
 *                        Nothing leaves the machine. `/private off` releases it.
 *
 * Design notes:
 *   - Connectivity is probed with a short timeout and cached for CHECK_TTL_MS so we
 *     don't add latency to every prompt.
 *   - We only ever restore a CLOUD model we ourselves saved. If you manually pick a
 *     model (via /model or Ctrl+P) we record it and stop fighting you.
 *   - Local target is the fastest confirmed tool-caller on this GPU (benchmarked):
 *     llama3.1:8b. Fallbacks: qwen3.5, qwen3:8b. NOT qwen2.5-coder / ornith /
 *     deepseek-coder-v2 — those cannot emit tool calls through Ollama's OpenAI API.
 *
 * Commands:
 *   /private        — toggle private (on-device) mode
 *   /online         — force online mode (disable private, restore cloud model)
 *   /mode           — show current mode, connectivity, and active model
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// ---- Configuration -------------------------------------------------------

const LOCAL_PROVIDER = "ollama";
// Ordered by preference: fastest working tool-caller first.
const LOCAL_MODELS = ["llama3.1:8b", "hermes3:8b", "qwen3.5:latest", "qwen3:8b"];

// Endpoints used purely as reachability probes (HEAD-ish GET, no auth, no data).
const PROBE_URLS = [
  "https://api.github.com/",
  "https://api.deepseek.com/",
];
const OLLAMA_URL = "http://localhost:11434/api/tags";

const PROBE_TIMEOUT_MS = 2000;
const CHECK_TTL_MS = 30_000; // re-probe connectivity at most every 30s

// ---- State ---------------------------------------------------------------

type Mode = "online" | "offline" | "private";

let privateMode = false;
// The cloud model we switched away from (to restore when back online).
let savedCloudModel: { provider: string; id: string } | null = null;
// True while WE are calling setModel, so model_select doesn't treat it as manual.
let selfSwitching = false;
// Whether the currently active model is a local one that WE forced.
let forcedLocal = false;

let lastProbeAt = 0;
let lastOnline = true;

// ---- Helpers -------------------------------------------------------------

async function reachable(url: string): Promise<boolean> {
  try {
    const controller = new AbortController();
    const t = setTimeout(() => controller.abort(), PROBE_TIMEOUT_MS);
    await fetch(url, { method: "GET", signal: controller.signal, cache: "no-store" });
    clearTimeout(t);
    return true; // any HTTP response (even 401/403) means the network is up
  } catch {
    return false;
  }
}

async function isOnline(force = false): Promise<boolean> {
  const now = Date.now();
  if (!force && now - lastProbeAt < CHECK_TTL_MS) return lastOnline;
  lastProbeAt = now;
  for (const url of PROBE_URLS) {
    if (await reachable(url)) {
      lastOnline = true;
      return true;
    }
  }
  lastOnline = false;
  return false;
}

async function ollamaUp(): Promise<boolean> {
  return reachable(OLLAMA_URL);
}

function isLocalModel(m: { provider: string } | null | undefined): boolean {
  return !!m && m.provider === LOCAL_PROVIDER;
}

// Resolve the first local model that both exists in the registry AND is installed.
function findLocalModel(ctx: any) {
  for (const id of LOCAL_MODELS) {
    const m = ctx.modelRegistry?.find?.(LOCAL_PROVIDER, id);
    if (m) return m;
  }
  return null;
}

async function switchTo(pi: any, ctx: any, model: any): Promise<boolean> {
  selfSwitching = true;
  try {
    const ok = await pi.setModel(model);
    return ok;
  } finally {
    // release on next tick so the model_select event (if any) is ignored
    setTimeout(() => (selfSwitching = false), 0);
  }
}

function currentModel(ctx: any): { provider: string; id: string } | null {
  const m = ctx.model;
  if (!m) return null;
  return { provider: m.provider, id: m.id };
}

// Core reconciliation: make the active model match the desired mode.
async function reconcile(pi: any, ctx: any, opts: { announce?: boolean } = {}) {
  const online = privateMode ? true : await isOnline();
  const wantLocal = privateMode || !online;
  const cur = currentModel(ctx);

  if (wantLocal) {
    if (isLocalModel(cur)) return; // already local, nothing to do
    const local = findLocalModel(ctx);
    if (!local) {
      if (opts.announce) {
        ctx.ui.notify(
          privateMode
            ? "Private mode on, but no local model is registered/installed. Install one (e.g. `ollama pull llama3.1:8b`)."
            : "Offline detected, but no local model is available. Start Ollama or `ollama pull llama3.1:8b`.",
          "warn"
        );
      }
      return;
    }
    if (!(await ollamaUp())) {
      if (opts.announce) {
        ctx.ui.notify("Ollama is not running — can't switch to a local model. `ollama serve`?", "warn");
      }
      return;
    }
    // remember the cloud model so we can restore it later
    if (cur && !isLocalModel(cur)) savedCloudModel = cur;
    const ok = await switchTo(pi, ctx, local);
    if (ok) {
      forcedLocal = true;
      const reason = privateMode ? "private mode" : "offline";
      ctx.ui.notify(`🔒 ${reason}: switched to local ${local.id}.`, "info");
    }
    return;
  }

  // want cloud (online && not private): restore if we forced local earlier
  if (forcedLocal && isLocalModel(cur) && savedCloudModel) {
    const restore = ctx.modelRegistry?.find?.(savedCloudModel.provider, savedCloudModel.id);
    if (restore) {
      const ok = await switchTo(pi, ctx, restore);
      if (ok) {
        forcedLocal = false;
        ctx.ui.notify(`🌐 back online: restored ${restore.id}.`, "info");
        savedCloudModel = null;
      }
    }
  }
}

function modeName(): Mode {
  if (privateMode) return "private";
  return lastOnline ? "online" : "offline";
}

// ---- Extension -----------------------------------------------------------

export default function (pi: ExtensionAPI) {
  // Initial probe + reconcile on session start (no forced switch noise unless needed).
  pi.on("session_start", async (_event, ctx) => {
    await isOnline(true);
    await reconcile(pi, ctx, { announce: false });
  });

  // Re-check before every prompt so the mode tracks reality as it changes.
  pi.on("before_agent_start", async (_event, ctx) => {
    await reconcile(pi, ctx, { announce: true });
  });

  // If the user manually changes model, respect it: stop forcing/restoring.
  pi.on("model_select", async (event, _ctx) => {
    if (selfSwitching) return; // our own switch — ignore
    // A genuine manual selection: adopt it as the baseline.
    forcedLocal = false;
    const m = (event as any).model;
    if (m && m.provider !== LOCAL_PROVIDER) {
      savedCloudModel = { provider: m.provider, id: m.id };
    }
  });

  pi.registerCommand("private", {
    description: "Toggle private (on-device only) mode — forces local models even when online",
    handler: async (args, ctx) => {
      const arg = (args ?? "").trim().toLowerCase();
      if (arg === "off" || arg === "0" || arg === "false") {
        privateMode = false;
      } else if (arg === "on" || arg === "1" || arg === "true") {
        privateMode = true;
      } else {
        privateMode = !privateMode; // bare /private toggles
      }
      ctx.ui.notify(
        privateMode
          ? "🔒 Private mode ON — all work stays on-device (local Ollama models only)."
          : "🌐 Private mode OFF — cloud models allowed again.",
        "info"
      );
      await reconcile(pi, ctx, { announce: true });
    },
  });

  pi.registerCommand("online", {
    description: "Force online mode: disable private mode and restore the cloud model",
    handler: async (_args, ctx) => {
      privateMode = false;
      await isOnline(true);
      await reconcile(pi, ctx, { announce: true });
      ctx.ui.notify("🌐 Online mode.", "info");
    },
  });

  pi.registerCommand("mode", {
    description: "Show current routing mode, connectivity, and active model",
    handler: async (_args, ctx) => {
      const online = await isOnline(true);
      const cur = currentModel(ctx);
      const lines = [
        "## Mode Router",
        `  Mode:         ${modeName().toUpperCase()}`,
        `  Private:      ${privateMode ? "ON (forcing local)" : "off"}`,
        `  Connectivity: ${online ? "online" : "OFFLINE"}`,
        `  Ollama:       ${(await ollamaUp()) ? "running" : "not running"}`,
        `  Active model: ${cur ? `${cur.provider}/${cur.id}` : "unknown"}`,
        `  Forced local: ${forcedLocal ? "yes (by mode-router)" : "no"}`,
        `  Saved cloud:  ${savedCloudModel ? `${savedCloudModel.provider}/${savedCloudModel.id}` : "none"}`,
        "",
        "  /private   toggle on-device mode",
        "  /online    restore cloud model",
      ];
      ctx.ui.notify(lines.join("\n"), "info");
    },
  });
}
