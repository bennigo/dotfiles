return {
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        {
          "<leader>w",
          nil,
        },
        {
          "<leader>W",
          group = "+windows",
          proxy = "<c-w>",
          expand = function()
            return require("which-key.extras").expand.win()
          end,
        },
        {
          "<leader>o",
          icon = "📓",
          group = "+obsidian",
          expand = function()
            return require("which-key.extras").expand.win()
          end,
        },
      },
    },
  },
}
