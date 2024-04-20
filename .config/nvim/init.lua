vim.g.mapleader = " "

require("plugins/packer")
require("plugins/nerdtree")
require("plugins/bufexplorer")
require("plugins/vim-wintabs")
require("plugins/telescope")
require("plugins/mason")
require("plugins/nvim-lspconfig")
require("plugins/nvim-cmp")
require("plugins/nvim-lint")
require("plugins/formatter")
require("plugins/markdown-preview")

vim.cmd("set nu")
vim.cmd("colorscheme rigel")
vim.cmd("let g:loaded_matchparen=1")

require("config/clipboard")
require("config/spellcheck")
require("config/whitespaces")
require("config/filetypes")

require("misc/json-format")
require("misc/save-files")
