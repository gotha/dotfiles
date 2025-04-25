vim.g.mapleader = " "

require("plugins/packer")

require("plugins/augment-code")
require("plugins/bufexplorer")
require("plugins/formatter")
require("plugins/markdown-preview")
require("plugins/mason")
require("plugins/nerdtree")
require("plugins/nvim-cmp")
require("plugins/nvim-lint")
require("plugins/nvim-lspconfig")
require("plugins/packer")
require("plugins/telescope")
require("plugins/vim-wintabs")

vim.cmd("set nu")
vim.cmd("colorscheme rigel")
vim.cmd("let g:loaded_matchparen=1")

require("config/clipboard")
require("config/filetypes")
require("config/spellcheck")
require("config/whitespaces")

require("misc/json-format")
require("misc/save-files")
