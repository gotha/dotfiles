autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType javascript setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType typescript setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType html setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType json setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType css setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType vue setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType vue syntax sync fromstart
autocmd FileType sh setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType go setlocal ts=2 sts=2 sw=2 noexpandtab
autocmd FileType php setlocal ts=4 sts=4 sw=4 noexpandtab
autocmd FileType vcl setlocal ts=4 sts=4 sw=4 expandtab
autocmd FileType xml setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType java setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType conf setlocal ts=4 sts=4 sw=4 expandtab

au BufNewFile,BufRead Jenkinsfile setf groovy
autocmd FileType Jenkinsfile setlocal ts=2 sts=2 sw=2 noexpandtab
