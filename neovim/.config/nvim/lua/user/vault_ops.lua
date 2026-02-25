-- File: lua/user/vault_ops.lua
-- Purpose: Bridge neovim vault editing with Claude Code terminal.
-- Provides: wikilink extraction, placeholder wrapping, and terminal send.

local M = {}

--- Extract [[wikilink]] text under cursor.
--- For [[file|display]] format, returns the display text
--- (placeholders use human-readable names).
--- Returns nil if cursor is not inside a wikilink.
function M.get_wikilink_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1 -- 1-indexed
  local pos = 1
  while true do
    local s, e = line:find("%[%[(.-)%]%]", pos)
    if not s then break end
    if col >= s and col <= e then
      local text = line:sub(s + 2, e - 2)
      local pipe = text:find("|")
      if pipe then text = text:sub(pipe + 1) end
      return text
    end
    pos = e + 1
  end
  return nil
end

--- Send text to a terminal channel, then submit with Enter after a short delay.
--- Splitting text and Enter avoids TUI frameworks (Ink) swallowing the
--- carriage return when it arrives in the same data chunk as the text.
---@param chan number terminal channel id
---@param text string text to type (without trailing newline/CR)
local function send_and_submit(chan, text)
  vim.fn.chansend(chan, text)
  vim.defer_fn(function()
    vim.fn.chansend(chan, "\r")
  end, 50)
end

--- Send arbitrary text to the Claude Code terminal and submit it.
--- Opens the terminal if not already running, with a deferred send.
---@param text string The prompt text to send (should NOT include trailing \n or \r)
function M.send_to_claude_terminal(text)
  local ok, terminal = pcall(require, "claudecode.terminal")
  if not ok then
    vim.notify("claudecode.nvim not available", vim.log.levels.ERROR)
    return
  end
  local bufnr = terminal.get_active_terminal_bufnr()
  if bufnr then
    local chan = vim.bo[bufnr].channel
    send_and_submit(chan, text)
    terminal.ensure_visible()
  else
    terminal.open()
    vim.defer_fn(function()
      local new_bufnr = terminal.get_active_terminal_bufnr()
      if new_bufnr then
        local chan = vim.bo[new_bufnr].channel
        send_and_submit(chan, text)
      else
        vim.notify("Could not find Claude terminal after opening", vim.log.levels.WARN)
      end
    end, 800)
  end
end

--- Wrap visual selection in [[ ]] (single-line only).
function M.wrap_selection_as_placeholder()
  vim.cmd("normal! \\27") -- exit visual mode to set '< '> marks
  local s = vim.fn.getpos("'<")
  local e = vim.fn.getpos("'>")
  if s[2] ~= e[2] then
    vim.notify("Multi-line placeholder wrap not supported", vim.log.levels.WARN)
    return
  end
  local lnum = s[2]
  local c1, c2 = s[3], e[3]
  local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1]
  local new = line:sub(1, c1 - 1) .. "[[" .. line:sub(c1, c2) .. "]]" .. line:sub(c2 + 1)
  vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, { new })
end

return M
