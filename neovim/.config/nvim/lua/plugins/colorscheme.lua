return {
  -- Extend LazyVim's catppuccin config with custom opts
  {
    "catppuccin/nvim",
    opts = function(_, opts)
      -- Extend LazyVim's opts with our customizations
      opts.transparent_background = true
      opts.treesitter = true
      return opts
    end,
  },

  {
    "folke/tokyonight.nvim",
    opts = {
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
    },
  },

  -- add gruvbox
  { "ellisonleao/gruvbox.nvim" },

  -- Configure LazyVim to load catppuccin
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin-mocha",
    },
  },
}
