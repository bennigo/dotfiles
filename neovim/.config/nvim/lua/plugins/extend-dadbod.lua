return {
  "kristijanhusak/vim-dadbod-ui",
  enabled = true,
  cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
  dependencies = "vim-dadbod",
  keys = {
    { "<leader>Dt", "<cmd>DBUIToggle<CR>", desc = "DBUI: toggle" },
    -- (A) Save the current DBUI query buffer as a named "Saved query".
    --     Avoids the <leader>W conflict with the window-command prefix.
    --     Only does anything inside a dadbod-managed query buffer.
    {
      "<leader>Dw",
      function()
        local keys = vim.api.nvim_replace_termcodes("<Plug>(DBUI_SaveQuery)", true, false, true)
        vim.api.nvim_feedkeys(keys, "m", false)
      end,
      desc = "DBUI: save query (named)",
    },
    -- (B) Bind ANY sql buffer (e.g. a project sql/*.sql file) to a connection
    --     by picking from the DBUI connection list. Sets b:db so :DB / <leader>Dr work.
    {
      "<leader>Db",
      function()
        local ok, conns = pcall(vim.fn["db_ui#connections_list"])
        if not ok or vim.tbl_isempty(conns) then
          vim.notify("No DBUI connections found (add one via :DBUIAddConnection)", vim.log.levels.WARN)
          return
        end
        vim.ui.select(conns, {
          prompt = "Bind buffer to connection:",
          format_item = function(c)
            return string.format("%s  [%s]%s", c.name, c.source, c.is_connected == 1 and " (connected)" or "")
          end,
        }, function(choice)
          if not choice then
            return
          end
          vim.b.db = choice.url
          vim.notify("Bound buffer to " .. choice.name .. "  (run with <leader>Dr)", vim.log.levels.INFO)
        end)
      end,
      desc = "DBUI: bind connection to buffer",
    },
    -- Run the query against the bound connection (b:db). Normal = whole file,
    -- Visual = just the selection. Explicit (not on-save) to avoid hammering
    -- production on every :w for a version-controlled file.
    { "<leader>Dr", "<cmd>%DB<CR>", desc = "DBUI: run buffer against b:db" },
    { "<leader>Dr", ":DB<CR>", mode = "v", desc = "DBUI: run selection against b:db" },
  },
  init = function()
    local data_path = vim.fn.stdpath("config")

    vim.g.db_ui_auto_execute_table_helpers = 1
    vim.g.db_ui_save_location = data_path .. "/db_ui"
    vim.g.db_ui_show_database_icon = true
    vim.g.db_ui_tmp_query_location = data_path .. "/db_ui/tmp"
    vim.g.db_ui_use_nerd_fonts = true
    vim.g.db_ui_use_nvim_notify = true

    vim.g.db_ui_execute_on_save = true
  end,
}
