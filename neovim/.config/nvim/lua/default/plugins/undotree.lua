return {
  enabled = true,
  'mbbill/undotree',
  vim.keymap.set('n', '<leader>u', vim.cmd.UndotreeToggle),
  vim.cmd [[let g:undotree_SplitWidth = 40]],
}
