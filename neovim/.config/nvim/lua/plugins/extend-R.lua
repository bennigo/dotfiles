return {
  "R-nvim/R.nvim",
  enabled = true,
  library_dir = "/usr/lib/R/library",
  site_library_dir = "/usr/lib/R/site-library",
  -- config = function()
  -- require("r").setup({
  --   r_path = "R",
  --     args = { "--quiet", "--no-save", "--no-restore" },
  --     library_dir = "/usr/lib/R/library",
  --     site_library_dir = "/usr/lib/R/site-library",
  --     hook = {
  --       on_filetype = function()
  --         vim.keymap.set("n", "<Enter>", "<Plug>RDSendLine", { buffer = true })
  --         vim.keymap.set("v", "<Enter>", "<Plug>RSendSelection", { buffer = true })
  --       end,
  --     },
  -- })
  -- end,
}
