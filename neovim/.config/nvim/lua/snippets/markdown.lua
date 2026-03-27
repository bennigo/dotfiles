-- ~/.config/nvim/lua/snippets/markdown.lua
-- Obsidian daily note snippets: timestamps, tasks, bullets, journaling
--
-- Trigger reference:
--   ct          HH:MM                       Bare time (current)
--   tt          (🕛 HH:MM: text)           Inline time stamp
--   dt          (➕ YYYY-MM-DD HH:MM: text) Inline datetime stamp
--   cdt         ➕ YYYY-MM-DD HH:MM         Bare creation datetime
--   ctd         ➕ YYYY-MM-DD               Bare creation date
--   db          - HH:MM — text              Dagbok entry
--   dtbull      - text ➕ YYYY-MM-DD HH:MM  Timed bullet
--   dbull       - text ➕ YYYY-MM-DD        Date bullet
--   dtask       - [ ] text ➕ YYYY-MM-DD    Task with creation date
--   dtask<N>    - [ ] text ➕ today 📅 +Nd  Task + deadline in N days
--   dtask<N>h   - [ ] text ➕ today 📅 +Nh  Task + deadline in N hours
--   dtask<N>m   - [ ] text ➕ today 📅 +Nm  Task + deadline in N minutes
--   stask<N>    - [ ] text ➕ today ⏳ +Nd  Task + scheduled in N days
--   stask<N>h   same, hours
--   deadl<N>    📅 YYYY-MM-DD               Deadline only
--   sched<N>    ⏳ YYYY-MM-DD               Scheduled date only
--   fstask<N>   - [ ] text ➕ today ⏳ +Nd 📅 +Md  Full task (scheduled + deadline)

local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

-- ── Shared helpers ──────────────────────────────────────────────────

local function now_tt()
  return os.date("%H:%M")
end

local function now_dt()
  return os.date("%Y-%m-%d %H:%M")
end

local function now_td()
  return os.date("%Y-%m-%d")
end

--- Convert a number + unit string into seconds offset from now.
--- @param n number  The numeric value
--- @param unit string  "d", "h", "m", or "" (default: days)
--- @return number seconds offset
local function unit_to_seconds(n, unit)
  if unit == "h" then
    return n * 3600
  elseif unit == "m" then
    return n * 60
  else
    return n * 86400
  end
end

--- Format a future date from regex captures (number + unit).
--- Uses date-only for days, datetime for hours/minutes.
--- @param snip table  LuaSnip snippet with .captures
--- @return string formatted date
local function future_date(snip)
  local n = tonumber(snip.captures[1] or "0") or 0
  local unit = snip.captures[2] or ""
  local fmt = (unit == "h" or unit == "m") and "%Y-%m-%d %H:%M" or "%Y-%m-%d"
  return os.date(fmt, os.time() + unit_to_seconds(n, unit))
end

--- Creation date format matching the unit in regex captures.
--- date-only for days, datetime for hours/minutes.
local function creation_date(snip)
  local unit = snip.captures[2] or ""
  local fmt = (unit == "h" or unit == "m") and "%Y-%m-%d %H:%M" or "%Y-%m-%d"
  return os.date(fmt, os.time())
end

-- ── Snippets ────────────────────────────────────────────────────────

