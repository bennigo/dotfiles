-- after/ftplugin/markdown.lua
-- Smart Dagbok timestamp continuation for normal mode `o`.
-- Runs AFTER bullets.vim sets its mappings, so our override sticks.
-- Insert mode <CR> is handled by extend-blink-cmp.lua (blink.cmp owns <CR>).
--
-- Behavior:
--   On a "- HH:MM" or "- HH:MM — text" line:
--     o → new "- HH:MM — " with current time
--   On any other line:
--     Delegates to bullets.vim <Plug>(bullets-newline)

local function is_dagbok_line(line)
  return line:match("^%s*%- %d%d:%d%d") ~= nil
end

vim.keymap.set("n", "o", function()
  local line = vim.api.nvim_get_current_line()

  if is_dagbok_line(line) then
    local indent = line:match("^(%s*)") or ""
    local time = os.date("%H:%M")
    local new_text = indent .. "- " .. time .. " — "
    local row = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_set_lines(0, row, row, true, { new_text })
    vim.api.nvim_win_set_cursor(0, { row + 1, #new_text })
    vim.cmd("startinsert!")
    return
  end

  local key = vim.api.nvim_replace_termcodes("<Plug>(bullets-newline)", true, false, true)
  vim.api.nvim_feedkeys(key, "n", false)
end, { buffer = true, desc = "Smart Dagbok timestamp or bullets.vim o" })
