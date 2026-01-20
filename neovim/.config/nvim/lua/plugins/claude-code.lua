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
            width = 0.95, -- 95% of screen width (enlarged)
            height = 0.95, -- 95% of screen height (enlarged)
            border = "rounded",
            zindex = 50, -- Higher z-index to render above other floating windows
            wo = {
              winblend = 0, -- no transparency (fixes rendering artifacts)
            },
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

      -- Alt+c for Claude Code (primary) - with deferred redraw for Kitty compatibility
      vim.keymap.set({ "n", "i", "t" }, "<M-c>", function()
        vim.cmd("ClaudeCodeFocus")
        vim.defer_fn(function()
          vim.cmd("mode")
        end, 10)
      end, { desc = "Toggle Claude Code (Max)" })

      -- Fallback: Quick return to Claude window (useful if diff steals focus)
      vim.keymap.set({ "n", "i" }, "<C-M-c>", function()
        vim.cmd("ClaudeCodeFocus")
        vim.defer_fn(function()
          vim.cmd("mode")
        end, 10)
      end, { desc = "Return to Claude Code" })
    end,
    keys = {
      -- Universal Claude Code toggle - Alt+c (with deferred redraw for Kitty compatibility)
      {
        "<M-c>",
        function()
          vim.cmd("ClaudeCodeFocus")
          vim.defer_fn(function()
            vim.cmd("mode")
          end, 10)
        end,
        desc = "Toggle Claude Code (Max)",
        mode = { "n", "i", "t" },
      },
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
        { "<leader>aci", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude Code", icon = "🤖" },
        { "<leader>acc", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude Code", icon = "💬" },
        { "<leader>acs", "<cmd>ClaudeCodeSend<cr>", desc = "Send to Claude Code", mode = { "n", "v" }, icon = "📤" },
        { "<leader>acm", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude Model", icon = "⚙️" },
        { "<leader>acd", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept Claude Diff", icon = "✅" },
        { "<leader>acD", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Reject Claude Diff", icon = "❌" },
      })

      opts.spec = spec
      return opts
    end,
  },
}
