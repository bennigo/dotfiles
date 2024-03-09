return {
	enabled = true,
	"mfussenegger/nvim-lint",
	lazy = true,
	event = { "BufEnter", "BufReadPre", "BufNewFile" }, -- to disable, comment this out
	-- event = {  }, -- to disable, comment this out
	config = function()
		local lint = require("lint")

		lint.linters_by_ft = {
			python = { "pylint" },
			lua = { "luacheck" },
			yaml = { "yamllint" },
		}

		local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

		vim.api.nvim_create_autocmd({
			"BufEnter",
			"BufWritePost",
			"InsertLeave",
		}, {
			group = lint_augroup,
			callback = function()
				lint.try_lint()
			end,
		})

		vim.keymap.set("n", "<leader>L", function()
			lint.try_lint()
		end, { desc = "Trigger linting for current file" })
	end,

	vim.diagnostic.config({ virtual_text = false }),
}
