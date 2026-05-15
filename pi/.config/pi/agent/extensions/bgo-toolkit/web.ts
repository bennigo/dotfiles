#!/usr/bin/env -S npx tsx
/**
 * bgo-toolkit: Web search + fetch for Pi.
 *
 * Wraps Brave Search API for web search and provides content fetching.
 * Replaces Brave MCP + fetch MCP from ~/.mcp.json.
 *
 * Credentials: reads BRAVE_API_KEY from environment (set via pass).
 * Never logs or exposes the API key in tool arguments or output.
 */

import { spawn } from "node:child_process";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

// ── Configuration ──────────────────────────────────────────────────

const BRAVE_API_BASE = "https://api.search.brave.com/res/v1";
const MAX_RESULTS = 10;
const MAX_FETCH_SIZE = 30000; // 30KB max per page
const FETCH_TIMEOUT_MS = 15000;

function getApiKey(): string {
  return process.env.BRAVE_API_KEY || "";
}

// ── Brave Search ───────────────────────────────────────────────────

interface BraveWebResult {
  title: string;
  url: string;
  description: string;
  age?: string;
  extra_snippets?: string[];
}

interface BraveSearchResponse {
  web?: {
    results: BraveWebResult[];
    total?: number;
  };
  error?: { detail: string };
}

async function braveSearch(query: string, count: number = MAX_RESULTS): Promise<BraveSearchResponse> {
  const apiKey = getApiKey();
  if (!apiKey) {
    return { error: { detail: "BRAVE_API_KEY not set. Run: pass show tokens/brave_api" } };
  }

  const params = new URLSearchParams({
    q: query,
    count: String(Math.min(count, MAX_RESULTS)),
    search_lang: "en",
    extra_snippets: "true",
  });

  try {
    const response = await fetch(`${BRAVE_API_BASE}/web/search?${params}`, {
      headers: {
        Accept: "application/json",
        "Accept-Encoding": "gzip",
        "X-Subscription-Token": apiKey,
      },
      signal: AbortSignal.timeout(10000),
    });

    if (!response.ok) {
      const text = await response.text();
      return { error: { detail: `Brave API ${response.status}: ${text.slice(0, 200)}` } };
    }

    return (await response.json()) as BraveSearchResponse;
  } catch (err: any) {
    return { error: { detail: err.message || "Unknown error" } };
  }
}

// ── Web fetch ──────────────────────────────────────────────────────

interface FetchResult {
  url: string;
  title: string;
  content: string;
  truncated: boolean;
  contentType: string;
  error?: string;
}

async function fetchUrl(url: string): Promise<FetchResult> {
  try {
    const response = await fetch(url, {
      headers: {
        "User-Agent": "Mozilla/5.0 (compatible; Pi-coding-agent/1.0)",
        Accept: "text/html,text/plain,*/*",
      },
      signal: AbortSignal.timeout(FETCH_TIMEOUT_MS),
      redirect: "follow",
    });

    const contentType = response.headers.get("content-type") || "unknown";
    const text = await response.text();

    if (!response.ok) {
      return { url, title: "", content: `HTTP ${response.status}`, truncated: false, contentType, error: `HTTP ${response.status}` };
    }

    // Extract title and body text from HTML
    let title = "";
    let content = text;

    if (contentType.includes("text/html") || contentType.includes("text/plain")) {
      // Crude but effective HTML-to-text: strip tags, normalize whitespace
      const titleMatch = content.match(/<title[^>]*>([^<]*)<\/title>/i);
      if (titleMatch) title = titleMatch[1].trim();

      // Remove scripts, styles, head
      content = content
        .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, "")
        .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, "")
        .replace(/<head[^>]*>[\s\S]*?<\/head>/gi, "")
        .replace(/<nav[^>]*>[\s\S]*?<\/nav>/gi, "")
        .replace(/<footer[^>]*>[\s\S]*?<\/footer>/gi, "")
        .replace(/<[^>]+>/g, " ")
        .replace(/&amp;/g, "&")
        .replace(/&lt;/g, "<")
        .replace(/&gt;/g, ">")
        .replace(/&quot;/g, '"')
        .replace(/&#39;/g, "'")
        .replace(/&nbsp;/g, " ")
        .replace(/\s+/g, " ")
        .replace(/\n\s*\n/g, "\n")
        .trim();
    }

    let truncated = false;
    if (content.length > MAX_FETCH_SIZE) {
      content = content.slice(0, MAX_FETCH_SIZE) + "\n... [truncated]";
      truncated = true;
    }

    return { url, title, content, truncated, contentType };
  } catch (err: any) {
    return { url, title: "", content: "", truncated: false, contentType: "", error: err.message || "Unknown error" };
  }
}

// ── curl-based fetch (fallback for sites that block fetch) ─────────

function curlFetch(url: string): Promise<FetchResult> {
  return new Promise((resolve) => {
    const proc = spawn("curl", [
      "-sSL", "--max-time", "15",
      "-H", "User-Agent: Mozilla/5.0 (compatible; Pi-coding-agent/1.0)",
      url,
    ], { stdio: ["ignore", "pipe", "pipe"] });

    let stdout = "";
    let stderr = "";

    proc.stdout.on("data", (d: Buffer) => { stdout += d.toString(); });
    proc.stderr.on("data", (d: Buffer) => { stderr += d.toString(); });

    proc.on("close", (code) => {
      if (code !== 0) {
        resolve({ url, title: "", content: stderr.slice(0, 500), truncated: false, contentType: "", error: `curl exit ${code}` });
        return;
      }

      let title = "";
      let content = stdout;
      const titleMatch = content.match(/<title[^>]*>([^<]*)<\/title>/i);
      if (titleMatch) title = titleMatch[1].trim();

      content = content
        .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, "")
        .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, "")
        .replace(/<[^>]+>/g, " ")
        .replace(/&amp;/g, "&")
        .replace(/&lt;/g, "<")
        .replace(/&gt;/g, ">")
        .replace(/&quot;/g, '"')
        .replace(/&#39;/g, "'")
        .replace(/&nbsp;/g, " ")
        .replace(/\s+/g, " ")
        .trim();

      let truncated = false;
      if (content.length > MAX_FETCH_SIZE) {
        content = content.slice(0, MAX_FETCH_SIZE) + "\n... [truncated]";
        truncated = true;
      }

      resolve({ url, title, content, truncated, contentType: "text/html" });
    });
  });
}

