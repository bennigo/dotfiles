-- Pi Coding Agent Neovim integration
-- Terminal wrapper using Snacks.nvim (no dedicated Neovim plugin exists for pi).
-- Loaded by lua/plugins/pi.lua on VeryLazy.
--
-- ── Why this does NOT search buffers by name ──────────────────────────────
-- `Snacks.terminal` has no `name` option (and never had one — verified against
-- snacks.nvim git history). The buffer of a Snacks terminal is a real terminal
-- buffer named `term://<cwd>//<pid>:<cmd>`, so a friendly name like "pi-agent"
-- can never match. Terminal identity comes from:
--   1. the Snacks terminal object returned by Snacks.terminal(), and
--   2. `vim.b[buf].snacks_terminal` ({ cmd, id, cwd, env }), which Snacks writes
--      on every terminal buffer — this is what survives a `:cd`, since Snacks
--      terminal ids include the *current working directory* and `v:count`.

local M = {}

--- `pi` lives in the npm-global bin dir, which is NOT on the session PATH when
--- Neovim is launched from the Sway launcher (systemd user env). Its shebang is
--- `#!/usr/bin/env node`, so node must be resolvable too.
local PI_CANDIDATES = {
  vim.fn.expand("~/.local/share/npm-global/bin/pi"),
  vim.fn.expand("~/.local/bin/pi"),
}

---@return string absolute path to `pi`, or "pi" as a last resort
local function pi_cmd()
  local exe = vim.fn.exepath("pi")
  if exe == "" then
    for _, c in ipairs(PI_CANDIDATES) do
      if vim.fn.executable(c) == 1 then
        exe = c
        break
      end
    end
  end
  return exe ~= "" and exe or "pi"
end

--- PATH with npm-global/bin and node's dir guaranteed present.
---@return string
local function patched_env()
  local path = vim.env.PATH or ""
  local parts = vim.split(path, ":", { plain = true, trimempty = true })
  local seen = {}
  for _, p in ipairs(parts) do
    seen[p] = true
  end
  local needed = { vim.fn.expand("~/.local/share/npm-global/bin") }
  local node = vim.fn.exepath("node")
  if node ~= "" then
    table.insert(needed, vim.fn.fnamemodify(node, ":h"))
  end
  for _, p in ipairs(needed) do
    if p ~= "" and not seen[p] then
      table.insert(parts, 1, p)
    end
  end
  return table.concat(parts, ":")
end

