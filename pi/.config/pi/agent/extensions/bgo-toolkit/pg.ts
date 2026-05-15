#!/usr/bin/env -S npx tsx
/**
 * bgo-toolkit: Postgres database access for Pi.
 *
 * Hybrid tool: auto-schema introspection (\\dt + \\d+) before every query,
 * EXPLAIN validation, read-write gate for postgres-local.
 *
 * Databases (from ~/.mcp.json env vars + neovim db_ui/connections.json):
 *   LOCAL_POSTGRES_URL          → localhost:5432/bgo (read-write, gated)
 *   PROD_GAS_URL                → pgread.vedur.is:5432/gas (read-only)
 *   PROD_SKJALFTALISA_URL       → pgread.vedur.is:5432/skjalftalisa (read-only)
 *   PROD_TOS_URL                → pgread.vedur.is:5432/tos (read-only)
 *   DEV_EPOS_URL                → pgdev.vedur.is:5432/epos (read-only)
 *   DEV_GNSS_URL                → pgdev.vedur.is:5432/gnss-europe-v0-2-9 (read-only)
 *   DEV_METRICS_URL             → pgdev.vedur.is:5432/gps_metrics (read-only)
 *   GPS_HEALTH_DEV_URL          → pgdev.vedur.is:5432/gps_health (read-only)
 *   GPS_HEALTH_LOCAL_URL        → localhost:5432/gps_health (read-write, gated)
 *
 * Extra databases only available when their env vars are set.
 */

import { spawn } from "node:child_process";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

// ── Database registry ──────────────────────────────────────────────

interface DbConfig {
  name: string;
  envVar: string;
  label: string;
  writable: boolean;
  description: string;
}

const DB_REGISTRY: DbConfig[] = [
  {
    name: "local",
    envVar: "LOCAL_POSTGRES_URL",
    label: "local (bgo)",
    writable: true,
    description: "Local development database — read-write, confirmation gated",
  },
  {
    name: "gas",
    envVar: "PROD_GAS_URL",
    label: "GAS (production)",
    writable: false,
    description: "Production GAS database — read-only",
  },
  {
    name: "skjalftalisa",
    envVar: "PROD_SKJALFTALISA_URL",
    label: "skjálftalísa (production)",
    writable: false,
    description: "Production earthquake database — read-only",
  },
  {
    name: "tos",
    envVar: "PROD_TOS_URL",
    label: "TOS (production)",
    writable: false,
    description: "Production TOS database — read-only",
  },
  {
    name: "epos",
    envVar: "DEV_EPOS_URL",
    label: "EPOS (development)",
    writable: false,
    description: "Development EPOS database — read-only",
  },
  {
    name: "gnss",
    envVar: "DEV_GNSS_URL",
    label: "GNSS (development)",
    writable: false,
    description: "Development GNSS database — read-only",
  },
  {
    name: "metrics",
    envVar: "DEV_METRICS_URL",
    label: "GPS metrics (development)",
    writable: false,
    description: "Development GPS metrics database — read-only",
  },
  {
    name: "gps_health",
    envVar: "GPS_HEALTH_DEV_URL",
    label: "GPS health (development)",
    writable: false,
    description: "GPS health monitoring — read-only (schema evolves frequently)",
  },
  {
    name: "gps_health_local",
    envVar: "GPS_HEALTH_LOCAL_URL",
    label: "GPS health (local)",
    writable: true,
    description: "Local GPS health — read-write, confirmation gated",
  },
];

function getAvailableDbs(): DbConfig[] {
  return DB_REGISTRY.filter((db) => process.env[db.envVar]);
}

function getDb(name: string): DbConfig | undefined {
  return DB_REGISTRY.find((db) => db.name === name && process.env[db.envVar]);
}

// ── Psql execution ─────────────────────────────────────────────────
// NEVER pass credentials in command-line arguments.
// Password is extracted from the connection URL and passed via
// PGPASSWORD env var in the child process only (never visible to the model).

interface PsqlResult {
  stdout: string;
  stderr: string;
  exitCode: number;
  truncated: boolean;
}

interface ParsedConn {
  host: string;
  port: number;
  user: string;
  password: string;
  dbname: string;
}

