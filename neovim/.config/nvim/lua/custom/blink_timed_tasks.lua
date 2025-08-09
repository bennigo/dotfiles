-- ~/.config/nvim/lua/custom/blink_timed_tasks.lua
-- Minimal provider; no varargs; optional logger support.

-- Try to use your existing logger; fallback to no-op if absent
local function resolve_logger()
  local ok, mod = pcall(require, "custom.devlog")
  if not ok then
    return function() end
  end
  if type(mod) == "function" then
    return mod
  elseif type(mod) == "table" and type(mod.log) == "function" then
    return mod.log
  else
    return function() end
  end
end

local log = resolve_logger()

local function now_ts(fmt)
  return os.date(fmt or "%Y-%m-%d %H:%M")
end

local function add_minutes(mins)
  local t = os.time() + (mins * 60)
  return os.date("%Y-%m-%d %H:%M", t)
end

local function tomorrow_at(hour, min)
  local d = os.date("*t")
  local t = os.time({
    year = d.year,
    month = d.month,
    day = d.day,
    hour = hour or 9,
    min = min or 0,
    sec = 0,
  }) + 24 * 60 * 60
  return os.date("%Y-%m-%d %H:%M", t)
end

local function current_prefix()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local before = line:sub(1, col)
  return before:match("(%S+)$") or ""
end

local function should_offer(prefix)
  prefix = (prefix or ""):lower()
  return prefix == "" or prefix:find("^tt")
end

local function make_item(label, text, filter)
  return {
    label = label,
    insertText = text,
    insertTextFormat = 1, -- PlainText
    kind = 15, -- Snippet-like
    documentation = "Insert a timestamped TODO line",
    filterText = filter or label,
    sortText = filter or label,
  }
end

local M = {}

function M.new(_opts)
  local inst = {}

  function inst.enabled(_ctx)
    log("[timed_tasks] enabled()")
    return true
  end

  function inst.is_available(_ctx)
    log("[timed_tasks] is_available()")
    return true
  end

  function inst.cancel_completions(_ctx)
    log("[timed_tasks] cancel_completions()")
    -- no-op
  end

  function inst.get_completions(_ctx)
    log("[timed_tasks] get_completions() begin")
    local prefix = current_prefix()
    if not should_offer(prefix) then
      log("[timed_tasks] filtered, prefix='" .. prefix .. "'")
      return {}
    end
    local items = {
      make_item("TODO now", string.format("- [ ] %s ", now_ts()), "tt"),
      make_item("TODO in 15m", string.format("- [ ] %s ", add_minutes(15)), "tt15"),
      make_item("TODO in 30m", string.format("- [ ] %s ", add_minutes(30)), "tt30"),
      make_item("TODO in 1h", string.format("- [ ] %s ", add_minutes(60)), "tt1h"),
      make_item("TODO tomorrow 09:00", string.format("- [ ] %s ", tomorrow_at(9, 0)), "ttt9"),
    }
    log("[timed_tasks] returning " .. tostring(#items) .. " items")
    return items
  end

  -- Optional: detect accidental overwrites of lifecycle methods
  local protected = {
    cancel_completions = true,
    get_completions = true,
    enabled = true,
    is_available = true,
  }

  return setmetatable(inst, {
    __newindex = function(t, k, v)
      if protected[k] then
        log("[timed_tasks] OVERWRITE " .. k .. " with " .. type(v))
        log(debug.traceback("stack at overwrite", 2))
      end
      rawset(t, k, v)
    end,
  })
end

return M
