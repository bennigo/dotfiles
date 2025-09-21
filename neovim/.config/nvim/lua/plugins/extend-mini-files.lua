return {
  "nvim-mini/mini.files",
  keys = {
    {
      "<leader>E",
      function()
        require("mini.files").open(vim.uv.cwd(), true)
      end,
      desc = "Open mini.files (cwd)",
    },
    {
      "<leader>fm",
      function()
        require("mini.files").open(vim.api.nvim_buf_get_name(0), true)
      end,
      desc = "Open mini.files (directory of current file)",
    },
    {
      "<leader>e",
      function()
        require("mini.files").open(LazyVim.root(), true)
      end,
      desc = "Open mini.files (root)",
    },
  },
  opts = {
    windows = {
      preview = true,
      width_nofocus = 15,
      width_focus = 20,
      width_preview = 80,
    },
    options = {
      use_as_default_explorer = true,
    },
    mappings = {
      close = "<Esc>",
    },
  },
}
