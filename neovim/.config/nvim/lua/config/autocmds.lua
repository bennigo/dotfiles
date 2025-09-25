-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Mermaid diagram auto-generation
-- Auto-generate PDF when saving .mmd files
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "*.mmd",
  callback = function()
    local file = vim.fn.expand('%')
    local pdf_file = file:gsub('%.mmd$', '.pdf')

    -- Generate PDF silently in background with proper settings
    vim.fn.jobstart({'mmdc', '-i', file, '-o', pdf_file, '-t', 'default', '-b', 'white', '-f', '-p', vim.fn.expand('~/.config/mermaid-puppeteer.json')}, {
      on_exit = function(_, exit_code)
        if exit_code == 0 then
          vim.notify("Generated: " .. vim.fn.fnamemodify(pdf_file, ':t'), vim.log.levels.INFO)
        else
          vim.notify("Failed to generate PDF from " .. vim.fn.fnamemodify(file, ':t'), vim.log.levels.ERROR)
        end
      end
    })
  end,
  desc = "Auto-generate PDF from Mermaid diagrams"
})
