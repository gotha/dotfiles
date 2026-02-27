-- Use OSC 52 for clipboard (works over SSH)
-- Neovim 0.10+ has built-in OSC 52 support

if vim.fn.has('nvim-0.10') == 1 then
	-- Use OSC 52 as clipboard provider (works over SSH)
	vim.g.clipboard = {
		name = 'OSC 52',
		copy = {
			['+'] = require('vim.ui.clipboard.osc52').copy('+'),
			['*'] = require('vim.ui.clipboard.osc52').copy('*'),
		},
		paste = {
			['+'] = require('vim.ui.clipboard.osc52').paste('+'),
			['*'] = require('vim.ui.clipboard.osc52').paste('*'),
		},
	}
else
	-- Fallback for older Neovim
	if vim.fn.has("macunix") == 1 then
		vim.opt.clipboard = "unnamedplus"
	elseif vim.fn.has("unix") == 1 then
		vim.opt.clipboard = "unnamed,unnamedplus"
	end
end

vim.opt.clipboard:append("unnamedplus")
