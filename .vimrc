set nocompatible

" Pathogen is used to handle plugins more cleanly
call pathogen#helptags()
call pathogen#runtime_append_all_bundles()
filetype off

syntax on
filetype plugin indent on

" Make it easier to update this file
nmap <leader>ev :e $MYVIMRC<CR>
nmap <leader>sv :so $MYVIMRC<CR>

nmap <leader>w :w!<cr>              " Quick-save!

set shiftwidth=2                    " Number of spaces per (auto) indent
set softtabstop=2                   " Use spaces as tab for BACKSPACE/DELETE
set tabstop=2                       " Number of spaces per tab
set textwidth=70                    " Wrap safely at an 80 char margin
set expandtab                       " Turn tabs into spaces

set title                           " Show title
set magic                           " Regex searches
set hlsearch                        " Highlighted searching
set incsearch                       " Search incrementally
set smartcase                       " Only ignore case for all-lowercase
set ignorecase                      " Ignore case during search
set spell                           " Spell check on by default
map <leader>ss :setlocal spell!<cr> " Spell check toggle
map <leader>sl :setlocal list!<cr>  " Toggle invisible characters
set listchars=tab:▸\ ,eol:¬         " Nicer invisi-chars

nnoremap <tab> %                    " Faster than %
vnoremap <tab> %

set showmatch                       " Show matching parens
set mat=1                           " How long to show paren match, in tenths/S
set ruler                           " Show lines and columns at the bottom

set visualbell                      " No beeping out loud
set noerrorbells                    " No bells

set nobackup
set noswapfile                      " I never ever use swap files
set autoread                        " Auto-reload files when changed outside
filetype plugin indent on           " Filetype-aware plugins and indentation
set encoding=utf8

if has("autocmd")
  " When editing a file, always jump to the last cursor position
  autocmd BufReadPost *
  \ if line("'\"") > 0 && line ("'\"") <= line("$") |
  \   exe "normal g'\"" |
  \ endif
endif
set viminfo^=%

" Set up :W, :Q, etc
cmap W w            
cmap Q q
cmap Tabe tabe

set pastetoggle=<F2>
:map <F5> :!runcode %<CR>
:map <F6> :!php %<CR>
:map <F7> :!clojure %<CR>

:map ,, <Esc>:tabp<CR>
:map ,. <Esc>:tabn<CR>

" Unhighlight with spacebar
:nnoremap <silent> <Space> :nohlsearch<Bar>:echo<CR>

" Let me save with sudo if I REALLY want to
cmap w!! w !sudo tee % >/dev/null

" Yank text to the OS X clipboard (Requires compiled-in support)
noremap <leader>y "*y
noremap <leader>yy "*Y

" Preserve indentation while pasting text from the OS X clipboard
noremap <leader>p :set paste<CR>:put  *<CR>:set nopaste<CR>

try
    colorscheme solarized
    set background=dark
catch /^Vim\%((\a\+)\)\=:E185/
    colorscheme evening
endtry
