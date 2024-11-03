return {
	"andrewferrier/wrapping.nvim",
	after = "nvim-notify",
	enabled = true,
	config = function()
		require("wrapping").setup()
	end,
}
