set nocompatible              " be iMproved, required
filetype off                  " required

syntax on
set clipboard+=unnamed
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


call plug#begin('~/.vim/plugged')

Plug 'scrooloose/nerdtree'
Plug 'jlanzarotta/bufexplorer'
Plug 'zefei/vim-wintabs'
Plug 'mileszs/ack.vim'
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
Plug 'shime/vim-livedown' 
Plug 'moll/vim-node' 
Plug 'w0rp/ale' 
Plug 'kien/ctrlp.vim' 
Plug 'nathanaelkane/vim-indent-guides' 
Plug 'vim-scripts/auto-pairs-gentle' 
Plug 'Valloric/YouCompleteMe'
Plug 'godlygeek/tabular'
Plug 'plasticboy/vim-markdown'
Plug 'sotte/presenting.vim'
Plug 'will133/vim-dirdiff'
Plug 'phpactor/phpactor', { 'for': 'php' }
Plug 'StanAngeloff/php.vim', { 'for': 'php' }
Plug 'ludovicchabant/vim-gutentags'

call plug#end()

set backupdir=/tmp
set directory=$HOME/.vim/swapfiles/

set undofile 		      " tell it to use an undo file
set undodir=$HOME/.vim/undo/ " set a directory to store the undo history

let g:indent_guides_enable_on_vim_startup = 1

if executable('ag')
  let g:ackprg = 'ag --vimgrep --ignore-dir node_modules --ignore-dir vendor'
endif


autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType javascript setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType json setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType css setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType vue setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType vue syntax sync fromstart
autocmd FileType sh setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType xslt setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType xsd setlocal ts=3 sts=2 sw=2 expandtab
autocmd FileType json syntax match Comment +\/\/.\+$+
let g:vue_disable_pre_processors=1


let mapleader=" "

map <leader>jf  <Esc>:%!python -m json.tool<CR>
map <leader>e  <Esc>:e .<CR>
map <leader>d  <Esc>:Ack 

map <leader>w	<Esc>:BufExplorer<CR><Esc>
map <leader>a	<Esc>:WintabsPrevious<CR><Esc>
map <leader>f	<Esc>:WintabsNext<CR><Esc>

map <leader>1 	<Esc>:WintabsFirst<CR><Esc>
map <leader>2 	<Esc>:WintabsGo 2<CR><Esc>
map <leader>3 	<Esc>:WintabsGo 3<CR><Esc>
map <leader>4 	<Esc>:WintabsGo 4<CR><Esc>
map <leader>5 	<Esc>:WintabsGo 5<CR><Esc>
map <leader>6 	<Esc>:WintabsGo 6<CR><Esc>
map <leader>7 	<Esc>:WintabsGo 7<CR><Esc>
map <leader>8 	<Esc>:WintabsGo 8<CR><Esc>
map <leader>9 	<Esc>:WintabsGo 9<CR><Esc>
map <leader>0 	<Esc>:WintabsLast<CR><Esc>


" ALE fixers and linters
let g:ale_fixers = {
\   'javascript': ['eslint', 'remove_trailing_lines', 'trim_whitespace'],
\   'yaml': ['remove_trailing_lines', 'trim_whitespace'],
\   'cloudformation': ['cfn_python_lint', 'remove_trailing_lines', 'trim_whitespace'],
\   'sh': ['shfmt'],
\}

let g:ale_linters = {
\   'javascript': ['eslint'],
\   'cloudformation': ['cfn_python_lint'],
\   'sh': ['shellcheck'] ,
\   'go': ['golint', 'govet']
\}

let g:ale_sh_shfmt_options='-i 2 -ci' " Google style
let g:ale_fix_on_save = 1



autocmd FileType go map <leader>b  <Esc>:GoBuild<CR>
autocmd FileType go map <leader>r  <Esc>:GoRun<CR>
autocmd FileType go map <leader>t  <Esc>:GoTest<CR>
autocmd FileType go map <leader>c  <Esc>:GoCoverage<CR>

" go to test or tested file 
autocmd FileType go map <leader>y  <Esc>:GoAlternate<CR> 
" show list of all functions in file
autocmd FileType go map <leader>o  <Esc>:GoDecls<CR> 
autocmd FileType go map <leader>g  <Esc>:GoDoc<CR> 
autocmd FileType go map <leader>u  <Esc>:GoReferrers<CR> 
autocmd FileType go map <leader>i  <Esc>:GoImplements<CR> 

autocmd FileType go set foldmethod=syntax
autocmd FileType go set foldnestmax=1
let g:go_fmt_command = "goimports"
let g:go_fmt_fail_silently = 1

" By default syntax-highlighting for Functions, Methods and Structs is disabled.
" Let's enable them!
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_structs = 1

" Hide locationlist on golang files when there are no errors
" let g:syntastic_auto_loc_list = 2
autocmd FileType java setlocal omnifunc=javacomplete#Complete

let g:livedown_browser = "firefox"
let g:livedown_open = 1
autocmd FileType markdown map <leader>p  <Esc>:LivedownPreview<CR>


set noerrorbells visualbell t_vb=
autocmd GUIEnter * set visualbell t_vb=


let g:vim_markdown_folding_disabled = 1

let g:indentLine_char_list = ['|', '¦', '┆', '┊']

" Spell check
set nospell
set spelllang=en_us
nmap <silent> <space>sp :setlocal spell!<CR>



autocmd FileType html nnoremap ,html  :-1read $HOME/.vim/snippets/html/main.html<CR>3jf>a
autocmd FileType sh nnoremap ,1  :-1read $HOME/.vim/snippets/bash/shebang.sh<CR>A<CR><CR>

" GO snippets
autocmd FileType go nnoremap ,p  <Esc>:-1read $HOME/.vim/snippets/go/package.go<CR>$a
autocmd FileType go nnoremap ,e  <Esc>:read $HOME/.vim/snippets/go/err.go<CR>:GoFmt<CR>ji
autocmd FileType go nnoremap ,d  <Esc>:read $HOME/.vim/snippets/go/dump.go<CR>:GoFmt<CR>f)i, 

set completeopt-=preview

