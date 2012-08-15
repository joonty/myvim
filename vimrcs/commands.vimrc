
" Common mistypings
command! Q q
command! -bang Q q<bang>
command! Qall qall
command! -bang Qall qall<bang>
command! W w
command! -nargs=1 -complete=tag Tag tag <args>
" Save a file that requires sudoing even when
" you opened it as a normal user.
command! Sw w !sudo tee % > /dev/null
" Shortcut to NERDTree
command! -nargs=1 -complete=dir Tree NERDTree <args>
" Command to build ctags file
command! -nargs=+ -complete=dir Rtags !ctags -R --languages=+PHP --exclude=build <args> | set tags=tags
" Show difference between modified buffer and original file
command! DiffSaved call s:DiffWithSaved()

