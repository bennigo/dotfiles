return {
	"goolord/alpha-nvim",
	enabled = true,
	dependencies = {
		"echasnovski/mini.icons",
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		-- require("alpha").setup(require("alpha.themes.dashboard").config)
		require("alpha").setup(require("alpha.themes.startify").config)
	end,
}
