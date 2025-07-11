return {
  "folke/snacks.nvim",
  enable = true,
  opts = function(_, opts)
    table.insert(
      opts.dashboard.preset.keys,
      7,
      { icon = "S", key = "S", desc = "Select Session", action = require("persistence").select }
    )
  end,
  keys = {
    { "<leader>e", false },
  },
}
