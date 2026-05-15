-- Pi Coding Agent — Neovim integration (terminal wrapper).
-- Module lives in lua/user/pi.lua. Uses Snacks.nvim terminal.
-- Keymaps are set at module load time (same pattern as claude-code.lua)
-- to ensure they're always active, not gated behind snacks opts timing.

local ok, pi = pcall(require, "user.pi")
if ok then
  pi.setup()
end

return {}