--- Does this Snacks terminal metadata describe the `pi` terminal?
---@param cmd string|string[]|nil
---@return boolean
local function is_pi_cmd(cmd)
  local s = type(cmd) == "table" and cmd[#cmd] or cmd
  return type(s) == "string" and s:match("(^|/)pi$") ~= nil
end

function M.setup()
  if M._did_setup then
    return
  end
  M._did_setup = true

  local pi_term = nil -- tracked Snacks terminal object

  --- Resolve the live pi terminal: tracked object first, then Snacks metadata.
  ---@return snacks.win? term
  local function get_pi_term()
    if pi_term and pi_term:buf_valid() then
      return pi_term
    end
    for _, t in ipairs(require("snacks").terminal.list()) do
      if is_pi_cmd(vim.b[t.buf].snacks_terminal and vim.b[t.buf].snacks_terminal.cmd) then
        pi_term = t
        return t
      end
    end
    pi_term = nil
    return nil
  end

  ---@return integer? channel
  local function get_pi_channel()
    local term = get_pi_term()
    local chan = term and vim.bo[term.buf].channel
    return (chan and chan > 0) and chan or nil
  end

  local function open_pi_terminal()
    -- `count = 1` pins one of the two moving parts of a Snacks terminal id
    -- (cwd is the other one, handled by get_pi_term scanning metadata).
    local term = Snacks.terminal(pi_cmd(), {
      count = 1,
      env = { PATH = patched_env() },
      win = {
        position = "float",
        width = 0.95,
        height = 0.95,
        border = "rounded",
        title = " π  Pi ",
        wo = { winblend = 30 },
        keys = {
          pi_hide = {
            "<M-p>",
            function(self)
              self:hide()
            end,
            mode = "t",
            desc = "Hide Pi agent",
          },
        },
      },
    })
    pi_term = term
    return term
  end

  ---@return snacks.win? term, boolean created
  local function ensure_pi_term()
    local term = get_pi_term()
    if term then
      return term, false
    end
    return open_pi_terminal(), true
  end

  local function toggle_pi()
    local term = get_pi_term()
    if not term then
      open_pi_terminal()
      return
    end
    if term:valid() then
      term:hide()
    else
      term:show()
      term:focus()
    end
  end

  --- Focus the pi float, showing it if hidden. Never hides it.
  local function focus_pi()
    local term = ensure_pi_term()
    if term and not term:valid() then
      term:show()
    end
    if term then
      term:focus()
    end
  end

  local function send_to_pi(text)
    if text == "" then
      vim.notify("Empty prompt — nothing to send", vim.log.levels.WARN)
      return
    end
    focus_pi()
    vim.defer_fn(function()
      local chan = get_pi_channel()
      if chan then
        vim.api.nvim_chan_send(chan, "\x1b[200~" .. text .. "\x1b[201~\n")
        vim.notify("Sent to Pi", vim.log.levels.INFO)
      else
        vim.notify("Pi terminal not found — paste manually with Ctrl+Shift+V", vim.log.levels.INFO)
      end
    end, 150)
  end

  local function kill_pi_term()
    local term = get_pi_term()
    if not term then
      vim.notify("No Pi terminal running", vim.log.levels.WARN)
      return false
    end
    -- nvim_buf_delete (not win:close) — win:close({buf=false}) would leave the
    -- terminal process running. Clear Snacks' TermClose handler first: a killed
    -- job reports a non-zero status and would pop a bogus
    -- "Terminal exited with code 143" error toast. Snacks registers it inside the
    -- per-window augroup, and nvim_clear_autocmds({event,buffer}) silently does
    -- nothing for grouped autocmds — the group is required.
    pcall(vim.api.nvim_clear_autocmds, {
      group = term.augroup,
      event = "TermClose",
      buffer = term.buf,
    })
    vim.api.nvim_buf_delete(term.buf, { force = true })
    pi_term = nil
    vim.notify("Pi terminal killed", vim.log.levels.INFO)
    return true
  end

  -- Keymaps
  vim.keymap.set({ "n", "i", "t" }, "<M-p>", toggle_pi, { desc = "Toggle Pi Coding Agent" })
  -- Layout/AltGr-proof fallback (right-Alt never reaches nvim as <M-p>).
  vim.keymap.set({ "n", "i", "t" }, "<C-M-p>", toggle_pi, { desc = "Toggle Pi Coding Agent" })
  vim.keymap.set("n", "<leader>ait", toggle_pi, { desc = "Toggle Pi" })
  vim.keymap.set("n", "<leader>aif", focus_pi, { desc = "Focus Pi" })

  vim.keymap.set("v", "<leader>ais", function()
    local start_pos = vim.fn.getpos("v")
    local end_pos = vim.fn.getpos(".")
    local lines = vim.fn.getregion(start_pos, end_pos, { type = vim.fn.mode() })
    local text = table.concat(lines, "\n"):gsub("^%s+", ""):gsub("%s+$", "")
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
    send_to_pi(text)
  end, { desc = "Send selection to Pi" })

  vim.keymap.set("n", "<leader>aip", function()
    Snacks.scratch.open({
      name = "Pi Prompt",
      ft = "markdown",
      filekey = { cwd = true, branch = false, count = false },
      win = {
        width = 0.7,
        height = 0.85,
        wo = { winblend = 10 },
        keys = {
          send = {
            "<C-s>",
            function(self)
              local lines = vim.api.nvim_buf_get_lines(self.buf, 0, -1, false)
              local text = table.concat(lines, "\n"):gsub("^%s+", ""):gsub("%s+$", "")
              vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, { "" })
              self:close()
              send_to_pi(text)
            end,
            desc = "Send to Pi",
            mode = { "n", "i" },
          },
        },
      },
    })
  end, { desc = "Compose Pi prompt" })

  vim.keymap.set("n", "<leader>aik", kill_pi_term, { desc = "Kill Pi terminal" })

  vim.keymap.set("n", "<leader>aiR", function()
    kill_pi_term()
    open_pi_terminal()
  end, { desc = "Restart Pi" })

  -- Exposed for tests / :lua calls
  M.toggle = toggle_pi
  M.focus = focus_pi
  M.send = send_to_pi
  M.kill = kill_pi_term
  M.open = open_pi_terminal
  M.get_term = get_pi_term
  M.get_channel = get_pi_channel
end

return M
