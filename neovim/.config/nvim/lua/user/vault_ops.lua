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

--- Wrap visual selection in [[ ]] and try to link to an existing vault note.
--- If a matching note is found, uses [[note-id|display text]] format.
--- If multiple matches, offers a selection menu.
--- If no match, wraps as bare [[text]] placeholder.
function M.wrap_selection_as_placeholder()
  -- Get visual selection range — marks are set when the keymap fires from visual mode
  local s = vim.fn.getpos("v")
  local e = vim.fn.getpos(".")
  -- Ensure s is before e
  if s[2] > e[2] or (s[2] == e[2] and s[3] > e[3]) then
    s, e = e, s
  end
  -- Exit visual mode after capturing positions
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
  if s[2] ~= e[2] then
    vim.notify("Multi-line placeholder wrap not supported", vim.log.levels.WARN)
    return
  end
  local lnum = s[2]
  local c1, c2 = s[3], e[3]
  local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1]
  if not line then
    vim.notify("Could not read line " .. lnum, vim.log.levels.ERROR)
    return
  end
  local selected_text = line:sub(c1, c2)

  -- Try to find a matching vault note
  local ok, search = pcall(require, "obsidian.search")
  if not ok then
    -- obsidian.nvim not available, just wrap as bare placeholder
    local new = line:sub(1, c1 - 1) .. "[[" .. selected_text .. "]]" .. line:sub(c2 + 1)
    vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, { new })
    return
  end

  local notes = search.resolve_note(selected_text)

  local function apply_link(note_id)
    local link
    if note_id and note_id ~= selected_text then
      link = "[[" .. note_id .. "|" .. selected_text .. "]]"
    else
      link = "[[" .. selected_text .. "]]"
    end
    -- Re-read line in case buffer changed
    local current_line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1]
    local new = current_line:sub(1, c1 - 1) .. link .. current_line:sub(c2 + 1)
    vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, { new })
  end

  -- Always show picker when matches exist — allows choosing "new note" over existing
  if #notes == 0 then
    -- No match — bare placeholder
    apply_link(nil)
  else
    local items = {}
    for _, note in ipairs(notes) do
      table.insert(items, {
        id = tostring(note.id),
        display = tostring(note.id) .. " — " .. (note.title or tostring(note.path)),
      })
    end
    -- Always offer these two alternatives
    table.insert(items, { id = nil, action = "new", display = "Create new note: " .. selected_text })
    table.insert(items, { id = nil, action = "placeholder", display = "[[" .. selected_text .. "]] (bare placeholder)" })

    vim.ui.select(items, {
      prompt = "Link to vault note:",
      format_item = function(item) return item.display end,
    }, function(choice)
      if not choice then return end
      if choice.action == "new" then
        -- Insert bare placeholder, then create note via Obsidian
        apply_link(nil)
        vim.schedule(function()
          vim.cmd("Obsidian new " .. selected_text)
        end)
      else
        apply_link(choice.id)
      end
    end)
  end
end

return M
