return {
  "folke/snacks.nvim",
  enabled = true,
  opts = function(_, opts)
    local final_opts = vim.tbl_deep_extend("force", {
      image = {
        enabled = true,
        show = true, -- Show images inline
        -- Make images more persistent across window changes
        opts = {
          -- Configure virtual text behavior
          virt_text_pos = "inline",
        },
        convert = {
          mermaid = function()
            local theme = vim.o.background == "light" and "neutral" or "dark"
            -- Create puppeteer config file for --no-sandbox
            local config_file = "/tmp/puppeteer-config.json"
            local config_content = '{"args":["--no-sandbox"]}'
            local file = io.open(config_file, "w")
            if file then
              file:write(config_content)
              file:close()
            end
            return {
              "-p", config_file, -- Use puppeteer config file
              "-i", "{src}",
              "-o", "{file}",
              "-b", "transparent",
              "-t", theme,
              "-s", "{scale}"
            }
          end
        },
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
