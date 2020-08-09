call glaive#Install()
" Optional: Enable codefmt's default mappings on the <Leader>= prefix.
Glaive codefmt plugin[mappings]
Glaive codefmt google_java_executable="google-java-format"

augroup autoformat_settings
  autocmd FileType java AutoFormatBuffer google-java-format
augroup END