// ── Extension ──────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    const hasKey = !!getApiKey();
    if (hasKey) {
      ctx.ui.notify("📦 web: Brave Search ready", "info");
    } else {
      ctx.ui.notify("📦 web: loaded (BRAVE_API_KEY not set — web_search disabled)", "warning");
    }
  });

  // ── web_search tool ────────────────────────────────────────────

  pi.registerTool({
    name: "web_search",
    label: "Web Search",
    description: [
      "Search the web using Brave Search API.",
      "Returns titles, URLs, descriptions, and extra snippets.",
      `Max ${MAX_RESULTS} results per query.`,
    ].join(" "),
    promptSnippet: "Search the web via Brave Search API",
    promptGuidelines: [
      "Use web_search to find current information, documentation, and facts on the web.",
      "After searching, use web_fetch to retrieve full page content for promising results.",
      "Be specific in queries — include version numbers, dates, or site: filters for better results.",
    ],
    parameters: Type.Object({
      query: Type.String({ description: "Search query" }),
      count: Type.Optional(
        Type.Number({ description: `Number of results (max ${MAX_RESULTS}). Default: 5`, default: 5 }),
      ),
    }),

    async execute(_toolCallId, params, _signal, onUpdate) {
      const apiKey = getApiKey();
      if (!apiKey) {
        return {
          content: [{ type: "text", text: "BRAVE_API_KEY not set. Web search unavailable." }],
          isError: true,
          details: {},
        };
      }

      onUpdate?.({ content: [{ type: "text", text: `Searching for: ${params.query}` }] });

      const data = await braveSearch(params.query, params.count ?? 5);

      if (data.error) {
        return {
          content: [{ type: "text", text: `Search error: ${data.error.detail}` }],
          isError: true,
          details: {},
        };
      }

      const results = data.web?.results || [];
      if (results.length === 0) {
        return {
          content: [{ type: "text", text: `No results found for: ${params.query}` }],
          details: { total: 0 },
        };
      }

      const formatted = results
        .map((r, i) => {
          const parts = [
            `### ${i + 1}. [${r.title}](${r.url})`,
            r.description,
          ];
          if (r.extra_snippets?.length) {
            parts.push(r.extra_snippets.map((s) => `> ${s}`).join("\n"));
          }
          if (r.age) parts.push(`*${r.age}*`);
          return parts.join("\n");
        })
        .join("\n\n");

      const total = data.web?.total ?? results.length;
      return {
        content: [
          {
            type: "text",
            text: `## Search: "${params.query}"\n${total} results total, showing ${results.length}\n\n${formatted}`,
          },
        ],
        details: { total, results: results.map((r) => ({ title: r.title, url: r.url })) },
      };
    },
  });

  // ── web_fetch tool ─────────────────────────────────────────────

  pi.registerTool({
    name: "web_fetch",
    label: "Fetch URL",
    description: [
      "Fetch and extract text content from a URL.",
      `Max ${MAX_FETCH_SIZE / 1000}KB per page.`,
      "HTML tags are stripped; scripts, styles, nav, and footer are removed.",
    ].join(" "),
    promptSnippet: "Fetch and extract text content from a URL",
    promptGuidelines: [
      "Use web_fetch to retrieve full page content after finding URLs via web_search.",
      "Fetch one URL at a time for best results — the content is already extracted as plain text.",
      "For JavaScript-heavy sites, the fallback curl-based fetcher may work better than fetch().",
    ],
    parameters: Type.Object({
      url: Type.String({ description: "URL to fetch" }),
      method: Type.Optional(
        Type.String({ description: "Fetch method: fetch (Node.js) or curl (shell fallback). Default: fetch", default: "fetch" }),
      ),
    }),

    async execute(_toolCallId, params, _signal, onUpdate) {
      onUpdate?.({ content: [{ type: "text", text: `Fetching: ${params.url}` }] });

      const result = params.method === "curl"
        ? await curlFetch(params.url)
        : await fetchUrl(params.url);

      if (result.error && !result.content) {
        // Try curl as fallback
        const curlResult = await curlFetch(params.url);
        if (!curlResult.error || curlResult.content) {
          return formatFetchResult(curlResult);
        }
        return {
          content: [{ type: "text", text: `Fetch failed: ${result.error}` }],
          isError: true,
          details: { url: params.url },
        };
      }

      return formatFetchResult(result);
    },
  });
}

function formatFetchResult(result: FetchResult) {
  const header = result.title
    ? `## ${result.title}\n**URL:** ${result.url}\n`
    : `## ${result.url}\n`;

  const truncatedNote = result.truncated ? `\n\n*[Content truncated at ${MAX_FETCH_SIZE / 1000}KB]*` : "";
  const errorNote = result.error ? `\n\n*Note: ${result.error}*` : "";

  return {
    content: [{ type: "text", text: `${header}\n${result.content}${truncatedNote}${errorNote}` }],
    details: {
      url: result.url,
      title: result.title,
      length: result.content.length,
      truncated: result.truncated,
    },
  };
}
