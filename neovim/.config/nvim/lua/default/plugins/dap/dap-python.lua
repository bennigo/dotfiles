local function setup()
-- Debugging
	vim.keymap.set("n", "<leader>Db", "<cmd>lua require'dap'.toggle_breakpoint()<cr>")
	vim.keymap.set("n", "<leader>Dc", "<cmd>lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<cr>")
	vim.keymap.set("n", "<leader>Dl", "<cmd>lua require'dap'.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<cr>")
	vim.keymap.set("n", '<leader>Dr', "<cmd>lua require'dap'.clear_breakpoints()<cr>")
	vim.keymap.set("n", '<leader>Da', '<cmd>Telescope dap list_breakpoints<cr>')
	vim.keymap.set("n", "<leader>Dc", "<cmd>lua require'dap'.continue()<cr>")
	vim.keymap.set("n", "<leader>Dj", "<cmd>lua require'dap'.step_over()<cr>")
	vim.keymap.set("n", "<leader>Dk", "<cmd>lua require'dap'.step_into()<cr>")
	vim.keymap.set("n", "<leader>Do", "<cmd>lua require'dap'.step_out()<cr>")
	vim.keymap.set("n", '<leader>Dd', function() require('dap').disconnect(); require('dapui').close(); end)
	vim.keymap.set("n", '<leader>Dt', function() require('dap').terminate(); require('dapui').close(); end)
	vim.keymap.set("n", "<leader>Dr", "<cmd>lua require'dap'.repl.toggle()<cr>")
	vim.keymap.set("n", "<leader>Dl", "<cmd>lua require'dap'.run_last()<cr>")
	vim.keymap.set("n", '<leader>Di', function() require "dap.ui.widgets".hover() end)
	vim.keymap.set("n", '<leader>D?', function() local widgets = require "dap.ui.widgets"; widgets.centered_float(widgets.scopes) end)
	vim.keymap.set("n", '<leader>Df', '<cmd>Telescope dap frames<cr>')
	vim.keymap.set("n", '<leader>Dh', '<cmd>Telescope dap commands<cr>')
	vim.keymap.set("n", '<leader>De', function() require('telescope.builtin').diagnostics({default_text=":E:"}) end)
end


return {
	-- https://github.com/mfussenegger/nvim-dap-python
	"mfussenegger/nvim-dap-python",
	ft = "python",
	dependencies = {
		-- https://github.com/mfussenegger/nvim-dap
		"mfussenegger/nvim-dap",
	},
	config = function()
		-- Update the path passed to setup to point to your system or virtual env python binary
		require("dap-python").setup("python")
		setup()
	end,

}
