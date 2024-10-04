-- install with yarn or npm
return {
	"iamcco/markdown-preview.nvim",
	enabled = true,
	cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
	build = "cd app && npm install",
	-- build = function() vim.fn["mkdp#util#install"]() end,
	init = function()
		vim.g.mkdp_filetypes = { "markdown" }
		vim.g.mkdp_browserfunc = "MarkdownPreview"
		vim.g.mkdp_theme = 'light'
	end,
	ft = { "markdown" },
	config = function()
		vim.cmd([[do FileType]])
		vim.cmd([[
		       function! MarkdownPreview(url)
			  let cmd = "firefox --new-window " . shellescape(a:url)
			  call jobstart(cmd)
		       endfunction
		    ]])

		vim.keymap.set("n", "<c-p>", "<cmd>MarkdownPreviewToggle<cr>", { desc="Markownd Preview"})
	end,
}
