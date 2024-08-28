-- [[ Basic Keymaps ]]
-- Keymaps for better default experience
-- See `:help keymap()`

-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

local opts = { noremap = true, silent = true }
-- local term_opts = { silent = true }

-- Shorten function name
local keymap = vim.keymap.set

keymap({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Modes
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",

-- keymap("n", "<leader>e", ":Lex 30<cr>", opts)
-- Nvimtree
-- keymap("n", "<leader>e", ":NvimTreeToggle<cr>", opts)
-- keymap("n", "<leader>pv", vim.cmd.Ex)

keymap('n', '<leader>r', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- keymap("n", "<leader>vpp", "<cmd>e ~/.dotfiles/nvim/.config/nvim/lua/theprimeagen/packer.lua<CR>");
-- keymap("n", "<leader>mr", "<cmd>CellularAutomaton make_it_rain<CR>");

keymap('n', '<leader><CR>', function()
  vim.cmd 'so'
end)

keymap('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
keymap('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

keymap('n', 'J', 'mzJ`z')
keymap('n', '<C-d>', '<C-d>zz')
keymap('n', '<C-u>', '<C-u>zz')
keymap('n', 'N', 'Nzzzv')
keymap('n', 'n', 'nzzzv')
keymap('n', '*', '*zz', opts)
keymap('n', '#', '#zz', opts)
keymap('n', 'g*', 'g*zz', opts)
keymap('n', 'g#', 'g#zz', opts)

---------------
keymap('n', 'Q', '<nop>')
keymap('n', '<C-f>', '<cmd>silent !tmux neww tmux-sessionizer<CR>')

keymap('n', '<C-k>', '<cmd>cnext<CR>zz')
keymap('n', '<C-j>', '<cmd>cprev<CR>zz')
keymap('n', 'q', '<cmd>ccl<CR>zz')
keymap('n', '<leader>k', '<cmd>lnext<CR>zz')
keymap('n', '<leader>j', '<cmd>lprev<CR>zz')
keymap('n', '<leader>t', '<cmd>TransparentToggle<CR>')
keymap('n',  '<C-s>', '<C-a>')
keymap('n',  '<C-x>', '<C-x>')

-- Better window navigation
-- keymap("n", "<tab-h>", "<C-w>h", opts)
-- keymap("n", "<tab-j>", "<C-w>j", opts)
-- keymap("n", "<tab-k>", "<C-w>k", opts)
-- keymap("n", "<mtab-l>", "<C-w>l", opts)
keymap('n', '<m-tab>', '<c-6>', opts)

keymap('n', '<m-q>', '<cmd>bdelete!<CR>', opts)
-- Remap for dealing with word wrap

keymap('n', '<leader>F', vim.lsp.buf.format)
-- Diagnostic keymaps
keymap('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
keymap('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
keymap('n', 'gl', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
keymap('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

-- next greatest remap ever : asbjornHaland
keymap('n', '<leader>Y', [["+Y]])
keymap({ 'n', 'v' }, '<leader>y', [["+y]])
keymap({ 'n', 'v' }, '<leader>d', [["_d]])
keymap({ 'n', 'v' }, '<leader>w', '<cmd>w!<CR>')

-- Insert --
keymap({ 'v', 'i' }, 'jk', '<ESC>', opts) -- Press jk fast to enter
keymap('i', '<C-c>', '<Esc>')             -- This is going to get me cancelled

-- Visual --
-- Stay in indent mode
keymap('v', '<', '<gv', opts)
keymap('v', '>', '>gv', opts)

-- Move text up and down
keymap('v', 'J', ":m '>+1<CR>gv=gv")
keymap('v', 'K', ":m '<-2<CR>gv=gv")
-- greatest remap ever
keymap('x', '<leader>p', [["_dP]])
keymap('n', '<leader>x', '<cmd>!chmod +x %<CR>', { silent = true })
