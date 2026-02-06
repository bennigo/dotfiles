-- CodeCompanion.nvim - Alternative AI assistant (evaluation alongside Avante)
--
-- Philosophy: "Like Zed AI" - chat + quick edits with deep Neovim integration
-- vs Avante's "Like Cursor" - full IDE experience
--
-- Keybindings use <leader>C* to avoid conflicts with Avante (<leader>a*)
-- and Claude Code (<leader>ac*)
--
-- Evaluation period: Try both for 1-2 weeks, compare:
-- - Buffer/LSP diagnostics sharing
-- - Diff application reliability
-- - Tool workflow (variables #, commands /)
-- - Overall stability

return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    -- Uses your existing fzf-lua for pickers (no telescope needed)
    "ibhagwan/fzf-lua",
    {
      "MeanderingProgrammer/render-markdown.nvim",
      ft = { "markdown", "codecompanion" },
    },
  },
  event = "VeryLazy",

  opts = {
    -- Strategy configuration
    strategies = {
      -- Chat strategy (main interaction mode)
      chat = {
        adapter = "ollama",
        roles = {
          llm = "CodeCompanion",
          user = "Benedikt",
        },
        -- Keymaps within chat buffer
        keymaps = {
          close = { modes = { n = "q", i = "<C-c>" } },
          stop = { modes = { n = "<C-c>" } },
        },
      },
      -- Inline strategy (quick edits in buffer)
      inline = {
        adapter = "ollama",
      },
      -- Agent strategy (tool execution)
      agent = {
        adapter = "ollama",
      },
    },

    -- Adapter configurations
    adapters = {
      -- Ollama (local, free) - matches your Avante setup
      ollama = function()
        return require("codecompanion.adapters").extend("ollama", {
          env = {
            url = "http://127.0.0.1:11434",
          },
          schema = {
            model = {
              default = "llama3.1:8b",
            },
          },
        })
      end,
    },

    -- Display settings
    display = {
      chat = {
        -- Window configuration
        window = {
          layout = "vertical", -- vertical split (like Claude Code)
          width = 0.45, -- 45% width
          height = 0.8,
          border = "rounded",
          opts = {
            winblend = 30, -- Match your transparency preference
          },
        },
        -- Show token count
        show_token_count = true,
        -- Show settings in chat
        show_settings = false,
      },
      inline = {
        diff = {
          enabled = true,
          priority = 130,
        },
      },
      action_palette = {
        provider = "fzf_lua", -- Use your existing fzf-lua
      },
    },

    -- Slash commands (/ in chat)
    -- These inject context into the conversation
    slash_commands = {
      ["buffer"] = {
        opts = {
          provider = "fzf_lua",
        },
      },
      ["file"] = {
        opts = {
          provider = "fzf_lua",
        },
      },
      ["help"] = {
        opts = {
          provider = "fzf_lua",
        },
      },
    },

    -- Opts for the chat buffer
    opts = {
      -- Log level
      log_level = "ERROR",
      -- Send code output to chat
      send_code = true,
    },
  },

  -- Keybindings - using <leader>C* to avoid conflicts
  keys = {
    -- Chat toggle (main interaction)
    {
      "<leader>Cc",
      "<cmd>CodeCompanionChat Toggle<cr>",
      desc = "CodeCompanion: Toggle Chat",
      mode = { "n", "v" },
    },
    -- Add selection to chat
    {
      "<leader>Ca",
      "<cmd>CodeCompanionChat Add<cr>",
      desc = "CodeCompanion: Add to Chat",
      mode = "v",
    },
    -- Inline edit (quick edits in buffer)
    {
      "<leader>Ci",
      "<cmd>CodeCompanion<cr>",
      desc = "CodeCompanion: Inline Edit",
      mode = { "n", "v" },
    },
    -- Action palette (all available actions)
    {
      "<leader>Cp",
      "<cmd>CodeCompanionActions<cr>",
      desc = "CodeCompanion: Action Palette",
      mode = { "n", "v" },
    },
    -- Quick commands
    {
      "<leader>Ce",
      "<cmd>CodeCompanion /explain<cr>",
      desc = "CodeCompanion: Explain Code",
      mode = "v",
    },
    {
      "<leader>Cf",
      "<cmd>CodeCompanion /fix<cr>",
      desc = "CodeCompanion: Fix Code",
      mode = "v",
    },
    {
      "<leader>Ct",
      "<cmd>CodeCompanion /tests<cr>",
      desc = "CodeCompanion: Generate Tests",
      mode = "v",
    },
    -- Buffer context
    {
      "<leader>Cb",
      function()
        -- Send current buffer to chat with context
        vim.cmd("CodeCompanionChat")
        vim.defer_fn(function()
          vim.api.nvim_feedkeys("/buffer\n", "n", false)
        end, 100)
      end,
      desc = "CodeCompanion: Chat with Buffer",
    },
  },

  config = function(_, opts)
    require("codecompanion").setup(opts)

    -- Optional: Set up completion source for chat buffers
    local ok, cmp = pcall(require, "cmp")
    if ok then
      cmp.setup.filetype("codecompanion", {
        sources = cmp.config.sources({
          { name = "codecompanion" },
        }),
      })
    end
  end,
}
