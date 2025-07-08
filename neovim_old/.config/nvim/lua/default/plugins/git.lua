return {
  -- Git related plugins
  'tpope/vim-fugitive',
  'tpope/vim-rhubarb',

  vim.keymap.set('n', '<leader>gs', vim.cmd.Git),
}