function parseConnUrl(connUrl: string): ParsedConn {
  // postgresql://user:password@host:port/dbname
  const url = new URL(connUrl);
  return {
    host: url.hostname,
    port: parseInt(url.port || "5432"),
    user: decodeURIComponent(url.username),
    password: decodeURIComponent(url.password),
    dbname: url.pathname.replace(/^\//, ""),
  };
}

function psql(connUrl: string, sql: string, timeoutSec = 30): Promise<PsqlResult> {
  const conn = parseConnUrl(connUrl);
  return new Promise((resolve) => {
    const proc = spawn(
      "psql",
      [
        "-AtX", "--no-psqlrc",
        "-v", "ON_ERROR_STOP=1",
        "-h", conn.host,
        "-p", String(conn.port),
        "-U", conn.user,
        "-d", conn.dbname,
        "-c", sql,
      ],
      {
        stdio: ["ignore", "pipe", "pipe"],
        timeout: timeoutSec * 1000,
        env: { ...process.env, PGPASSWORD: conn.password },
      },
    );

    let stdout = "";
    let stderr = "";
    let truncated = false;

    proc.stdout.on("data", (data: Buffer) => {
      const chunk = data.toString();
      if (stdout.length + chunk.length > 50000) {
        truncated = true;
        stdout += chunk.slice(0, 50000 - stdout.length) + "\n... [output truncated at 50KB]";
      } else {
        stdout += chunk;
      }
    });

    proc.stderr.on("data", (data: Buffer) => {
      stderr += data.toString();
    });

    proc.on("close", (code) => {
      resolve({ stdout: stdout.trim(), stderr: stderr.trim(), exitCode: code ?? 1, truncated });
    });

    proc.on("error", (err) => {
      resolve({ stdout: "", stderr: err.message, exitCode: 1, truncated: false });
    });
  });
}

// ── Schema introspection ───────────────────────────────────────────

async function introspectSchema(connUrl: string, tableFilter?: string): Promise<string> {
  const lines: string[] = [];

  // List tables
  const tableQuery = tableFilter
    ? `SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname='public' AND tablename ILIKE '%${tableFilter.replace(/'/g, "''")}%' ORDER BY tablename`
    : "SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname='public' ORDER BY tablename";

  const tableResult = await psql(connUrl, tableQuery);
  if (tableResult.exitCode !== 0) {
    return `Schema introspection failed: ${tableResult.stderr}`;
  }

  const tables = tableResult.stdout
    .split("\n")
    .map((l) => l.trim())
    .filter(Boolean);

  if (tables.length === 0) {
    return "No tables found in public schema.";
  }

  lines.push(`## Schema: ${tables.length} table(s)`);
  lines.push("");

  // For each table, get columns
  for (const table of tables.slice(0, 20)) {
    // limit to 20 tables to avoid context bloat
    const colResult = await psql(
      connUrl,
      `SELECT column_name, data_type, is_nullable, column_default FROM information_schema.columns WHERE table_schema='public' AND table_name='${table.replace(/'/g, "''")}' ORDER BY ordinal_position`,
    );

    if (colResult.exitCode === 0 && colResult.stdout) {
      const cols = colResult.stdout.split("\n").map((l) => l.trim());
      lines.push(`### ${table}`);
      lines.push("```");
      for (const col of cols) {
        const [name, type, nullable, defaultVal] = col.split("|");
        const nullMark = nullable === "YES" ? "?" : "";
        const defaultStr = defaultVal ? ` = ${defaultVal}` : "";
        lines.push(`  ${name}: ${type}${nullMark}${defaultStr}`);
      }
      lines.push("```");
      lines.push("");
    }
  }

  if (tables.length > 20) {
    lines.push(`... and ${tables.length - 20} more tables (use table_filter to narrow)`);
  }

  return lines.join("\n");
}

// ── Query validation ───────────────────────────────────────────────

async function validateQuery(connUrl: string, sql: string): Promise<string | null> {
  const explainResult = await psql(connUrl, `EXPLAIN ${sql}`);
  if (explainResult.exitCode !== 0) {
    return `Query validation failed: ${explainResult.stderr}`;
  }
  return null; // valid
}

function isWriteQuery(sql: string): boolean {
  const upper = sql.trim().toUpperCase();
  const writeKeywords = [
    /^\s*INSERT\b/,
    /^\s*UPDATE\b/,
    /^\s*DELETE\b/,
    /^\s*DROP\b/,
    /^\s*CREATE\b/,
    /^\s*ALTER\b/,
    /^\s*TRUNCATE\b/,
    /^\s*GRANT\b/,
    /^\s*REVOKE\b/,
    /^\s*COPY\b/,
  ];
  return writeKeywords.some((re) => re.test(upper));
}

// ── Extension ──────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
  const available = getAvailableDbs();
  const availableNames = available.map((d) => d.name);

  pi.on("session_start", async (_event, ctx) => {
    const count = available.length;
    if (count > 0) {
      const list = available.map((d) => `  ${d.name} → ${d.label} ${d.writable ? "(rw)" : "(ro)"}`).join("\n");
      ctx.ui.notify(`📦 pg: ${count} database(s) available\n${list}`, "info");
    } else {
      ctx.ui.notify("📦 pg: loaded (no databases — set env vars)", "warning");
    }
  });

  // ── pg_query tool ──────────────────────────────────────────────

  pi.registerTool({
    name: "pg_query",
    label: "Postgres Query",
    description: [
      "Execute a read-only SQL query against a registered postgres database.",
      "Schema introspection runs automatically before the query so the model always sees current table structures.",
      "Queries are validated via EXPLAIN before execution.",
      `Available databases: ${availableNames.join(", ") || "none configured"}.`,
    ].join(" "),
    promptSnippet: "Query postgres databases with automatic schema introspection",
    promptGuidelines: [
      "Use pg_query to explore and query postgres databases. The tool auto-introspects schema before each query.",
      "Use pg_list_databases to see available databases. Use pg_describe_table to inspect a specific table before querying it.",
    ],
    parameters: Type.Object({
      database: Type.String({
        description: `Database name. Available: ${availableNames.join(", ") || "none"}`,
      }),
      query: Type.String({
        description: "SQL SELECT query to execute (read-only; writes are blocked on read-only databases)",
      }),
      introspect: Type.Optional(
        Type.Boolean({
          description: "Run schema introspection before the query. Default: true.",
          default: true,
        }),
      ),
    }),

    async execute(_toolCallId, params, _signal, onUpdate, ctx) {
      const db = getDb(params.database);
      if (!db) {
        const avail = available.map((d) => d.name).join(", ");
        return {
          content: [{ type: "text", text: `Unknown database: "${params.database}". Available: ${avail}` }],
          isError: true,
          details: {},
        };
      }

      const connUrl = process.env[db.envVar]!;

      // Check write query on read-only DB
      if (!db.writable && isWriteQuery(params.query)) {
        return {
          content: [
            {
              type: "text",
              text: `Write query blocked: ${db.label} is read-only.\nQuery: ${params.query}`,
            },
          ],
          isError: true,
          details: {},
        };
      }

      // Write gate for writable DBs
      if (db.writable && isWriteQuery(params.query) && ctx.hasUI) {
        const ok = await ctx.ui.confirm(
          `Write query on ${db.label}`,
          `Database: ${db.name}\nQuery: ${params.query.slice(0, 200)}${params.query.length > 200 ? "..." : ""}`,
        );
        if (!ok) {
          return {
            content: [{ type: "text", text: "Write query cancelled by user." }],
            details: {},
          };
        }
      }

      // Schema introspection
      let schemaInfo = "";
      if (params.introspect !== false) {
        onUpdate?.({ content: [{ type: "text", text: "Introspecting schema..." }] });
        // Try to extract table names from the query for targeted introspection
        const tableMatch = params.query.match(/FROM\s+(\w+)|JOIN\s+(\w+)/gi);
        if (tableMatch) {
          const tables = tableMatch.map((m) => m.replace(/FROM\s+|JOIN\s+/i, "").trim());
          const schemaParts: string[] = [];
          for (const table of tables) {
            const colResult = await psql(
              connUrl,
              `SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_schema='public' AND table_name='${table.replace(/'/g, "''")}' ORDER BY ordinal_position`,
            );
            if (colResult.exitCode === 0 && colResult.stdout) {
              const cols = colResult.stdout
                .split("\n")
                .map((l) => {
                  const [n, t, nu] = l.split("|");
                  return `  ${n}: ${t}${nu === "YES" ? " (nullable)" : ""}`;
                })
                .join("\n");
              schemaParts.push(`### ${table}\n${cols}`);
            }
          }
          schemaInfo = schemaParts.join("\n\n");
        } else {
          schemaInfo = await introspectSchema(connUrl);
        }
      }

      // Validate via EXPLAIN
      onUpdate?.({ content: [{ type: "text", text: "Validating query..." }] });
      const validationError = await validateQuery(connUrl, params.query);
      if (validationError) {
        const response = schemaInfo
          ? `Schema:\n${schemaInfo}\n\nValidation error:\n${validationError}`
          : `Validation error:\n${validationError}`;
        return {
          content: [{ type: "text", text: response }],
          isError: true,
          details: { schema: schemaInfo },
        };
      }

      // Execute
      onUpdate?.({ content: [{ type: "text", text: "Executing query..." }] });
      const result = await psql(connUrl, params.query);

      if (result.exitCode !== 0) {
        const response = schemaInfo
          ? `Schema:\n${schemaInfo}\n\nError:\n${result.stderr}`
          : `Error:\n${result.stderr}`;
        return {
          content: [{ type: "text", text: response }],
          isError: true,
          details: { schema: schemaInfo },
        };
      }

      const output = result.stdout || "(empty result)";
      const truncatedNote = result.truncated ? "\n[output truncated at 50KB]" : "";
      const header = schemaInfo ? `${schemaInfo}\n\n## Query result\n` : "## Query result\n";

      return {
        content: [{ type: "text", text: `${header}\`\`\`\n${output}\n\`\`\`${truncatedNote}` }],
        details: { schema: schemaInfo, rowCount: output.split("\n").length },
      };
    },
  });

  // ── pg_list_databases tool ─────────────────────────────────────

  pi.registerTool({
    name: "pg_list_databases",
    label: "List Databases",
    description: "List all available postgres databases with their access mode and description.",
    parameters: Type.Object({}),
    async execute() {
      if (available.length === 0) {
        return {
          content: [{ type: "text", text: "No databases configured. Set PG_* env variables." }],
          details: {},
        };
      }

      const lines = available.map(
        (db) => `- **${db.name}** — ${db.label} — ${db.writable ? "read-write ⚠️" : "read-only"} — ${db.description}`,
      );

      return {
        content: [{ type: "text", text: `## Available databases (${available.length})\n\n${lines.join("\n")}` }],
        details: { count: available.length },
      };
    },
  });

  // ── pg_describe_table tool ─────────────────────────────────────

  pi.registerTool({
    name: "pg_describe_table",
    label: "Describe Table",
    description: "Describe a table's columns, types, and constraints. Use before writing queries against unfamiliar tables.",
    parameters: Type.Object({
      database: Type.String({
        description: `Database name. Available: ${availableNames.join(", ") || "none"}`,
      }),
      table: Type.String({
        description: "Table name to describe",
      }),
    }),
    async execute(_toolCallId, params) {
      const db = getDb(params.database);
      if (!db) {
        return {
          content: [{ type: "text", text: `Unknown database: "${params.database}"` }],
          isError: true,
          details: {},
        };
      }

      const connUrl = process.env[db.envVar]!;

      // Column info
      const colResult = await psql(
        connUrl,
        `SELECT column_name, data_type, is_nullable, column_default FROM information_schema.columns WHERE table_schema='public' AND table_name='${params.table.replace(/'/g, "''")}' ORDER BY ordinal_position`,
      );

      if (colResult.exitCode !== 0) {
        return {
          content: [{ type: "text", text: `Error: ${colResult.stderr}` }],
          isError: true,
          details: {},
        };
      }

      // Row count
      const countResult = await psql(connUrl, `SELECT COUNT(*) FROM "${params.table.replace(/"/g, '""')}"`);
      const rowCount = countResult.exitCode === 0 ? countResult.stdout.trim() : "?";

      // Indexes
      const idxResult = await psql(
        connUrl,
        `SELECT indexname, indexdef FROM pg_indexes WHERE tablename='${params.table.replace(/'/g, "''")}'`,
      );

      const cols = colResult.stdout
        .split("\n")
        .filter(Boolean)
        .map((l) => {
          const [name, type, nullable, defaultVal] = l.split("|");
          const nullMark = nullable === "YES" ? "?" : "";
          const defaultStr = defaultVal ? ` = ${defaultVal}` : "";
          return `  ${name}: ${type}${nullMark}${defaultStr}`;
        })
        .join("\n");

      const indexes =
        idxResult.exitCode === 0 && idxResult.stdout
          ? idxResult.stdout
              .split("\n")
              .filter(Boolean)
              .map((l) => {
                const [name, def] = l.split("|");
                return `  ${name}: ${def}`;
              })
              .join("\n")
          : "  (none)";

      return {
        content: [
          {
            type: "text",
            text: [
              `## ${params.table} (${db.label})`,
              `Rows: ~${rowCount}`,
              "",
              "### Columns",
              "```",
              cols,
              "```",
              "",
              "### Indexes",
              "```",
              indexes,
              "```",
            ].join("\n"),
          },
        ],
        details: { database: db.name, table: params.table, rowCount },
      };
    },
  });
}
