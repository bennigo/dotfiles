return {
	"andrewferrier/wrapping.nvim",
	enabled = true,
	config = function()
		require("wrapping").setup({
			-- Custom configuration options
			set_nvim_opt_defaults = true,  -- Whether to automatically set Neovim options for wrapping
			notify_on_switch = true,       -- Enable notifications when switching modes
		})
	end,
}
