-- Markdown specific settings
vim.opt.wrap = true -- Wrap text
vim.opt.breakindent = true -- Match indent on line break
vim.opt.linebreak = true -- Line break on whole words
vim.opt.shiftwidth = 4 -- the number of spaces inserted for each indentation
vim.opt.tabstop = 4 -- insert 4 spaces for a tab
vim.opt.softtabstop = 4

-- Allow j/k when navigating wrapped lines
vim.keymap.set("n", "j", "gj")
vim.keymap.set("n", "k", "gk")

-- Spell check
vim.opt.spelllang = "is,en_us"
vim.opt.spell = true

-- ftplugin/markdown.lua
-- Continue lists when pressing "o" on bullet/numbered/checkbox lines

-- local function continue_list_on_o()
--   local row = vim.api.nvim_win_get_cursor(0)[1] -- 1-based
--   local line = vim.api.nvim_get_current_line()
--
--   -- Detect indent
--   local indent = line:match("^(%s*)") or ""
--   -- Strip indent for easier matching
--   local content = line:sub(#indent + 1)
--
--   -- Match patterns:
--   -- 1) Checkbox bullets: "- [ ] ..." or "* [x] ..." or "+ [ ] ..."
--   local b_bullet, b_state = content:match("^([%-%*%+])%s+%[([xX%s])%]")
--   -- 2) Numbered with checkbox: "1. [ ] ..." or "2) [x] ..."
--   local n_num, n_delim, n_state = content:match("^(%d+)([%.%)])%s+%[([xX%s])%]")
--
--   -- 3) Plain bullets: "- ..." or "* ..." or "+ ..."
--   local p_bullet = content:match("^([%-%*%+])%s+")
--   -- 4) Plain numbered: "1. ..." or "2) ..."
--   local p_num, p_delim = content:match("^(%d+)([%.%)])%s+")
--
--   local new_prefix = nil
--   local insert_col = 0
--
--   if b_bullet then
--     -- New task line with unchecked box by default
--     new_prefix = string.format("%s%s [ ] ", indent, b_bullet)
--     insert_col = #new_prefix
--   elseif n_num then
--     local next_num = tonumber(n_num) + 1
--     new_prefix = string.format("%s%d%s [ ] ", indent, next_num, n_delim)
--     insert_col = #new_prefix
--   elseif p_bullet then
--     new_prefix = string.format("%s%s ", indent, p_bullet)
--     insert_col = #new_prefix
--   elseif p_num then
--     local next_num = tonumber(p_num) + 1
--     new_prefix = string.format("%s%d%s ", indent, next_num, p_delim)
--     insert_col = #new_prefix
--   end
--
--   if not new_prefix then
--     -- Fallback to normal "o"
--     vim.api.nvim_feedkeys("o", "n", false)
--     return
--   end
--
--   -- Insert a new line below with the computed prefix
--   -- Buffer lines are 0-based in set_lines
--   vim.api.nvim_buf_set_lines(0, row, row, true, { new_prefix })
--   -- Move cursor to the start of the insertion point
--   vim.api.nvim_win_set_cursor(0, { row + 1, insert_col })
--   -- Enter insert mode
--   vim.cmd("startinsert")
-- end
--
-- -- Buffer-local mapping for Markdown only
-- vim.keymap.set("n", "o", continue_list_on_o, {
--   buffer = true,
--   desc = "Continue list/bullet on o",
-- })
--
-- -- Optional: combine with obsidian.nvim’s checkbox toggle for convenience [1]
-- vim.keymap.set("n", "<leader>tt", "<cmd>ObsidianToggleCheckbox<CR>", {
--   buffer = true,
--   desc = "Toggle checkbox (obsidian.nvim)",
-- })
