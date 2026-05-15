#!/usr/bin/env -S npx tsx
/**
 * bgo-toolkit: Vault integration for Pi.
 *
 * Wraps vault-lookup.py and learning-query.py so Pi can query
 * the Obsidian vault (bgovault) for existing knowledge.
 */

import { spawn } from "node:child_process";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const VAULT_SCRIPTS = "/home/bgo/notes/bgovault/.scripts";

function spawnPython(script: string, args: string[], timeoutSec = 15): Promise<{ stdout: string; stderr: string; exitCode: number }> {
  return new Promise((resolve) => {
    const proc = spawn("python3", [script, ...args], {
      cwd: VAULT_SCRIPTS,
      stdio: ["ignore", "pipe", "pipe"],
      timeout: timeoutSec * 1000,
    });

    let stdout = "";
    let stderr = "";

    proc.stdout.on("data", (d: Buffer) => { stdout += d.toString(); });
    proc.stderr.on("data", (d: Buffer) => { stderr += d.toString(); });

    proc.on("close", (code) => resolve({ stdout: stdout.trim(), stderr: stderr.trim(), exitCode: code ?? 1 }));
    proc.on("error", (err) => resolve({ stdout: "", stderr: err.message, exitCode: 1 }));
  });
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    ctx.ui.notify("📦 vault: vault-lookup + learning-query ready", "info");
  });

  // ── vault_lookup tool ─────────────────────────────────────────

  pi.registerTool({
    name: "vault_lookup",
    label: "Vault Lookup",
    description: "Search the Obsidian vault (bgovault) for notes relevant to a topic. Returns note titles, paths, and relevant excerpts. Use to find existing knowledge before starting research.",
    promptSnippet: "Search Obsidian vault for relevant notes",
    promptGuidelines: [
      "Use vault_lookup to find existing notes on a topic before doing web research or writing new notes.",
      "The vault contains research notes, project documentation, and personal knowledge base.",
      "Follow up with read on the returned note paths to get full content.",
    ],
    parameters: Type.Object({
      topic: Type.String({ description: "Topic to search for" }),
    }),

    async execute(_toolCallId, params, _signal, onUpdate) {
      onUpdate?.({ content: [{ type: "text", text: `Searching vault for: ${params.topic}` }] });

      const result = await spawnPython(
        `${VAULT_SCRIPTS}/vault-lookup.py`,
        [params.topic],
      );

      if (result.exitCode !== 0) {
        return {
          content: [{ type: "text", text: `Vault lookup failed:\n${result.stderr || "(no error output)"}` }],
          isError: true,
          details: {},
        };
      }

      return {
        content: [{ type: "text", text: result.stdout || `No results found for "${params.topic}"` }],
        details: { topic: params.topic },
      };
    },
  });

  // ── learning_query tool ───────────────────────────────────────

  pi.registerTool({
    name: "learning_query",
    label: "Learning Query",
    description: "Query the learning system (meta-journal) for insights, methods, and patterns learned from past work. Use to recall what approaches worked or didn't work.",
    promptSnippet: "Query learning system for past insights",
    promptGuidelines: [
      "Use learning_query to recall past approaches, methods, and lessons learned.",
      "The learning system tracks what worked and what didn't across projects.",
      "Use --next-id to get the next available entry ID for creating new entries.",
    ],
    parameters: Type.Object({
      query: Type.Optional(Type.String({ description: "Search query (leave empty to list recent)" })),
      nextId: Type.Optional(Type.Boolean({ description: "Get next available entry ID for creating new entries", default: false })),
      count: Type.Optional(Type.Number({ description: "Number of results", default: 10 })),
    }),

    async execute(_toolCallId, params, _signal, onUpdate) {
      const args: string[] = [];

      if (params.nextId) {
        args.push("--next-id", "mj");
      } else if (params.query) {
        args.push(params.query);
        if (params.count) args.push("-n", String(params.count));
      } else {
        args.push("-n", String(params.count || 10));
      }

      onUpdate?.({ content: [{ type: "text", text: "Querying learning system..." }] });

      const result = await spawnPython(`${VAULT_SCRIPTS}/learning-query.py`, args);

      if (result.exitCode !== 0) {
        return {
          content: [{ type: "text", text: `Learning query failed:\n${result.stderr || "(no error output)"}` }],
          isError: true,
          details: {},
        };
      }

      return {
        content: [{ type: "text", text: result.stdout || "No results." }],
        details: { query: params.query },
      };
    },
  });
}
