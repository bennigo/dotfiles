-- Pi Coding Agent Neovim integration
-- Terminal wrapper using Snacks.nvim (no dedicated Neovim plugin exists for pi).
-- Loaded by lua/plugins/pi.lua on VeryLazy.

local M = {}

function M.setup()
  local pi_buf = nil

  local function find_pi_buf()
    if pi_buf and vim.api.nvim_buf_is_valid(pi_buf) then
      return pi_buf
    end
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.bo[buf].buftype == "terminal" then
        local name = vim.api.nvim_buf_get_name(buf)
        if name:find("pi%-agent") then
          pi_buf = buf
          return buf
        end
      end
    end
    return nil
  end

  local function get_pi_channel()
    local buf = find_pi_buf()
    if buf and vim.bo[buf].channel and vim.bo[buf].channel > 0 then
      return vim.bo[buf].channel
    end
    return nil
  end

  local function pi_is_visible()
    local buf = find_pi_buf()
    if not buf then
      return false
    end
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == buf then
        return true
      end
    end
    return false
  end

  local function open_pi_terminal()
    -- Uses settings.json defaults. To use a specific provider:
    --   "pi --provider anthropic --model claude-sonnet-4-5"
    --   "pi --provider ollama --model qwen3.5"
    Snacks.terminal("pi", {
      name = "pi-agent",
      win = {
        position = "float",
        width = 0.95,
        height = 0.95,
        border = "rounded",
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
  end

  local function toggle_pi()
    local buf = find_pi_buf()
    if not buf then
      open_pi_terminal()
      return
    end
    if pi_is_visible() then
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win) == buf then
          vim.api.nvim_win_close(win, true)
          return
        end
      end
    else
      local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = math.floor(vim.o.columns * 0.95),
        height = math.floor(vim.o.lines * 0.95),
        col = math.floor(vim.o.columns * 0.025),
        row = math.floor(vim.o.lines * 0.025),
        border = "rounded",
        style = "minimal",
      })
      vim.wo[win].winblend = 30
      vim.api.nvim_set_current_win(win)
      vim.cmd("startinsert")
    end
  end

  local function focus_pi()
    local buf = find_pi_buf()
    if not buf then
      open_pi_terminal()
      return
    end
    if not pi_is_visible() then
      local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = math.floor(vim.o.columns * 0.95),
        height = math.floor(vim.o.lines * 0.95),
        col = math.floor(vim.o.columns * 0.025),
        row = math.floor(vim.o.lines * 0.025),
        border = "rounded",
        style = "minimal",
      })
      vim.wo[win].winblend = 30
    end
    vim.cmd("startinsert")
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

  -- Keymaps
  vim.keymap.set({ "n", "i", "t" }, "<M-p>", toggle_pi, { desc = "Toggle Pi Coding Agent" })
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

  vim.keymap.set("n", "<leader>aik", function()
    local buf = find_pi_buf()
    if buf then
      vim.api.nvim_buf_delete(buf, { force = true })
      pi_buf = nil
      vim.notify("Pi terminal killed", vim.log.levels.INFO)
    else
      vim.notify("No Pi terminal running", vim.log.levels.WARN)
    end
  end, { desc = "Kill Pi terminal" })

  vim.keymap.set("n", "<leader>aiR", function()
    local buf = find_pi_buf()
    if buf then
      vim.api.nvim_buf_delete(buf, { force = true })
      pi_buf = nil
    end
    open_pi_terminal()
  end, { desc = "Restart Pi" })
end

return M
