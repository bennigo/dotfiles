local M = {}

local defaults = {
  pdf_folder = "Assets/pdf", -- relative to vault root
  link_style = "wiki", -- or "markdown"
  name_func = function(source)
    local base = "pdf"
    if source then
      base = source:match("([^/\\]+)%.pdf") or source:match("([^/\\]+)$") or "pdf"
      base = base:gsub("%.%w+$", "")
    end
    local ts = os.date("%Y%m%d-%H%M%S")
    local name = ts .. "-" .. base
    name = name:lower():gsub("%s+", "-"):gsub("[^%w%-_]+", "")
    return name
  end,
}

local function find_vault_root()
  local dir = vim.fn.expand("%:p:h")
  if dir == "" then
    dir = vim.loop.cwd()
  end
  local prev = nil
  while dir and dir ~= prev do
    if vim.fn.isdirectory(dir .. "/.obsidian") == 1 then
      return dir
    end
    prev = dir
    dir = vim.fn.fnamemodify(dir, ":h")
  end
  return vim.loop.cwd()
end

local function ensure_dir(path)
  if vim.fn.isdirectory(path) == 0 then
    vim.fn.mkdir(path, "p")
  end
end

local function write_file(path, data)
  local f, err = io.open(path, "wb")
  if not f then
    return nil, err
  end
  f:write(data)
  f:close()
  return true
end

local function read_file(path)
  local f, err = io.open(path, "rb")
  if not f then
    return nil, err
  end
  local data = f:read("*a")
  f:close()
  return data
end

local function is_url(s)
  return type(s) == "string" and s:match("^https?://")
end

local function has_pdf_ext(s)
  return type(s) == "string" and s:lower():match("%.pdf$")
end

local function vault_relative(target_abs, vault_root)
  local rel = target_abs:gsub("^" .. vim.pesc(vault_root) .. "/?", "")
  return rel
end

-- Define this ABOVE M.save_pdf so it's in scope.
local function prompt_input(prompt, cb)
  local ok = pcall(function()
    vim.ui.input({ prompt = prompt }, function(ans)
      cb(ans)
    end)
  end)
  if not ok then
    -- Fallback to builtin CLI prompt to avoid UI provider issues
    vim.schedule(function()
      local ans = vim.fn.input(prompt)
      if ans == "" then
        ans = nil
      end
      cb(ans)
    end)
  end
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", defaults, opts or {})
  vim.api.nvim_create_user_command("ObsidianSavePdf", function(cmd)
    M.save_pdf(cmd.fargs)
  end, {
    desc = "Download/copy a PDF into your vault's pdf folder and insert a link",
    nargs = "*",
  })
end

function M.save_pdf(fargs)
  local source = fargs[1] -- URL or local path
  local name = fargs[2] -- optional base name without .pdf

  if not source or source == "" then
    prompt_input("PDF URL or local path: ", function(input)
      if not input or input == "" then
        vim.notify("ObsidianSavePdf cancelled: no source provided", vim.log.levels.WARN)
        return
      end
      M.save_pdf({ input, name })
    end)
    return
  end

  local vault_root = find_vault_root()
  local pdf_dir = vault_root .. "/" .. M.config.pdf_folder
  ensure_dir(pdf_dir)

  local inferred = M.config.name_func(source)
  local base = (name and name ~= "" and name) or inferred
  base = base:gsub("%.pdf$", "")

  local target_abs = pdf_dir .. "/" .. base .. ".pdf"
  local counter = 1
  while vim.fn.filereadable(target_abs) == 1 do
    target_abs = pdf_dir .. "/" .. base .. "-" .. counter .. ".pdf"
    counter = counter + 1
  end

  local ok, err
  if is_url(source) then
    local curl = require("plenary.curl")
    local res = curl.get(source, { compressed = false, raw = true })
    if not res or res.status ~= 200 then
      vim.notify("Failed to download PDF: HTTP " .. tostring(res and res.status or "nil"), vim.log.levels.ERROR)
      return
    end
    if not has_pdf_ext(source) then
      local ctype = res.headers and (res.headers["content-type"] or res.headers["Content-Type"])
      if not ctype or not tostring(ctype):lower():find("application/pdf", 1, true) then
        vim.notify(
          "Warning: Response does not look like a PDF (Content-Type: " .. tostring(ctype) .. ")",
          vim.log.levels.WARN
        )
      end
    end
    ok, err = write_file(target_abs, res.body)
    if not ok then
      vim.notify("Failed to write PDF: " .. tostring(err), vim.log.levels.ERROR)
      return
    end
  else
    local src_abs = vim.fn.fnamemodify(source, ":p")
    if vim.fn.filereadable(src_abs) == 0 then
      vim.notify("Source file not found: " .. src_abs, vim.log.levels.ERROR)
      return
    end
    local data, rerr = read_file(src_abs)
    if not data then
      vim.notify("Failed to read source: " .. tostring(rerr), vim.log.levels.ERROR)
      return
    end
    ok, err = write_file(target_abs, data)
    if not ok then
      vim.notify("Failed to write PDF: " .. tostring(err), vim.log.levels.ERROR)
      return
    end
  end

  local rel = vault_relative(target_abs, vault_root)
  local link
  if M.config.link_style == "markdown" then
    link = string.format("[%s](%s)", vim.fn.fnamemodify(rel, ":t"), rel)
  else
    link = string.format("[[%s]]", rel)
  end

  vim.api.nvim_put({ link }, "c", true, true)
  vim.notify("Saved PDF -> " .. rel, vim.log.levels.INFO)
end

return M
