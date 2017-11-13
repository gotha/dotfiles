set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

Plugin 'Valloric/YouCompleteMe'
Plugin 'jiangmiao/auto-pairs'
Plugin 'tpope/vim-repeat'
Plugin 'svermeulen/vim-easyclip'
Plugin 'pangloss/vim-javascript'
Plugin 'tpope/vim-surround'
Plugin 'scrooloose/nerdtree'
Plugin 'szw/vim-tags'
Plugin 'w0rp/ale'
Plugin 'jlanzarotta/bufexplorer'
Plugin 'leafgarland/typescript-vim'
Plugin 'zefei/vim-wintabs'
Plugin 'qpkorr/vim-bufkill'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line

syntax on
set nu

" Disable Arrow keys in Escape mode
map <up> <nop>
map <down> <nop>
map <left> <nop>
map <right> <nop>

" Disable Arrow keys in Insert mode
imap <up> <nop>
imap <down> <nop>
imap <left> <nop>
imap <right> <nop>


set tabstop=4
set softtabstop=0 noexpandtab
set shiftwidth=4

cmap nt NERDTree
cmap te tabedit
cmap vs vsplit
" YouCompleteMe - do not show completion in another window
set completeopt-=preview
let g:javascript_plugin_flow = 1
let g:vim_tags_auto_generate = 1

" Changing cursor in normal and insert mode 
if !exists("g:os")
    if has("win64") || has("win32") || has("win16")
        let g:os = "Windows"
    else
        let g:os = substitute(system('uname'), '\n', '', '')
    endif
endif

if has("gui_running")
    if g:os == "Darwin"
		let &t_SI = "\<Esc>]50;CursorShape=1\x7"
		let &t_SR = "\<Esc>]50;CursorShape=2\x7"
		let &t_EI = "\<Esc>]51;CursorShape=0\x7"
    elseif g:os == "Linux"
		if has("autocmd")
		  au VimEnter,InsertLeave * silent execute '!echo -ne "\e[1 q"' | redraw!
		  au InsertEnter,InsertChange *
			\ if v:insertmode == 'i' | 
			\   silent execute '!echo -ne "\e[5 q"' | redraw! |
			\ elseif v:insertmode == 'r' |
			\   silent execute '!echo -ne "\e[3 q"' | redraw! |
			\ endif
		  au VimLeave * silent execute '!echo -ne "\e[ q"' | redraw!
		endif
    endif
endif


" Buffers 
nnoremap <silent> <C-S-M> :BufExplorer<CR>

nnoremap <silent> <C-S-N> :WintabsNext<CR>
nnoremap <silent> <C-S-B> :WintabsPrevious<CR>

set backupdir=/tmp
set directory=$HOME/.vim/swapfiles//

