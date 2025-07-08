return {
  enabled = true,
  'mbbill/undotree',
  vim.keymap.set('n', '<leader>u', vim.cmd.UndotreeToggle, { desc = "Toggle [U]ndo Tree" }),
  vim.cmd [[let g:undotree_SplitWidth = 40]],
}
