return {
	"kristijanhusak/vim-dadbod-ui",
	dependencies = {
		{ "tpope/vim-dadbod", lazy = true },
		{ "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
	},
	cmd = {
		"DBUI",
		"DBUIToggle",
		"DBUIAddConnection",
		"DBUIFindBuffer",
	},
	init = function()
		-- Your DBUI configuration
		vim.g.db_ui_use_nerd_fonts = 1
	end,

	config = function()
		require("default.config.dadbod").setup()
	end,

	vim.keymap.set("n", "<leader>b", vim.cmd.DBUIToggle),dad
	-- "Toggle data[b]ase uiFuzzily search in current buffer"
}
