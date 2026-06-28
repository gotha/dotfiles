-- nvim-treesitter `main` branch.
--
-- The legacy `master` branch does not support Neovim 0.12 (its injection queries
-- crash the highlighter with `node:range()` on a nil node). `main` is the rewrite
-- that targets Neovim 0.12+. Its API differs from master: there is no
-- `configs.setup{ ensure_installed, highlight }` — parsers are installed
-- explicitly and highlighting is enabled per-filetype via vim.treesitter.start().
--
-- Parser install needs the tree-sitter CLI + a C compiler + curl, all provided by
-- the nvim home-manager module. Parsers/queries land in stdpath("data")/site.

-- Install parsers (idempotent: a no-op when already present; runs async).
require("nvim-treesitter").install({
	"python",
	"lua",
	"nix",
	"rust",
	"go",
	"php",
	"hcl",
	"bash",
	"json",
	"yaml",
	"toml",
	"markdown",
	"markdown_inline",
	"vimdoc",
})

-- Enable treesitter highlighting per filetype. Markdown is intentionally left to
-- Neovim's legacy regex syntax: the rigel colorscheme doesn't style treesitter's
-- @markup.* groups, so treesitter highlighting makes markdown look unstyled.
-- Treesitter folding still applies to markdown via foldexpr (lua/config/folding.lua).
vim.api.nvim_create_autocmd("FileType", {
	pattern = {
		"python",
		"lua",
		"nix",
		"rust",
		"go",
		"php",
		"hcl",
		"terraform",
		"sh",
		"bash",
		"json",
		"yaml",
		"toml",
	},
	callback = function(args)
		-- pcall: silently no-op if the parser isn't installed yet (install is async).
		pcall(vim.treesitter.start, args.buf)
	end,
})
