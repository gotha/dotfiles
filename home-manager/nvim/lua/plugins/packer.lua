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

	use({
		"ravitemer/mcphub.nvim",
		requires = { "nvim-lua/plenary.nvim" },
	})

	--use({
	--	"olimorris/codecompanion.nvim",
	--	requires = {
	--		"nvim-lua/plenary.nvim",
	--		"nvim-treesitter/nvim-treesitter",
	--	},
	--})

	use("Rigellute/rigel")
end)
