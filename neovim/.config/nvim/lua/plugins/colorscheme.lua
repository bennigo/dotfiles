return {
  -- Extend LazyVim's catppuccin config with custom opts
  {
    "catppuccin/nvim",
    opts = function(_, opts)
      -- Extend LazyVim's opts with our customizations
      if vim.g.transparent_background == nil then
        vim.g.transparent_background = true
      end
      opts.transparent_background = vim.g.transparent_background
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
