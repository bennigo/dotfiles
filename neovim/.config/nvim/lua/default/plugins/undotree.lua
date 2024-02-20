return {
  'mbbill/undotree',
  vim.keymap.set('n', '<leader>u', vim.cmd.undotreetoggle),
  vim.cmd [[let g:undotree_splitwidth = 40]],
}

