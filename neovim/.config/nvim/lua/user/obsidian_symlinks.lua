-- Make obsidian.nvim see symlinked notes inside the vault.
--
-- The vault symlinks docs that live in code repos (receivers-*.md, dotfiles,
-- gtimes-*.md). obsidian.nvim skipped them, so [[receivers-readme]] offered to
-- create a new note instead of opening the existing one:
--   * ripgrep (link resolution, search, grep picker) does not follow symlinks
--     without --follow;
--   * the note cache scans with vim.fs.find{ type = "file" }, and vim.fs.dir
--     reports a symlink as type "link", so it never matches;
--   * Note.from_file() resolves the symlink, which breaks find_notes_async()
--     (see patch_note_from_file).
--
-- Fixes, scoped to the vault: rg gets --follow; vim.fs.dir reports a symlink
-- to a regular .md file under the vault as "file" (symlinked directories such
-- as Assets -> ../vault-assets stay "link"); symlinked notes keep their vault
-- path. These wrap plugin internals, so re-test after updating obsidian.nvim.

local M = {}

local function add_follow(cmd)
  if type(cmd) == "table" and cmd[1] == "rg" and not vim.tbl_contains(cmd, "--follow") then
    table.insert(cmd, 2, "--follow")
  end
  return cmd
end

local function patch_ripgrep()
  local ok, rg = pcall(require, "obsidian.search.ripgrep")
  if not ok or rg._symlink_patched then
    return
  end
  for _, name in ipairs({ "build_find_cmd", "build_search_cmd", "build_grep_cmd" }) do
    local orig = rg[name]
    if type(orig) == "function" then
      rg[name] = function(...)
        return add_follow(orig(...))
      end
    end
  end
  rg._symlink_patched = true
end

-- Note.from_file() resolves symlinks, so a vault symlink loads with the path of
-- its target in the code repo. find_notes_async() then sorts its results by the
-- path ripgrep returned (the vault path), the lookup gives nil, the comparison
-- errors inside the coroutine and link resolution never calls back. Keep the
-- vault path for symlinked notes so lookups match and the note opens in-vault.
local function patch_note_from_file(vault)
  local ok, Note = pcall(require, "obsidian.note")
  if not ok or Note._symlink_patched then
    return
  end
  local Path = require("obsidian.path")
  local orig = Note.from_file
  Note.from_file = function(path, opts)
    local note = orig(path, opts)
    local abs = vim.fs.normalize(vim.fn.fnamemodify(tostring(path), ":p"))
    if vim.startswith(abs, vault .. "/") then
      local lstat = vim.uv.fs_lstat(abs)
      if lstat and lstat.type == "link" then
        note.path = Path.new(abs)
      end
    end
    return note
  end
  Note._symlink_patched = true
end

local function patch_fs_dir(vault)
  if vim.fs._obsidian_symlink_patched then
    return
  end
  local orig_dir = vim.fs.dir
  vim.fs.dir = function(path, opts)
    local iter = orig_dir(path, opts)
    local root = type(path) == "string" and vim.fs.normalize(vim.fn.expand(path)) or nil
    if not root or (root ~= vault and not vim.startswith(root, vault .. "/")) then
      return iter
    end
    return function()
      local name, kind, err = iter()
      if kind == "link" and name and name:lower():match("%.md$") then
        local stat = vim.uv.fs_stat(vim.fs.joinpath(root, name))
        if stat and stat.type == "file" then
          kind = "file"
        end
      end
      return name, kind, err
    end
  end
  vim.fs._obsidian_symlink_patched = true
end

---@param vault string vault root, e.g. "~/notes/bgovault"
function M.setup(vault)
  vault = vim.fs.normalize(vim.fn.expand(vault))
  patch_fs_dir(vault)
  patch_ripgrep()
  patch_note_from_file(vault)
end

return M
