-- ~/.config/nvim/lua/custom/devlog.lua
local M = {}

local function state_path()
  local ok, stdpath = pcall(vim.fn.stdpath, "state")
  if not ok then
    return vim.fn.expand("~/.local/state/nvim")
  end
  return stdpath
end

M.file = state_path() .. "/blink-debug.log"

local function to_s(x)
  if type(x) == "string" then
    return x
  end
  local ok, dumped = pcall(vim.inspect, x)
  return ok and dumped or tostring(x)
end

function M.log(...)
  local ok, f = pcall(io.open, M.file, "a")
  if not ok or not f then
    return
  end
  local parts = { os.date("%Y-%m-%d %H:%M:%S") }
  local args = { ... }
  for i = 1, #args do
    parts[#parts + 1] = to_s(args[i])
  end
  f:write(table.concat(parts, " ") .. "\n")
  f:close()
end

function M.clear()
  pcall(os.remove, M.file)
end

return M
