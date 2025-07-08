return {
    "jvdmeulen/json-fold.nvim",
    enabled = false,
    config = function()
        require('json-fold').setup()

        -- keybinding for the min (un-)fold actions
        vim.api.nvim_set_keymap('n', '<leader>Jc', ':JsonFoldFromCursor<CR>', { noremap = true, silent = true })
        vim.api.nvim_set_keymap('n', '<leader>Jd', ':JsonUnfoldFromCursor<CR>', { noremap = true, silent = true })

        -- keybinding for the max (un-)fold actions
        vim.api.nvim_set_keymap('n', '<leader>JC', ':JsonMaxFoldFromCursor<CR>', { noremap = true, silent = true })
        vim.api.nvim_set_keymap('n', '<leader>JD', ':JsonMaxUnfoldFromCursor<CR>', { noremap = true, silent = true })
 end
}
