-- Setup language servers with lazy loading based on filetype

-- TypeScript/JavaScript
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
	callback = function()
		vim.lsp.enable("ts_ls")
	end,
})

-- Rust
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "rust" },
	callback = function()
		vim.lsp.config.rust_analyzer = {
			settings = {
				["rust-analyzer"] = {
					rustfmt = {
						extraArgs = { "--edition 2021" },
					},
				},
			},
		}
		vim.lsp.enable("rust_analyzer")
	end,
})

-- Go
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "go", "gomod" },
	callback = function()
		vim.lsp.config.gopls = {
			filetypes = { "go", "gomod" },
			root_markers = { "go.mod", ".git" },
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
		}
		vim.lsp.enable("gopls")
	end,
})

-- C/C++
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "c", "cpp", "objc", "objcpp" },
	callback = function()
		vim.lsp.enable("clangd")
	end,
})

-- PHP
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "php" },
	callback = function()
		vim.lsp.enable("phpactor")
	end,
})

-- Terraform
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "terraform", "tf" },
	callback = function()
		vim.lsp.enable("terraformls")
	end,
})

-- Python - Ruff LSP for linting and formatting
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "python" },
	callback = function()
		-- Ruff LSP for linting and formatting
		vim.lsp.config.ruff = {
			cmd = { "ruff", "server" },
			filetypes = { "python" },
			root_markers = { "pyproject.toml", "ruff.toml", ".ruff.toml", ".git" },
			settings = {
				-- Ruff language server settings
				-- Configuration is primarily done via ruff.toml
				-- These settings override the config file if needed
				lineLength = 100,
				lint = {
					-- Enable specific rule categories
					select = {
						"E",    -- pycodestyle errors
						"W",    -- pycodestyle warnings
						"F",    -- pyflakes
						"I",    -- isort (import sorting)
						"N",    -- pep8-naming
						"UP",   -- pyupgrade
						"B",    -- flake8-bugbear
						"C4",   -- flake8-comprehensions
						"SIM",  -- flake8-simplify
						"TCH",  -- flake8-type-checking
						"RUF",  -- Ruff-specific rules
						"PT",   -- flake8-pytest-style
						"Q",    -- flake8-quotes
						"RET",  -- flake8-return
						"ARG",  -- flake8-unused-arguments
					},
					ignore = {
						"E501",   -- Line too long (handled by formatter)
						"B008",   -- Do not perform function calls in argument defaults
						"RET504", -- Unnecessary assignment before return
						"ARG001", -- Unused function argument
						"ARG002", -- Unused method argument
					},
				},
				format = {
					-- Format settings
					quoteStyle = "double",
					indentStyle = "space",
				},
			},
		}
		vim.lsp.enable("ruff")

		-- Pyright for type checking (lenient mode)
		vim.lsp.config.pyright = {
			settings = {
				python = {
					analysis = {
						autoSearchPaths = true,
						diagnosticMode = "workspace",
						useLibraryCodeForTypes = true,
						typeCheckingMode = "basic", -- lenient mode
						-- Mypy-like settings
						reportUnusedImport = true,
						reportUnusedVariable = true,
						reportDuplicateImport = true,
						reportOptionalMemberAccess = false, -- lenient
						reportOptionalSubscript = false, -- lenient
						reportOptionalCall = false, -- lenient
						reportOptionalIterable = false, -- lenient
						reportOptionalContextManager = false, -- lenient
					},
				},
			},
		}
		vim.lsp.enable("pyright")
	end,
})

-- Nix
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "nix" },
	callback = function()
		vim.lsp.config.nixd = {
			autostart = true,
			settings = {
				nixd = {
					formatting = {
						command = { "nixfmt" },
					},
					diagnostic = {
						suppress = { "sema-escaping-with" },
					},
				},
				nix = {
					flake = {
						-- Automatically archive flake inputs without prompting
						autoArchive = true,
						-- Automatically evaluate flake inputs
						autoEvalInputs = true,
					},
				},
			},
		}
		vim.lsp.enable("nixd")
	end,
})

-- Rego
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "rego" },
	callback = function()
		vim.lsp.enable("regols")
	end,
})

vim.lsp.config.jdtls = {
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
	root_markers = { ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" },
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
}
vim.lsp.enable("jdtls")

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
