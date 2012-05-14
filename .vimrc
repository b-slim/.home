set encoding=utf-8
set fileencodings=utf-8,cp1251

set hidden

filetype plugin on
filetype indent on

syntax on

set shiftwidth=4
set softtabstop=4

set nowrap

set autoindent
set copyindent

set shiftround "round indent to multiple of shiftwidth

set hlsearch

"per-language indentation settings
au filetype perl set shiftwidth=2 softtabstop=2 expandtab
au filetype sh set shiftwidth=2 softtabstop=2 expandtab
au filetype python set expandtab

au BufNewFile,BufRead *.tt2 set filetype=html

set wildignore=*.pyc,*.clas

set nobackup noswapfile

set listchars=eol:$,tab:>-,trail:~,extends:>,precedes:<
set list

set showtabline=2

set cursorline nocursorcolumn

set number
