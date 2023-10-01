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

vim.cmd("set nu")
vim.cmd("colorscheme rigel")

require("config/clipboard")
require("config/spellcheck")
require("config/whitespaces")
require("config/filetypes")
