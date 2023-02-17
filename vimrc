if exists(':let') == 0
    finish
endif
set nocompatible               " be iMproved

filetype off                   " required!

"<Leader> key is ,
let mapleader=","

if has("win32")
    let g:os = "win"
else
    let g:os = "unix"
endif

if g:os == "win"
    set shell=C:/cygwin/bin/bash
    set shellcmdflag=--login\ -c
    set shellxquote=\"
    set runtimepath=$HOME/.vim,$VIM/vimfiles,$VIMRUNTIME,$VIM/vimfiles/after,$HOME/.vim/after
    let $TMP=expand("$HOME/vim-tmp")
    let $TEMP=expand("$HOME/vim-tmp")
endif

" Vundle init
set rtp+=~/.vim/bundle/vundle/

" Require Vundle
try
    call vundle#rc()
catch
    echohl Error | echo "Vundle is not installed. Run 'cd ~/.vim/ && git submodule init && git submodule update'" | echohl None
endtry


"{{{ Vundle Plugins!
if exists(':Plugin')
    Plugin 'gmarik/vundle'

    " Plugins
    "Plugin 'joonty/vim-do'
    Plugin 'easymotion/vim-easymotion'
    Plugin 'scrooloose/nerdtree.git'
    Plugin 'vimwiki/vimwiki.git'
    Plugin 'joonty/vim-sauce.git'
    "Plugin 'joonty/vdebug.git'
    Plugin 'joonty/vim-taggatron.git'
    Plugin 'tpope/vim-fugitive.git'
    Plugin 'tpope/vim-surround.git'
    "Plugin 'tpope/vim-commentary.git'
    Plugin 'tpope/vim-endwise.git'
    Plugin 'ervandew/supertab.git'
    "Plugin 'joonty/vim-tork.git'
    Plugin 'jremmen/vim-ripgrep.git'
    Plugin 'zhaocai/GoldenView.Vim'
    "Plugin 'pelodelfuego/vim-swoop'
    Plugin 'kien/ctrlp.vim'
    "Plugin 'itchyny/lightline.vim'
    "Plugin 'godlygeek/tabular'
    Plugin 'FelikZ/ctrlp-py-matcher'

    " Language support
    Plugin 'scrooloose/syntastic.git'
    "Plugin 'kchmck/vim-coffee-script'
    Plugin 'tpope/vim-rails.git'
    Plugin 'tpope/vim-markdown.git'
    Plugin 'othree/html5.vim.git'
    Plugin 'pangloss/vim-javascript.git'
    Plugin 'mxw/vim-jsx.git'
    Plugin 'vim-ruby/vim-ruby'
    "Plugin 'rust-lang/rust.vim.git'
    "Plugin 'StanAngeloff/php.vim.git'
    "Plugin 'elixir-lang/vim-elixir.git'
    Plugin 'hdima/python-syntax.git'

    " Colors
    Plugin 'chriskempson/vim-tomorrow-theme'
end
"}}}

filetype plugin indent on     " required!
syntax enable
colorscheme Tomorrow-Night
runtime macros/matchit.vim
let g:EasyMotion_leader_key = '\'

"{{{ Functions

"{{{ Restart rails
command! RestartRails call RestartRails(getcwd())
function! RestartRails(dir)
    let l:ret=system("touch ".a:dir."/tmp/restart.txt")
    if l:ret == ""
        echo "Restarting Rails, like a boss"
    else
        echohl Error | echo "Failed to restart rails - is your working directory a rails app?" | echohl None
    endif
endfunction
"}}}
"{{{ Open URL in browser

