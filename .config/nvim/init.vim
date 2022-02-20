set nocompatible " be iMproved, required
filetype off     " required

"set clipboard+=unnamed
set clipboard+=unnamedplus
set nu

let mapleader=" "

set backupdir=/tmp
set directory=$HOME/.vim/swapfiles/

set undofile 		      " tell it to use an undo file
set undodir=$HOME/.vim/undo/ " set a directory to store the undo history

set noerrorbells visualbell t_vb=
autocmd GUIEnter * set visualbell t_vb=

set completeopt-=preview

"This unsets the "last search pattern" register by hitting return
nnoremap <CR> :noh<CR><CR>

call plug#begin('~/.local/share/nvim/plugged')

Plug 'scrooloose/nerdtree'
Plug 'jlanzarotta/bufexplorer'
Plug 'zefei/vim-wintabs'

Plug 'mileszs/ack.vim'
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
Plug 'moll/vim-node' " for nodejs
Plug 'kien/ctrlp.vim' " search for files with Ctrl+P
Plug 'vim-scripts/auto-pairs-gentle' " Insert or delete brackets, parens, quotes in pair.
Plug 'shime/vim-livedown' "for markdown files
Plug 'dense-analysis/ale'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'pangloss/vim-javascript'
Plug 'NLKNguyen/cloudformation-syntax.vim'
Plug 'sebdah/vim-delve'
Plug 'tpope/vim-fugitive'
Plug 'ntpeters/vim-better-whitespace'
Plug 'Rigellute/rigel'
Plug 'vim-airline/vim-airline'
"
Plug 'neovim/nvim-lspconfig'

Plug 'udalov/kotlin-vim'

call plug#end()

map <leader>e  <Esc>:e .<CR>

source ~/.config/nvim/misc/disable-arrow-keys.vim
source ~/.config/nvim/misc/spellcheck.vim
source ~/.config/nvim/misc/snippets.vim
source ~/.config/nvim/misc/json-format.vim
source ~/.config/nvim/misc/filetypes.vim
source ~/.config/nvim/misc/whitespaces.vim

source ~/.config/nvim/plugins/wintabs.vim
source ~/.config/nvim/plugins/buffexplorer.vim
source ~/.config/nvim/plugins/vim-go.vim
source ~/.config/nvim/plugins/coc-nvim.vim
source ~/.config/nvim/plugins/ale.vim
source ~/.config/nvim/plugins/ack.vim
source ~/.config/nvim/plugins/livedown.vim
source ~/.config/nvim/plugins/markdown.vim

colorscheme rigel

let g:loaded_matchparen=1
