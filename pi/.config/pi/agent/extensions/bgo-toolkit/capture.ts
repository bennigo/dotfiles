#!/usr/bin/env -S npx tsx
/**
 * bgo-toolkit: Idea capture pipeline.
 *
 * /capture command drops ideas into Obsidian inbox (0.Inbox/) for later sorting.
 * Also registers a capture_idea tool the LLM can call.
 */

import * as fs from "node:fs";
import * as path from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const INBOX_DIR = "/home/bgo/notes/bgovault/0.Inbox";

function slugify(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 60);
}

function captureIdea(text: string, source: string = "pi-capture"): string {
  const now = new Date();
  const dateStr = now.toISOString().replace(/:/g, "").replace(/\..+/, "").replace("T", "-");
  const slug = slugify(text.slice(0, 50));
  const filename = `${dateStr}-${source}-${slug}.md`;

  const frontmatter = [
    "---",
    `created: ${now.toISOString().slice(0, 19)}`,
    "tags:",
    "  - status/inbox",
    "  - source/pi-capture",
    "---",
    "",
  ].join("\n");

  const content = `${frontmatter}# ${text.split("\n")[0].slice(0, 80)}\n\n${text}\n`;

  const filepath = path.join(INBOX_DIR, filename);
  fs.mkdirSync(INBOX_DIR, { recursive: true });
  fs.writeFileSync(filepath, content, "utf-8");

  return filepath;
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    ctx.ui.notify("📦 capture: /capture ready", "info");
  });

  // ── /capture command ──────────────────────────────────────────

  pi.registerCommand("capture", {
    description: "Capture an idea to Obsidian inbox for later sorting",
    handler: async (args, ctx) => {
      if (!args?.trim()) {
        const input = await ctx.ui.editor("Capture idea:", "");
        if (!input?.trim()) return;
        args = input.trim();
      }

      try {
        const filepath = captureIdea(args);
        const basename = path.basename(filepath);
        ctx.ui.notify(`Captured → ${basename}`, "success");
      } catch (err: any) {
        ctx.ui.notify(`Capture failed: ${err.message}`, "error");
      }
    },
  });

  // ── capture_idea tool ─────────────────────────────────────────

  pi.registerTool({
    name: "capture_idea",
    label: "Capture Idea",
    description: "Save a research idea, todo, or insight to the Obsidian inbox for later review. Use when you discover something worth investigating further.",
    promptSnippet: "Save ideas to Obsidian inbox",
    promptGuidelines: [
      "Use capture_idea to save research threads, tool ideas, or insights discovered during a session.",
      "The note goes to 0.Inbox/ and will be sorted during the next inbox review.",
    ],
    parameters: Type.Object({
      text: Type.String({ description: "Idea text (first line becomes title)" }),
      source: Type.Optional(Type.String({ description: "Source tag for the filename", default: "pi" })),
    }),

    async execute(_toolCallId, params) {
      try {
        const filepath = captureIdea(params.text, params.source || "pi");
        return {
          content: [{ type: "text", text: `Captured: ${path.basename(filepath)}` }],
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
