-- Clipboard configuration
-- On macOS, use pbcopy/pbpaste which works reliably in tmux
-- OSC 52 is used for remote/SSH scenarios

if vim.fn.has("mac") == 1 or vim.fn.has("macunix") == 1 then
	-- macOS: use system clipboard via pbcopy/pbpaste
	vim.g.clipboard = {
		name = "macOS-clipboard",
		copy = {
			["+"] = "pbcopy",
			["*"] = "pbcopy",
		},
		paste = {
			["+"] = "pbpaste",
			["*"] = "pbpaste",
		},
		cache_enabled = 0,
	}
elseif vim.env.SSH_TTY then
	-- Remote SSH session: use OSC 52 for copy only
	if vim.fn.has('nvim-0.10') == 1 then
		local osc52 = require('vim.ui.clipboard.osc52')
		vim.g.clipboard = {
			name = 'OSC 52',
			copy = {
				['+'] = osc52.copy('+'),
				['*'] = osc52.copy('*'),
			},
			paste = {
				['+'] = function() return vim.fn.getreg('0', 1, true) end,
				['*'] = function() return vim.fn.getreg('0', 1, true) end,
			},
		}
	end
else
	-- Linux/other: use standard clipboard
	vim.opt.clipboard = "unnamed,unnamedplus"
end

vim.opt.clipboard:append("unnamedplus")
