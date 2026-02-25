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

--- Copy text to system clipboard and open/focus the Claude Code terminal.
--- The user pastes manually (Ctrl+Shift+V) because PTY injection is unreliable
--- with TUI frameworks like Ink/React that power Claude Code.
---@param text string The prompt text to copy and paste into Claude
function M.send_to_claude_terminal(text)
  local ok, terminal = pcall(require, "claudecode.terminal")
  if not ok then
    vim.notify("claudecode.nvim not available", vim.log.levels.ERROR)
    return
  end
  vim.fn.setreg("+", text)
  terminal.open()
  vim.notify("Copied to clipboard — paste with Ctrl+Shift+V", vim.log.levels.INFO)
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
