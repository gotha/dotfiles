
autocmd bufnewfile,bufread *.spec.ts set filetype=typescript.test
autocmd bufnewfile,bufread *.spec.js set filetype=javascript.test

autocmd FileType typescript map <leader>r  <Esc>:!ts-node %<CR>
autocmd FileType typescript.test map <leader>t  <Esc>:!./node_modules/.bin/jest %<CR>
autocmd FileType javascript.test map <leader>t  <Esc>:!./node_modules/.bin/jest %<CR>
