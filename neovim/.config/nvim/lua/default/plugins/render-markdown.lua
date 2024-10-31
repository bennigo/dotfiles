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
		preset = "obsidian",
		-- The level of logs to write to file: vim.fn.stdpath('state') .. '/render-markdown.log'
		-- Only intended to be used for plugin development / debugging
		log_level = "error",
		-- Print runtime of main update method
		-- Only intended to be used for plugin development / debugging
		log_runtime = false,
		-- Filetypes this plugin will run on
		file_types = { "markdown" },

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
	})
end

return {
	"MeanderingProgrammer/render-markdown.nvim",
	enabled = true,
	-- opts = {},
	cmd = { "RenderMarkdown" },
	-- main = "render-markdown",
	-- name = "render-markdown", -- Only needed if you have another plugin named markdown.nvim
	dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons", "echasnovski/mini.nvim" }, -- if you use the mini.nvim suite
	-- dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" }, -- if you use the mini.nvim suite
	---@module 'render-markdown',
	---@type render.md.UserConfig,

	config = function()
		setup()
		require("obsidian").get_client().opts.ui.enable = false
		vim.api.nvim_buf_clear_namespace(0, vim.api.nvim_get_namespaces()["ObsidianUI"], 0, -1)
		require("render-markdown").setup({})
	end,
}
