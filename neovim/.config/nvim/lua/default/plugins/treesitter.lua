local function setup()
    -- [[ configure treesitter ]]
    -- see `:help nvim-treesitter`
    require('nvim-treesitter.configs').setup {

        highlight = { enable = true, disable = {} },
        indent = { enable = true },
        -- enable autotagging (w/ nvim-ts-autotag plugin)
        autotag = {
            enable = true,
        },
        sync_install = true,
        ignore_install = {},
        -- add languages to be installed here that you want installed for treesitter
        ensure_installed = { 'c', 'lua', 'vim', 'vimdoc', 'query', 'python', 'rust', 'tsx', 'typescript', 'markdown', 'norg', 'bash'},
        modules = {},

        -- autoinstall languages that are not installed. defaults to false (but you can change for yourself!)
        auto_install = true,

        incremental_selection = {
            enable = true,
            keymaps = {
                init_selection = '<leader>vs',
                node_incremental = '<leader>vi',
                scope_incremental = '<leader>vc',
                node_decremental = '<leader>vd',
            },
        },
        context_commentstring = {
            enable = true,
            enable_autocmd = false,
        },
        textobjects = {
            select = {
                enable = true,
                lookahead = true, -- automatically jump forward to textobj, similar to targets.vim
                keymaps = {
                    -- you can use the capture groups defined in textobjects.scm
                    ['aa'] = '@parameter.outer',
                    ['ia'] = '@parameter.inner',
                    ['af'] = '@function.outer',
                    ['if'] = '@function.inner',
                    ['ac'] = '@class.outer',
                    ["ic"] = { query = "@class.inner", desc = "select inner part of a class region" },
                    -- you can also use captures from other query groups like `locals.scm`
                    ["as"] = { query = "@scope", query_group = "locals", desc = "select language scope" },
                },
                      selection_modes = {
        ['@parameter.outer'] = 'v', -- charwise
        ['@function.outer'] = 'v', -- linewise
        ['@class.outer'] = '<c-v>', -- blockwise
      },
            },
            move = {
                enable = true,
                set_jumps = true, -- whether to set jumps in the jumplist
                goto_next_start = {
                    [']m'] = '@function.outer',
                    [']]'] = '@class.outer',
                },
                goto_next_end = {
                    [']m'] = '@function.outer',
                    [']['] = '@class.outer',
                },
                goto_previous_start = {
                    ['[m'] = '@function.outer',
                    ['[['] = '@class.outer',
                },
                goto_previous_end = {
                    ['[m'] = '@function.outer',
                    ['[]'] = '@class.outer',
                },
            },
            swap = {
                enable = true,
                swap_next = {
                    ['<leader>a'] = '@parameter.inner',
                },
                swap_previous = {
                    ['<leader>a'] = '@parameter.inner',
                },
            },
       },
    }
end

return {

    enabled = true,
    -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    event = { "BufReadPre", "BufNewFile" },
    build = ":TSUpdate",

    dependencies = {
        'nvim-treesitter/nvim-treesitter-textobjects',
        'nvim-treesitter/nvim-treesitter-context',
        "windwp/nvim-ts-autotag",
        build = ':TSUpdate'
    },
    config = function()
        vim.defer_fn(function()
            setup()
        end, 0)
    end,
}
