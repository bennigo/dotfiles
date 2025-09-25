-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- local keymap = vim.keymap.set
-- Shorten function name
local function keymap(mode, lhs, rhs, opts)
  opts = opts or {}
  opts.silent = opts.silent ~= false
  vim.keymap.set(mode, lhs, rhs, opts)
end
local opts = { noremap = true, silent = true }

-- changing default Lazyvim  keymaps because I want <leader>w to save the current buffer
-- changing default Lazyvim  keymaps because I want <leader>w to save the current buffer
vim.keymap.del("n", "<leader>wd")
vim.keymap.del("n", "<leader>wm")
vim.keymap.set("n", "<leader>Wd", "<C-W>c", { desc = "Delete window" })
Snacks.toggle.zoom():map("<leader>Wm")
-- vim.keymap.del("n", "<leader>e")

keymap("n", "<m-m>", "<cmd>Floaterminal<cr>")
keymap({ "t" }, "<m-m>", "<c-\\><c-n><cmd>Floaterminal<cr>")
keymap("t", "<c-\\>", "<c-\\><c-n>")

-- find file keybindings
keymap("n", "<leader>fL", function()
  Snacks.picker.files({ dirs = { "~/work/projects/gps/gpslibrary_new/" }, hidden = false })
end, { desc = "Find GPS library files" })

keymap("n", "<leader>fd", function()
  Snacks.picker.files({ dirs = { "~/.dotfiles/", "~/.config/", "~/.local" }, hidden = true })
  -- LazyVim.pick("files", { dirs = { "~.dotfiles/" }, hidden = true })
end, { desc = "Find dotfile" })

keymap("n", "<leader>fw", function()
  Snacks.picker.files({ dirs = { "~/work/" } })
end, { desc = "find work files" })

-- search string keybindings
keymap("n", "<leader>sL", function()
  Snacks.picker.grep({ dirs = { "~/work/projects/gps/gpslibrary_new/" }, hidden = false })
end, { desc = "grep GPS library files" })

keymap("n", "<leader>so", function()
  Snacks.picker.grep({ dirs = { "~/.dotfiles/", "~/.config/", "~/.local" }, hidden = true })
  -- LazyVim.pick("files", { dirs = { "~.dotfiles/" }, hidden = true })
end, { desc = "grep dotfile" })

keymap("n", "<leader>sO", function()
  Snacks.picker.grep({ dirs = { "~/work/, ~/work/projects/" }, hidden = false })
  -- LazyVim.pick("files", { dirs = { "~.dotfiles/" }, hidden = true })
end, { desc = "grep workfiles" })

-- Toggle transparency
keymap("n", "<leader>uo", function()
  local cat = require("catppuccin")
  cat.options.transparent_background = not cat.options.transparent_background
  cat.compile()
  vim.cmd.colorscheme(vim.g.colors_name)
end, { desc = "Toggle transparency" })

keymap("n", "<leader>uN", function()
  local noice = require("noice")
  if require("noice.config")._running then
    noice.cmd("disable")
  else
    noice.cmd("enable")
  end
end, { desc = "Toggle noice" })
-- ====================================================================

keymap({ "v", "i" }, "jk", "<ESC>", opts) -- Press jk fast to enter
keymap({ "i", "x", "n", "s", "v" }, "<m-w>", "<cmd>w!<cr><esc>", { desc = "Save file" })
keymap("n", "<leader>w", "<cmd>w<cr>", { desc = "Save file" })
-- keymap({ "n", "v" }, "<leader>w", "<cmd>w!<CR>")

keymap("n", "<leader>r", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Replace word under cursor" })

-- keymap("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
-- keymap("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

keymap("n", "<leader><CR>", function()
  vim.cmd("so %")
end, { desc = "Source file" })

keymap("n", "J", "mzJ`z")
keymap("n", "<C-d>", "<C-d>zz")
keymap("n", "<C-u>", "<C-u>zz")
keymap("n", "N", "Nzzzv")
keymap("n", "n", "nzzzv")
keymap("n", "*", "*zz", opts)
keymap("n", "#", "#zz", opts)
keymap("n", "g*", "g*zz", opts)
keymap("n", "g#", "g#zz", opts)
keymap("i", "<BS>", "<C-h>")

-- keymap("n", "Q", "<nop>")
keymap("n", "Q", "<cmd>ccl<CR>zz")
-- keymap("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")
-- keymap("n", "<C-k>", "<cmd>cnext<CR>zz")
-- keymap("n", "<C-j>", "<cmd>cprev<CR>zz")
-- keymap("n", "<leader>k", "<cmd>lnext<CR>zz")
-- keymap("n", "<leader>j", "<cmd>lprev<CR>zz")
-- keymap("n", "TT", "<cmd>TransparentToggle<CR>")

vim.keymap.del("n", "<C-s>") -- I need <C-s> for incremneting due to <C-a> is my tmux key
keymap("n", "<C-s>", "<C-a>")
keymap("n", "<C-x>", "<C-x>")

keymap("n", "<m-tab>", "<c-6>", opts)

keymap("n", "<m-q>", "<cmd>bdelete<CR>", opts)
keymap("n", "<leader>F", vim.lsp.buf.format, { desc = "Format" })

-- Diagnostic keymaps
-- keymap("n", "[d", function()
-- 	vim.diagnostic.jump({ count = -1, float = true })
-- end, { desc = "Go to previous diagnostic message" })
--
-- keymap("n", "]d", function()
-- 	vim.diagnostic.jump({ count = 1, float = true })
-- end, { desc = "Go to next diagnostic message" })
keymap("n", "gl", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
-- keymap("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })

-- next greatest remap ever : asbjornHaland
keymap("n", "<leader>Y", [["+Y]])
keymap({ "n", "v" }, "<leader>y", [["+y]])
keymap({ "n", "v" }, "<leader>d", [["_d]])

-- Insert --
keymap({ "v", "i" }, "jk", "<ESC>", opts) -- Press jk fast to enter
-- keymap('i', '<C-c>', '<Esc>')             -- This is going to get me cancelled

-- Visual --
-- Stay in indent mode
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- Move text up and down
keymap("v", "J", ":m '>+1<CR>gv=gv")
keymap("v", "K", ":m '<-2<CR>gv=gv")

-- greatest remap ever
-- keymap('x', '<leader>p', [["_dP]])
keymap("x", "p", [["_dP]])
keymap("n", "<leader>X", "<cmd>!chmod +x %<CR>", { silent = true })

-- Mermaid diagram preview with Zathura
keymap("n", "<leader>mp", function()
  local file = vim.api.nvim_buf_get_name(0)
  if not file:match('%.mmd$') then
    vim.notify("Not a Mermaid file", vim.log.levels.WARN)
    return
  end

  local pdf_file = file:gsub('%.mmd$', '.pdf')

  -- Check if PDF exists, if not generate it first
  if vim.fn.filereadable(pdf_file) == 0 then
    vim.notify("Generating PDF first...", vim.log.levels.INFO)
    vim.fn.system('mmdc -i "' .. file .. '" -o "' .. pdf_file .. '" -t default -b white -f -p ~/.config/mermaid-puppeteer.json')
  end

  -- Open with zathura in background
  vim.fn.jobstart({'zathura', pdf_file}, { detach = true })
  vim.notify("Opened: " .. vim.fn.fnamemodify(pdf_file, ':t'), vim.log.levels.INFO)
end, { desc = "Preview Mermaid PDF with Zathura" })
