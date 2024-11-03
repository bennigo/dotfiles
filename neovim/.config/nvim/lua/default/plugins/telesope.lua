local function setup()
	local actions = require("telescope.actions")
	local telescope = require("telescope")
	require("telescope").load_extension("zoxide")

	telescope.setup({
		-- [[ Configure Telescope ]]
		-- See `:help telescope` and `:help telescope.setup()`
		defaults = {
			winblend = 10,
			-- prompt_prefix = "  ",
			prompt_prefix = " 🔍 ",
			-- prompt_prefix = "  ",
			previewer = true,
			selection_caret = "➤ ",
			sorting_strategy = "descending",
			layout_config = {
				horizontal = {
					preview_cutoff = 180,
					preview_width = 0.5,
					prompt_position = "bottom",
				},
			},
			mappings = {
				i = {
					["<C-k>"] = actions.move_selection_previous, -- move previeous
					["<C-j>"] = actions.move_selection_next,
					["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
				},
			},
			-- path_display = {
			--     shorten = true,
			--     truncate = true
			-- }
		},
	})

	-- current document stuff
	vim.keymap.set("n", "<leader>?", function()
		-- You can pass additional configuration to telescope to change theme, layout, etc.
		require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
			winblend = 10,
			previewer = false,
		}))
	end, { desc = "[/] Fuzzily search in current buffer" })

	-- open buffers
	vim.keymap.set("n", "<leader><space>", function()
		require("telescope.builtin").buffers({
			sort_mru = true,
			tiebreak = function()
				return false
			end,
		})
	end, { desc = "[spc] Find existing buffers" })

	-- recently opened files
	vim.keymap.set("n", "<leader>/", function()
		require("telescope.builtin").oldfiles({
			tiebreak = function()
				return false
			end,
		})
	end, { desc = "[?] Find recently opened files" })

	-- search files and text

	-- project files
	vim.keymap.set("n", "<leader>gf", require("telescope.builtin").git_files, { desc = "Search [G]it [F]iles" })
	vim.keymap.set(
		"n",
		"<leader>sw",
		require("telescope.builtin").grep_string,
		{ desc = "[S]earch project current [W]ord" }
	)
	vim.keymap.set("n", "<leader>pg", function()
		require("telescope.builtin").live_grep({
			follow = true,
			previewer = true,
			layout_config = {
				height = 0.95,
				width = 0.95,
				horizontal = {
					preview_cutoff = 50,
					preview_width = 0.6,
				},
			},
		})
	end, { desc = "[S]earch by [G]rep" })
	vim.keymap.set("n", "<leader>pd", require("telescope.builtin").diagnostics, { desc = "[S]earch [D]iagnostics" })
	vim.keymap.set("n", "<leader>pf", require("telescope.builtin").find_files, { desc = "[S]earch project [F]iles" })
	vim.keymap.set("n", "<leader>pr", require("telescope.builtin").resume, { desc = "[S]earch [R]esume" })

	-- find files in personal directories
	vim.keymap.set("n", "<leader>Pf", function()
		require("telescope.builtin").find_files({ cwd = "~/personal/", follow = true })
	end, { desc = "[P]ersonal [P]rojects" })

	vim.keymap.set("n", "<leader>Pg", function()
		require("telescope.builtin").live_grep({
			cwd = "~/personal/",
			follow = true,
			previewer = true,
			layout_config = {
				height = 0.95,
				width = 0.95,
				horizontal = {
					preview_cutoff = 50,
					preview_width = 0.6,
				},
			},
		})
	end, { desc = "[W]ork [G]grep" })

	-- find files in work directories
	vim.keymap.set("n", "<leader>Wf", function()
		require("telescope.builtin").find_files({ cwd = "~/work/projects", follow = true })
	end, { desc = "[W]ork [P]rojects" })

	vim.keymap.set("n", "<leader>Wg", function()
		require("telescope.builtin").live_grep({
			cwd = "~/work/projects",
			follow = true,
			previewer = true,
			layout_config = {
				height = 0.95,
				width = 0.95,
				horizontal = {
					preview_cutoff = 50,
					preview_width = 0.6,
				},
			},
		})
	end, { desc = "[W]ork [G]grep" })

	-- NOTE: Find nvim config files (standard location)
	vim.api.nvim_set_keymap(
		"n",
		"<leader>nc",
		[[<cmd>:lua require'fzf-lua'.colorschemes({ winopts = { height=0.33, width=0.33 } })<cr>]],
		{ desc = "[N]eovim [C]olorschemes", noremap = true, silent = true }
	)
	-- vim.keymap.set('n', '<leader>nc', [[<cmd>Telescope colorscheme<cr>]], {noremap = true, silent = true})
	vim.keymap.set("n", "<leader>nz", "<cmd>Telescope zoxide list<cr>", {})
	-- find spell suggestions of word under cursor
	vim.keymap.set(
		"n",
		"<leader>ns",
		'<cmd>lua require("telescope.builtin").spell_suggest()<cr>',
		{ desc = "[N]eovim [S]pell suggestions" }
	)
	vim.keymap.set("n", "<leader>nh", require("telescope.builtin").help_tags, { desc = "[S]earch [H]elp" })

	vim.keymap.set("n", "<leader>nf", function()
		require("telescope.builtin").find_files({ cwd = "~/.config/nvim", follow = true })
	end, { desc = "[n]eovim config [file]" })

	vim.keymap.set("n", "<leader>ng", function()
		require("telescope.builtin").live_grep({ cwd = "~/.config/nvim", follow = true })
	end, { desc = "[n]eovim [c]onfig" })

	vim.keymap.set("n", "<leader>nof", function()
		require("telescope.builtin").find_files({
			cwd = "~/personal/ext_dotfiles",
			follow = true,
			hidden = true,
			search_file = "*.lua",
		})
	end, { desc = "[N]eovim [O]ther [F]ile" })

	vim.keymap.set("n", "<leader>nog", function()
		require("telescope.builtin").live_grep({
			cwd = "~/personal/ext_dotfiles",
			follow = true,
		})
	end, { desc = "[N]eovim [O]ther [G]rep" })

	-- find notes
	-- vim.keymap.set("n", "<leader>Wn", function() end, { desc = "[N]otes" })

	-- if IsAvailable('telescope-fzf-native') then
	-- https://github.com/nvim-telescope/telescope-fzf-native.nvim
	-- end

	-- find yank_history, depends on yanky
	-- require("telescope").load_extension("yank_history")
	-- vim.api.nvim_set_keymap('n', '<leader>ty', '<cmd>Telescope yank_history<cr>', {})
	-- require("telescope").load_extension("yank_history")
	-- vim.api.nvim_set_keymap('n', '<leader>ty', '<cmd>Telescope yank_history<cr>', {})
	-- https://github.com/jvgrootveld/telescope-zoxide

	-- vim.api.nvim_set_keymap('n', '<leader>gs', '<cmd>lua require("telescope.builtin").git_status()<cr>', {})
	--
end

return {
	"nvim-telescope/telescope.nvim",
	-- lazy = true,
	dependencies = {
		"nvim-lua/plenary.nvim",
		"jvgrootveld/telescope-zoxide",
		"nanotee/zoxide.vim", -- needed to make zoxide plugin work I think, maybe not..??
		{
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build",
			dependencies = { "junegunn/fzf.vim", "junegunn/fzf" },
			config = function()
				require("telescope").load_extension("fzf")
			end,
		},
		-- {
		--   "nvim-telescope/telescope-dap.nvim",
		--   config = function()
		--     require("telescope").load_extension("dap")
		--   end,
		-- },
	},
	config = function()
		setup()
	end,
}
