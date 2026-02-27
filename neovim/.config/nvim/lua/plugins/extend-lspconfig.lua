local vault_dir = vim.fn.expand("~/notes/bgovault")

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        virtual_text = false,
      },
      servers = {
        marksman = {
          -- Disable marksman inside the Obsidian vault where obsidian-ls
          -- handles gd/references/rename for wikilinks. Marksman stays
          -- active for markdown files in other projects.
          root_dir = function(bufnr)
            local fname = vim.api.nvim_buf_get_name(bufnr)
            if fname:find(vault_dir, 1, true) then
              return nil
            end
            return require("lspconfig.util").root_pattern(".marksman.toml", ".git")(fname)
          end,
        },
      },
    },
  },
}
