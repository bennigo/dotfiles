return {
  -- Add Claude Code integration to AI ecosystem
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" }, -- Required for terminal support
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
            wo = {
              winblend = 30, -- transparency (0-100)
            },
            -- Allow hiding from within terminal using Alt+c
            keys = {
              claude_hide = {
                "<M-c>",
                function(self)
                  self:hide()
                end,
                mode = "t",
                desc = "Hide Claude Code",
              },
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

      -- Alt+c for Claude Code (primary)
      vim.keymap.set({ "n", "i", "t" }, "<M-c>", "<cmd>ClaudeCodeFocus<cr>", { desc = "Toggle Claude Code (Max)" })

      -- Fallback: Quick return to Claude window (useful if diff steals focus)
      vim.keymap.set({ "n", "i" }, "<C-M-c>", "<cmd>ClaudeCodeFocus<cr>", { desc = "Return to Claude Code" })

      -- Remote Control: open Claude Code accessible from phone/browser
      vim.keymap.set("n", "<leader>acR", function()
        vim.cmd("ClaudeCode --remote-control")
      end, { desc = "Claude Code Remote Control" })

      -- ── Prompt Buffer ──────────────────────────────────────────────
      -- Compose prompts in a persistent Snacks scratch buffer with full
      -- editing power, then send to Claude Code terminal.

      --- Find the Claude Code terminal buffer and its channel ID.
      ---@return integer|nil channel The terminal channel, or nil
      local function get_claude_terminal_chan()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.bo[buf].buftype == "terminal" then
            local name = vim.api.nvim_buf_get_name(buf)
            if name:find("claude") then
              local chan = vim.bo[buf].channel
              if chan and chan > 0 then
                return chan
              end
            end
          end
        end
        return nil
      end

      --- Send prompt text to Claude Code terminal via bracketed paste.
      ---@param text string
      local function send_prompt_to_claude(text)
        if text == "" then
          vim.notify("Empty prompt — nothing to send", vim.log.levels.WARN)
          return
        end
        vim.fn.setreg("+", text)
        vim.cmd("ClaudeCodeFocus")
        vim.defer_fn(function()
          local chan = get_claude_terminal_chan()
          if chan then
            vim.api.nvim_chan_send(chan, "\x1b[200~" .. text .. "\x1b[201~")
            vim.notify("Prompt pasted into Claude Code", vim.log.levels.INFO)
          else
            vim.notify("Prompt copied — paste with Ctrl+Shift+V", vim.log.levels.INFO)
          end
        end, 100)
      end

      -- ── Expand Stub Keybinding ─────────────────────────────────
      -- Normal: send /expand-stub with current buffer's note stem
      -- Visual: send /expand-stub with visual selection text

      vim.keymap.set("n", "<leader>ace", function()
        local bufname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t:r")
        if bufname == "" then
          vim.notify("No buffer name", vim.log.levels.WARN)
          return
        end
        send_prompt_to_claude('/expand-stub "' .. bufname .. '"')
      end, { desc = "Expand stub (buffer)" })

      vim.keymap.set("v", "<leader>ace", function()
        local start_pos = vim.fn.getpos("v")
        local end_pos = vim.fn.getpos(".")
        local lines = vim.fn.getregion(start_pos, end_pos, { type = vim.fn.mode() })
        local text = table.concat(lines, " "):gsub("^%s+", ""):gsub("%s+$", "")
        -- Strip wikilink brackets if present
        text = text:gsub("^%[%[", ""):gsub("%]%]$", "")
        -- Strip display text from piped links: stem|display -> stem
        text = text:gsub("|.*$", "")
        if text == "" then
          vim.notify("Empty selection", vim.log.levels.WARN)
          return
        end
        -- Exit visual mode before sending
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
        send_prompt_to_claude('/expand-stub "' .. text .. '"')
      end, { desc = "Expand stub (selection)" })

      vim.keymap.set("n", "<leader>acp", function()
        Snacks.scratch.open({
          name = "Claude Prompt",
          ft = "markdown",
          filekey = { cwd = true, branch = false, count = false },
          win = {
            width = 0.7,
            height = 0.85,
            wo = { winblend = 10 },
            keys = {
              send = {
                "<C-s>",
                function(self)
                  local lines = vim.api.nvim_buf_get_lines(self.buf, 0, -1, false)
                  local text = table.concat(lines, "\n"):gsub("^%s+", ""):gsub("%s+$", "")
                  vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, { "" })
                  self:close()
                  send_prompt_to_claude(text)
                end,
                desc = "Send to Claude",
                mode = { "n", "i" },
              },
            },
          },
        })
      end, { desc = "Compose Claude prompt" })
    end,
    keys = {
      -- Universal Claude Code toggle - Alt+c
      { "<M-c>", "<cmd>ClaudeCodeFocus<cr>", desc = "Toggle Claude Code (Max)", mode = { "n", "i", "t" } },
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
        { "<leader>acR", desc = "Claude Code Remote Control", icon = "📱" },
        { "<leader>acp", desc = "Compose Claude prompt", icon = "📝" },
        { "<leader>ace", desc = "Expand stub", mode = { "n", "v" }, icon = "🌱" },
      })

      opts.spec = spec
      return opts
    end,
  },
}
