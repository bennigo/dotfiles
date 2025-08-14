return {
  "ibhagwan/fzf-lua",
  event = "VeryLazy",
  config = function()
    local fzf = require("fzf-lua")

    -- Configure ripgrep as the backend for file listing and grepping,
    -- adding exclusion globs for Obsidian-specific folders and common noise.
    fzf.setup({
      files = {
        -- List files using rg so we can apply -g '!…' exclusions
        cmd = table.concat({
          "rg",
          "--files",
          "--hidden",
          "--follow",
          "-g",
          "!.git/",
          "-g",
          "!node_modules/",
          "-g",
          "!build/",
          "-g",
          "!dist/",
          "-g",
          "!venv/",
          "-g",
          "!coverage/",
          "-g",
          "!target/",
          "-g",
          "!Assets/attachments/**", -- Obsidian: adjust to your vault
          "-g",
          "!Templates/test_templates/**", -- Obsidian: adjust to your vault
        }, " "),
      },
      grep = {
        -- Content search using rg with the same exclusions
        cmd = table.concat({
          "rg",
          "--vimgrep",
          "--hidden",
          "--follow",
          "--smart-case",
          "--no-heading",
          "--column",
          "--line-number",
          "-g",
          "!.git/",
          "-g",
          "!node_modules/",
          "-g",
          "!build/",
          "-g",
          "!dist/",
          "-g",
          "!venv/",
          "-g",
          "!coverage/",
          "-g",
          "!target/",
          "-g",
          "!Assets/attachments/**", -- Obsidian: adjust to your vault
          "-g",
          "!Templates/test_templates/**", -- Obsidian: adjust to your vault
        }, " "),
      },
    })
  end,
}
