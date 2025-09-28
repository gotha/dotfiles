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

	--use("augmentcode/augment.vim")

	use({
		"ravitemer/mcphub.nvim",
		run = "npm install -g mcp-hub@latest",
		requires = { "nvim-lua/plenary.nvim" },
		config = function()
			require("mcphub").setup({
				-- optional: defaults are fine to start
			})
		end,
	})

	use({
		"yetone/avante.nvim",
		branch = "main",
		--run = "make BUILD_FROM_SOURCE=true",
		run = "make",
		requires = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"MeanderingProgrammer/render-markdown.nvim",
			"stevearc/dressing.nvim", -- for enhanced input UI
			"folke/snacks.nvim", -- for modern input UI
		},
		config = function()
			require("avante").setup({
				system_prompt = function()
					local hub = require("mcphub").get_hub_instance()
					return hub and hub:get_active_servers_prompt() or ""
				end,
				custom_tools = function()
					return { require("mcphub.extensions.avante").mcp_tool() }
				end,
				provider = "ollama",
				providers = {
					ollama = {
						endpoint = "http://127.0.0.1:11434",
						model = "qwen2.5-coder:7b", -- :7b or :14b or :32b
					},
				},
			})
		end,
	})

	use("ktklin/confluence-cloud-vim")

	use("Rigellute/rigel")
end)
