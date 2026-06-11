" --- Plugins --- 
call plug#begin()

Plug 'prabirshrestha/vim-lsp'
Plug 'elixir-editors/vim-elixir'
Plug 'roblillack/vim-bufferlist'
Plug 'airblade/vim-gitgutter'
Plug 'godlygeek/tabular'
Plug 'preservim/vim-markdown'

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

" statusline color per mode (needs vim 8.2.3430+ for ModeChanged)
function! s:StatuslineModeColor() abort
    let l:m = mode()
    if l:m =~# '^i'
        " insert: orange
        hi StatusLine cterm=NONE ctermfg=232 ctermbg=208 gui=NONE guifg=#000000 guibg=#ff8700
    elseif l:m =~# "^[vV\<C-v>]"
        " visual: darkblue/magenta
        hi StatusLine cterm=NONE ctermfg=255 ctermbg=90 gui=NONE guifg=#eeeeee guibg=#870087
    else
        " normal: gray/silver
        hi StatusLine cterm=NONE ctermfg=232 ctermbg=250 gui=NONE guifg=#000000 guibg=#bcbcbc
    endif
endfunction

if exists('##ModeChanged')
    augroup statusline_mode_color
        autocmd!
        autocmd ModeChanged * call s:StatuslineModeColor()
        autocmd VimEnter,ColorScheme * call s:StatuslineModeColor()
    augroup END
endif

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

" --- folding ---
set foldenable
set foldmethod=indent
set foldlevel=10

set norelativenumber

" --- keymaps ---
nnoremap <F1>    :w<cr>
nnoremap <F2>    :w<cr>
nnoremap <F14>   :noa w<cr>
nnoremap <F3>    zo
nnoremap <C-F3>  zO
nnoremap <F15>   zR
nnoremap <F4>    zc
nnoremap <C-F4>  zC
nnoremap <S-Tab> :b#<cr>

inoremap <F1>    <Esc>:w<CR>
inoremap <F2>    <Esc>:w<CR>
inoremap <F3>    <Esc>zo<Insert>
inoremap <F4>    <Esc>zc<Up><Insert><Down>
inoremap <S-Tab> <Esc>:b#<cr>

