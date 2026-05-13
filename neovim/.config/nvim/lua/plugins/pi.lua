-- Pi Coding Agent — Neovim integration (terminal wrapper).
-- Module lives in lua/user/pi.lua. Uses Snacks.nvim terminal.
return {
  {
    "folke/snacks.nvim",
    optional = true, -- runs only if snacks is installed (it always is)
    opts = function(_, opts)
      -- Hook into snacks init to set up pi keymaps. Must return opts
      -- unchanged to not break existing snacks config (extend-snacks.lua).
      local ok, pi = pcall(require, "user.pi")
      if ok then
        pi.setup()
      end
      return opts
    end,
  },
}
