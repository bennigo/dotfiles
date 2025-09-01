-- lua/plugins/obsidian.lua

-- Obsidian.nvim setup with YAML-merge wrappers that:
-- - Parse the template file into YAML + Body
-- - Merge YAML into the note's front matter
-- - Insert ONLY the Body into the buffer (no duplicate YAML in the body)
-- - Ensure front matter merge happens at the right time:
--     * New note: set a global "pending template" BEFORE :ObsidianNew
--     * Existing note: set buffer var and (optionally) auto-save to regenerate header
-- Also bypasses Snacks UI by using vim.fn.inputlist and vim.fn.input.

local uv = vim.uv or vim.loop

-- Simple pattern-escape (compat if vim.pesc is unavailable)
local function pesc(s)
  return (s:gsub("([^%w])", "%%%1"))
end

-- Centralized config reused across helpers and obsidian setup.
local CFG = {
  workspaces = {
    {
      name = "bgovault",
      path = "~/notes/bgovault/",
    },
  },

  notes_subdir = "0.Inbox",

  daily_notes = {
    folder = "Journal/daily",
    date_format = "%Y-%m-%d",
    alias_format = "📅 %B %-d, %Y day: %j",
    default_tags = { "daily/notes" },
    template = "template_daily.md",
    workdays_only = true,
  },

  templates = {
    folder = "Templates",
    date_format = "%Y-%m-%d",
    time_format = "%H:%M",
    substitutions = {
      yesterday = function()
        return tostring(os.date("%Y-%m-%d", os.time() - 86400))
      end,
      alias_journal_heading = function(note_date)
        return note_date.partial_note and note_date.partial_note.title
          or tostring(os.date("📅 %B %-d, %Y, Day: %j", os.time()))
      end,
      alias_heading = function()
        return tostring(os.date("📅 %B %-d, %Y, Day: %j", os.time()))
      end,
      timed_task = function()
        return string.format("- [ ] (%s): Task 1", os.date("%Y-%m-%d", os.time()))
      end,
      meeting_type = function()
        return "TEST"
      end,
    },
  },

  -- If true, after inserting a template into an existing note, perform a silent write
  -- to trigger obsidian to regenerate front matter immediately.
  auto_write_after_template = true,
}