function! Browser ()
    let line = getline (".")
    let line = matchstr (line, "http[^   ]*")
    exec "!google-chrome ".line
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
"{{{ Run command and put output in scratch
command! -complete=shellcmd -nargs=+ Shell call s:RunShellCommand(<q-args>)
function! s:RunShellCommand(cmdline)
    let isfirst = 1
    let words = []
    for word in split(a:cmdline)
        if isfirst
            let isfirst = 0  " don't change first word (shell command)
        else
            if word[0] =~ '\v[%#<]'
                let word = expand(word)
            endif
            let word = shellescape(word, 1)
        endif
        call add(words, word)
    endfor
    let expanded_cmdline = join(words)
    botright new
    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap
    call setline(1, 'You entered:  ' . a:cmdline)
    call setline(2, 'Expanded to:  ' . expanded_cmdline)
    call append(line('$'), substitute(getline(2), '.', '=', 'g'))
    silent execute '$read !'. expanded_cmdline
    1
endfunction
"}}}
"{{{ CakePHP unit test callback for PHPUnitQf
function! CakePHPTestCallback(args)
    " Trim white space
    let l:args = substitute(a:args, '^\s*\(.\{-}\)\s*$', '\1', '')

    " If no arguments are passed to :Test
    if len(l:args) is 0
        let l:file = expand('%')
        if l:file =~ "^.*app/Test/Case.*"
            " If the current file is a unit test
            let l:args = substitute(l:file,'^.*app/Test/Case/\(.\{-}\)Test\.php$','\1','')
        else
            " Otherwise try and run the test for this file
            let l:args = substitute(l:file,'^.*app/\(.\{-}\)\.php$','\1','')
        endif
    endif
    return l:args
endfunction
"}}}
" {{{ Sass compile
let g:sass_output_file = ""
let g:sass_enabled = 0
let g:sass_path_maps = {}
command! Sass call SassCompile()
autocmd BufWritePost *.scss call SassCompile()
function! SassCompile()
    if g:sass_enabled == 0
        return
    endif
    let curfile = expand('%:p')
    let inlist = 0
    for fpath in keys(g:sass_path_maps)
        if fpath == curfile
            let g:sass_output_file = g:sass_path_maps[fpath]
            let inlist = 1
            break
        endif
    endfor
    if g:sass_output_file == ""
        let g:sass_output_file = input("Please specify an output CSS file: ",g:sass_output_file,"file")
    endif
    let l:op = system("sass --no-cache --style compressed ".@%." ".g:sass_output_file)
    if l:op != ""
        echohl Error | echo "Error compiling sass file" | echohl None
        let &efm="Syntax error: %m %#on line %l of %f%.%#"
        cgete [l:op]
        cope
    endif
    if inlist == 0
        let choice = confirm("Would you like to keep using this output path for this sass file?","&Yes\n&No")
        if choice == 1
            let g:sass_path_maps[curfile] = g:sass_output_file
        endif
    endif
    let g:sass_output_file = ""
endfunction
"}}}
"{{{ Function to use spaces instead of tabs
command! -nargs=+ Spaces call s:use_spaces(<q-args>)
function! s:use_spaces(swidth)
    let l:cwidth = a:swidth
    let &tabstop=l:cwidth
    let &shiftwidth=l:cwidth
    let &softtabstop=l:cwidth
    set expandtab
endfunction
"}}}
"{{{ Function to use tabs instead of spaces
command! Tabs call s:use_tabs()
function! s:use_tabs()
    let &tabstop=4
    let &shiftwidth=4
    let &softtabstop=0
    set noexpandtab
endfunction
"}}}
"{{{ Wipeout buffers not used
function! Wipeout()
    " list of *all* buffer numbers
    let l:buffers = range(1, bufnr('$'))

    " what tab page are we in?
    let l:currentTab = tabpagenr()
    try
        " go through all tab pages
        let l:tab = 0
        while l:tab < tabpagenr('$')
            let l:tab += 1

            " go through all windows
            let l:win = 0
            while l:win < winnr('$')
                let l:win += 1
                " whatever buffer is in this window in this tab, remove it from
                " l:buffers list
                let l:thisbuf = winbufnr(l:win)
                call remove(l:buffers, index(l:buffers, l:thisbuf))
            endwhile
        endwhile

        " if there are any buffers left, delete them
        if len(l:buffers)
            execute 'bwipeout' join(l:buffers)
        endif
    finally
        " go back to our original tab page
        execute 'tabnext' l:currentTab
    endtry
