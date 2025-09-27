vim.cmd([[packadd packer.nvim]])

return require("packer").startup(function(use)
	use("wbthomason/packer.nvim")

	use({ "preservim/nerdtree" })

	use("jlanzarotta/bufexplorer")
	use("zefei/vim-wintabs")

	use({
		"nvim-telescope/telescope.nvim",
		branch = "0.1.x",
		requires = { { "nvim-lua/plenary.nvim" } },
	})

	use({
		"neovim/nvim-lspconfig",
		requires = {
			{ "williamboman/mason.nvim" },
			{ "williamboman/mason-lspconfig.nvim" },
		},
	})

	use({
		"pmizio/typescript-tools.nvim",
		requires = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
		config = function()
			require("typescript-tools").setup({})
		end,
	})

	use("hrsh7th/nvim-cmp") -- Autocompletion plugin
	use("hrsh7th/cmp-nvim-lsp") -- LSP source for nvim-cmp
	use("saadparwaiz1/cmp_luasnip") -- Snippets source for nvim-cmp
	use("L3MON4D3/LuaSnip") -- Snippets plugin

	use("mfussenegger/nvim-lint")
	use("mhartington/formatter.nvim")
	--use({
	--	"stevearc/conform.nvim",
	--	config = function()
	--		require("conform").setup()
	--	end,
	--})

	use("tpope/vim-fugitive")

	use({
		"iamcco/markdown-preview.nvim",
		run = "cd app && npm install",
		setup = function()
			vim.g.mkdp_filetypes = { "markdown" }
		end,
		ft = { "markdown" },
	})

	use({
		"echasnovski/mini.surround",
		branch = "stable",
		config = function()
			require("mini.surround").setup()
		end,
	})

	use("jparise/vim-graphql")

	use("nelsyeung/twig.vim")

	use("augmentcode/augment.vim")

	use("ktklin/confluence-cloud-vim")

	use("Rigellute/rigel")

	use({
		"olimorris/codecompanion.nvim",
		requires = {
			{ "nvim-lua/plenary.nvim" },
		},
		config = function()
			require("codecompanion").setup({
				adapters = {
					http = {
						ollama = function()
							return require("codecompanion.adapters").extend("ollama", {
								env = { url = "http://127.0.0.1:11434" },
								model = "qwen2.5-coder:7b", -- default model
								-- num_ctx = 32768,                        -- optionally raise context
								-- temperature = 0.2,
							})
						end,
					},
				},

				strategies = {
					chat = { adapter = "ollama", model = "qwen2.5-coder:32b-instruct" },
					inline = { adapter = "ollama", model = "qwen2.5-coder:7b" },
				},

				mappings = {
					open_chat = "<leader>cc",
					clear_chat = "<leader>cn",
					send_selection = "<leader>cs",
				},
			})
		end,
	})
end)
