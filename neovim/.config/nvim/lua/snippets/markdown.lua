-- ~/.config/nvim/lua/snippets/markdown.lua
local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

local function now_dt()
  return os.date("%Y-%m-%d %H:%M")
end

local function now_ts()
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

  -- tbull -> now
  s({ trig = "tbull", name = "Timed bullet (now)", dscr = "Insert a Markdown bullet with current time" }, {
    t("- "),
    i(1, "Bullet point"),
    t(" ➕ "),
    f(function()
      return now_ts()
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

  -- Keep specials that regex won't cover
  -- s({ trig = "dtask9", name = "Timed TODO (tomorrow 09:00)" }, {
  --   t("- [ ] ("),
  --   f(function()
  --     return now_ts()
  --   end, {}),
  --   t("): 📅 "),
  --   f(function()
  --     return tomorrow_at(9, 0)
  --   end, {}),
  --   t(" "),
  --   i(1, "Task for tomorrow morning"),
  -- }),

  -- tt -> now
  s({ trig = "tt", name = "Timed TODO (now)", dscr = "Insert a Markdown checkbox with current time" }, {
    t("(🕛"),
    f(function()
      return now_ts()
    end, {}),
    t(": "),
    i(1, "text"),
    t(")"),
  }),

  -- dt -> now
  s({ trig = "dt", name = "Timed TODO (now)", dscr = "Insert a Markdown checkbox with current date and time" }, {
    t("(📅"),
    f(function()
      return now_dt()
    end, {}),
    t(": "),
    i(1, "text"),
    t(")"),
  }),

  -- td-> now
  s({ trig = "td", name = "Timed TODO (now)", dscr = "Insert a Markdown checkbox with current date" }, {
    t("(📅"),
    f(function()
      return now_td()
    end, {}),
    t(": "),
    i(1, "text"),
    t(")"),
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

  -- Regex-trigger: deadl<number> or deadl<number>h (e.g., deadl20 -> +20m, deadl2h -> +120m)
  -- regTrig uses Lua patterns. wordTrig=false allows expansion even if not at a strict word boundary.
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
    t(": "),
    i(1, "Task"),
  }),
}
