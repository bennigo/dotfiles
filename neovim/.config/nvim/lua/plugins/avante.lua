return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  lazy = false,
  version = false,
  opts = {
    -- Provider configuration
    provider = "ollama", -- default provider (local, no cost)
    auto_suggestions_provider = "ollama",

    -- Behaviour settings
    behaviour = {
      auto_suggestions = false, -- don't auto-suggest
      auto_set_highlight_group = true,
      auto_set_keymaps = true,
      auto_apply_diff_after_generation = false,
      support_paste_from_clipboard = true,
    },

    -- Disable tool support for providers that don't support it
    support_tools = false,

    -- Mappings - Alt+c for Zen mode toggle
    mappings = {
      --- @class AvanteConflictMappings
      diff = {
        ours = "co",
        theirs = "ct",
        all_theirs = "ca",
        both = "cb",
        cursor = "cc",
        next = "]x",
        prev = "[x",
      },
      suggestion = {
        accept = "<M-l>",
        next = "<M-]>",
        prev = "<M-[>",
        dismiss = "<C-]>",
      },
      jump = {
        next = "]]",
        prev = "[[",
      },
      submit = {
        normal = "<CR>",
        insert = "<C-s>",
      },
      sidebar = {
        switch_windows = "<Tab>",
        reverse_switch_windows = "<S-Tab>",
      },
    },

    -- Hints and suggestions
    hints = { enabled = true },

    -- Window configuration - sidebar mode settings
    windows = {
      ---@type "right" | "left" | "top" | "bottom"
      position = "right",
      wrap = true,
      width = 40, -- 40% when in sidebar mode
      sidebar_header = {
        align = "center",
        enabled = true,
        rounded = true,
      },
      -- Enable transparency
      winblend = 30, -- 0-100, higher = more transparent
    },

    -- Highlights configuration
    highlights = {
      ---@type AvanteConflictHighlights
      diff = {
        current = "DiffText",
        incoming = "DiffAdd",
      },
    },

    --- @class AvanteConflictUserConfig
    diff = {
      autojump = true,
      ---@type string | fun(): any
      list_opener = "copen",
    },
  },

  -- Build step
  build = "make",

  -- Dependencies
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    --- Icon support
    {
      "nvim-mini/mini.icons",
      version = false,
    },
    {
      -- Make sure to set this up properly if you have lazy=true
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        file_types = { "markdown", "Avante" },
      },
      ft = { "markdown", "Avante" },
    },
  },

  -- Custom keybindings
  keys = {
    -- Alt+Shift+c: Toggle Zen mode (full-screen)
    {
      "<M-C>",
      function()
        require("avante.api").zen_mode()
      end,
      desc = "Avante: Zen Mode (Local)",
      mode = { "n", "i", "v" },
    },
    -- Leader mappings for avante commands
    { "<leader>aa", function() require("avante.api").ask() end, desc = "Avante: Ask" },
    { "<leader>ar", function() require("avante.api").refresh() end, desc = "Avante: Refresh" },
    { "<leader>ae", function() require("avante.api").edit() end, desc = "Avante: Edit", mode = { "n", "v" } },

    -- Sidebar mode toggle (occasional use)
    { "<leader>as", function() require("avante").toggle() end, desc = "Avante: Toggle Sidebar" },

    -- Provider switching (only Ollama configured)
    { "<leader>apo", "<cmd>AvanteProviderSwitch ollama<cr>", desc = "Use Ollama (DeepSeek)" },
  },

  config = function(_, opts)
    -- Add Ollama provider configuration (new format)
    opts.providers = opts.providers or {}
    opts.providers.ollama = {
      __inherited_from = "openai",
      api_key_name = "",
      endpoint = "http://127.0.0.1:11434/v1",
      model = "llama3.1:8b", -- Using Llama instead - better compatibility
      -- Disable tool/function calling support
      use_xml_format = false,
      role_map = {
        user = "user",
        assistant = "assistant",
      },
      parse_response = function(data_stream, event_state, opts)
        require("avante.providers").openai.parse_response(data_stream, event_state, opts)
      end,
    }

    require("avante_lib").load()
    require("avante").setup(opts)
  end,
}
