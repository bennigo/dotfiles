return {
  "folke/snacks.nvim",
  enabled = true,
  opts = function(_, opts)
    local final_opts = vim.tbl_deep_extend("force", {
      image = {
        enabled = true,
      },
    }, opts)

    table.insert(final_opts.dashboard.preset.keys, 7, {
      icon = "S",
      key = "S",
      desc = "Select Session",
      action = require("persistence").select,
    })

    return final_opts
  end,
  keys = {
    { "<leader>e", false },
  },
}
