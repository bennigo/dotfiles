return {
  {
    "barreiroleo/ltex_extra.nvim",
    dependencies = { "neovim/nvim-lspconfig" },
  },

  {
    "R-nvim/cmp-r",
    {
      "hrsh7th/nvim-cmp",
      config = function()
        require("cmp").setup({ sources = { { name = "cmp_r" } } })
        require("cmp_r").setup({})
      end,
    },
  },

  {
    "fladson/vim-kitty",
    ft = "kitty",
  },
}
