-- lua/plugins/obsidian.lua

-- Hint to Area mapping. Extend as needed.
local HEADER_HINT_TO_AREA = {
  daily = "Journal",
  meeting = "Meetings",
  meetings = "Meetings",
  project = "Projects",
  journal = "Journal",
  note = "Notes",
  fundur = "Meetings", -- 'fundur' => Meetings
}

local function trim(s)
  return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

-- Find the top YAML header range (0-based inclusive indices): --- ... --- at very top, or nil if missing.
local function get_top_header_range(bufnr)
  bufnr = bufnr or 0
  local n = vim.api.nvim_buf_line_count(bufnr)
  if n == 0 then
    return nil
  end
  local first = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
  if not first or not first:match("^%-%-%-%s*$") then
    return nil
  end
  for i = 1, n - 1 do
    local line = vim.api.nvim_buf_get_lines(bufnr, i, i + 1, false)[1]
    if line and line:match("^%-%-%-%s*$") then
      return 0, i
    end
  end
  return nil
end

-- Parse the current top YAML (flat keys, bracket lists, simple scalars).
-- Returns a table like: { tags = {...}, attendees = {...}, [other_keys] = "value" }
local function parse_top_yaml_header(bufnr)
  bufnr = bufnr or 0
  local s, e = get_top_header_range(bufnr)
  if not s or not e or e <= s then
    return nil
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, s + 1, e, false)
  local meta = { tags = {}, attendees = {} }

  local function strip_quotes(v)
    v = v:gsub([[^"(.*)"$]], "%1")
    v = v:gsub([[^'(.*)'$]], "%1")
    return v
  end

  local function parse_list_or_scalar(v)
    v = trim(v)
    local inner = v:match("^%[(.*)%]$")
    if inner then
      local out = {}
      for token in inner:gmatch("[^,]+") do
        local t = strip_quotes(trim(token))
        if t ~= "" then
          table.insert(out, t)
        end
      end
      return out
    else
      v = strip_quotes(v)
      if v == "" then
        return {}
      end
      return { v }
    end
  end

  for _, raw in ipairs(lines) do
    local k, v = raw:match("^%s*([%w_%-]+)%s*:%s*(.+)%s*$")
    if k and v then
      local key_lower = k:lower()
      local list = parse_list_or_scalar(v)

      if key_lower == "tags" then
        meta.tags = list
      elseif key_lower == "attendees" or key_lower == "atendees" then
        meta.attendees = list
      else
        -- keep simple scalars as strings (if list has 1 item, use that; else keep original joined)
        if #list == 0 then
          meta[key_lower] = ""
        elseif #list == 1 then
          meta[key_lower] = list[1]
        else
          -- join for visibility; you can extend to keep arrays for other keys if needed
          meta[key_lower] = table.concat(list, ", ")
        end
      end
    end
  end

  return meta
end

-- Decide Area from parsed header. Returns Area or nil.
local function area_from_header_meta(meta)
  if not meta then
    return nil
  end

  -- template-like hint keys if you use them
  local hint = meta.template or meta.type or meta.category or meta.kind
  if hint and hint ~= "" then
    local low = tostring(hint):lower()
    for key, area in pairs(HEADER_HINT_TO_AREA) do
      if low:find(key, 1, true) then
        return area
      end
    end
  end

  -- tags mapping
  if meta.tags and #meta.tags > 0 then
    for _, t in ipairs(meta.tags) do
      local low = tostring(t):lower()
      for key, area in pairs(HEADER_HINT_TO_AREA) do
        if low == key or low:find("/" .. key .. "$", 1, true) or low:find("^" .. key .. "/", 1, true) then
          return area
        end
      end
    end
  end

  -- attendees imply a meeting
  if meta.attendees and #meta.attendees > 0 then
    return "Meetings"
  end

  return nil
end

-- Merge two arrays (strings), preserve order, remove duplicates.
local function merge_unique(a, b)
  local out, seen = {}, {}
  local function add(lst)
    for _, v in ipairs(lst or {}) do
      local key = tostring(v)
      if not seen[key] then
        seen[key] = true
        table.insert(out, v)
      end
    end
  end
  add(a or {})
  add(b or {})
  return out
end

