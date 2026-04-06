return {
  -- Extend LazyVim's catppuccin config with custom opts
  {
    "catppuccin/nvim",
    opts = function(_, opts)
      -- Extend LazyVim's opts with our customizations
      opts.transparent_background = true
      opts.treesitter = true

      -- Custom highlight overrides for transparency
      opts.custom_highlights = function(colors)
        return {
          -- Make floating windows transparent
          NormalFloat = { bg = "NONE" },
          FloatBorder = { bg = "NONE" },
          -- Terminal transparency
          NormalTerm = { bg = "NONE" },
          TermCursor = { bg = colors.sky, fg = colors.base },
        }
      end

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
