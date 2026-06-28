-- Treesitter-based folding.
--
-- vim.treesitter.foldexpr() is a built-in Neovim function (not the plugin), so
-- it is safe to set globally: for a buffer whose language has no installed
-- parser it yields no folds and no error. Folds appear once the language's
-- parser is installed (see lua/plugins/treesitter.lua).
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"

-- Empty foldtext renders the first folded line with its normal syntax
-- highlighting instead of the default dashed summary line.
vim.opt.foldtext = ""

-- Start fully unfolded; fold on demand (za toggles one, zM closes all,
-- zR opens all).
vim.opt.foldenable = true
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
