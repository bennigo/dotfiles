-- File: lua/user/obsidian_helpers.lua
-- Purpose: Helpers for obsidian.nvim (slugify, title generation, and command wrappers).
-- Note: Namespaced under "user" to avoid colliding with the plugin's "obsidian" module.

local M = {}
local Obsidian = require("obsidian.search")
local files = Obsidian.build_find_cmd("/home/bgo/notes/bgovault/Templates/")

vim.notify(files, vim.log.levels.DEBUG, { title = "Obsidian: " })

-- Simple, ASCII-oriented slugify
function M.slugify(str)
  str = string.lower(str or "")
  str = str:gsub("[^%w]+", "-")
  str = str:gsub("%-+", "-")
  str = str:gsub("^%-", ""):gsub("%-$", "")
  return str
end

-- Timestamped title: "YYYY-MM-DD-HHMMSS[-suffix]"
function M.gen_title(opts)
  opts = opts or {}
  local date = os.date("%Y-%m-%d-%H%M%S")
  local suffix = opts.suffix and M.slugify(opts.suffix) or nil
  if suffix and #suffix > 0 then
    return ("%s-%s"):format(date, suffix)
  else
    return date
  end
end

-- Daily-style title: "YYYY-MM-DD[-suffix]"
function M.gen_daily_title(opts)
  opts = opts or {}
  local date = os.date("%Y-%m-%d")
  local suffix = opts.suffix and M.slugify(opts.suffix) or nil
  if suffix and #suffix > 0 then
    return ("%s-%s"):format(date, suffix)
  else
    return date
  end
end

-- Wrapper to create a note and apply a template.
-- If args.template is provided, we call:
--   :ObsidianNewFromTemplate <template> <title>
-- Otherwise we do a two-step:
--   :ObsidianNew <title>  -> opens the new note
--   :ObsidianTemplate     -> opens picker to insert a template
-- args = { suffix = string|nil, mode = "timestamp" | "daily" | nil, template = string|nil }
function M.new_from_template_auto(args)
  args = args or {}
  local mode = args.mode or "timestamp"
  local suffix = args.suffix
  local template = args.template

  local title
  if mode == "daily" then
    title = M.gen_daily_title({ suffix = suffix })
  else
    title = M.gen_title({ suffix = suffix })
  end

  if template and #template > 0 then
    vim.notify(vim.inspect(template), vim.log.levels.DEBUG, { title = "Using template: " })
    vim.notify(vim.inspect(title), vim.log.levels.DEBUG, { title = "Using template: " })
    vim.notify(
      string.format("ObsidianNewFromTemplate %s %s", title, template),
      vim.log.levels.DEBUG,
      { title = "Using template: " }
    )
    -- Pass template first, then title.
    vim.cmd(string.format("ObsidianNewFromTemplate %s %s", vim.fn.shellescape(title), template))
  else
    -- Keep the picker by using New + Template
    vim.cmd(string.format("ObsidianNew %s", vim.fn.shellescape(title)))
    -- Insert template via picker into the newly created note
    vim.cmd("ObsidianTemplate")
  end
end

return M
