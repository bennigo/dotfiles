-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Auto-activate conda environment in terminal buffers
-- DISABLED: Auto-activation removed per user preference
-- vim.api.nvim_create_autocmd("TermOpen", {
--   pattern = "*",
--   callback = function()
--     -- Get the current conda environment from the parent shell
--     local conda_env = vim.env.CONDA_DEFAULT_ENV
--     if conda_env and conda_env ~= "" then
--       -- Send command to activate the conda environment in the new terminal
--       vim.fn.chansend(vim.b.terminal_job_id, string.format("conda activate %s\n", conda_env))
--     end
--   end,
--   desc = "Auto-activate conda environment in terminals"
-- })

-- Refresh Wayland env vars from tmux (fixes xdg-open after session restore)
if vim.env.TMUX and vim.env.TMUX ~= "" then
  for _, var in ipairs({ "WAYLAND_DISPLAY", "SWAYSOCK", "DISPLAY", "KITTY_LISTEN_ON" }) do
    local ok, result = pcall(vim.fn.system, { "tmux", "show-environment", var })
    if ok and result and result:match("^" .. var .. "=") then
      vim.env[var] = result:match("^" .. var .. "=(.+)"):gsub("%s+$", "")
    end
  end
end

-- Override gx in markdown buffers to resolve vault paths for wikilinks/images
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function(ev)
    vim.keymap.set("n", "gx", function()
      local line = vim.api.nvim_get_current_line()
      local col = vim.api.nvim_win_get_cursor(0)[2] + 1

      -- Extract wikilink or image embed under cursor: [[file]] or ![[file]]
      local target
      for s, link in line:gmatch("()!?%[%[([^%]|#]+)[^%]]*%]%]") do
        local e = s + #link + 4
        if col >= s and col <= e then
          target = link
          break
        end
      end

      -- Fall back to default gx for URLs and non-wikilink text
      if not target then
        vim.ui.open(vim.fn.expand("<cfile>"))
        return
      end

      -- Resolve the target to a vault path
      local vault = vim.fn.expand("~/notes/bgovault")
      local direct = vault .. "/" .. target
      if vim.fn.filereadable(direct) == 1 then
        vim.ui.open(direct)
        return
      end

      -- Search vault for the file
      local found = vim.fn.globpath(vault, "**/" .. target, false, true)
      if #found > 0 then
        vim.ui.open(found[1])
      else
        vim.notify("Not found in vault: " .. target, vim.log.levels.WARN)
      end
    end, { buffer = ev.buf, desc = "Open link/image (vault-aware)" })
  end,
})

-- Mermaid diagram auto-generation
-- Auto-generate PDF when saving .mmd files
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "*.mmd",
  callback = function()
    local file = vim.fn.expand('%')
    local pdf_file = file:gsub('%.mmd$', '.pdf')

    -- Generate PDF silently in background with proper settings
    vim.fn.jobstart({'mmdc', '-i', file, '-o', pdf_file, '-t', 'default', '-b', 'white', '-f', '-p', vim.fn.expand('~/.config/mermaid-puppeteer.json')}, {
      on_exit = function(_, exit_code)
        if exit_code == 0 then
          vim.notify("Generated: " .. vim.fn.fnamemodify(pdf_file, ':t'), vim.log.levels.INFO)
        else
          vim.notify("Failed to generate PDF from " .. vim.fn.fnamemodify(file, ':t'), vim.log.levels.ERROR)
        end
      end
    })
  end,
  desc = "Auto-generate PDF from Mermaid diagrams"
})

-- Smart Dagbok timestamp continuation moved to after/ftplugin/markdown.lua
-- (must run AFTER bullets.vim sets its <CR> and o mappings)

-- Keyboard layout switching: US English in Normal/Visual, system layout in Insert
-- Uses swaymsg to switch layout index (0=US, 1=Icelandic per sway config)
if vim.fn.executable("swaymsg") == 1 and vim.env.SWAYSOCK then
  local insert_layout = 0 -- tracks user's preferred Insert mode layout

  local function set_layout(index)
    vim.fn.jobstart({ "swaymsg", "input", "type:keyboard", "xkb_switch_layout", tostring(index) })
  end

  local function get_current_layout()
    local ok, result = pcall(vim.fn.system, { "swaymsg", "-t", "get_inputs" })
    if not ok or not result then
      return 0
    end
    local data = vim.json.decode(result)
    if not data then
      return 0
    end
    for _, input in ipairs(data) do
      if input.type == "keyboard" and input.identifier and input.identifier:find("AT_Translated") then
        return input.xkb_active_layout_index or 0
      end
    end
    return 0
  end

  local grp = vim.api.nvim_create_augroup("sway_keyboard_layout", { clear = true })

  -- Force US layout on startup (Normal mode)
  set_layout(0)

  vim.api.nvim_create_autocmd("InsertEnter", {
    group = grp,
    callback = function()
      set_layout(insert_layout)
    end,
    desc = "Restore user's keyboard layout for Insert mode",
  })

  vim.api.nvim_create_autocmd("InsertLeave", {
    group = grp,
    callback = function()
      insert_layout = get_current_layout()
      set_layout(0)
    end,
    desc = "Switch to US keyboard layout for Normal mode",
  })

  -- Terminal buffers behave like Insert mode
  vim.api.nvim_create_autocmd("TermEnter", {
    group = grp,
    callback = function()
      set_layout(insert_layout)
    end,
    desc = "Restore user's keyboard layout for Terminal mode",
  })

  vim.api.nvim_create_autocmd("TermLeave", {
    group = grp,
    callback = function()
      insert_layout = get_current_layout()
      set_layout(0)
    end,
    desc = "Switch to US keyboard layout when leaving Terminal mode",
  })

  -- Restore layout when quitting Neovim
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = grp,
    callback = function()
      set_layout(insert_layout)
    end,
    desc = "Restore keyboard layout on Neovim exit",
  })
end
