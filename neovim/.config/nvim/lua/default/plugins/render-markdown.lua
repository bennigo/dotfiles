local function setup()
	require("render-markdown").setup({
		-- Whether Markdown should be rendered by default or not
		enabled = true,
		-- Maximum file size (in MB) that this plugin will attempt to render
		-- Any file larger than this will effectively be ignored
		max_file_size = 10.0,
		-- Milliseconds that must pass before updating marks, updates occur
		-- within the context of the visible window, not the entire buffer
		debounce = 100,
		-- Pre configured settings that will attempt to mimic various target
		-- user experiences. Any user provided settings will take precedence.
		--  obsidian: mimic Obsidian UI
		--  lazy:     will attempt to stay up to date with LazyVim configuration
		--  none:     does nothing
		preset = "lazy",
		-- The level of logs to write to file: vim.fn.stdpath('state') .. '/render-markdown.log'
		-- Only intended to be used for plugin development / debugging
		log_level = "error",
		-- Print runtime of main update method
		-- Only intended to be used for plugin development / debugging
		log_runtime = false,
		-- Filetypes this plugin will run on
		file_types = { "markdown", "rmd" },

		heading = {
			enabled = true,
			sign = true,
			position = "overlay",
			icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
			signs = { "󰫎 " },
			width = "full",
			left_margin = 0,
			left_pad = 0,
			right_pad = 0,
			min_width = 0,
			border = false,
			border_virtual = false,
			border_prefix = false,
			above = "▄",
			below = "▀",
			backgrounds = {
				"RenderMarkdownH1Bg",
				"RenderMarkdownH2Bg",
				"RenderMarkdownH3Bg",
				"RenderMarkdownH4Bg",
				"RenderMarkdownH5Bg",
				"RenderMarkdownH6Bg",
			},
			foregrounds = {
				"RenderMarkdownH1",
				"RenderMarkdownH2",
				"RenderMarkdownH3",
				"RenderMarkdownH4",
				"RenderMarkdownH5",
				"RenderMarkdownH6",
			},
		},
		paragraph = {
			-- Turn on / off paragraph rendering
			enabled = true,
			-- Amount of margin to add to the left of paragraphs
			-- If a floating point value < 1 is provided it is treated as a percentage of the available window space
			left_margin = 0,
			-- Minimum width to use for paragraphs
			min_width = 0,
		},
		-- Checkboxes are a special instance of a 'list_item' that start with a 'shortcut_link'
		-- There are two special states for unchecked & checked defined in the markdown grammar
		checkbox = {
			-- Turn on / off checkbox state rendering
			enabled = true,
			-- Determines how icons fill the available space:
			--  inline:  underlying text is concealed resulting in a left aligned icon
			--  overlay: result is left padded with spaces to hide any additional text
			position = "inline",
			unchecked = {
				-- Replaces '[ ]' of 'task_list_marker_unchecked'
				icon = "󰄱 ",
				-- Highlight for the unchecked icon
				highlight = "RenderMarkdownUnchecked",
				-- Highlight for item associated with unchecked checkbox
				scope_highlight = nil,
			},
			checked = {
				-- Replaces '[x]' of 'task_list_marker_checked'
				icon = "󰱒 ",
				-- Highlight for the checked icon
				highlight = "RenderMarkdownChecked",
				-- Highlight for item associated with checked checkbox
				scope_highlight = nil,
			},
			-- Define custom checkbox states, more involved as they are not part of the markdown grammar
			-- As a result this requires neovim >= 0.10.0 since it relies on 'inline' extmarks
			-- Can specify as many additional states as you like following the 'todo' pattern below
			--   The key in this case 'todo' is for healthcheck and to allow users to change its values
			--   'raw':             Matched against the raw text of a 'shortcut_link'
			--   'rendered':        Replaces the 'raw' value when rendering
			--   'highlight':       Highlight for the 'rendered' icon
			--   'scope_highlight': Highlight for item associated with custom checkbox
			custom = {
				todo = { raw = "[-]", rendered = "󰥔 ", highlight = "RenderMarkdownTodo", scope_highlight = "RenderMarkdownTodo" },
				arrow = { raw = "[>]", rendered =" ", highlight = "ObsidianRightArrow", scope_highlight = nil},
				tilde = { raw = "[~]", rendered ="󰰱 ", highlight = "ObsidianTilde", scope_highlight = nil},
				importand = { raw = "[!]", rendered =" ", highlight = "ObsidianImportant", scope_highlight = "ObsidianImportant" },

			},
		},
	})
end

return {
	"MeanderingProgrammer/render-markdown.nvim",
	enabled = true,
	-- opts = {},
	ft = "markdown",
	cmd = { "RenderMarkdown" },
	-- main = "render-markdown",
	-- name = "render-markdown", -- Only needed if you have another plugin named markdown.nvim
	dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons", "echasnovski/mini.nvim" }, -- if you use the mini.nvim suite
	-- dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" }, -- if you use the mini.nvim suite
	---@module 'render-markdown',
	---@type render.md.UserConfig

	config = function()
		require("obsidian").get_client().opts.ui.enable = false
		vim.api.nvim_buf_clear_namespace(0, vim.api.nvim_get_namespaces()["ObsidianUI"], 0, -1)
		setup()
		-- require("render-markdown").setup({})
	end,
}
