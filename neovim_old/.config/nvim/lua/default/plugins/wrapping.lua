return {
	"andrewferrier/wrapping.nvim",
	after = "nvim-notify",
	enabled = false,
	config = function()
		require("wrapping").setup()
	end,
}
