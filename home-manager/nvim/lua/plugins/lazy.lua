-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
require("lazy").setup({
	-- File explorer
	{
		"preservim/nerdtree",
		cmd = { "NERDTree", "NERDTreeToggle", "NERDTreeFind" },
		keys = {
			{ "<leader>e", "<cmd>:e .<cr>", desc = "Open NERDTree" },
		},
		init = function()
			-- Load NERDTree when opening a directory
			vim.api.nvim_create_autocmd("BufEnter", {
				pattern = "*",
				callback = function()
					if vim.fn.isdirectory(vim.fn.expand("%:p")) == 1 then
						require("lazy").load({ plugins = { "nerdtree" } })
					end
				end,
			})
		end,
		config = function()
			vim.g.NERDTreeQuitOnOpen = 1
			vim.g.NERDTreeShowHidden = 1
			-- Hide Python cache and build files
			vim.g.NERDTreeIgnore = {
				"__pycache__",
				"\\.pyc$",
				"\\.pyo$",
				"\\.pyd$",
				"\\.pytest_cache$",
				"\\.mypy_cache$",
				"\\.ruff_cache$",
			}
		end,
	},

	-- Buffer explorer
	{
		"jlanzarotta/bufexplorer",
		keys = {
			{ "<leader>w", "<cmd>BufExplorer<cr>", desc = "Buffer Explorer" },
		},
	},

	-- Window tabs
	{
		"zefei/vim-wintabs",
		event = "VeryLazy",
		config = function()
			require("plugins/vim-wintabs")
		end,
	},

	-- Telescope fuzzy finder
	{
		"nvim-telescope/telescope.nvim",
		branch = "0.1.x",
		dependencies = { "nvim-lua/plenary.nvim" },
		keys = {
			{ "<leader>tf", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
			{ "<leader>tg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
			{ "<leader>tb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
			{ "<leader>th", "<cmd>Telescope help_tags<cr>", desc = "Help Tags" },
			{ "<leader>tr", "<cmd>Telescope resume<cr>", desc = "Resume" },
		},
		config = function()
			require("plugins/telescope")
		end,
	},

	-- LSP Configuration
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("plugins/nvim-lspconfig")
		end,
	},

	-- Autocompletion
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"saadparwaiz1/cmp_luasnip",
			"L3MON4D3/LuaSnip",
		},
		config = function()
			require("plugins/nvim-cmp")
		end,
	},

	-- Linting
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("plugins/nvim-lint")
		end,
	},

	-- Formatting
	{
		"stevearc/conform.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("plugins/conform")
		end,
	},

	-- Diagnostics UI
	{
		"folke/trouble.nvim",
		opts = {},
		keys = {
			{ "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
			{ "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
			{ "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols (Trouble)" },
			{
				"<leader>cl",
				"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
				desc = "LSP Definitions / references / ... (Trouble)",
			},
			{ "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location List (Trouble)" },
			{ "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List (Trouble)" },
		},
	},

	-- Git integration
	{
		"tpope/vim-fugitive",
		cmd = { "Git", "G", "Gdiffsplit", "Gvdiffsplit", "Gread", "Gwrite", "Ggrep", "GMove", "GDelete", "GBrowse" },
	},

	-- Lazygit integration
	{
		"kdheepak/lazygit.nvim",
		lazy = true,
		cmd = {
			"LazyGit",
			"LazyGitConfig",
			"LazyGitCurrentFile",
			"LazyGitFilter",
			"LazyGitFilterCurrentFile",
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		keys = {
			{ "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
		},
	},

	-- Markdown preview
	{
		"iamcco/markdown-preview.nvim",
		ft = { "markdown" },
		build = "cd app && npm install",
		init = function()
			vim.g.mkdp_filetypes = { "markdown" }
		end,
		keys = {
			{ "<leader>p", "<cmd>:MarkdownPreview<cr>", desc = "Markdown Preview" },
		},
	},

	-- Surround text objects
	{
		"echasnovski/mini.surround",
		branch = "stable",
		event = "VeryLazy",
		config = function()
			require("mini.surround").setup()
		end,
	},

	-- GraphQL syntax
	{
		"jparise/vim-graphql",
		ft = { "graphql", "gql" },
	},

	-- Twig syntax
	{
		"nelsyeung/twig.vim",
		ft = { "twig" },
	},

	-- Augment Code
	{
		"augmentcode/augment.vim",
		event = "VeryLazy",
		config = function()
			require("plugins/augment-code")
		end,
	},

	-- Color scheme
	{
		"Rigellute/rigel",
		lazy = false,
		priority = 1000,
	},
})
