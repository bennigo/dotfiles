local ftMap = {
	vim = "indent",
	python = { "indent" },
	git = "",
}

return {
	"kevinhwang91/nvim-ufo",
	enabled = true,
	-- disable = false,
	dependencies = "kevinhwang91/promise-async",
	config = function()
		vim.o.foldcolumn = "1" -- '0' is not bad
		vim.o.foldlevelstart = 100
		vim.wo.foldlevel = 99
		-- vim.o.foldnestmax = 0
		-- vim.o.foldclose = "all"
		-- vim.o.foldopen = "all"
		-- vim.o.foldmethod = "expr"
		vim.o.foldexpr = "nvim_treesitter#foldexpr()"

		vim.keymap.set("n", "zR", require("ufo").openAllFolds)
		vim.keymap.set("n", "zM", require("ufo").closeAllFolds)
		vim.keymap.set("n", "zr", require("ufo").openFoldsExceptKinds)
		vim.keymap.set("n", "zm", require("ufo").closeFoldsWith) -- closeAllFolds == closeFoldsWith(0)
		vim.keymap.set("n", "K", function()
			local winid = require("ufo").peekFoldedLinesUnderCursor()
			if not winid then
				-- choose one of coc.nvim and nvim lsp
				-- vim.fn.CocActionAsync("definitionHover") -- coc.nvim
				vim.lsp.buf.hover()
			end
		end)

		local handler = function(virtual_text, line_start, line_end, window_width, truncate)
			local newVirtText = {}
			local suffix = ("    ⋯ %d lines "):format(line_end - line_start)
			local suffix_width = vim.fn.strdisplaywidth(suffix)
			local target_width = window_width - suffix_width
			local current_width = 0
			for _, chunk in ipairs(virtual_text) do
				local chunkText = chunk[1]
				local chunkWidth = vim.fn.strdisplaywidth(chunkText)
				if target_width > current_width + chunkWidth then
					table.insert(newVirtText, chunk)
				else
					chunkText = truncate(chunkText, target_width - current_width)
					local hlGroup = chunk[2]
					table.insert(newVirtText, { chunkText, hlGroup })
					chunkWidth = vim.fn.strdisplaywidth(chunkText)
					-- str width returned from truncate() may less than 2nd argument, need padding
					if current_width + chunkWidth < target_width then
						suffix = (" "):rep(target_width - current_width - chunkWidth) .. suffix
					end
					break
				end
				current_width = current_width + chunkWidth
			end
			-- local padding_width = math.min(target_width - current_width, 5)
			-- local padding = (' '):rep(padding_width)
			-- table.insert(newVirtText, { padding, 'UfoFoldedFg' })
			table.insert(newVirtText, { suffix, "Comment" })
			return newVirtText
		end

		require("ufo").setup({
			open_fold_hl_timeout = 150,
			close_fold_kinds = { "imports", "comment" },
			preview = {
				win_config = {
					border = { "", "─", "", "", "", "─", "", "" },
					winhighlight = "Normal:Folded",
					winblend = 0,
				},
				mappings = {
					scrollU = "<C-u>",
					scrollD = "<C-d>",
					jumpTop = "[",
					jumpBot = "]",
				},
			},
			provider_selector = function(bufnr, filetype, buftype)
				return { "treesitter", "indent" }
			end,

			fold_virt_text_handler = handler,
			-- provider_selector = function(bufnr, filetype, buftype)
			-- 	-- if you prefer treesitter provider rather than lsp,
			-- 	-- return ftMap[filetype] or {'treesitter', 'indent'}
			-- 	return ftMap[filetype]

			-- refer to ./doc/example.lua for detail
			-- end,
		})
	end,
}
