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
      -- Create note IDs in a Zettelkasten format with a timestamp and a suffix.
      -- In this case a note with the title 'My new note' will be given an ID that looks
      -- like '1657296016-my-new-note', and therefore the file name '1657296016-my-new-note.md'
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
      -- This is equivalent to the default behavior.
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

      -- If this is a daily note (by path), set Area to "Journal" if not already set.
      local note_path = tostring(note.path or "")
      if note_path:match("Journal/daily") and (out.area == nil or out.Area == "") then
        out.Area = "Journal"
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

        alias_journal_heading = function(note_date)
          return note_date.partial_note.title or tostring(os.date("📅 %B %-d, %Y, Day: %j", os.time()))
        end,

        alias_heading = function()
          return tostring(os.date("📅 %B %-d, %Y, Day: %j", os.time()))
        end,

        timed_task = function()
          return string.format("- [ ] Task 1 ➕ %s", os.date("%Y-%m-%d", os.time()))
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

    -- NOTE: follow_url_func and follow_img_func are deprecated
    -- They now default to vim.ui.open, which is what we want

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

    -- Optional, define your own callbacks to further customize behavior.
    callbacks = {
      -- Runs at the end of `require("obsidian").setup()`.
      ---@param client obsidian.Client
      post_setup = function(client) end,

      -- Runs anytime you enter the buffer for a note.
      ---@param client obsidian.Client
      ---@param note obsidian.Note
      enter_note = function(client, note) end,

      -- Runs anytime you leave the buffer for a note.
      ---@param client obsidian.Client
      ---@param note obsidian.Note
      leave_note = function(client, note) end,

      -- Runs right before writing the buffer for a note.
      ---@param client obsidian.Client
      ---@param note obsidian.Note
      pre_write_note = function(client, note) end,

      -- Runs anytime the workspace is set/changed.
      ---@param client obsidian.Client
      ---@param workspace obsidian.Workspace
      post_set_workspace = function(client, workspace) end,
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
      -- The default folder to place images in via `:ObsidianPasteImg`.
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
    -- For other mappings:
    -- vim.keymap.set("n", "gf", "<cmd>ObsidianFollowLink<cr>", { desc = "[O]bsidian [J]journal [Y]esterday" })
    vim.keymap.set("n", "<leader>oc", function()
      return require("obsidian").util.toggle_checkbox()
    end, { buffer = true, desc = "[O]bsidian Toggle [C]heckbox" })

    vim.keymap.set("n", "<CR>", function()
      return require("obsidian").util.smart_action()
    end, { buffer = true, expr = true, desc = "[O]bsidian Smart_action" })

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

    -- journaling
    vim.keymap.set("n", "<leader>ojy", "<cmd>Obsidian yesterday<cr>", { desc = "[O]bsidian [J]journal [Y]esterday" })
    vim.keymap.set("n", "<leader>ojt", "<cmd>Obsidian today<cr>", { desc = "[O]bsidian [J]journal [T]oday" })
    vim.keymap.set("n", "<leader>ojm", "<cmd>Obsidian tomorrow<cr>", { desc = "[O]bsidian [J]ournal [T]omorrow" })
    vim.keymap.set("n", "<leader>ojd", "<cmd>Obsidian dailies<cr>", { desc = "[O]bsidian [J]journal [D]ailies" })

    -- new notes
    vim.keymap.set("n", "<leader>onn", "<cmd>Obsidian new<cr>", { desc = "[O]bsidian [N]ew" })
    vim.keymap.set("n", "<leader>ont", "<cmd>Obsidian new_from_template<cr>", { desc = "[O]bsidian new from [T]emplate" })
    -- vim.keymap.set(
    --   "n",
    --   "<leader>ona",
    --   "<cmd>ObsidianNewFromTemplateAuto<cr>",
    --   { desc = "[O]bsidian new from [T]emplate (auto title)" }
    -- )
  end,
}
