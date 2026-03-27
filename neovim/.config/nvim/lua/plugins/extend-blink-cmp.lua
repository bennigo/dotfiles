-- extend-blink-cmp.lua
-- Custom <CR> keymap for blink.cmp: dagbok timestamp continuation
-- Inserts our dagbok logic before the default accept/fallback chain.
return {
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        ["<CR>"] = {
          function(cmp)
            -- If completion menu is visible, accept normally
            if cmp.is_visible() then
              return cmp.accept()
            end

            -- Dagbok timestamp logic — only in markdown files
            if vim.bo.filetype ~= "markdown" then
              return -- fall through to next in chain
            end

            local line = vim.api.nvim_get_current_line()

            -- Empty dagbok line (offramp): "- HH:MM" or "- HH:MM —" with no text
            if line:match("^%s*%- %d%d:%d%d%s*$") or line:match("^%s*%- %d%d:%d%d %—%s*$") then
              vim.api.nvim_set_current_line("")
              return true
            end

            -- Dagbok line with content: create new timestamped line below
            if line:match("^%s*%- %d%d:%d%d") then
              local indent = line:match("^(%s*)") or ""
              local time = os.date("%H:%M")
              local new_text = indent .. "- " .. time .. " — "
              local row = vim.api.nvim_win_get_cursor(0)[1]
              vim.schedule(function()
                vim.api.nvim_buf_set_lines(0, row, row, true, { new_text })
                vim.api.nvim_win_set_cursor(0, { row + 1, #new_text })
                vim.cmd("startinsert!")
              end)
              return true
            end

            -- Not a dagbok line — fall through to accept/fallback
          end,
          "accept",
          "fallback",
        },
      },
    },
  },
}