endfunction
"}}}
"{{{ Find and replace in multiple files
command! -nargs=* -complete=file Fart call FindAndReplace(<f-args>)
function! FindAndReplace(...)
    if a:0 < 3
        echohl Error | echo "Three arguments required: 1. file pattern, 2. search expression and 3. replacement" | echohl None
        return
    endif
    if a:0 > 3
        echohl Error | echo "Too many arguments, three required: 1. file pattern, 2. search expression and 3. replacement" | echohl None
        return
    endif
    let l:pattern = a:1
    let l:search = a:2
    let l:replace = a:3
    echo "Replacing occurences of '".l:search."' with '".l:replace."' in files matching '".l:pattern."'"

    execute '!find . -name "'.l:pattern.'" -print | xargs -t sed -i "s/'.l:search.'/'.l:replace.'/g"'
endfunction

"}}}
"{{{ Toggle relative and absolute line numbers
function! LineNumberToggle()
  if(&relativenumber == 1)
    set number
  else
    set relativenumber
  endif
endfunc
"}}}
"{{{ Toggle the arrow keys

let g:arrow_keys_enabled = 1
noremap <Up> <nop>
noremap <Down> <nop>
noremap <Left> <nop>
noremap <Right> <nop>

function! ArrowKeysToggle()
  if g:arrow_keys_enabled == 1
    call DisableArrowKeys()
    echo "Disabling arrow keys"
    let g:arrow_keys_enabled = 0
  else
    call EnableArrowKeys()
    echo "Enabling arrow keys"
    let g:arrow_keys_enabled = 1
  end
endfunc

function! EnableArrowKeys()
  noremap <Up> k
  inoremap <Up> <Up>
  noremap <Down> j
  inoremap <Down> <Down>
  noremap <Left> h
  inoremap <Left> <Left>
  noremap <Right> l
  inoremap <Right> <Right>
endfunc

function! DisableArrowKeys()
  noremap <Up> <nop>
  inoremap <Up> <nop>
  noremap <Down> <nop>
  inoremap <Down> <nop>
  noremap <Left> <nop>
  inoremap <Left> <nop>
  noremap <Right> <nop>
  inoremap <Right> <nop>
endfunc
"}}}

"{{{ Insert command output
command! -nargs=+ Iruby call InsertCommand("ruby " . <q-args>)
command! -nargs=+ Ipython call InsertCommand("python " . <q-args>)

function! InsertCommand(command)
    redir => output
    silent execute a:command
    redir END
    call feedkeys('i'.substitute(output, '^[\n]*\(.\{-}\)[\n]*$', '\1', 'gm'))
endfunction
"}}}

"{{{ Create new blog post for joncairns.com
function! BlogPost(name)
    let l:slug = substitute(substitute(tolower(a:name), " ", "-", "g"), '\[^a-z-]', "", "g")
    let l:date = strftime("%Y-%m-%d")
    let l:datetime = strftime("%Y-%m-%d %H:%M:%S")
    Sauce joncairns
    exec 'edit _posts/' . l:date . '-' . l:slug . '.markdown'
    let @p= '---' . "\n" . '
            \author: joonty' . "\n" .'
            \comments: true' . "\n" .'
            \date: ' . l:datetime . "\n" .'
            \layout: post' . "\n" .'
            \slug: ' . l:slug . "\n" .'
            \title: ' . a:name . "\n" .'
            \categories:' . "\n" .'
            \- Dev' . "\n" .'
            \tags:' . "\n" .'
            \- ' . "\n" .'
            \---'
    put! p
endfunction
command! -nargs=+ BlogPost call BlogPost(<q-args>)
"}}}
"{{{ Get visual selection
function! GetVisualSelection()
  " Why is this not a built-in Vim script function?!
  let [lnum1, col1] = getpos("'<")[1:2]
  let [lnum2, col2] = getpos("'>")[1:2]
  let lines = getline(lnum1, lnum2)
  let lines[-1] = lines[-1][: col2 - (&selection == 'inclusive' ? 1 : 2)]
  let lines[0] = lines[0][col1 - 1:]
  return join(lines, "\n")
