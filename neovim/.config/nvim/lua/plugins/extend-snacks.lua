return {
  "folke/snacks.nvim",
  enabled = true,
  opts = function(_, opts)
    local uv = vim.uv or vim.loop

    -- Obsidian vault-relative image resolver (ported from image.lua)
    local function find_vault_root(start_dir)
      local hit = vim.fs.find(".obsidian", { upward = true, path = start_dir, type = "directory" })[1]
      if hit then
        return vim.fs.dirname(hit)
      end
    end

    local function resolve_obsidian_image(file, src)
      if not src or src == "" or src:find("^%w%w+://") then
        return nil
      end
      local bufdir = vim.fs.dirname(file)
      local vault = find_vault_root(bufdir)
      if not vault then
        return nil
      end
      local candidates = {
        vault .. "/" .. src,
        vault .. "/Assets/charts/" .. src,
        vault .. "/Assets/attachments/" .. src,
        vault .. "/Assets/" .. src,
        vault .. "/Attachments/" .. src,
      }
      for _, p in ipairs(candidates) do
        if uv.fs_stat(p) then
          return p
        end
      end
      return nil
    end

    local final_opts = vim.tbl_deep_extend("force", {
      image = {
        enabled = true,
        show = true, -- Show images inline
        resolve = resolve_obsidian_image,
        doc = {
          inline = false, -- virtual lines cause cursor jitter
          float = true,   -- floating windows instead
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