local function setup()
  require("obsidian").setup({
    workspaces = {
      {
        name = "bgovault",
        path = "~/notes/bgovault/",
      },
    },

    notes_subdir = "0.Inbox",
    log_level = vim.log.levels.INFO,

    daily_notes = {
      folder = "Journal/daily",
      date_format = "%Y-%m-%d",
      alias_format = "📅 %B %-d, %Y day: %j",
      default_tags = { "daily/notes" },
      template = "template_daily.md",
      workdays_only = true,
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
    disable_frontmatter = false,

    -- Single source of truth for writing front matter:
    -- parse current header, merge tags/attendees, compute Area, then return the final table.
    note_frontmatter_func = function(note)
      if note.title then
        note:add_alias(note.title)
      end

      -- Parse the current header in the buffer right now.
      local header = parse_top_yaml_header(0) or {}
      local header_tags = header.tags or {}
      local header_attendees = header.attendees or {}

      -- Existing values already known by obsidian.nvim
      local existing_tags = note.tags or {}
      local existing_attendees = {}
      if note.metadata then
        existing_attendees = note.metadata.Attendees or note.metadata.attendees or {}
      end

      -- Merge
      local merged_tags = merge_unique(existing_tags, header_tags)
      local merged_attendees = merge_unique(existing_attendees, header_attendees)

      -- Decide Area
      local area = nil
      if note.metadata and note.metadata.Area and tostring(note.metadata.Area) ~= "" then
        area = note.metadata.Area
      else
        area = area_from_header_meta(header)
        -- Daily-by-path default if still empty
        local note_path = tostring(note.path or "")
        if (not area or area == "") and note_path:match("Journal/daily") then
          area = "Journal"
        end
      end

      -- Build the final front matter to write.
      local out = {
        Created = os.date("!%Y-%m-%d %H:%M", os.time()),
        id = note.id,
        aliases = note.aliases,
        tags = merged_tags, -- merged tags will be written back
        Area = area or "",
        Project = "",
        Resource = "",
      }

      -- Include Attendees if present (use capitalized key for readability).
      if #merged_attendees > 0 then
        out.Attendees = merged_attendees
      end

      -- Preserve any additional user metadata already attached to the note object,
      -- but do not overwrite the merged tags/Attendees/Area we just computed.
      if note.metadata ~= nil then
        for k, v in pairs(note.metadata) do
          if k ~= "Attendees" and k ~= "attendees" and k ~= "Area" then
            out[k] = v
          end
        end
      end

      -- Ensure the keys exist even if empty
      out.Area = out.Area or ""
      out.Project = out.Project or ""
      out.Resource = out.Resource or ""

      return out
    end,

    templates = {
      folder = "Templates",
      date_format = "%Y-%m-%d",
      time_format = "%H:%M",
      substitutions = {
        yesterday = function()
          return tostring(os.date("%Y-%m-%d", os.time() - 86400))
        end,
        alias_journal_heading = function(note_date)
          return note_date.partial_note.title or tostring(os.date("📅 %B %-d, %Y, Day: %j", os.time()))
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
      customizations = {},
    },

    follow_url_func = function(url)
      vim.ui.open(url)
    end,

    follow_img_func = function(img)
      vim.ui.open(img)
    end,

    open = {
      use_advanced_uri = false,
      func = vim.ui.open,
    },

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

    -- Keep callbacks minimal; all merging happens inside note_frontmatter_func now.
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
      ["/"] = { char = "󰦕", hl_group = "Obsidianbullet" },
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
    "ibhagwan/fzf-lua",
  },
  config = function()
    setup()

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
    vim.keymap.set("n", "<leader>ojd", "<cmd>ObsidianDailies<cr>", { desc = "[O]bsidian [J]ournal [D]ailies" })

    vim.keymap.set("n", "<leader>or", "<cmd>ObsidianRename<cr>", { desc = "[O]bsidian [R]ename" })
    vim.keymap.set("n", "<leader>ob", "<cmd>ObsidianBacklinks<cr>", { desc = "[O]bsidian [B]acklinks" })
    vim.keymap.set("n", "<leader>oo", "<cmd>ObsidianOpen<cr>", { desc = "[O]bsidian [O]pen" })
    vim.keymap.set("n", "<leader>on", "<cmd>ObsidianNew<cr>", { desc = "[O]bsidian [N]ew" })
    vim.keymap.set("n", "<leader>ot", "<cmd>ObsidianNewFromTemplate<cr>", { desc = "[O]bsidian new from [T]emplate" })
    vim.keymap.set("n", "<leader>oT", "<cmd>ObsidianTemplate<cr>", { desc = "[O]bsidian insert from [T]emplate" })
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
