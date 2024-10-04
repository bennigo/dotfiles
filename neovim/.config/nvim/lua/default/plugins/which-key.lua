local function config()
	local wk = require("which-key")
	wk.add({
		{ "<leader>s", group = "Search" },
	})
end

return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		-- your configuration comes here
		-- or leave it empty to use the default settings
		-- refer to the configuration section below
	},

	keys = {
		{
			"<leader>.",
			function()
				require("which-key").show({ global = false })
			end,
			desc = "Buffer Local Keymaps (which-key)",
		},
		{ "<leader>s", group = "Search" },
	},
	config = function()
		require("which-key").add({
			{ "<leader>l", group = "[L]SP" },
			-- { "<leader>d", group = "[D]ocument" },
			{ "<leader>g", group = "[G]it" },
			{ "<leader>r", group = "[R]ename" },
			{ "<leader>s", group = "[S]earch [P]project" },
			{ "<leader>n", group = "[N]eovim config" },
			{ "<leader>c", group = "[C]hatGPT" },
			{ "<leader>W", group = "[W]orkspace" },
			{ "<leader>P", group = "[P]ersonal" },
			{ "<leader>D", group = "[D]Dap" },
		})
	end,
}

-- return {
-- 	"folke/which-key.nvim",
-- 	event = "VeryLazy",
-- 	init = function()
-- 		vim.o.timeout = true
-- 		vim.o.timeoutlen = 500
-- 	end,
-- 	opts = {
-- 		-- your configuration comes here
-- 		-- or leave it empty to use the default settings
-- 		-- refer to the configuration section below
-- 	},
-- 	config = function()
-- 		require("which-key").register({
-- 			['<leader>c'] = { name = '[C]ode', _ = 'which_key_ignore' },
-- 			-- ['<leader>d'] = { name = '[D]ocument', _ = 'which_key_ignore' },
-- 			['<leader>g'] = { name = '[G]it', _ = 'which_key_ignore' },
-- 			['<leader>h'] = { name = 'More git', _ = 'which_key_ignore' },
-- 			['<leader>r'] = { name = '[R]ename', _ = 'which_key_ignore' },
-- 			['<leader>s'] = { name = '[S]earch [P]project', _ = 'which_key_ignore' },
-- 			['<leader>W'] = { name = '[W]orkspace', _ = 'which_key_ignore' },
-- 			['<leader>D'] = { name = '[D]Dap', _ = 'which_key_ignore' },
-- 		})
-- 	end,
-- }
