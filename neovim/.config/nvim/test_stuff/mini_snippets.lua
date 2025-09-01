-- ~/.config/nvim/lua/custom/mini_snippets.lua
-- Lightweight "mini-snippets" using insert-mode expr mappings, inspired by the article. [0]

local M = {}

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

-- Return last non-space token before cursor
local function current_prefix()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local before = line:sub(1, col)
  return before:match("(%S+)$") or ""
end

-- Build the snippet text based on a token like "tt", "tt15", etc.
local function build_todo_from(prefix)
  local lower = prefix:lower()

  if lower == "tt" then
    return string.format("- [ ] %s ", now_ts())
  end

  local mins = lower:match("^tt(%d+)$")
  if mins then
    return string.format("- [ ] %s ", add_minutes(tonumber(mins)))
  end

  local mh = lower:match("^tt(%d+)h$")
  if mh then
    return string.format("- [ ] %s ", add_minutes(tonumber(mh) * 60))
  end

  if lower == "ttt9" then
    return string.format("- [ ] %s ", tomorrow_at(9, 0))
  end

  return nil
end

-- Create an expr mapping that expands on a chosen key (default: <Space>)
function M.map_timed_todo(bufnr, key)
  bufnr = bufnr or 0
  key = key or "<Space>"

  vim.keymap.set("i", key, function()
    -- Get the last token and see if it matches a snippet trigger
    local prefix = current_prefix()
    local replacement = build_todo_from(prefix)
    if not replacement then
      return key -- pass key through (e.g., normal space)
    end

    -- Delete the token and insert the snippet
    local backspaces = string.rep("<BS>", #prefix)
    return backspaces .. replacement
  end, { buffer = bufnr, expr = true, desc = "Mini-snippet: timed TODO on Space" })
end

return M
