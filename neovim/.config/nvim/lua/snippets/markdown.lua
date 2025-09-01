-- ~/.config/nvim/lua/snippets/markdown.lua
local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

local function now_dt()
  return os.date("%Y-%m-%d %H:%M")
end

local function now_tt()
  return os.date("%H:%M")
end

local function now_td()
  return os.date("%Y-%m-%d")
end

local function add_minutes(mins)
  local ts = os.time() + mins * 60
  return os.date("%Y-%m-%d %H:%M", ts)
end

local function tomorrow_at(hour, min)
  local d = os.date("*t")
  local ts = os.time({
    year = d.year,
    month = d.month,
    day = d.day,
    hour = hour or 9,
    min = min or 0,
    sec = 0,
  }) + 24 * 60 * 60
  return os.date("%Y-%m-%d %H:%M", ts)
end

return {

  -- tt -> now
  s({ trig = "tt", name = "Timed insert (🕛 HH:MM: insert)", dscr = "Insert now statement  with current time" }, {
    t("(🕛"),
    f(function()
      return now_tt()
    end, {}),
    t(": "),
    i(1, "text"),
    t(")"),
  }),

  -- dt -> now
  s({
    trig = "dt",
    name = "Timed insert (➕ YYYY-mm-dd HH:MM: insert )",
    dscr = "Insert now statement with current date and time",
  }, {
    t("➕"),
    f(function()
      return now_dt()
    end, {}),
    t(": "),
    i(1, "text"),
    t(")"),
  }),

  -- cdt -> now
  s({ trig = "cdt", name = "(now)", dscr = "Created now current date and time" }, {
    t("(➕ "),
    f(function()
      return now_dt()
    end, {}),
    t(" "),
  }),

  -- td-> now
  s({ trig = "ctd", name = "Timed TODO (now)", dscr = "Created now: with current date" }, {
    t("(➕"),
    f(function()
      return now_td()
    end, {}),
    t(": "),
    i(1, "text"),
    t(")"),
  }),

  -- ctd-> now
  s({ trig = "ctd", name = "Timed TODO (now)", dscr = "Created now: with current date" }, {
    t("➕ "),
    f(function()
      return now_td()
    end, {}),
    t(" "),
  }),

  -- dtbull -> now
  s({ trig = "dtbull", name = "Timed bullet (now)", dscr = "Insert a Markdown bullet with current date and time" }, {
    t("- "),
    i(1, "Bullet point"),
    t(" ➕ "),
    f(function()
      return now_dt()
    end, {}),
    t("  "),
  }),

  -- dbull -> now
  s({ trig = "dbull", name = "Timed bullet (today)", dscr = "Insert a Markdown bullet with current date" }, {
    t("- "),
    i(1, "Bullet point"),
    t(" ➕ "),
    f(function()
      return now_td()
    end, {}),
    t("  "),
  }),

  -- dtask -> now
  s({ trig = "dtask", name = "Timed task (creation)", dscr = "Insert a Markdown task with current date and time" }, {
    t("- [ ] "),
    i(1, "Task "),
    t(" ➕ "),
    f(function()
      return now_dt()
    end, {}),
    t("  "),
  }),

  -- Regex-trigger: tt<number> or tt<number>h (e.g., tt20 -> +20m, tt2h -> +120m)
  -- regTrig uses Lua patterns. wordTrig=false allows expansion even if not at a strict word boundary.
  s({ trig = "dtask(%d+)([dhm]?)", regTrig = true, wordTrig = false, hidden = false, name = "Timed TODO (regex)" }, {
    t("- [ ] "),
    i(1, "Task"),
    t(" ➕ "),
    f(function(_, snip)
      local dformat = "%Y-%m-%d"
      local unit = snip.captures[2] or ""
      if unit == "h" or unit == "m" then
        dformat = "%Y-%m-%d %H:%M"
      end
      return os.date(dformat, os.time())
    end, {}),
    t(" 📅 "),
    f(function(_, snip)
      local dformat = "%Y-%m-%d"
      local n = tonumber(snip.captures[1] or "0") or 0
      local unit = snip.captures[2] or ""
      if unit == "h" or unit == "m" then
        dformat = "%Y-%m-%d %H:%M"
      end

      local mins
      if unit == "h" then
        mins = n * 60
      elseif unit == "m" then
        mins = n
      else
        mins = n * 24 * 60
      end
      return os.date(dformat, os.time() + mins * 60)
    end, {}),
    t(" "),
  }),

  s({ trig = "deadl(%d+)([dhm]?)", regTrig = true, wordTrig = false, hidden = false, name = "Timed TODO (regex)" }, {
    t("📅 "),
    f(function(_, snip)
      local dformat = "%Y-%m-%d"
      local n = tonumber(snip.captures[1] or "0") or 0
      local unit = snip.captures[2] or ""
      if unit == "h" or unit == "m" then
        dformat = "%Y-%m-%d %H:%M"
      end

      local mins
      if unit == "h" then
        mins = n * 60
      elseif unit == "m" then
        mins = n
      else
        mins = n * 24 * 60
      end
      return os.date(dformat, os.time() + mins * 60)
    end, {}),
  }),

  -- Regex-trigger: deadl<number> or deadl<number>h (e.g., deadl20 -> +20m, deadl2h -> +120m)
  -- regTrig uses Lua patterns. wordTrig=false allows expansion even if not at a strict word boundary.
  s({ trig = "tdeadl(%d+)([dhm]?)", regTrig = true, wordTrig = false, hidden = false, name = "Timed TODO (regex)" }, {
    i(1, "Task "),
    t("📅 "),
    f(function(_, snip)
      local dformat = "%Y-%m-%d"
      local n = tonumber(snip.captures[1] or "0") or 0
      local unit = snip.captures[2] or ""
      if unit == "h" or unit == "m" then
        dformat = "%Y-%m-%d %H:%M"
      end

      local mins
      if unit == "h" then
        mins = n * 60
      elseif unit == "m" then
        mins = n
      else
        mins = n * 24 * 60
      end
      return os.date(dformat, os.time() + mins * 60)
    end, {}),
  }),
}
