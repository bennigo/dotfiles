-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
--

local options = {
  -- hlsearch = false, -- highlight all matches on previous search pattern
  incsearch = true,
  --
  number = true, -- set numbered lines
  relativenumber = true, -- set relative numbered lines
  --
  mouse = "a", -- allow the mouse to be used in neovim
  --
  -- shiftwidth = 4, -- the number of spaces inserted for each indentation
  -- tabstop = 4, -- insert 2 spaces for a tab
  --
  -- clipboard = "", -- Sync clipboard between OS and Neovim. See `:help 'clipboard'`
  -- breakindent = true, -- Enable break indent
  -- ignorecase = true, -- ignore case in search patterns
  -- smartcase = true, -- smart case
  -- signcolumn = "yes", -- always show the sign column, otherwise it would shift the text each time
  -- updatetime = 250, -- faster completion (4000ms default)
  -- timeout = true,
  -- timeoutlen = 300,
  -- completeopt = { "menuone", "noselect" }, -- mostly just for cmp
  -- termguicolors = true, -- NOTE You should make sure your terminal supports this
  -- cmdheight = 0, -- more space in the neovim command line for displaying messages
  -- conceallevel = 2, -- so that `` is visible in markdown files
  -- fileencoding = "utf-8", -- the encoding written to a file
  -- pumheight = 10, -- pop up menu height
  -- showtabline = 4, -- always show tabs
  -- smartindent = true, -- make indenting smarter again
  -- splitbelow = true, -- force all horizontal splits to go below current window
  -- splitright = true, -- force all vertical splits to go to the right of current window
  -- swapfile = false, -- creates a swapfile
  -- undodir = os.getenv("HOME") .. "/.local/nvim/undodir",
  -- undofile = true, -- Save undo history
  -- backup = false, -- creates a backup file
  -- writebackup = false, -- if a file is being edited by another program (or was written to file while editing with another program), it is not allowed to be edited
  -- expandtab = true, -- convert tabs to spaces
  -- cursorline = true, -- highlight the current line
  -- numberwidth = 2, -- set number column width to 2 {default 4}
  -- wrap = false, -- display lines as one long line
  scrolloff = 20, -- is one of my fav
  sidescrolloff = 8,
  -- guifont = "monospace:h17", -- the font used in graphical neovim applications
  -- virtualedit = "block",
  -- inccommand = "split",
}

for k, v in pairs(options) do
  vim.opt[k] = v
end

vim.wo.colorcolumn = "80"
vim.opt.shortmess:append("c")
vim.opt.spell = true
vim.opt.spelllang = "is,en_us"

-- Set ZDOTDIR so zsh finds .zshrc in non-standard location
vim.env.ZDOTDIR = vim.env.HOME .. "/.config/zsh"

-- Configure shell (conda environment is handled via TermOpen autocmd)
vim.opt.shell = "/bin/zsh"
-- Keep default shellcmdflag to avoid zle errors

-- vim.cmd "set whichwrap+=<,>,[,],h,l"
vim.cmd([[set iskeyword+=-]])
