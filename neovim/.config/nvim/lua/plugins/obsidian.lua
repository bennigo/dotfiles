local function setup()
  require("obsidian").setup({
    workspaces = {
      -- {
      -- 	name = "work",
      -- 	path = "~/notes/vault/work",
      -- },
      {
        name = "bgovault",
        path = "~/notes/bgovault/",
      },
    },
    open = {
      -- Optional, set to true if you use the Obsidian Advanced URI plugin.
      -- https://github.com/Vinzent03/obsidian-advanced-uri
      use_advanced_uri = false,
      -- func = vim.ui.open,
    },
    -- Optional, if you keep notes in a specific subdirectory of your vault.
    notes_subdir = "0.Inbox",

    -- Optional, set the log level for obsidian.nvim. This is an integer corresponding to one of the log
    -- levels defined by "vim.log.levels.*".
    log_level = vim.log.levels.INFO,

    daily_notes = {
      -- Optional, if you keep daily notes in a separate directory.
      folder = "Journal/daily",
      -- Optional, if you want to change the date format for the ID of daily notes.
      date_format = "%Y-%m-%d",
      -- Optional, if you want to change the date format of the default alias of daily notes.
      alias_format = "📅 %B %-d, %Y day: %j",
      -- Optional, default tags to add to each new daily note created.
      default_tags = { "type/daily-note" },
      -- Optional, if you want to automatically insert a template from your template directory like 'daily.md'
      template = "template_daily.md",
      -- Optional, if you want `Obsidian yesterday` to return the last work day or `Obsidian tomorrow` to return the next work day.
      workdays_only = true,
    },

    -- Optional, completion of wiki links, local markdown links, and tags using nvim-cmp.
    completion = {
      -- Set to false to disable completion.
      nvim_cmp = false,
      blink = true, -- Set to false to disable blink.
      -- Trigger completion at 2 chars.
      min_chars = 2,
      -- Set to false to disable new note creation in the picker
      create_new = true,
    },

    -- Where to put new notes. Valid options are
    --  * "current_dir" - put new notes in same directory as the current buffer.
    --  * "notes_subdir" - put new notes in the default notes subdirectory.
    new_notes_location = "notes_subdir",

    -- Optional, customize how note IDs are generated given an optional title.
    ---@param title string|?
    ---@return string
    note_id_func = function(title)
      -- Preserve date-formatted IDs so note_path_func can route them to Journal/daily/
      if title and title:match("^%d%d%d%d%-%d%d%-%d%d$") then
        return title
      end
      -- Create note IDs in a Zettelkasten format with a timestamp and a suffix.
      local suffix = ""
      if title ~= nil then
        -- If title is given, transform it into valid file name.
        suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
      else
        -- If title is nil, just add 4 random uppercase letters to the suffix.
        for _ = 1, 4 do
          suffix = suffix .. string.char(math.random(65, 90))
        end
      end
      return tostring(os.time()) .. "-" .. suffix
    end,

    -- Optional, customize how note file names are generated given the ID, target directory, and title.
    ---@param spec { id: string, dir: obsidian.Path, title: string|? }
    ---@return string|obsidian.Path The full path to the new note.
    note_path_func = function(spec)
      local id_str = tostring(spec.id)
      -- Route YYYY-MM-DD IDs to Journal/daily/ (daily note navigation links)
      if id_str:match("^%d%d%d%d%-%d%d%-%d%d$") then
        return vim.fn.expand("~/notes/bgovault") .. "/Journal/daily/" .. id_str .. ".md"
      end
      local path = spec.dir / tostring(spec.id)
      return path:with_suffix(".md")
    end,

    -- Optional, customize how wiki links are formatted. You can set this to one of:
    --  * "use_alias_only", e.g. '[[Foo Bar]]'
    --  * "prepend_note_id", e.g. '[[foo-bar|Foo Bar]]'
    --  * "prepend_note_path", e.g. '[[foo-bar.md|Foo Bar]]'
    --  * "use_path_only", e.g. '[[foo-bar.md]]'
    -- Or you can set it to a function that takes a table of options and returns a string, like this:
    wiki_link_func = function(opts)
      return require("obsidian.util").wiki_link_id_prefix(opts)
    end,

    -- Optional, customize how markdown links are formatted.
    markdown_link_func = function(opts)
      return require("obsidian.util").markdown_link(opts)
    end,

    -- Either 'wiki' or 'markdown'.
    preferred_link_style = "wiki",

    -- Frontmatter configuration (replaces deprecated disable_frontmatter and note_frontmatter_func)
    frontmatter = {
      enabled = true,
      ---@return table
      func = function(note)
      -- Add the title of the note as an alias.
      if note.title then
        note:add_alias(note.title)
      end

      local out = {
        id = note.id,
        created = os.date("!%Y-%m-%d %H:%M", os.time()),
        aliases = note.aliases,
        tags = note.tags,
        area = "",
        project = "",
        resource = "",
      }

      -- `note.metadata` contains any manually added fields in the frontmatter.
      -- So here we just make sure those fields are kept in the frontmatter.
      if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
        for k, v in pairs(note.metadata) do
          out[k] = v
        end
      end

      -- If this is a daily note (by path), set area to "Journal" if not already set,
      -- add type/daily-note tag and date alias (matching daily_notes config).
      local note_path = tostring(note.path or "")
      local date_match = note_path:match("Journal/daily/(%d%d%d%d%-%d%d%-%d%d)%.md")
      if date_match then
        if out.area == nil or out.area == "" then
          out.area = "Journal"
        end
        -- Add type/daily-note tag
        if out.tags and not vim.tbl_contains(out.tags, "type/daily-note") then
          table.insert(out.tags, "type/daily-note")
        end
        -- Add date alias (matches daily_notes.alias_format)
        local y, m, d = date_match:match("(%d+)-(%d+)-(%d+)")
        local ts = os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 12 })
        local date_alias = os.date("📅 %B %-d, %Y day: %j", ts)
        if out.aliases and not vim.tbl_contains(out.aliases, date_alias) then
          table.insert(out.aliases, date_alias)
        end
      elseif note_path:match("Journal/daily") and (out.area == nil or out.area == "") then
        out.area = "Journal"
      end

      -- Ensure keys exist, even if still empty after merges.
      out.area = out.area or ""
      out.project = out.project or ""
      out.resource = out.resource or ""

      return out
      end,
    },

    templates = {
      folder = "Templates",
      date_format = "%Y-%m-%d",
      time_format = "%H:%M",
      -- A map for custom variables, the key should be the variable and the value a function
      substitutions = {

        yesterday = function()
          return tostring(os.date("%Y-%m-%d", os.time() - 86400))
        end,

        tomorrow = function()
          return tostring(os.date("%Y-%m-%d", os.time() + 86400))
        end,

        last_week = function()
          local t = os.time() - 7 * 86400
          return os.date("%G-W%V", t)
        end,

        next_week = function()
          local t = os.time() + 7 * 86400
          return os.date("%G-W%V", t)
        end,

        monday = function()
          local t = os.time()
          local wday = os.date("*t", t).wday -- 1=Sun, 2=Mon, ...
          local offset = (wday == 1) and -6 or (2 - wday)
          return os.date("%Y-%m-%d", t + offset * 86400)
        end,

        sunday = function()
          local t = os.time()
          local wday = os.date("*t", t).wday
          local offset = (wday == 1) and 0 or (8 - wday)
          return os.date("%Y-%m-%d", t + offset * 86400)
        end,

        alias_journal_heading = function(note_date)
          return note_date.partial_note.title or tostring(os.date("📅 %B %-d, %Y, Day: %j", os.time()))
        end,

        alias_heading = function()
          return tostring(os.date("📅 %B %-d, %Y, Day: %j", os.time()))
        end,

        property = function()
          return "property"
        end,

        meeting_type = function()
          return "TEST ⏰ 🕛"
        end,
      },

      -- A map for configuring unique directories and paths for specific templates
      --- See: https://github.com/obsidian-nvim/obsidian.nvim/wiki/Template#customizations
      customizations = {
        template_resource = {
          note_id_func = function(title)
            local suffix = ""
            if title ~= nil then
              -- If title is given, transform it into valid file name.
              suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
            else
              -- If title is nil, just add 4 random uppercase letters to the suffix.
              for _ = 1, 4 do
                suffix = suffix .. string.char(math.random(65, 90))
              end
            end
            return tostring(os.time()) .. "-" .. suffix
          end,
          notes_subdir = "3.Resources",
        },

        template_ki_stjorn_meeting = {
          -- This function currently only receives the note title as an input
          note_id_func = function(title)
            local suffix = ""
            if title ~= nil then
              suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
            else
              suffix = "ki_stjonarfundur"
            end
            vim.notify(vim.inspect(title), vim.log.levels.DEBUG, { title = "Using template: " })

            return tostring(os.time()) .. "-" .. suffix
          end,
        },
      },
    },

    -- Resolve image path in vault before opening (vim.ui.open passes bare filename)
    follow_img_func = function(img)
      local vault_root = vim.fn.expand("~/notes/bgovault")
      local full = vault_root .. "/" .. img
      if vim.fn.filereadable(full) == 1 then
        vim.ui.open(full)
      else
        -- Search for the file anywhere in the vault
        local found = vim.fn.globpath(vault_root, "**/" .. img, false, true)
        if #found > 0 then
          vim.ui.open(found[1])
        else
          vim.notify("Image not found: " .. img, vim.log.levels.WARN)
        end
      end
    end,

    -- Use new command format (e.g., "Obsidian backlinks" instead of "ObsidianBacklinks")
    legacy_commands = false,

    picker = {
      -- Set your preferred picker. Can be one of 'telescope.nvim', 'fzf-lua', or 'mini.pick'.
      name = "fzf-lua",
      -- Optional, configure key mappings for the picker. These are the defaults.
      -- Not all pickers support all mappings.
      note_mappings = {
        -- Create a new note from your query.
        new = "<C-x>",
        -- Insert a link to the selected note.
        insert_link = "<C-l>",
      },
      tag_mappings = {
        -- Add tag(s) to current note.
        tag_note = "<C-x>",
        -- Insert a tag at the current location.
        insert_tag = "<C-l>",
      },
    },

    -- Search configuration (replaces deprecated top-level sort_by, sort_reversed, search_max_lines)
    search = {
      -- Sort search results by "path", "modified", "accessed", or "created".
      sort_by = "modified",
      sort_reversed = true,
      -- Maximum number of lines to read from notes on disk when performing searches.
      max_lines = 1000,
    },

    -- Optional, determines how certain commands open notes. The valid options are:
    -- 1. "current" (the default) - to always open in the current window
    -- 2. "vsplit" - to open in a vertical split if there's not already a vertical split
    -- 3. "hsplit" - to open in a horizontal split if there's not already a horizontal split
    open_notes_in = "current",

    -- Custom open: use Obsidian Local REST API when running, xdg-open when not.
    -- Both xdg-open and gio open the note in a new pop-out window instead of reusing
    -- the existing one. The REST API's /open/ endpoint navigates within the existing window.
    open = {
      func = function(uri)
        -- Extract vault-relative file path from obsidian:// URI
        local file = uri:match("file=([^&]+)")
        if file then
          file = vim.uri_decode(file)
        end

        local is_running = vim.fn.system("pgrep -x obsidian"):match("%d+") ~= nil
        if is_running and file then
          -- Use REST API to open file in existing window (no new window)
          vim.fn.jobstart({
            "curl", "-sk",
            "-H", "Authorization: Bearer 633d0602c1469b69bd560a2d52b5ee7dc0dc830a8f9b50a45fb4064aca4e567c",
            "-X", "POST",
            "https://localhost:27124/open/" .. file,
          }, {
            detach = true,
            on_stdout = function() end,
            on_stderr = function() end,
          })
          -- Focus the Obsidian window on Sway (matches both Wayland app_id and XWayland class)
          vim.fn.jobstart({ "swaymsg", '[app_id="obsidian"] focus; [class="obsidian"] focus' }, {
            detach = true,
            on_stdout = function() end,
            on_stderr = function() end,
          })
        else
          -- Obsidian not running — launch with gtk-launch (same as Sway startup),
          -- then show from scratchpad after it appears.
          vim.fn.jobstart({ "gtk-launch", "obsidian.desktop" }, {
            detach = true,
            on_stdout = function() end,
            on_stderr = function() end,
          })
          -- Poll for window to land in scratchpad (for_window rule must fire first),
          -- then show it. Using jq to check the scratchpad node specifically avoids
          -- a race where the window exists in the tree but hasn't been moved yet.
          local attempts = 0
          local timer = vim.uv.new_timer()
          timer:start(1000, 1000, vim.schedule_wrap(function()
            attempts = attempts + 1
            -- Check for Obsidian in scratchpad (matches both Wayland app_id and XWayland class)
            local in_scratchpad = vim.fn.system(
              'swaymsg -t get_tree | jq -e \'.. | select(.name? == "__i3_scratch") | .. | select(.app_id? == "obsidian" or .window_properties?.class? == "obsidian")\' >/dev/null 2>&1 && echo yes || echo no'
            ):gsub("%s+", "")
            if in_scratchpad == "yes" then
              timer:stop()
              timer:close()
              -- Show from scratchpad and ensure correct size (try both selectors)
              vim.fn.system('swaymsg \'[app_id="obsidian"] scratchpad show, resize set width 2000 px height 1190 px, move position center; [class="obsidian"] scratchpad show, resize set width 2000 px height 1190 px, move position center\'')
              -- If we have a file path, open it via REST API once the server is ready
              if file then
                vim.defer_fn(function()
                  vim.fn.jobstart({
                    "curl", "-sk",
                    "-H", "Authorization: Bearer 633d0602c1469b69bd560a2d52b5ee7dc0dc830a8f9b50a45fb4064aca4e567c",
                    "-X", "POST",
                    "https://localhost:27124/open/" .. file,
                  }, {
                    on_stdout = function() end,
                    on_stderr = function() end,
                  })
                end, 2000)
              end
            elseif attempts >= 15 then
              timer:stop()
              timer:close()
            end
          end))
        end
      end,
    },

    -- Optional, define your own callbacks to further customize behavior.
    callbacks = {
      -- Runs at the end of `require("obsidian").setup()`.
      post_setup = function() end,

      -- Runs anytime you enter the buffer for a note.
      ---@param note obsidian.Note
      enter_note = function(note)
        -- Auto-apply daily template when a bare daily note is opened (e.g. from wikilink follow).
        -- Uses the note's date (from filename) instead of wall-clock date for all substitutions.
        local path = tostring(note.path)
        local date_str = path:match("Journal/daily/(%d%d%d%d%-%d%d%-%d%d)%.md$")
        if not date_str then
          return
        end
        -- Check if note is bare (only frontmatter, no body content)
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local past_frontmatter = false
        local frontmatter_count = 0
        for _, line in ipairs(lines) do
          if line:match("^%-%-%-") then
            frontmatter_count = frontmatter_count + 1
            if frontmatter_count == 2 then
              past_frontmatter = true
            end
          elseif past_frontmatter and line:match("%S") then
            return -- has real content already
          end
        end
        if not past_frontmatter then return end

        -- Parse note date from filename and compute yesterday/tomorrow
        local y, m, d = date_str:match("(%d+)-(%d+)-(%d+)")
        local note_ts = os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 12 })
        local yesterday = os.date("%Y-%m-%d", note_ts - 86400)
        local tomorrow = os.date("%Y-%m-%d", note_ts + 86400)
        local time_now = os.date("%H:%M")

        -- Read template, strip its frontmatter, substitute with note-correct dates
        local vault = vim.fn.expand("~/notes/bgovault")
        local f = io.open(vault .. "/Templates/template_daily.md", "r")
        if not f then return end
        local tmpl = f:read("*a")
        f:close()
        tmpl = tmpl:gsub("^%-%-%-.-%-%-%-\n?", "")
        tmpl = tmpl:gsub("{{date}}", date_str)
        tmpl = tmpl:gsub("{{yesterday}}", yesterday)
        tmpl = tmpl:gsub("{{tomorrow}}", tomorrow)
        tmpl = tmpl:gsub("{{time}}", time_now)

        local new_lines = vim.split(tmpl, "\n")
        vim.api.nvim_buf_set_lines(0, #lines, #lines, false, new_lines)
      end,

      -- Runs anytime you leave the buffer for a note.
      ---@param note obsidian.Note
      leave_note = function(note) end,

      -- Runs right before writing the buffer for a note.
      ---@param note obsidian.Note
      pre_write_note = function(note) end,

      -- Runs anytime the workspace is set/changed.
      ---@param workspace obsidian.Workspace
      post_set_workspace = function(workspace) end,
    },

    -- Optional, configure additional syntax highlighting / extmarks.
    -- This requires you have `conceallevel` set to 1 or 2. See `:help conceallevel` for more details.
    ui = {
      enable = true, -- set to false to disable all additional syntax features
      ignore_conceal_warn = false, -- set to true to disable conceallevel specific warning
      update_debounce = 200, -- update delay after a text change (in milliseconds)
      max_file_length = 5000, -- disable UI features for files with more than this many lines
      -- Define how various check-boxes are displayed
      -- checkbox = {
      --   order = { " ", "/", "x", ">", "~", "!", "-" },
      -- },
      -- Use bullet marks for non-checkbox lists.
      bullets = { char = "•", hl_group = "ObsidianBullet" },
      external_link_icon = { char = "", hl_group = "ObsidianExtLinkIcon" },
      -- Replace the above with this if you don't have a patched font:
      -- external_link_icon = { char = "", hl_group = "ObsidianExtLinkIcon" },
      reference_text = { hl_group = "ObsidianRefText" },
      highlight_text = { hl_group = "ObsidianHighlightText" },
      tags = { hl_group = "ObsidianTag" },
      block_ids = { hl_group = "ObsidianBlockID" },
      hl_groups = {
        -- The options are passed directly to `vim.api.nvim_set_hl()`. See `:help nvim_set_hl`.
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

    -- Specify how to handle attachments.
    ---@class obsidian.config.AttachmentsOpts
    ---Default folder to save images to, relative to the vault root.
    ---@field img_folder? string
    ---Default name for pasted images
    ---@field img_name_func? fun(): string
    ---Default text to insert for pasted images, for customizing, see: https://github.com/obsidian-nvim/obsidian.nvim/wiki/Images
    ---@field img_text_func? fun(path: obsidian.Path): string
    ---Whether to confirm the paste or not. Defaults to true.
    ---@field confirm_img_paste? boolean

    attachments = {
      -- The default folder to place images in via `:Obsidian paste_img`.
      -- If this is a relative path it will be interpreted as relative to the vault root.
      -- You can always override this per image by passing a full path to the command instead of just a filename.
      folder = "Assets/attachments", -- replaces deprecated img_folder

      img_text_func = function(path)
        -- Use the new global Obsidian API (no client access to avoid deprecation warnings)
        local workspace_root = Obsidian.workspace.path
        local relative_path = vim.fn.fnamemodify(tostring(path), ":s?" .. tostring(workspace_root) .. "/??")

        local format_string = {
          markdown = "![](%s)",
          wiki = "![[%s]]",
        }
        local style = Obsidian.opts.preferred_link_style or "markdown"

        if style == "markdown" then
          relative_path = require("obsidian.util").urlencode(relative_path, { keep_path_sep = true })
        end

        return string.format(format_string[style], relative_path)
      end,

      img_name_func = function()
        return string.format("Pasted_image_%s", os.date("%Y%m%d%H%M%S"))
      end,
      confirm_img_paste = true,
    },

    ---@class obsidian.config.FooterOpts
    ---
    ---@field enabled? boolean
    ---@field format? string
    ---@field hl_group? string
    ---@field separator? string|false Set false to disable separator; set an empty string to insert a blank line separator.
    footer = {
      enabled = true,
      format = "{{backlinks}} backlinks  {{properties}} properties  {{words}} words  {{chars}} chars",
      hl_group = "Comment",
      separator = string.rep("-", 80),
    },
    ---@class obsidian.config.CheckboxOpts
    ------Order of checkbox state chars, e.g. { " ", "x" }
    ---@field order? string[]
    checkbox = {
      -- NOTE: the 'char' value has to be a single character, and the highlight groups are defined below.
      [" "] = { char = "󰄱", hl_group = "ObsidianTodo" },
      ["-"] = { char = "🕛", hl_group = "ObsidianTodo" },
      ["/"] = { char = "󰦕", hl_group = "Obsidianbullet" },
      ["x"] = { char = "", hl_group = "ObsidianDone" },
      [">"] = { char = "", hl_group = "ObsidianRightArrow" },
      ["~"] = { char = "󰰱", hl_group = "ObsidianTilde" },
      ["!"] = { char = "", hl_group = "ObsidianImportant" },
      -- Replace the above with this if you don't have a patched font:
      -- [" "] = { char = "☐", hl_group = "ObsidianTodo" },
      -- ["x"] = { char = "✔", hl_group = "ObsidianDone" },

      -- You can also add more custom ones...
      order = { " ", "-", "/", "x", ">", "~", "!" },
    },
  })
