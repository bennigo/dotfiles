-- Footnote navigation for Obsidian/Markdown in Neovim
-- Provides bidirectional jumping between [^ref] and [^ref]: definitions
-- Integrates with obsidian.nvim's smart_action() via the <CR> mapping

local M = {}

--- Get the footnote reference label under or near the cursor.
--- Matches [^label] but NOT [^label]: (which is a definition).
--- @return string|nil label The footnote label, or nil if not on a reference
function M.cursor_footnote_ref()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1 -- 1-indexed

  -- Find all [^...] on the line, check if cursor is inside one
  local start = 1
  while true do
    local s, e, label = line:find("%[%^([^%]]+)%]", start)
    if not s then break end

    -- Check cursor is within the match
    if col >= s and col <= e then
      -- Exclude definitions: [^label]: at start of line
      local before = line:sub(1, s - 1)
      local after = line:sub(e + 1, e + 1)
      if before:match("^%s*$") and after == ":" then
        return nil -- this is a definition, not a reference
      end
      return label
    end
    start = e + 1
  end
  return nil
end

--- Get the footnote definition label if cursor is on a definition line.
--- Matches lines starting with [^label]:
--- @return string|nil label The footnote label, or nil if not on a definition
function M.cursor_footnote_def()
  local line = vim.api.nvim_get_current_line()
  local label = line:match("^%s*%[%^([^%]]+)%]:")
  return label
end

--- Jump to the footnote definition line for the given label.
--- @param label string The footnote label to find
function M.goto_definition(label)
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  -- Escape special pattern characters in label
  local escaped = label:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
  local pattern = "^%s*%[%^" .. escaped .. "%]:"

  for i, line in ipairs(lines) do
    if line:match(pattern) then
      vim.cmd("normal! m'") -- save to jumplist
      vim.api.nvim_win_set_cursor(0, { i, 0 })
      vim.cmd("normal! zz")
      return
    end
  end
  vim.notify("Footnote definition [^" .. label .. "]: not found", vim.log.levels.WARN)
end

--- Jump to footnote reference(s) for the given label.
--- If one reference: jump directly. If multiple: populate quickfix list.
--- @param label string The footnote label to find
function M.goto_reference(label)
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local escaped = label:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
  local ref_pattern = "%[%^" .. escaped .. "%]"
  local def_pattern = "^%s*%[%^" .. escaped .. "%]:"
  local fname = vim.api.nvim_buf_get_name(bufnr)

  local refs = {}
  for i, line in ipairs(lines) do
    -- Skip definition lines
    if not line:match(def_pattern) and line:find("[^" .. label .. "]", 1, true) then
      -- Verify with proper pattern (plain find above is just a quick pre-filter)
      if line:match(ref_pattern) then
        local col = line:find("%[%^" .. escaped .. "%]")
        table.insert(refs, { filename = fname, lnum = i, col = col or 1, text = line })
      end
    end
  end

  if #refs == 0 then
    vim.notify("No references to [^" .. label .. "] found", vim.log.levels.WARN)
  elseif #refs == 1 then
    vim.cmd("normal! m'")
    vim.api.nvim_win_set_cursor(0, { refs[1].lnum, (refs[1].col or 1) - 1 })
    vim.cmd("normal! zz")
  else
    -- Use fzf-lua floating picker if available, otherwise vim.ui.select
    local ok, fzf = pcall(require, "fzf-lua")
    if ok then
      local items = {}
      for _, ref in ipairs(refs) do
        -- Format as file:line:col:text so fzf-lua previewer can show the right location
        table.insert(items, string.format("%s:%d:%d: %s",
          fname, ref.lnum, ref.col or 1, ref.text:sub(1, 120)))
      end
      fzf.fzf_exec(items, {
        prompt = "Footnote [^" .. label .. "] references> ",
        previewer = "builtin",
        actions = {
          ["default"] = function(selected)
            if selected and selected[1] then
              local lnum = tonumber(selected[1]:match(":(%d+):%d+:"))
              if lnum then
                vim.cmd("normal! m'")
                vim.api.nvim_win_set_cursor(0, { lnum, 0 })
                vim.cmd("normal! zz")
              end
            end
          end,
        },
      })
    else
      -- Fallback: vim.ui.select
      local display = {}
      for i, ref in ipairs(refs) do
        display[i] = string.format("L%d: %s", ref.lnum, ref.text:sub(1, 80))
      end
      vim.ui.select(display, { prompt = "References to [^" .. label .. "]:" }, function(_, idx)
        if idx then
          vim.cmd("normal! m'")
          vim.api.nvim_win_set_cursor(0, { refs[idx].lnum, (refs[idx].col or 1) - 1 })
          vim.cmd("normal! zz")
        end
      end)
    end
  end
end

--- Smart action wrapper: check for footnotes first, then delegate to obsidian.
--- Designed for use with expr=true keymaps: uses vim.schedule + returns "".
--- @return string Empty string (expr mapping contract)
function M.smart_action_with_footnotes()
  local ref_label = M.cursor_footnote_ref()
  if ref_label then
    vim.schedule(function()
      M.goto_definition(ref_label)
    end)
    return ""
  end

  local def_label = M.cursor_footnote_def()
  if def_label then
    vim.schedule(function()
      M.goto_reference(def_label)
    end)
    return ""
  end

  -- Fall through to obsidian smart_action
  return require("obsidian").actions.smart_action()
end

return M