endfunction
"}}}
"{{{ Where() -> show current file location
function! Where()
  echo expand("%:p")
endfunction
"}}}

"}}}

"{{{ Commands
" Common mistypings
command! -nargs=* -complete=function Call exec 'call '.<f-args>
command! Q q
command! -bang Q q<bang>
command! Qall qall
command! -bang Qall qall<bang>
command! W w
command! -nargs=1 -complete=file E e <args>
command! -bang -nargs=1 -complete=file E e<bang> <args>
command! -nargs=1 -complete=tag Tag tag <args>
" Save a file that requires sudoing even when
" you opened it as a normal user.
command! Sw w !sudo tee % > /dev/null
" Show difference between modified buffer and original file
command! DiffSaved call s:DiffWithSaved()

command Wipeout call Wipeout()
command Where call Where()
"}}}

"{{{ Settings
set ttyscroll=0
set hidden
set history=1000
set ruler
set ignorecase
set smartcase
set title
set scrolloff=3
set backupdir=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp
set directory=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp
set wrapscan
set clipboard=unnamed
set visualbell
set backspace=indent,eol,start
"Status line coolness
set laststatus=2
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
set shortmess+=filmnrxoOt
set viewoptions=folds,options,cursor,unix,slash
set virtualedit=onemore
set shell=zsh\ --login

"Spaces, not tabs
set shiftwidth=4
set tabstop=4
set expandtab

"Speed highlighting up
set nocursorcolumn
set nocursorline
syntax sync minlines=256

