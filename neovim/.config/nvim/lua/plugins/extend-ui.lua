return {
  {
    "LazyVim/LazyVim",
    opts = {
      ui = {
        open_fn = function(path)
          -- Handle dotfiles directly
          if path:match("^%.") then
            vim.cmd(string.format("edit %%:%s", path))
            return
          end

          -- Preserve LazyVim's enhanced UI features
          require("lazyvim.util").open_file(path)
        end,
      },
    },
  },
}
