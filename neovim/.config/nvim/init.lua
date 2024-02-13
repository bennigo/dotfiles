require("default.config")
require("default.lazy")


-- vim.api.nvim_create_autocmd("BufEnter", {
--     callback = function()
--         vim.lsp.start({
--            name = 'clangd',
--            cmd = {'clangd'},
--            root_dir = vim.fn.getcwd(),
--         })
--     end,
-- })
