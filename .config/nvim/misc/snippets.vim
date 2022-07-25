
autocmd FileType html nnoremap ,html  :-1read $HOME/.config/nvim/snippets/html/main.html<CR>3jf>a
autocmd FileType sh nnoremap ,1  :-1read $HOME/.config/nvim/snippets/bash/shebang.sh<CR>A<CR><CR>

" GO snippets
autocmd FileType go nnoremap ,p  <Esc>:-1read $HOME/.config/nvim/snippets/go/package.go<CR>$a
autocmd FileType go nnoremap ,e  <Esc>:read $HOME/.config/nvim/snippets/go/err.go<CR>:GoFmt<CR>ji
autocmd FileType go nnoremap ,d  <Esc>:read $HOME/.config/nvim/snippets/go/dump.go<CR>:GoFmt<CR>f)i,
autocmd FileType go nnoremap ,s  <Esc>:read $HOME/.config/nvim/snippets/go/dump_full.go<CR>:GoFmt<CR>jf)i,

" JS/TS snippets
autocmd FileType javascript nnoremap ,d  <Esc>:read $HOME/.config/nvim/snippets/js/consolelog.js<CR>f)i

autocmd FileType typescript nnoremap ,d  <Esc>:read $HOME/.config/nvim/snippets/js/consolelog.js<CR>f)i
autocmd FileType typescript nnoremap ,cl  <Esc>:read $HOME/.config/nvim/snippets/ts/class.ts<CR>f}i
