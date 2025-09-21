return {
  {
    "catppuccin/nvim",
    version = "*", -- recommended, use latest release instead of latest commit
    lazy = true,
    name = "catppuccin",
    opts = function(_, opts)
      -- Official LazyVim fix for bufferline integration
      local module = require("catppuccin.groups.integrations.bufferline")
      if module then
        module.get_theme = module.get -- Compatibility layer for LazyVim
      end
      return {
        transparent_background = true,
        treesitter = true,
      }
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

  -- Configure LazyVim to load gruvbox
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin-mocha",
    },
  },
}