end

return {
  "obsidian-nvim/obsidian.nvim",
  -- "epwalsh/obsidian.nvim",
  version = "*", -- recommended, use latest release instead of latest commit
  enabled = true,
  lazy = false,

  dependencies = {
    -- Required.
    "nvim-lua/plenary.nvim",
    "ibhagwan/fzf-lua",
    "Saghen/blink.cmp",
    "nvim-treesitter",
  },
  config = function()
    setup()

    -- Initialize your PDF helper and create its keymap (guarded).
    do
      -- IMPORTANT: dot notation; file should be at lua/user/obsidian_pdf.lua
      local ok, pdf = pcall(require, "user.obsidian_pdf")
      if ok then
        pdf.setup({
          pdf_folder = "Assets/pdf", -- relative to vault root
          link_style = "wiki", -- or "markdown"
        })

        -- Keymap to prompt and save/insert a PDF quickly
        vim.keymap.set("n", "<leader>od", function()
          pdf.save_pdf({})
        end, { desc = "Obsidian: Save PDF into vault and insert link" })
      else
        vim.notify("obsidian_pdf module not found: " .. tostring(pdf), vim.log.levels.WARN)
      end
    end

    -- Vault operations (bridge obsidian ↔ Claude Code)
    do
      local ok, vault_ops = pcall(require, "user.vault_ops")
      if ok then
        vim.keymap.set("n", "<leader>oe", function()
          local link = vault_ops.get_wikilink_under_cursor()
          if link then
            vault_ops.send_to_claude_terminal("/expand-topic [[" .. link .. "]]")
          else
            vim.notify("No [[wikilink]] under cursor", vim.log.levels.WARN)
          end
        end, { desc = "[O]bsidian [E]xpand topic → Claude" })

        vim.keymap.set("v", "<leader>o[", function()
          vault_ops.wrap_selection_as_placeholder()
        end, { desc = "[O]bsidian wrap as [[placeholder]]" })
      end
    end

    -- For other mappings:
    -- vim.keymap.set("n", "gf", "<cmd>Obsidian follow_link<cr>", { desc = "[O]bsidian Follow Link" })
    vim.keymap.set("n", "<leader>oc", function()
      return require("obsidian").actions.toggle_checkbox()
    end, { buffer = true, desc = "[O]bsidian Toggle [C]heckbox" })

    -- obsidian.nvim hardcodes <CR> → api.smart_action on every BufEnter (autocmds.lua:49).
    -- Instead of fighting the autocmd, we monkey-patch the function itself so the
    -- plugin's own <CR> mapping calls our footnote-aware wrapper.
    -- Done once at startup — no autocmds, no vim.schedule, no race with which-key.
    do
      local obsidian_api = require("obsidian.api")
      local original_smart_action = obsidian_api.smart_action
      obsidian_api.smart_action = function()
        -- Check footnotes first
        local fn = require("user.footnote_nav")
        local ref_label = fn.cursor_footnote_ref()
        if ref_label then
          vim.schedule(function() fn.goto_definition(ref_label) end)
          return ""
        end
        local def_label = fn.cursor_footnote_def()
        if def_label then
          vim.schedule(function() fn.goto_reference(def_label) end)
          return ""
        end
        -- Fall through to original (saved reference, not our patched version)
        return original_smart_action()
      end
    end

    -- New command format (legacy_commands = false)
    vim.keymap.set("n", "<leader>ob", "<cmd>Obsidian backlinks<cr>", { desc = "[O]bsidian [B]backlinks" })
    vim.keymap.set("n", "<leader>or", "<cmd>Obsidian rename<cr>", { desc = "[O]bsidian [R]ename" })
    vim.keymap.set("n", "<leader>oo", "<cmd>Obsidian open<cr>", { desc = "[O]bsidian [O]pen" })
    vim.keymap.set("n", "<leader>oT", "<cmd>Obsidian template<cr>", { desc = "[O]bsidian insert from [T]emplate" })

    vim.keymap.set("n", "<leader>ot", "<cmd>Obsidian tags<cr>", { desc = "[O]bsidian search [T]ags" })
    vim.keymap.set("n", "<leader>oq", "<cmd>Obsidian quick_switch<cr>", { desc = "[O]bsidian [Q]uickSwitch" })
    vim.keymap.set("n", "<leader>os", "<cmd>Obsidian search<cr>", { desc = "[O]bsidian [S]earch" })
    vim.keymap.set("n", "<leader>op", "<cmd>Obsidian paste_img<cr>", { desc = "[O]bsidian [P]aste image" })
    vim.keymap.set("n", "<leader>oP", function()
      local file = vim.fn.expand("%:p")
      if file == "" then
        vim.notify("No file to print", vim.log.levels.WARN)
        return
      end
      local ft = vim.bo.filetype
      if ft ~= "markdown" then
        vim.notify("print-md only supports markdown files", vim.log.levels.WARN)
        return
      end
      vim.cmd("silent !print-md " .. vim.fn.shellescape(file))
      vim.notify("Sent to printer: " .. vim.fn.fnamemodify(file, ":t"), vim.log.levels.INFO)
    end, { desc = "[O]bsidian [P]rint note" })

    --- Bullet timestamp: (HH:MM) same-day, (YYYY-MM-DD HH:MM) cross-day.
    local function bullet_suffix()
      local fname = vim.fn.expand("%:t:r")
      if fname == os.date("%Y-%m-%d") then
        return " (" .. os.date("%H:%M") .. ")"
      else
        return " (" .. os.date("%Y-%m-%d %H:%M") .. ")"
      end
    end

    --- Task created-date: always ➕ YYYY-MM-DD HH:MM.
    local function todo_suffix()
      return " ➕ " .. os.date("%Y-%m-%d %H:%M")
    end

    --- Position cursor in a daily-note section with prefix and suffix.
    --- @param section string   Section heading (e.g. "Skyndiminnispunktar")
    --- @param prefix string    Text before cursor (e.g. "- ")
    --- @param suffix_fn fun(): string  Returns text after cursor
    local function jot_to_section(section, prefix, suffix_fn)
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      for idx, line in ipairs(lines) do
        if line:match("^## " .. section) then
          local insert_at = idx
          for j = idx + 1, #lines do
            if lines[j]:match("^## ") then
              insert_at = j - 1
              break
            end
            insert_at = j
          end
          -- Skip trailing blank lines so entry stays adjacent to content
          while insert_at > idx and lines[insert_at]:match("^%s*$") do
            insert_at = insert_at - 1
          end
          local suffix = suffix_fn()
          vim.api.nvim_buf_set_lines(0, insert_at, insert_at, false, { prefix .. suffix })
          vim.api.nvim_win_set_cursor(0, { insert_at + 1, #prefix })
          vim.cmd("startinsert")
          return
        end
      end
    end

    --- Open a daily note and position cursor for quick capture.
    --- @param cmd string      Obsidian subcommand: "today", "yesterday", "tomorrow"
    --- @param section string  Section heading to target
    --- @param prefix string   Text before cursor (e.g. "- " or "- [ ] ")
    --- @param suffix_fn fun(): string  Returns text after cursor
    local function quick_jot(cmd, section, prefix, suffix_fn)
      vim.cmd("Obsidian " .. cmd)
      vim.defer_fn(function()
        jot_to_section(section, prefix, suffix_fn)
      end, 200)
    end

    --- Register a one-shot autocmd to jot into the next daily note that opens.
    --- @param section string  Section heading to target
    --- @param prefix string   Text before cursor (e.g. "- " or "- [ ] ")
    --- @param suffix_fn fun(): string  Returns text after cursor
    local function jot_after_picker(section, prefix, suffix_fn)
      vim.api.nvim_create_augroup("ObsidianQuickJot", { clear = true })
      vim.api.nvim_create_autocmd("BufEnter", {
        group = "ObsidianQuickJot",
        pattern = "*/Journal/daily/*.md",
        once = true,
        callback = function()
          vim.defer_fn(function()
            jot_to_section(section, prefix, suffix_fn)
          end, 200)
        end,
      })
    end

    -- journaling: quick-jot variants (bullet + timestamp in Skyndiminnispunktar)
    vim.keymap.set("n", "<leader>ojt", function() quick_jot("today", "Skyndiminnispunktar", "- ", bullet_suffix) end, { desc = "[O]bsidian [j]ot [t]oday" })
    vim.keymap.set("n", "<leader>ojm", function() quick_jot("tomorrow", "Skyndiminnispunktar", "- ", bullet_suffix) end, { desc = "[O]bsidian [j]ot to[m]orrow" })
    vim.keymap.set("n", "<leader>ojy", function() quick_jot("yesterday", "Skyndiminnispunktar", "- ", bullet_suffix) end, { desc = "[O]bsidian [j]ot [y]esterday" })
    vim.keymap.set("n", "<leader>ojd", function() jot_after_picker("Skyndiminnispunktar", "- ", bullet_suffix); vim.cmd("Obsidian dailies") end, { desc = "[O]bsidian [j]ot [d]ailies" })

    -- journaling: quick-todo variants (checkbox + created-date in Verkefni dagsins)
    vim.keymap.set("n", "<leader>oJt", function() quick_jot("today", "Verkefni dagsins", "- [ ] ", todo_suffix) end, { desc = "[O]bsidian todo [J]ot [t]oday" })
    vim.keymap.set("n", "<leader>oJm", function() quick_jot("tomorrow", "Verkefni dagsins", "- [ ] ", todo_suffix) end, { desc = "[O]bsidian todo [J]ot to[m]orrow" })
    vim.keymap.set("n", "<leader>oJy", function() quick_jot("yesterday", "Verkefni dagsins", "- [ ] ", todo_suffix) end, { desc = "[O]bsidian todo [J]ot [y]esterday" })
    vim.keymap.set("n", "<leader>oJd", function() jot_after_picker("Verkefni dagsins", "- [ ] ", todo_suffix); vim.cmd("Obsidian dailies") end, { desc = "[O]bsidian todo [J]ot [d]ailies" })

    -- new notes
    vim.keymap.set("n", "<leader>onn", "<cmd>Obsidian new<cr>", { desc = "[O]bsidian [N]ew" })
    vim.keymap.set("n", "<leader>ont", "<cmd>Obsidian new_from_template<cr>", { desc = "[O]bsidian new from [T]emplate" })

    -- REST API integration (requires Local REST API plugin running in Obsidian)
    local rest_api = vim.fn.expand("~/notes/bgovault/.scripts/obsidian-rest-api.sh")
    if vim.fn.filereadable(rest_api) == 1 then
      -- Open current note in Obsidian GUI (graph, canvas, preview)
      vim.keymap.set("n", "<leader>oag", function()
        local rel = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":.")
        if rel == "" or not rel:match("%.md$") then
          vim.notify("Not a vault markdown file", vim.log.levels.WARN)
          return
        end
        vim.fn.system(rest_api .. " open " .. vim.fn.shellescape(rel))
        vim.notify("Opened in Obsidian: " .. rel, vim.log.levels.INFO)
      end, { desc = "[O]bsidian [A]PI open in [G]UI" })

      -- Dataview DQL query (prompted)
      vim.keymap.set("n", "<leader>oad", function()
        vim.ui.input({ prompt = "DQL> " }, function(query)
          if not query or query == "" then return end
          local output = vim.fn.system(rest_api .. " dql " .. vim.fn.shellescape(query))
          -- Show in a scratch buffer
          vim.cmd("botright new")
          vim.bo.buftype = "nofile"
          vim.bo.bufhidden = "wipe"
          vim.bo.filetype = "markdown"
          vim.api.nvim_buf_set_name(0, "DQL: " .. query:sub(1, 40))
          vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(output, "\n"))
        end)
      end, { desc = "[O]bsidian [A]PI [D]ataview query" })

      -- Search via REST API (uses Obsidian's indexed search)
      vim.keymap.set("n", "<leader>oas", function()
        vim.ui.input({ prompt = "Search> " }, function(query)
          if not query or query == "" then return end
          local output = vim.fn.system(rest_api .. " search " .. vim.fn.shellescape(query))
          vim.cmd("botright new")
          vim.bo.buftype = "nofile"
          vim.bo.bufhidden = "wipe"
          vim.bo.filetype = "markdown"
          vim.api.nvim_buf_set_name(0, "Search: " .. query)
          vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(output, "\n"))
        end)
      end, { desc = "[O]bsidian [A]PI [S]earch" })

      -- Show backlinks for current note via Dataview
      vim.keymap.set("n", "<leader>oab", function()
        local stem = vim.fn.expand("%:t:r")
        if stem == "" then
          vim.notify("No file open", vim.log.levels.WARN)
          return
        end
        local dql = 'TABLE file.mtime as Modified WHERE contains(file.outlinks, [[' .. stem .. ']]) SORT file.mtime DESC'
        local output = vim.fn.system(rest_api .. " dql " .. vim.fn.shellescape(dql))
        vim.cmd("botright new")
        vim.bo.buftype = "nofile"
        vim.bo.bufhidden = "wipe"
        vim.bo.filetype = "markdown"
        vim.api.nvim_buf_set_name(0, "Backlinks: " .. stem)
        vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(output, "\n"))
      end, { desc = "[O]bsidian [A]PI [B]acklinks (Dataview)" })

      -- Execute Obsidian command (prompted with filter)
      vim.keymap.set("n", "<leader>oax", function()
        vim.ui.input({ prompt = "Command filter> " }, function(filter)
          if not filter then return end
          local output = vim.fn.system(rest_api .. " commands " .. vim.fn.shellescape(filter))
          local lines = vim.split(output, "\n")
          if #lines == 0 then
            vim.notify("No commands match: " .. filter, vim.log.levels.WARN)
            return
          end
          vim.ui.select(lines, { prompt = "Execute command:" }, function(choice)
            if not choice then return end
            local cmd_id = choice:match("^%s*(%S+)")
            if cmd_id then
              vim.fn.system(rest_api .. " exec " .. vim.fn.shellescape(cmd_id))
              vim.notify("Executed: " .. cmd_id, vim.log.levels.INFO)
            end
          end)
        end)
      end, { desc = "[O]bsidian [A]PI e[X]ecute command" })
    end
  end,
}
