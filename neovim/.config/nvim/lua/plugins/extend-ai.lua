return {
  -- Add Claude Code integration to AI ecosystem
  {
    "coder/claudecode.nvim",
    enabled = true,
    event = "VeryLazy",
    config = function()
      require("claudecode").setup({
        -- Optional: Configure Claude Code settings here
        -- server_address = "127.0.0.1:8080", -- Default WebSocket server address
        -- auto_start_server = true, -- Automatically start the WebSocket server
        terminal = {
          -- Split window configuration (commented out)
          -- split_side = "right",
          -- split_width_percentage = 0.47,

          -- Floating window configuration (active)
          snacks_win_opts = {
            position = "float",
            width = 0.85, -- 85% of screen width
            height = 0.9, -- 90% of screen height
            border = "rounded",
          },
        },
        -- Diff configuration to prevent focus stealing
        diff_opts = {
          auto_close_on_accept = true,
          vertical_split = true,
          open_in_current_tab = true,
          keep_terminal_focus = true, -- Keep focus in Claude window
        },
      })

      -- Simple toggle function that just works
      vim.keymap.set({ "n", "i", "t" }, "<M-c>", "<cmd>ClaudeCodeFocus<cr>", { desc = "Toggle Claude Code" })
      
      -- Fallback: Quick return to Claude window (useful if diff steals focus)
      vim.keymap.set({ "n", "i" }, "<C-M-c>", "<cmd>ClaudeCodeFocus<cr>", { desc = "Return to Claude Code" })
    end,
    keys = {
      -- Universal Claude Code toggle that works in all modes
      { "<M-c>", "<cmd>ClaudeCodeFocus<cr>", desc = "Toggle Claude Code", mode = { "n", "i", "t" } },
    },
  },

  -- Extend which-key AI group to include Claude Code mappings
  {
    "folke/which-key.nvim",
    opts = function(_, opts)
      local spec = opts.spec or {}

      -- Add Claude Code keybindings to the AI group
      vim.list_extend(spec, {
        {
          "<leader>a",
          group = "ai",
          expand = function()
            return require("which-key.extras").expand.buf()
          end,
        },
        { "<leader>ai", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude Code", icon = "🤖" },
        { "<leader>ac", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude Code", icon = "💬" },
        { "<leader>as", "<cmd>ClaudeCodeSend<cr>", desc = "Send to Claude Code", mode = { "n", "v" }, icon = "📤" },
        { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude Model", icon = "⚙️" },
        { "<leader>ad", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept Claude Diff", icon = "✅" },
        { "<leader>aD", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Reject Claude Diff", icon = "❌" },
      })

      opts.spec = spec
      return opts
    end,
  },
}