return {

  -- ── Inline timestamps ───────────────────────────────────────────

  -- ct → 14:30
  s({ trig = "ct", name = "Bare time", dscr = "Current time HH:MM" }, {
    f(function() return now_tt() end, {}),
  }),

  -- tt → (🕛 14:30: text)
  s({ trig = "tt", name = "Time stamp", dscr = "Inline time reference" }, {
    t("(🕛 "),
    f(function() return now_tt() end, {}),
    t(": "),
    i(1, "text"),
    t(")"),
  }),

  -- dt → (➕ 2026-03-27 14:30: text)
  s({ trig = "dt", name = "Datetime stamp", dscr = "Inline datetime reference" }, {
    t("(➕ "),
    f(function() return now_dt() end, {}),
    t(": "),
    i(1, "text"),
    t(")"),
  }),

  -- cdt → ➕ 2026-03-27 14:30
  s({ trig = "cdt", name = "Creation datetime", dscr = "Bare creation datetime" }, {
    t("➕ "),
    f(function() return now_dt() end, {}),
  }),

  -- ctd → ➕ 2026-03-27
  s({ trig = "ctd", name = "Creation date", dscr = "Bare creation date" }, {
    t("➕ "),
    f(function() return now_td() end, {}),
  }),

  -- ── Dagbok entry ────────────────────────────────────────────────

  -- db → - 14:30 — text
  s({ trig = "db", name = "Dagbok entry", dscr = "Timestamped journal entry for Dagbók section" }, {
    t("- "),
    f(function() return now_tt() end, {}),
    t(" — "),
    i(1),
  }),

  -- ── Bullets ─────────────────────────────────────────────────────

  -- dtbull → - Bullet ➕ 2026-03-27 14:30
  s({ trig = "dtbull", name = "Timed bullet", dscr = "Bullet with datetime" }, {
    t("- "),
    i(1, "Bullet point"),
    t(" ➕ "),
    f(function() return now_dt() end, {}),
  }),

  -- dbull → - Bullet ➕ 2026-03-27
  s({ trig = "dbull", name = "Date bullet", dscr = "Bullet with date" }, {
    t("- "),
    i(1, "Bullet point"),
    t(" ➕ "),
    f(function() return now_td() end, {}),
  }),

  -- ── Tasks ───────────────────────────────────────────────────────

  -- dtask → - [ ] Task ➕ 2026-03-27
  s({ trig = "dtask", name = "Task (creation date)", dscr = "Checkbox task with creation date" }, {
    t("- [ ] "),
    i(1, "Task"),
    t(" ➕ "),
    f(function() return now_td() end, {}),
  }),

  -- dtask<N>[dhm] → - [ ] Task ➕ today 📅 +N days/hours/minutes
  s({
    trig = "dtask(%d+)([dhm]?)",
    regTrig = true,
    wordTrig = false,
    name = "Task + deadline",
    dscr = "Task with creation date and deadline (e.g. dtask5 = +5 days)",
  }, {
    t("- [ ] "),
    i(1, "Task"),
    t(" ➕ "),
    f(function(_, snip) return creation_date(snip) end, {}),
    t(" 📅 "),
    f(function(_, snip) return future_date(snip) end, {}),
  }),

  -- stask<N>[dhm] → - [ ] Task ➕ today ⏳ +N days/hours/minutes
  s({
    trig = "stask(%d+)([dhm]?)",
    regTrig = true,
    wordTrig = false,
    name = "Task + scheduled",
    dscr = "Task with creation date and scheduled start (e.g. stask3 = start in 3 days)",
  }, {
    t("- [ ] "),
    i(1, "Task"),
    t(" ➕ "),
    f(function(_, snip) return creation_date(snip) end, {}),
    t(" ⏳ "),
    f(function(_, snip) return future_date(snip) end, {}),
  }),

  -- fstask<N>[dhm] → - [ ] Task ➕ today ⏳ +N 📅 deadline (second insert node)
  s({
    trig = "fstask(%d+)([dhm]?)",
    regTrig = true,
    wordTrig = false,
    name = "Full task (scheduled + deadline)",
    dscr = "Task with scheduled start and manual deadline (e.g. fstask3 = start in 3 days)",
  }, {
    t("- [ ] "),
    i(1, "Task"),
    t(" ➕ "),
    f(function(_, snip) return creation_date(snip) end, {}),
    t(" ⏳ "),
    f(function(_, snip) return future_date(snip) end, {}),
    t(" 📅 "),
    i(2, os.date("%Y-%m-%d")),
  }),

  -- ── Date-only inserts ───────────────────────────────────────────

  -- deadl<N>[dhm] → 📅 2026-04-01
  s({
    trig = "deadl(%d+)([dhm]?)",
    regTrig = true,
    wordTrig = false,
    name = "Deadline date",
    dscr = "Deadline emoji + future date",
  }, {
    t("📅 "),
    f(function(_, snip) return future_date(snip) end, {}),
  }),

  -- sched<N>[dhm] → ⏳ 2026-04-01
  s({
    trig = "sched(%d+)([dhm]?)",
    regTrig = true,
    wordTrig = false,
    name = "Scheduled date",
    dscr = "Scheduled emoji + future date",
  }, {
    t("⏳ "),
    f(function(_, snip) return future_date(snip) end, {}),
  }),
}
