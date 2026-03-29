return {
  {
    "3rd/image.nvim",
    optional = true, -- only if you're using LazyVim’s ui.image or have image.nvim installed
    opts = function(_, opts)
      local uv = vim.uv or vim.loop

      local function exists(p)
        if not p or p == "" then
          return false
        end
        return uv.fs_stat(vim.fs.normalize(p)) ~= nil
      end

      local function find_vault_root(start_dir)
        local start = start_dir or vim.fn.expand("%:p:h")
        local hit = vim.fs.find(".obsidian", { upward = true, path = start, type = "directory" })[1]
        if hit then
          return vim.fs.dirname(hit)
        end
      end

      opts = opts or {}
      -- The key piece: resolve Obsidian-style vault-relative paths
      opts.resolve_image_path = function(path, buf)
        if not path or path == "" then
          return path
        end

        -- Expand ~ at the beginning
        if path:sub(1, 1) == "~" then
          path = path:gsub("^~", vim.fn.expand("~"))
        end

        -- Already absolute and exists
        if exists(path) then
          return path
        end

        -- Try relative to buffer directory
        local bufnr = buf or 0
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        local bufdir = vim.fs.dirname(bufname)
        if bufdir and bufdir ~= "" then
          local rel_to_buf = vim.fs.joinpath(bufdir, path)
          if exists(rel_to_buf) then
            return rel_to_buf
          end
        end

        -- Try relative to the Obsidian vault root (detected via ".obsidian")
        local vault = find_vault_root(bufdir)
        if vault then
          -- Direct vault-relative match
          local vault_rel = vim.fs.joinpath(vault, path)
          if exists(vault_rel) then
            return vault_rel
          end

          -- Common Obsidian attachments folders
          local candidates = {
            vim.fs.joinpath(vault, "Assets", "attachments", path),
            vim.fs.joinpath(vault, "assets", "attachments", path),
            vim.fs.joinpath(vault, "Attachments", path),
            vim.fs.joinpath(vault, "attachments", path),
          }
          for _, p in ipairs(candidates) do
            if exists(p) then
              return p
            end
          end
        end

        -- Fallback to original; image.nvim will still try and report if missing
        return path
      end

      return opts
    end,
  },
}
