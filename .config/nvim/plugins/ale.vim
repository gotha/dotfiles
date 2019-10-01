
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
