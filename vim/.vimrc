" --- Plugins --- 
call plug#begin()

Plug 'prabirshrestha/vim-lsp'
Plug 'elixir-editors/vim-elixir'
Plug 'roblillack/vim-bufferlist'

call plug#end()

" --- Plugin config --- 
"
" >> vim-lsp
let g:lsp_use_native_client = 1

if executable('expert')
    augroup lsp_expert
    autocmd!
    autocmd User lsp_setup call lsp#register_server({
        \ 'name': 'expert',
        \ 'cmd': {server_info -> ['expert', '--stdio']},
        \ 'allowlist': ['elixir', 'eelixir', 'heex', 'surface']
    \ })
    autocmd FileType elixir setlocal omnifunc=lsp#complete
    autocmd FileType eelixir setlocal omnifunc=lsp#complete
    autocmd FileType heex setlocal omnifunc=lsp#complete
    augroup END
endif

" if executable('expert')
"     au User lsp_setup call lsp#register_server({
"         \ 'name': 'expert',
"         \ 'cmd': {server_info->['expert`']},
"         \ 'allowlist': ['elixir'],
"         \ })
" endif
" if executable('pylsp')
"     " pip install python-lsp-server
"     au User lsp_setup call lsp#register_server({
"         \ 'name': 'pylsp',
"         \ 'cmd': {server_info->['pylsp']},
"         \ 'allowlist': ['python'],
"         \ })
" endif

function! s:on_lsp_buffer_enabled() abort
    setlocal omnifunc=lsp#complete
    setlocal signcolumn=yes
    if exists('+tagfunc') | setlocal tagfunc=lsp#tagfunc | endif
    nmap <buffer> gd <plug>(lsp-definition)
    nmap <buffer> gs <plug>(lsp-document-symbol-search)
    nmap <buffer> gS <plug>(lsp-workspace-symbol-search)
    nmap <buffer> gr <plug>(lsp-references)
    nmap <buffer> <leader>rn <plug>(lsp-rename)
    nmap <buffer> [g <plug>(lsp-previous-diagnostic)
    nmap <buffer> ]g <plug>(lsp-next-diagnostic)
    nmap <buffer> K <plug>(lsp-hover)

    let g:lsp_format_sync_timeout = 1000
    autocmd! BufWritePre *.rs,*.go call execute('LspDocumentFormatSync')
    
    " refer to doc to add more commands
endfunction

augroup lsp_install
    au!
    " call s:on_lsp_buffer_enabled only for languages that has the server registered.
    autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
augroup END 
"
" 
" >> vim-elixir 
syntax on
" Enables filetype detection, loads ftplugin, and loads indent
" " (Not necessary on nvim and may not be necessary on vim 8.2+)
filetype plugin indent on
" 
" 
" >> vim-bufferlist
map <silent> \\ :call BufferList()<CR>
let g:BufferListWidth = 25
let g:BufferListMaxWidth = 50
" hi BufferSelected term=reverse ctermfg=white ctermbg=red cterm=bold
" hi BufferNormal term=NONE ctermfg=black ctermbg=darkcyan cterm=NONE

" 
" 
" --- my config --- 
colorscheme desert

set nowrap
set laststatus=2
set number
set numberwidth=6 

" 
" 
" --- sane defaults ---
set nocompatible
set title
set encoding=utf-8

