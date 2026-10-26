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

    local found_cache = {} -- recursive Assets/ lookups, keyed by vault + src

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
        vault .. "/Assets/diagrams/" .. src,
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
      -- Obsidian resolves ![[name.png]] anywhere in the vault; search Assets/ recursively
      -- (e.g. Assets/charts/ki_tolfraedi/). Assets is a symlink, so search its real path.
      local key = vault .. "\0" .. src
      if found_cache[key] == nil then
        local assets = uv.fs_realpath(vault .. "/Assets")
        local hit = assets
          and vim.fs.find(vim.fs.basename(src), { path = assets, type = "file", limit = 1 })[1]
        found_cache[key] = hit or false
      end
      return found_cache[key] or nil
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
          magick = {
            -- snacks' pdf default has no size cap: a tall matplotlib page
            -- (gpsplot stack, ~11x17 in) became 2046x3277 px at 192 dpi and the
            -- hover float stayed empty; cap it like snacks' raster default
            pdf = { "-density", 192, "{src}[{page}]", "-background", "white",
                    "-alpha", "remove", "-trim", "-scale", "1920x1080>" },
          },
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
