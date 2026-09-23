-- Pi Coding Agent — Neovim integration (terminal wrapper).
-- Module lives in lua/user/pi.lua. Uses Snacks.nvim terminal.
-- Keymaps are set at module load time (same pattern as claude-code.lua)
-- to ensure they're always active, not gated behind snacks opts timing.

local ok, pi = pcall(require, "user.pi")
if ok then
  pi.setup()
end

return {
  -- ── Free <M-p> from LazyVim's LSP reference-jump keys ──────────────────
  -- LazyVim binds `<a-n>` / `<a-p>` ("Next/Prev Reference" via Snacks.words.jump)
  -- in its lspconfig spec under `opts.servers["*"].keys`, and those are applied
  -- *buffer-locally* on LspAttach. `<a-p>` and `<M-p>` are the same key to
  -- Neovim, and a buffer-local mapping beats the global one — so in any
  -- LSP-attached buffer (i.e. any real source file) Alt+P silently does nothing,
  -- while still working *inside* the Pi float, whose hide key is Snacks'
  -- buffer-local t-mode map. Hence: "Alt+P collapses the float but never opens it."
  --
  -- The lspconfig spec declares `opts_extend = { "servers.*.keys" }`, so this list
  -- is APPENDED to LazyVim's, and `{ "<a-p>", false }` cancels its `<a-p>` entry
  -- (lazy/core/handler/keys.lua: rhs == false → removed from the resolved set).
  -- `]]` / `[[` stay bound to the same reference jump, so nothing is lost.
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ["*"] = {
          keys = { { "<a-p>", false } },
        },
      },
    },
  },
}
