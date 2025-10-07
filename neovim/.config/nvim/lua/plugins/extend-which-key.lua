return {
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        {
          "<leader>w",
          nil,
        },
        {
          "<leader>W",
          group = "+windows",
          proxy = "<c-w>",
          expand = function()
            return require("which-key.extras").expand.win()
          end,
        },
        {
          "<leader>o",
          icon = "📓",
          group = "+obsidian",
          expand = function()
            return require("which-key.extras").expand.win()
          end,
        },
        -- AI Tools keybindings
        {
          "<leader>a",
          icon = "🤖",
          group = "+ai",
        },
        -- Avante (Ollama/Local)
        { "<leader>aa", desc = "Ask Avante (Local)" },
        { "<leader>ar", desc = "Refresh Avante" },
        { "<leader>ae", desc = "Edit with Avante" },
        { "<leader>as", desc = "Toggle Avante Sidebar" },
        {
          "<leader>ap",
          icon = "🔄",
          group = "+provider",
        },
        { "<leader>apo", desc = "Use Ollama (DeepSeek)" },
        -- Claude Code (Max Plan)
        {
          "<leader>ac",
          icon = "🔮",
          group = "+claude-code",
        },
        { "<leader>aci", desc = "Toggle Claude Code" },
        { "<leader>acc", desc = "Focus Claude Code" },
        { "<leader>acs", desc = "Send to Claude Code" },
        { "<leader>acm", desc = "Select Claude Model" },
        { "<leader>acd", desc = "Accept Diff" },
        { "<leader>acD", desc = "Reject Diff" },
      },
    },
  },
}
