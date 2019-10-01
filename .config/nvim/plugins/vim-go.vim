
autocmd FileType go map <leader>b  <Esc>:GoBuild<CR>
autocmd FileType go map <leader>r  <Esc>:GoRun<CR>
autocmd FileType go map <leader>t  <Esc>:GoTest<CR>
autocmd FileType go map <leader>c  <Esc>:GoCoverage<CR>
autocmd FileType go map <leader>im  <Esc>:GoImports<CR>
autocmd FileType go map <leader>in  <Esc>:GoInstall<CR>

" go to test or tested file 
autocmd FileType go map <leader>y  <Esc>:GoAlternate<CR> 
" show list of all functions in file
autocmd FileType go map <leader>o  <Esc>:GoDecls<CR> 
autocmd FileType go map <leader>g  <Esc>:GoDoc<CR> 

autocmd FileType go set foldmethod=syntax
autocmd FileType go set foldnestmax=1
let g:go_fmt_command = "goimports"
let g:go_fmt_fail_silently = 1

" By default syntax-highlighting for Functions, Methods and Structs is disabled.
" Let's enable them!
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_structs = 1