" Ignore stuff
set wildignore+=*/tmp/*,*.so,*.swp,*.zip,.DS_Store

" Line numbers
set relativenumber
"}}}

let g:NERDTreeMapHelp = "h"

" Set font for GUI (e.g. GVim)
if has("gui_running")
    set guifont=Liberation\ Mono\ for\ Powerline\ 12
endif

"{{{ Key Maps
" Fast saving
nnoremap <Leader>w :w<CR>
vnoremap <Leader>w <Esc>:w<CR>
nnoremap <C-s> :w<CR>
inoremap <C-s> <Esc>:w<CR>
vnoremap <C-s> <Esc>:w<CR>

nnoremap <Leader>x :x<CR>
vnoremap <Leader>x <Esc>:x<CR>

" Stop that damn ex mode
nnoremap Q <nop>

" Quickfix!
nnoremap <Space>] :cnext<CR>
nnoremap <Space>[ :cprev<CR>
nnoremap <Space>q :cclose<CR>
nnoremap <Space>o :cope<CR>

" Quick nohl
nnoremap <Leader>h :nohl<CR>

" Line number type toggle
nnoremap <Leader>l :call LineNumberToggle()<cr>

" Quick search
nnoremap <C-f> :Rg ''<left>
" Quick search - word under cursor
nnoremap <Leader>f :Rg <cword><CR>
inoremap <Leader>f :Rg <cword><CR>
vnoremap <Leader>f :<C-U>exec ":Rg '" . GetVisualSelection() ."'"<CR>
" Quick search - method call under cursor
nnoremap <Leader>m :Rg \.<cword>\b<CR>
inoremap <Leader>m :Rg \.<cword>\b<CR>
vnoremap <Leader>m :<C-U>exec ":Rg '\." . GetVisualSelection() ."\b'"<CR>
" Quick search - word under cursor in current file
nnoremap <Leader>t :Rg <cword> %:p<CR>
inoremap <Leader>t :Rg <cword> %:p<CR>
vnoremap <Leader>t :<C-U>exec ":Rg '" . GetVisualSelection() ."' %:p"<CR>
" Quick search - method definition under cursor
nnoremap <Leader>d :Rg def\ \(self\.\)\?\<cword><CR>
inoremap <Leader>d :Rg def\ \(self\.\)\?\<cword><CR>

" Ctrl-P
let g:ctrlp_user_command = 'rg %s --files --color=never --glob ""'
let g:ctrlp_match_func = { 'match': 'pymatcher#PyMatch' }
nnoremap <Space>t :CtrlPCurWD<CR>
nnoremap <Space>l :CtrlPLine<CR>
nnoremap <Space>f :CtrlPCurFile<CR>
nnoremap <Space>s :CtrlPBufTag<CR>
nnoremap <Space>b :CtrlPBuffer<CR>

" Instead of 1 line, move 3 at a time
nnoremap <C-e> 3<C-e>
nnoremap <C-y> 3<C-y>

" Show hidden characters (spaces, tabs, etc)
nmap <silent> <leader>s :set nolist!<CR>

" PHPDoc commands
inoremap <C-d> <ESC>:call PhpDocSingle()<CR>i
nnoremap <C-d> :call PhpDocSingle()<CR>
vnoremap <C-d> :call PhpDocRange()<CR>

" Fugitive shortcuts
nnoremap <Leader>c :Gcommit -a<CR>i
nnoremap <Leader>a :Git add %:p<CR>
"}}}


" Tree of nerd
nnoremap <Leader>n :NERDTreeToggle<CR>

" Tabularize
vnoremap <Leader>t= :Tabularize /=<CR>
vnoremap <Leader>t, :Tabularize /,<CR>
vnoremap <Leader>t" :Tabularize /"<CR>
vnoremap <Leader>t' :Tabularize /'<CR>
vnoremap <Leader>t: :Tabularize /:<CR>

" Show trailing white space
hi ExtraSpace ctermbg=red guibg=red
match ExtraSpace /\s\+$/
autocmd BufWinEnter * match ExtraSpace /\s\+$/
autocmd InsertEnter * match ExtraSpace /\s\+\%#\@<!$/
autocmd InsertLeave * match ExtraSpace /\s\+$/
autocmd BufWinLeave * call clearmatches()
nnoremap <leader>z :%s/\s\+$//<cr>:let @/=''<CR>


autocmd filetype crontab setlocal nobackup nowritebackup

" Tab completion - local
let g:SuperTabDefaultCompletionType = "<c-n>"

" Vdebug options
let g:vdebug_options = {"on_close":"detach", "debug_file":"~/vdebug.log", "debug_file_level":2}

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_check_on_open=1
let g:syntastic_enable_signs=1
let g:syntastic_enable_balloons = 1
let g:syntastic_eruby_ruby_quiet_messages =
    \ {'regex': 'possibly useless use of a variable in void context'}

let g:syntastic_error_symbol = "❌"
let g:syntastic_warning_symbol = "⚠️"
highlight SyntasticErrorSign guifg=white
highlight SyntasticWarningSign guifg=white

let NERDTreeIgnore = ['\.pyc$','\.sock$']

let g:vdebug_features = {'max_depth':3}
let g:tork_pre_command = "rvm use default@global > /dev/null"
let g:taggatron_run_in_background = 1

let g:rails_projections = {
\ "lib/*.rb": { "command": "lib" },
\ "app/workers/*.rb": { "command": "worker" }}

let g:lightline = {
      \ 'colorscheme': 'wombat',
      \ 'component_expand': {
      \   'syntastic': 'SyntasticStatuslineFlag',
      \ },
      \ 'component_type': {
      \   'syntastic': 'error',
      \ },
      \ 'subseparator': { 'left': '|', 'right': '|' }
      \ }

let g:golden_ratio_exclude_nonmodifiable = 1
let g:golden_ratio_wrap_ignored = 0
set re=1

cnoremap <expr> X (getcmdtype() is# ':' && empty(getcmdline())) ? 'x' : 'X'
nnoremap <silent> <M-Right> <c-w>l
nnoremap <silent> <M-Left> <c-w>h
nnoremap <silent> <M-Up> <c-w>k
nnoremap <silent> <M-Down> <c-w>j
let g:vimwiki_list = [{'path': '~/vimwiki/',
                      \ 'syntax': 'markdown', 'ext': '.md'}]
