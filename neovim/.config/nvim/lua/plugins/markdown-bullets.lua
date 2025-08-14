-- lua/plugins/markdown-bullets.lua
return {
  {
    -- Widely used for better Markdown bullets/numbered lists in LazyVim setups [0][4]
    "bullets-vim/bullets.vim",
    ft = { "markdown", "text" },
    init = function()
      -- Restrict bullets.vim to relevant filetypes
      vim.g.bullets_enabled_file_types = { "markdown", "text" }
      -- You can tweak plugin behavior here as needed; defaults already handle list continuation
      -- For example:
      -- vim.g.bullets_set_mappings = 1
    end,
  },
}
