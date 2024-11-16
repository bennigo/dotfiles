return {
  "roobert/surround-ui.nvim",
  enabled=true,
  dependencies = {
    "kylechui/nvim-surround",
    "folke/which-key.nvim",
  },
  config = function()
    require("surround-ui").setup({
      root_key = "S",
    })
  end,
}
