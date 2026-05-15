#!/usr/bin/env -S npx tsx
/**
 * bgo-toolkit: Memory bridge between Pi and Claude Code.
 *
 * Reads/writes ~/.claude/projects/<encoded-cwd>/memory/ tree.
 * Append-only writes, shared read pool. Both agents read from the same files.
 *
 * Claude Code auto-loads memory from this directory. Pi reads via this extension.
 * When Pi writes, it follows the same format Claude Code uses (markdown + frontmatter).
 */

import * as fs from "node:fs";
import * as path from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const MEMORY_BASE = path.join(process.env.HOME || "/home/bgo", ".claude", "projects");

function encodeCwd(cwd: string): string {
  // Claude Code encodes cwd by replacing / with -
  return cwd.replace(/^\//, "").replace(/\//g, "-");
}

function getMemoryDir(cwd: string): string {
  return path.join(MEMORY_BASE, encodeCwd(cwd), "memory");
}

function listMemories(cwd: string): { name: string; description: string; path: string }[] {
  const dir = getMemoryDir(cwd);
  if (!fs.existsSync(dir)) return [];

  return fs.readdirSync(dir)
    .filter((f) => f.endsWith(".md"))
    .map((f) => {
      const filepath = path.join(dir, f);
      const content = fs.readFileSync(filepath, "utf-8");
      const nameMatch = content.match(/^---\nname:\s*(.+)$/m);
      const descMatch = content.match(/^description:\s*(.+)$/m);
      return {
        name: nameMatch?.[1] || f.replace(".md", ""),
        description: descMatch?.[1] || "",
        path: filepath,
      };
    });
}

function saveMemory(cwd: string, text: string): string {
  const dir = getMemoryDir(cwd);
  fs.mkdirSync(dir, { recursive: true });

  const now = new Date().toISOString().slice(0, 19);
  const firstLine = text.split("\n")[0].slice(0, 80);
  const slug = firstLine
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "")
    .slice(0, 50);

  const filename = `${slug}.md`;
  const filepath = path.join(dir, filename);

  const frontmatter = [
    "---",
    `name: ${firstLine}`,
    `description: ${text.slice(0, 200)}`,
    "type: project",
    `saved: ${now}`,
    "---",
    "",
  ].join("\n");

  fs.writeFileSync(filepath, `${frontmatter}${text}\n`, "utf-8");
  return filepath;
}

export default function (pi: ExtensionAPI) {
  let projectCwd = "";

  pi.on("session_start", async (_event, ctx) => {
    projectCwd = ctx.cwd;
    const memories = listMemories(projectCwd);
    if (memories.length > 0) {
      ctx.ui.notify(`📦 memory-bridge: ${memories.length} memory(s) for this project`, "info");
    } else {
      ctx.ui.notify("📦 memory-bridge: ready (no memories yet)", "info");
    }
  });

  // ── memory_recall tool ────────────────────────────────────────

  pi.registerTool({
    name: "memory_recall",
    label: "Recall Memory",
    description: "Recall saved project memories from the shared Pi/Claude Code memory tree. Use at the start of a session to load context from previous sessions.",
    promptSnippet: "Recall project memories shared with Claude Code",
    promptGuidelines: [
      "Use memory_recall at the start of a session to load context from previous work in this project.",
      "Memories are shared between Pi and Claude Code — both agents read/write the same files.",
    ],
    parameters: Type.Object({
      filter: Type.Optional(Type.String({ description: "Optional text filter for memory names/descriptions" })),
    }),

    async execute(_toolCallId, params) {
      const memories = listMemories(projectCwd);

      let filtered = memories;
      if (params.filter) {
        const f = params.filter.toLowerCase();
        filtered = memories.filter(
          (m) => m.name.toLowerCase().includes(f) || m.description.toLowerCase().includes(f),
        );
      }

      if (memories.length === 0) {
        return {
          content: [{ type: "text", text: "No saved memories for this project." }],
          details: { count: 0 },
        };
      }

      const loaded = filtered.map((m) => {
        const content = fs.readFileSync(m.path, "utf-8");
        // Strip frontmatter for display
        const body = content.replace(/^---[\s\S]*?---\n*/, "").trim();
        return `### ${m.name}\n${m.description ? `*${m.description}*\n\n` : ""}${body.slice(0, 500)}${body.length > 500 ? "..." : ""}`;
      });

      const note = filtered.length < memories.length
        ? `\n*(showing ${filtered.length} of ${memories.length} memories)*`
        : "";

      return {
        content: [
          {
            type: "text",
            text: `## Project Memories (${filtered.length})\n\n${loaded.join("\n\n---\n\n")}${note}`,
          },
        ],
        details: { count: filtered.length, total: memories.length },
      };
    },
  });

  // ── memory_save tool ──────────────────────────────────────────

  pi.registerTool({
    name: "memory_save",
    label: "Save Memory",
    description: "Save a project memory to the shared Pi/Claude Code memory tree. Both agents will see it. Use to persist important decisions, patterns, or context across sessions.",
    promptSnippet: "Save project memory (shared with Claude Code)",
    promptGuidelines: [
      "Use memory_save to persist important discoveries, decisions, or patterns for future sessions.",
      "Memories are shared with Claude Code — both agents can read them.",
      "Write concise, specific memories. First line is used as the title.",
    ],
    parameters: Type.Object({
      text: Type.String({ description: "Memory content (first line becomes title)" }),
    }),

    async execute(_toolCallId, params) {
      try {
        const filepath = saveMemory(projectCwd, params.text);
        return {
          content: [{ type: "text", text: `Memory saved: ${path.basename(filepath)}` }],
          details: { filepath },
        };
      } catch (err: any) {
        return {
          content: [{ type: "text", text: `Failed: ${err.message}` }],
          isError: true,
          details: {},
        };
      }
    },
  });
}
