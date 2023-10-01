vim.cmd([[packadd packer.nvim]])

return require("packer").startup(function(use)
	use("wbthomason/packer.nvim")

	use({
		"preservim/nerdtree",
		requires = {
			{ "ryanoasis/vim-devicons" },
			{ "tiagofumo/vim-nerdtree-syntax-highlight" },
			{ "Xuyuanp/nerdtree-git-plugin" },
		},
	})

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

	use("mfussenegger/nvim-lint")
	use("mhartington/formatter.nvim")

	use("tpope/vim-fugitive")

	use("Rigellute/rigel")
end)
