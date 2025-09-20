-- Setup language servers.
local lspconfig = require("lspconfig")
lspconfig.ts_ls.setup({})
lspconfig.rust_analyzer.setup({
	-- Server-specific settings. See `:help lspconfig-setup`
	settings = {
		["rust-analyzer"] = {
			rustfmt = {
				extraArgs = { "--edition 2021" },
			},
		},
	},
})
lspconfig.gopls.setup({
	on_attach = on_attach,
	capabilities = capabilities,
	filetypes = { "go", "gomod" },
	root_dir = lspconfig.util.root_pattern("go.mod", ".git"),
	settings = {
		gopls = {
			usePlaceholders = false,
			buildFlags = { "-tags=integration,load" },
			gofumpt = true,
			["local"] = "<repo>",
		},
	},
	init_options = {
		buildFlags = { "-tags=integration,load" },
	},
})
lspconfig.clangd.setup({})
lspconfig.phpactor.setup({})
lspconfig.terraformls.setup({})
lspconfig.pyright.setup({
	capabilities = capabilities,
	settings = {
		python = {
			analysis = {
				autoSearchPaths = true,
				diagnosticMode = "workspace",
				useLibraryCodeForTypes = true,
				typeCheckingMode = "basic",
			},
		},
	},
})
lspconfig.nil_ls.setup( {
  autostart = true,
  capabilities = capabilities,
  settings = {
    ['nil'] = {
      formatting = {
        command = { "nixfmt" },
      },
    },
  },
})
lspconfig.kotlin_language_server.setup({
	filetypes = { "kotlin", "kt", "kts" },
})

lspconfig.regols.setup({})

lspconfig.jdtls.setup({
	cmd = {
		"java",
		"-Declipse.application=org.eclipse.jdt.ls.core.id1",
		"-Dosgi.bundles.defaultStartLevel=4",
		"-Declipse.product=org.eclipse.jdt.ls.core.product",
		"-Dlog.protocol=true",
		"-Dlog.level=ALL",
		"-Xms1g",
		"--add-modules=ALL-SYSTEM",
		"--add-opens",
		"java.base/java.util=ALL-UNNAMED",
		"--add-opens",
		"java.base/java.lang=ALL-UNNAMED",
		"-jar",
		vim.fn.glob("/path/to/jdtls/plugins/org.eclipse.equinox.launcher_*.jar"),
		"-configuration",
		"/path/to/jdtls/config_linux", -- or config_mac/config_win
		"-data",
		vim.fn.expand("~/.cache/jdtls/workspace"),
	},
	root_dir = lspconfig.util.root_pattern(".git", "mvnw", "gradlew", "pom.xml", "build.gradle"),
	settings = {
		java = {
			eclipse = {
				downloadSources = true,
			},
			configuration = {
				updateBuildConfiguration = "interactive",
			},
			maven = {
				downloadSources = true,
			},
			implementationsCodeLens = {
				enabled = true,
			},
			referencesCodeLens = {
				enabled = true,
			},
			references = {
				includeDecompiledSources = true,
			},
			signatureHelp = { enabled = true },
			format = {
				enabled = true,
			},
		},
	},
	init_options = {
		bundles = {},
	},
})

-- Global mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
-- vim.keymap.set('n', '<space>e', vim.diagnostic.open_float)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist)

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", {}),
	callback = function(ev)
		-- Enable completion triggered by <c-x><c-o>
		vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

		-- Buffer local mappings.
		-- See `:help vim.lsp.*` for documentation on any of the below functions
		local opts = { buffer = ev.buf }
		vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
		vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
		vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
		vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
		--vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts)
		--vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts)
		-- vim.keymap.set('n', '<space>wl', function()
		--   print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
		-- end, opts)
		vim.keymap.set("n", "<space>D", vim.lsp.buf.type_definition, opts)
		vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, opts)
		vim.keymap.set({ "n", "v" }, "<space>ca", vim.lsp.buf.code_action, opts)
		vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
		-- vim.keymap.set('n', '<space>f', function()
		--   vim.lsp.buf.format { async = true }
		-- end, opts)
	end,
})
