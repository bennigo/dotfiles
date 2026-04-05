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
        { "<leader>apo", desc = "Use Ollama (Llama)" },
        { "<leader>apc", desc = "Use Claude Code (ACP)" },
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
        -- CodeCompanion (evaluation alternative to Avante)
        {
          "<leader>C",
          icon = "🧪",
          group = "+codecompanion",
        },
        { "<leader>Cc", desc = "Toggle Chat" },
        { "<leader>Ca", desc = "Add to Chat", mode = "v" },
        { "<leader>Ci", desc = "Inline Edit" },
        { "<leader>Cp", desc = "Action Palette" },
        { "<leader>Ce", desc = "Explain Code", mode = "v" },
        { "<leader>Cf", desc = "Fix Code", mode = "v" },
        { "<leader>Ct", desc = "Generate Tests", mode = "v" },
        { "<leader>Cb", desc = "Chat with Buffer" },
        -- Markdown inline formatting (markdown.nvim)
        {
          "gs",
          group = "+surround/format",
          icon = "✏️",
          mode = { "n", "v" },
        },
        { "gsi", desc = "Toggle italic", mode = { "n", "v" } },
        { "gsb", desc = "Toggle bold", mode = { "n", "v" } },
        { "gss", desc = "Toggle strikethrough", mode = { "n", "v" } },
        { "gsc", desc = "Toggle code", mode = { "n", "v" } },
      },
    },
  },
}
