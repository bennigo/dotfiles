return {
	"R-nvim/R.nvim",
	enabled = false,
	config = function()
		-- Create a table with the options to be passed to setup()
		local opts = {
			hook = {
				on_filetype = function()
					vim.api.nvim_buf_set_keymap(0, "n", "<Enter>", "<Plug>RDSendLine", {})
					vim.api.nvim_buf_set_keymap(0, "v", "<Enter>", "<Plug>RSendSelection", {})
				end,
			},
			R_args = { "--quiet", "--no-save" },
			min_editor_width = 72,
			rconsole_width = 78,
			disable_cmds = {
				"RClearConsole",
				"RCustomStart",
				"RSPlot",
				"RSaveClose",
			},
		}
		-- Check if the environment variable "R_AUTO_START" exists.
		-- If using fish shell, you could put in your config.fish:
		-- alias r "R_AUTO_START=true nvim"
		if vim.env.R_AUTO_START == "true" then
			opts.auto_start = "on startup"
			opts.objbr_auto_start = true
		end
		require("r").setup(opts)
	end,
	lazy = false,
}
