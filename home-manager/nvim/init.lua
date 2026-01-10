vim.g.mapleader = " "

-- Load lazy.nvim plugin manager
require("plugins/lazy")

vim.cmd("set nu")
vim.cmd("colorscheme rigel")
vim.cmd("let g:loaded_matchparen=1")

require("config/clipboard")
require("config/filetypes")
require("config/spellcheck")
require("config/whitespaces")
require("config/diagnostics")

require("misc/json-format")
require("misc/save-files")
