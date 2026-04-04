return {
  "tadmccorkle/markdown.nvim",
  ft = "markdown",
  opts = {
    mappings = {
      inline_surround_toggle = "gs", -- toggle inline style (e.g. gsi=italic, gsb=bold, gss=strikethrough)
      inline_surround_toggle_line = "gss", -- line-wise toggle
      inline_surround_delete = "ds", -- delete emphasis surrounding cursor
      inline_surround_change = "cs", -- change emphasis surrounding cursor
      link_add = "<leader>gl", -- add link
      link_follow = false, -- obsidian.nvim handles this
      go_curr_heading = false, -- LazyVim defaults
      go_parent_heading = false,
      go_next_heading = false, -- LazyVim uses ]] / [[
      go_prev_heading = false,
    },
    inline_surround = {
      emphasis = { key = "i", txt = "*" }, -- gsi → *italic*
      strong = { key = "b", txt = "**" }, -- gsb → **bold**
      strikethrough = { key = "s", txt = "~~" }, -- gss → ~~strikethrough~~ (normal mode: gsss)
      code = { key = "c", txt = "`" }, -- gsc → `code`
    },
    link = {
      paste = { enable = true },
    },
  },
}
