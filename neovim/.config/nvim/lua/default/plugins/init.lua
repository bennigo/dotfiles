return {
	-- NOTE: First, some plugins that don't require any configuration

	-- Detect tabstop and shiftwidth automatically
	"tpope/vim-sleuth",
	-- "tpope/vim-surround",
	"nvim-telescope/telescope-symbols.nvim",

	{
		-- Add indentation guides even on blank lines
		"lukas-reineke/indent-blankline.nvim",
		-- Enable `lukas-reineke/indent-blankline.nvim`
		-- See `:help ibl`
		main = "ibl",
		opts = {},
	},
	-- "gc" to comment visual regions/lines
	{
		"numToStr/Comment.nvim",
		event = { "BufNewFile", "BufReadPre" },
		config = true,
	},
	{
		"ibhagwan/fzf-lua",
		-- optional for icon support
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			-- callin `setup` is optional for customization
			require("fzf-lua").setup({})
		end,
	},
}
