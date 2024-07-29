return {
  enabled = true,
  'stevearc/conform.nvim',
  event = { 'BufReadPre', 'BufNewFile' },

  config = function()
    local conform = require("conform")

    conform.setup({
      formatters_by_ft = {
        python = { 'isort', 'black'},
        javascript = { 'prettier' },
        json = { 'prettier' },
        yaml = { 'prettier' },
        markdown = { 'prettier' },
        lua = { 'stylua' },
        toml = { 'toml' },
      },
      format_on_save = false,
      lsp_fallback = true,
      async = false,
      timout_ms = 1000,
      formatters = {
        black = {
          prepend_args = { '--fast' },
        },
      },
    })


    vim.keymap.set({ 'n', 'v' }, '<leader>F', function()
      conform.format {
        lsp_fallback = true,
        async = false,
        timout_ms = 500,
      }
    end, { desc = '[F]ormat field or range (in visual mode)' })
  end,
}
