set nocompatible               " be iMproved
filetype off                   " required!
let mapleader=","

set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

let g:NERDTreeMapHelp = "h"

"{{{ Vundle Bundles!
Bundle 'gmarik/vundle'

" My Bundles here:
"
" original repos on github
Bundle 'tpope/vim-fugitive'
Bundle 'Lokaltog/vim-easymotion'
Bundle 'rstacruz/sparkup', {'rtp': 'vim/'}
Bundle 'tpope/vim-rails.git'
Bundle 'scrooloose/nerdtree.git'
" vim-scripts repos
Bundle 'L9'
Bundle 'FuzzyFinder'
Bundle 'bufexplorer.zip'
" non github repos
Bundle 'git://git.wincent.com/command-t.git'
" ...
Bundle 'joonty/ManPageView.git'
Bundle 'joonty/vim-phpqa.git'
Bundle 'joonty/vim-sauce.git'
Bundle 'tpope/vim-fugitive.git'
Bundle 'greyblake/vim-preview.git'
Bundle 'sjl/gundo.vim.git'
Bundle 'fholgado/minibufexpl.vim.git'
"}}}

filetype plugin indent on     " required! 
syntax enable
colorscheme jc
runtime macros/matchit.vim
let g:EasyMotion_leader_key = '<Space>'

"{{{ Functions

"{{{ Open URL in browser

function! Browser ()
	let line = getline (".")
	let line = matchstr (line, "http[^   ]*")
	exec "!konqueror ".line
endfunction

"}}}
"{{{ Close quickfix with main window close 
au BufEnter * call MyLastWindow()
function! MyLastWindow()
	" if the window is quickfix go on
	if &buftype=="quickfix"
		" if this window is last on screen quit without warning
		if winbufnr(2) == -1
			quit!
		endif
	endif
endfunction
"}}}
"{{{ Diff current unsaved file
function! s:DiffWithSaved()
	let filetype=&ft
	diffthis
	vnew | r # | normal! 1Gdd
	diffthis
	exe "setlocal bt=nofile bh=wipe nobl noswf ro ft=" . filetype
endfunction
"}}}
"{{{ Clean close
command! Bw call CleanClose(1,0)
command! Bq call CleanClose(0,0)
command! -bang Bw call CleanClose(1,1)
command! -bang Bq call CleanClose(0,1)

function! CleanClose(tosave,bang)
	if a:bang == 1
		let bng = "!"
	else
		let bng = ""
	endif
	if (a:tosave == 1)
		w!
	endif
	let todelbufNr = bufnr("%")
	let newbufNr = bufnr("#")
	if ((newbufNr != -1) && (newbufNr != todelbufNr) && buflisted(newbufNr))
		exe "b".newbufNr
	else
		exe "bnext".bng
	endif

	if (bufnr("%") == todelbufNr)
		new
	endif
	exe "bd".bng.todelbufNr
endfunction
"}}}

"}}}

"{{{ Settings
set hidden
set history=1000
set ruler
set ignorecase
set smartcase
set title
set scrolloff=3
set backupdir=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp
set directory=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp
set wildmenu
set wildmode=list:longest
set wrapscan
set clipboard=unnamed
set shortmess=atI
set visualbell
set backspace=indent,eol,start
"Status line coolness
set laststatus=2
set statusline=branch:\ %{fugitive#statusline()}\ %F%m%r%h%w\ (%{&ff}){%Y}\ [%l,%v][%p%%]
set showcmd
" Search things
set hlsearch
set incsearch " ...dynamically as they are typed.
set listchars=tab:>-,trail:·,eol:$
" Folds
set foldmethod=marker
set wildmenu
set wildmode=list:longest,full
set mouse=a
set nohidden
"}}}

" Favorite Color Scheme
if has("gui_running")
	set guifont=Anonymous\ Pro\ 13
endif

"{{{ PHPDoc
let g:pdv_cfg_Author = "Jon Cairns <jon@22blue.co.uk>"
let g:pdv_cfg_Copyright = "Copyright (c) 22 Blue ".strftime("%Y")
let g:pdv_cfg_License = ""
let g:pdv_cfg_Version = ""
let g:pdv_cfg_Version = ""
"}}}

"{{{ Mini Buffer
let g:miniBufExplMapWindowNavVim = 1 
let g:miniBufExplMapWindowNavArrows = 1 
let g:miniBufExplMapCTabSwitchBufs = 1 
let g:miniBufExplModSelTarget = 1 
"}}}

"{{{ Key Maps

"Escape insert with jj
inoremap jj <Esc>

nnoremap JJJJ <Nop>

" Open Url on this line with the browser \w
map <Leader>b :call Browser ()<CR>

"nnoremap y "+y
"vnoremap y "+y
nnoremap <C-e> 3<C-e>
nnoremap <C-y> 3<C-y>
filetype on
filetype plugin on
filetype indent on
map ; <Plug>ShowFunc 

" Highlight search terms...
nmap <silent> <leader>s :set nolist!<CR>
inoremap <C-d> <ESC>:call PhpDocSingle()<CR>i 
nnoremap <C-d> :call PhpDocSingle()<CR> 
vnoremap <C-d> :call PhpDocRange()<CR> 
nnoremap \ :GundoToggle<CR>
"}}}

" Autocommands
"  
" run file with PHP CLI (CTRL-M)
"autocmd FileType php noremap <C-M> :w!<CR>:!/usr/bin/php %<CR>
" " PHP parser check (CTRL-L)
autocmd! FileType php noremap <C-L> :!/usr/bin/php -l %<CR>
autocmd! FileType php set omnifunc=phpcomplete#CompletePHP

"{{{ Commands
command! Q q
command! -bang Q q<bang>

command! W w
command! B buffers
command! Sw w !sudo tee % > /dev/null
command! -nargs=1 -complete=dir Tree NERDTree <args>
command! -nargs=+ -complete=dir Rtags !ctags -R --languages=+PHP --exclude=build <args> | set tags=tags
com! DiffSaved call s:DiffWithSaved()

"}}}

" PHPQA stuff
let g:phpqa_codecoverage_autorun = 0
let g:phpqa_messdetector_autorun = 0
let g:phpqa_codesniffer_autorun = 0