-- Resolve active workspace root based on current buffer/cwd.
local function get_active_ws_root()
  local bufname = vim.api.nvim_buf_get_name(0)
  local base = bufname ~= "" and (vim.fs.dirname(bufname) or bufname) or (uv.cwd and uv.cwd() or vim.fn.getcwd())
  local chosen = vim.fn.expand(CFG.workspaces[1].path)
  for _, ws in ipairs(CFG.workspaces) do
    local p = vim.fn.expand(ws.path)
    if base:sub(1, #p) == p then
      chosen = p
      break
    end
  end
  return vim.fs.normalize(chosen)
end

local function templates_root()
  return vim.fs.normalize(get_active_ws_root() .. "/" .. (CFG.templates.folder or "Templates"))
end

local function rel_from_abs(abs, root)
  local r = vim.fs.normalize(abs)
  root = vim.fs.normalize(root)
  r = r:gsub("^" .. pesc(root) .. "/?", "")
  return r
end

local function find_template_abs(user_input)
  if not user_input or user_input == "" then
    return nil
  end
  local troot = templates_root()
  local candidate = user_input:gsub("\\", "/")
  local abs = vim.fs.normalize(troot .. "/" .. candidate)
  local st = uv.fs_stat(abs)
  if st and st.type == "file" then
    return abs
  end
  if not abs:match("%.md$") then
    local with_md = abs .. ".md"
    st = uv.fs_stat(with_md)
    if st and st.type == "file" then
      return with_md
    end
  end
  return nil
end

-- Render placeholders in text ({{date}}, {{time}}, {{title}}, plus custom substitutions).
local function render_placeholders(text, ctx)
  local date_fmt = (CFG.templates and CFG.templates.date_format) or "%Y-%m-%d-%a"
  local time_fmt = (CFG.templates and CFG.templates.time_format) or "%H:%M"

  local rendered = text
  rendered = rendered:gsub("{{%s*date%s*}}", os.date(date_fmt))
  rendered = rendered:gsub("{{%s*time%s*}}", os.date(time_fmt))

  if ctx and ctx.title and ctx.title ~= "" then
    rendered = rendered:gsub("{{%s*title%s*}}", ctx.title)
  end

  local subs = (CFG.templates and CFG.templates.substitutions) or {}
  for key, fn in pairs(subs) do
    if type(fn) == "function" then
      local ok, val = pcall(fn, ctx)
      if ok and type(val) == "string" then
        local pattern = "{{%s*" .. pesc(key) .. "%s*}}"
        rendered = rendered:gsub(pattern, val)
      end
    end
  end

  return rendered
end

-- Utility: read all lines of a file safely.
local function readfile_lines(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok or not lines or #lines == 0 then
    return {}
  end
  return lines
end

-- Split a template into YAML (as text) and Body (text), applying placeholder rendering to both.
local function read_template_parts(template_abs_path, ctx)
  local lines = readfile_lines(template_abs_path)
  if #lines == 0 then
    return "", ""
  end

  local start_idx, end_idx
  for i, line in ipairs(lines) do
    if line:match("^%-%-%-%s*$") then
      if not start_idx then
        start_idx = i
      else
        end_idx = i
        break
      end
    end
  end

  local yaml_text = ""
  local body_text = table.concat(lines, "\n")
  if start_idx and end_idx and end_idx > start_idx then
    local y = {}
    for i = start_idx + 1, end_idx - 1 do
      y[#y + 1] = lines[i]
    end
    yaml_text = table.concat(y, "\n")
    local b = {}
    for i = end_idx + 1, #lines do
      b[#b + 1] = lines[i]
    end
    body_text = table.concat(b, "\n")
  end

  yaml_text = render_placeholders(yaml_text, ctx)
  body_text = render_placeholders(body_text, ctx)
  return yaml_text, body_text
end

-- Parse YAML header from a template file and return a Lua table (uses front-matter.nvim if available).
local function parse_template_yaml(template_abs_path, ctx)
  if not template_abs_path or template_abs_path == "" then
    return {}
  end

  local yaml_text, _ = read_template_parts(template_abs_path, ctx)

  -- Try to parse via front-matter.nvim; if missing, skip gracefully.
  local ok_req, fm_mod = pcall(require, "front-matter")
  if not ok_req then
    return {}
  end

  -- Write a tiny temp file with just the YAML so front-matter can parse it.
  local tmp = vim.fn.tempname() .. ".md"
  local tmp_lines = { "---" }
  vim.list_extend(tmp_lines, vim.split(yaml_text, "\n", { plain = true }))
  table.insert(tmp_lines, "---")
  table.insert(tmp_lines, "")
  pcall(vim.fn.writefile, tmp_lines, tmp)

  local meta = {}
  local ok_fm, fm = pcall(function()
    return fm_mod.get({ tmp })
  end)
  if ok_fm and fm and fm[tmp] then
    meta = fm[tmp]
  end
  pcall(uv.fs_unlink, tmp)

  return type(meta) == "table" and meta or {}
end

-- Detect front matter range in current buffer. Returns start_idx, end_idx (1-based, inclusive) or nil.
local function find_frontmatter_range_in_buf(bufnr)
  bufnr = bufnr or 0
  local total = vim.api.nvim_buf_line_count(bufnr)
  if total == 0 then
    return nil
  end
  local first = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
  if not first or not first:match("^%-%-%-%s*$") then
    return nil
  end
  for i = 1, math.min(total, 5000) do
    local line = vim.api.nvim_buf_get_lines(bufnr, i - 1, i, false)[1]
    if i > 1 and line and line:match("^%-%-%-%s*$") then
      return 1, i
    end
  end
  return nil
end

-- Insert template body at the cursor (used by :ObsidianTemplateYAML).
local function insert_template_body_at_cursor(template_abs_path, ctx)
  local _, body_text = read_template_parts(template_abs_path, ctx)
  if not body_text or body_text == "" then
    return
  end
  local body_lines = vim.split(body_text, "\n", { plain = true })
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1 -- 0-based
  vim.api.nvim_buf_set_lines(0, row, row, false, body_lines)
end

-- Insert template body after front matter if present, otherwise at top (used by :ObsidianNewFromTemplateYAML).
local function insert_template_body_after_frontmatter(template_abs_path, ctx)
  local _, body_text = read_template_parts(template_abs_path, ctx)
  if not body_text or body_text == "" then
    return
  end
  local body_lines = vim.split(body_text, "\n", { plain = true })
  local s, e = find_frontmatter_range_in_buf(0)
  local insert_row = 0
  if s and e then
    insert_row = e -- insert after closing '---' (1-based end -> 0-based index = e)
  end
  vim.api.nvim_buf_set_lines(0, insert_row, insert_row, false, body_lines)
end

-- Picker: command-line list using vim.fn.inputlist to avoid Snacks/vim.ui overrides.
local function pick_template_async(cb)
  local troot = templates_root()
  -- Collect all markdown files recursively.
  local files = vim.fn.globpath(troot, "**/*.md", false, true) or {}
  if #files == 0 then
    vim.notify("No templates found in " .. troot, vim.log.levels.WARN)
    return
  end
  table.sort(files)
  local rels = vim.tbl_map(function(abs)
    return rel_from_abs(abs, troot)
  end, files)

  local lines = { "Select a template:" }
  for i, rel in ipairs(rels) do
    table.insert(lines, string.format("%d) %s", i, rel))
  end
  local choice = vim.fn.inputlist(lines)
  if choice < 1 or choice > #rels then
    return
  end
  local rel = rels[choice]
  cb({
    relpath = rel,
    abspath = vim.fs.normalize(troot .. "/" .. rel),
  })
end

-- Wrapper: Insert template BODY and record template path for YAML merge (at cursor).
local function do_insert_template_with_yaml_at_cursor(rel_or_abs)
  local troot = templates_root()
  local abspath = rel_or_abs
  if not rel_or_abs:match("^/") and not rel_or_abs:match("^%a:[/\\]") then
    abspath = troot .. "/" .. rel_or_abs
  end
  if not abspath:match("%.md$") then
    abspath = abspath .. ".md"
  end
  abspath = vim.fs.normalize(abspath)
  -- Record for YAML merge in note_frontmatter_func (for existing note, on save)
  vim.b.obsidian_template_path = abspath
  -- Insert only the body, at the cursor
  local title = vim.fn.expand("%:t:r")
  insert_template_body_at_cursor(abspath, { title = title })

  if CFG.auto_write_after_template then
    -- Trigger Obsidian to regenerate front matter on save
    vim.schedule(function()
      local ok, err = pcall(vim.cmd, "silent write")
      if not ok then
        vim.notify("Write failed: " .. tostring(err), vim.log.levels.WARN)
      end
    end)
  end
end

-- Wrapper: Record pending template (global), create new note, then insert BODY after front matter.
local function do_new_note_from_template(template_rel, title)
  -- Set global pending path BEFORE creating the note so frontmatter merge happens during creation.
  vim.g.obsidian_pending_template_path = vim.fs.normalize(templates_root() .. "/" .. template_rel)

  vim.cmd("ObsidianNew " .. vim.fn.fnameescape(title))

  -- Insert only the body after the header once the buffer is created.
  vim.schedule(function()
    insert_template_body_after_frontmatter(vim.g.obsidian_pending_template_path, { title = title })
    -- Optionally save to persist header/body immediately
    if CFG.auto_write_after_template then
      local ok, err = pcall(vim.cmd, "silent write")
      if not ok then
        vim.notify("Write failed: " .. tostring(err), vim.log.levels.WARN)
      end
    end
  end)
end

-- Command: :ObsidianTemplateYAML [template]
local function cmd_template_yaml(opts)
  local arg = opts.args
  if arg and arg ~= "" then
    local abs = find_template_abs(arg)
    if not abs then
      vim.notify("Template not found: " .. arg, vim.log.levels.WARN)
      return
    end
    do_insert_template_with_yaml_at_cursor(rel_from_abs(abs, templates_root()))
  else
    pick_template_async(function(choice)
      if not choice then
        return
      end
      do_insert_template_with_yaml_at_cursor(choice.relpath)
    end)
  end
end

-- Command: :ObsidianNewFromTemplateYAML [template] [title...]
local function cmd_new_from_template_yaml(opts)
  local fargs = opts.fargs or {}
  local template_arg = fargs[1]
  local title = nil
  if #fargs >= 2 then
    title = table.concat(fargs, " ", 2)
  end

  local function do_create_with(template_rel)
    if not title or title == "" then
      local input_title = vim.fn.input("New note title: ")
      if not input_title or input_title == "" then
        return
      end
      title = input_title
    end
    do_new_note_from_template(template_rel, title)
  end

  if template_arg and template_arg ~= "" then
    local abs = find_template_abs(template_arg)
    if not abs then
      vim.notify("Template not found: " .. template_arg, vim.log.levels.WARN)
      return
    end
    local rel = rel_from_abs(abs, templates_root())
    do_create_with(rel)
  else
    pick_template_async(function(choice)
      if not choice then
        return
      end
      do_create_with(choice.relpath)
    end)
  end
end

-- Parse YAML header from a template file and return a Lua table via front-matter.nvim.
local function parse_template_yaml_for_merge(template_abs_path, ctx)
  return parse_template_yaml(template_abs_path, ctx)
end

local function setup()
  require("obsidian").setup({
    workspaces = CFG.workspaces,

    open = {
      use_advanced_uri = false,
      func = vim.ui.open,
    },

    notes_subdir = CFG.notes_subdir,

    log_level = vim.log.levels.INFO,

    daily_notes = {
      folder = CFG.daily_notes.folder,
      date_format = CFG.daily_notes.date_format,
      alias_format = CFG.daily_notes.alias_format,
      default_tags = CFG.daily_notes.default_tags,
      template = CFG.daily_notes.template,
      workdays_only = CFG.daily_notes.workdays_only,
    },

    completion = {
      nvim_cmp = true,
      blink = true,
      min_chars = 2,
      create_new = true,
    },

    new_notes_location = "notes_subdir",

    note_id_func = function(title)
      local suffix = ""
      if title ~= nil then
        suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
      else
        for _ = 1, 4 do
          suffix = suffix .. string.char(math.random(65, 90))
        end
      end
      return tostring(os.time()) .. "-" .. suffix
    end,

    note_path_func = function(spec)
      local path = spec.dir / tostring(spec.id)
      return path:with_suffix(".md")
    end,

    wiki_link_func = function(opts)
      return require("obsidian.util").wiki_link_id_prefix(opts)
    end,

    markdown_link_func = function(opts)
      return require("obsidian.util").markdown_link(opts)
    end,

    preferred_link_style = "wiki",

    -- Keep plugin-managed frontmatter; we merge from template YAML.
    disable_frontmatter = false,

    note_frontmatter_func = function(note)
      if note.title then
        note:add_alias(note.title)
      end

      local out = {
        Created = os.date("!%Y-%m-%d %H:%M", os.time()),
        id = note.id,
        aliases = note.aliases,
        tags = note.tags,
        Area = "",
        Project = "",
        Resource = "",
      }

      -- Merge any manually-added fields.
      if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
        for k, v in pairs(note.metadata) do
          out[k] = v
        end
      end

      -- Prefer a pending template (for new notes), otherwise buffer-local (for existing notes)
      local template_path = nil
      if vim.g.obsidian_pending_template_path and vim.g.obsidian_pending_template_path ~= "" then
        template_path = vim.g.obsidian_pending_template_path
      elseif vim.b.obsidian_template_path and vim.b.obsidian_template_path ~= "" then
        template_path = vim.b.obsidian_template_path
      end

      if template_path then
        local tpl_meta = parse_template_yaml_for_merge(template_path, { title = note.title or "" })
        for k, v in pairs(tpl_meta or {}) do
          out[k] = v
        end
      end

      -- Also merge YAML from daily template if this is a daily note.
      local note_path_str = tostring(note.path or "")
      local daily_folder_pat = pesc(CFG.daily_notes.folder)
      if note_path_str:match(daily_folder_pat) then
        local daily_tpl_abs = templates_root() .. "/" .. (CFG.daily_notes.template or "")
        local tpl_meta = parse_template_yaml_for_merge(daily_tpl_abs, { title = note.title or "" })
        for k, v in pairs(tpl_meta or {}) do
          out[k] = v
        end
        if out.Area == nil or out.Area == "" then
          out.Area = "Journal"
        end
      end

      -- Clear global pending template so it only applies to the note being created
      if vim.g.obsidian_pending_template_path then
        vim.g.obsidian_pending_template_path = nil
      end

      out.Area = out.Area or ""
      out.Project = out.Project or ""
      out.Resource = out.Resource or ""
      return out
    end,

    templates = {
      folder = CFG.templates.folder,
      date_format = CFG.templates.date_format,
      time_format = CFG.templates.time_format,
      substitutions = CFG.templates.substitutions,
      customizations = {},
    },

    follow_url_func = function(url)
      vim.ui.open(url)
    end,

    follow_img_func = function(img)
      vim.ui.open(img)
    end,

    picker = {
      name = "fzf-lua",
      note_mappings = {
        new = "<C-x>",
        insert_link = "<C-l>",
      },
      tag_mappings = {
        tag_note = "<C-x>",
        insert_tag = "<C-l>",
      },
    },

    sort_by = "modified",
    sort_reversed = true,

    search_max_lines = 1000,

    open_notes_in = "current",

    callbacks = {
      post_setup = function(client) end,
      enter_note = function(client, note) end,
      leave_note = function(client, note) end,
      pre_write_note = function(client, note) end,
      post_set_workspace = function(client, workspace) end,
    },

    ui = {
      enable = true,
      ignore_conceal_warn = false,
      update_debounce = 200,
      max_file_length = 5000,
      bullets = { char = "•", hl_group = "ObsidianBullet" },
      external_link_icon = { char = "", hl_group = "ObsidianExtLinkIcon" },
      reference_text = { hl_group = "ObsidianRefText" },
      highlight_text = { hl_group = "ObsidianHighlightText" },
      tags = { hl_group = "ObsidianTag" },
      block_ids = { hl_group = "ObsidianBlockID" },
      hl_groups = {
        ObsidianTodo = { bold = true, fg = "#f78c6c" },
        ObsidianDeadline = { bold = true, fg = "#A6E3A2" },
        ObsidianDone = { bold = true, fg = "#89ddff" },
        ObsidianRightArrow = { bold = true, fg = "#f78c6c" },
        ObsidianTilde = { bold = true, fg = "#ff5370" },
        ObsidianImportant = { bold = true, fg = "#d73128" },
        ObsidianBullet = { bold = true, fg = "#89ddff" },
        ObsidianRefText = { underline = true, fg = "#c792ea" },
        ObsidianExtLinkIcon = { fg = "#c792ea" },
        ObsidianTag = { italic = true, fg = "#89ddff" },
        ObsidianBlockID = { italic = true, fg = "#89ddff" },
        ObsidianHighlightText = { bg = "#75662e" },
      },
    },

    attachments = {
      img_folder = "Assets/attachments",
      img_name_func = function()
        return string.format("Pasted image %s", os.date("%Y%m%d%H%M%S"))
      end,
      confirm_img_paste = true,
    },

    footer = {
      enabled = true,
      format = "{{backlinks}} backlinks  {{properties}} properties  {{words}} words  {{chars}} chars",
      hl_group = "Comment",
      separator = string.rep("-", 80),
    },

    checkbox = {
      [" "] = { char = "󰄱", hl_group = "ObsidianTodo" },
      ["-"] = { char = "🕛", hl_group = "ObsidianTodo" },
      ["/"] = { char = "󰦕", hl_group = "ObsidianBullet" },
      ["x"] = { char = "", hl_group = "ObsidianDone" },
      [">"] = { char = "", hl_group = "ObsidianRightArrow" },
      ["~"] = { char = "󰰱", hl_group = "ObsidianTilde" },
      ["!"] = { char = "", hl_group = "ObsidianImportant" },
      order = { " ", "-", "/", "x", ">", "~", "!" },
    },
  })
end

return {
  "obsidian-nvim/obsidian.nvim",
  enabled = true,
  lazy = false,
  ft = "markdown",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "ibhagwan/fzf-lua", -- used by obsidian.nvim for its own pickers
    { "goropikari/front-matter.nvim" }, -- required here to parse YAML for merging
  },
  config = function()
    setup()

    -- User commands that enable YAML merging for templates:
    vim.api.nvim_create_user_command("ObsidianTemplateYAML", cmd_template_yaml, { nargs = "?" })
    vim.api.nvim_create_user_command("ObsidianNewFromTemplateYAML", cmd_new_from_template_yaml, { nargs = "*" })

    -- Toggle checkbox and smart_action
    vim.keymap.set("n", "<leader>oc", function()
      return require("obsidian").util.toggle_checkbox()
    end, { buffer = true, desc = "[O]bsidian Toggle [C]heckbox" })

    vim.keymap.set("n", "<CR>", function()
      return require("obsidian").util.smart_action()
    end, { buffer = true, expr = true, desc = "[O]bsidian Smart_action" })

    -- journaling
    vim.keymap.set("n", "<leader>ojy", "<cmd>ObsidianYesterday<cr>", { desc = "[O]bsidian [J]ournal [Y]esterday" })
    vim.keymap.set("n", "<leader>ojt", "<cmd>ObsidianToday<cr>", { desc = "[O]bsidian [J]ournal [T]oday" })
    vim.keymap.set("n", "<leader>ojm", "<cmd>ObsidianTomorrow<cr>", { desc = "[O]bsidian [J]ournal [T]omorrow" })
    vim.keymap.set("n", "<leader>ojd", "<cmd>ObsidianDailies<cr>", { desc = "[O]bsidian [J]ournal [D]dailies" })

    vim.keymap.set("n", "<leader>or", "<cmd>ObsidianRename<cr>", { desc = "[O]bsidian [R]ename" })
    vim.keymap.set("n", "<leader>ob", "<cmd>ObsidianBacklinks<cr>", { desc = "[O]bsidian [B]backlinks" })
    vim.keymap.set("n", "<leader>oo", "<cmd>ObsidianOpen<cr>", { desc = "[O]bsidian [O]pen" })
    vim.keymap.set("n", "<leader>on", "<cmd>ObsidianNew<cr>", { desc = "[O]bsidian [N]ew" })

    -- YAML-aware template commands (use these instead of the built-ins):
    vim.keymap.set(
      "n",
      "<leader>ot",
      "<cmd>ObsidianNewFromTemplateYAML<cr>",
      { desc = "[O]bsidian new from [T]emplate (+YAML)" }
    )
    vim.keymap.set(
      "n",
      "<leader>oT",
      "<cmd>ObsidianTemplateYAML<cr>",
      { desc = "[O]bsidian insert from [T]emplate (+YAML)" }
    )

    -- Extra example mapping kept:
    vim.keymap.set(
      "n",
      "<leader>oN",
      "<cmd>ObsidianTemplate template_time<cr>",
      { desc = "[O]bsidian insert now point [T]emplate" }
    )

    vim.keymap.set("n", "<leader>os", "<cmd>ObsidianSearch<cr>", { desc = "[O]bsidian [S]earch" })
    vim.keymap.set("n", "<leader>op", "<cmd>ObsidianPasteImg<cr>", { desc = "[O]bsidian [P]aste image" })
  end,
}
