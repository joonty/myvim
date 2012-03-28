" ------------------------------------------------------------------------------
" Filename:      ShowFunc.vim                                                {{{
" VimScript:     #397
"
" Maintainer:    Dave Vehrs <dvehrs (at) gmail.com>
" Last Modified: 28 Mar 2006 03:58:12 PM by Dave V
"
" Copyright:     (C) 2002,2003,2004,2005,2006 Dave Vehrs
"
"                This program is free software; you can redistribute it and/or
"                modify it under the terms of the GNU General Public License as
"                published by the Free Software Foundation; either version 2 of
"                the License, or (at your option) any later version.
"
"                This program is distributed in the hope that it will be useful,
"                but WITHOUT ANY WARRANTY; without even the implied warranty of
"                MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
"                GNU General Public License for more details.
"
"                You should have received a copy of the GNU General Public
"                License along with this program; if not, write to the Free
"                Software Foundation, Inc., 59 Temple Place, Suite 330, 
"                Boston, MA 02111-1307 USA _OR_ download at copy at 
"                http://www.gnu.org/licenses/licenses.html#TOCGPL
"
" Description:   This script creates a hyper link list of all the functions,
"                subroutines, classes, macros or procedures in a  single file or
"                all currently open windows and displays them in a dynamically
"                sized cwindow.
" History:       This script inspired by an idea posted by Flemming Madsen, in
"                vimtip#79.
"
" WARNING:       It may write the file as a side effect.
" Requires:      Vim 6.0 or newer.
"                Exuberant ctags (http://ctags.sourceforge.net/).
" Install:       Put this file in the vim plugins directory (~/.vim/plugin)
"                to load it automatically, or load it manually with
"                :so ShowFunc.vim.
"                
"                                          Additional notes at end of file...}}}
" ------------------------------------------------------------------------------
" Configuration:                                                             {{{

" Test for and if necessary configure all default settings.  If you would like
" to change any setting, just add let g:variablename = "new-value" to your
" .vimrc.
" For Example, to change the location of the ctags binary, add this:
"     let g:showfuncctagsbin = "/bin/ctags"
"       OR
"     let g:showfuncctagsbin = "c:\\gnu\\ctags\\ctags.exe"
 
" Default ScanType Options:   buffers  |  Scan all open buffers.
"                             current  |  Scan only the current buffer.
"                             windows  |  Scan all open windows.
if !exists("g:ShowFuncScanType")
  let g:ShowFuncScanType = "current"
endif

" Default SortType Options:   yes      |  Display output sorted alphabetically.
"                             no       |  Display output in file order.
"                             foldcase |  Display output sorted alphabetically,
"                                      |  disregarding case.
if !exists("g:ShowFuncSortType")
  let g:ShowFuncSortType = "foldcase"
endif

" You can limited the filetypes that are supported by listing them seperated 
" by "^@".  
" let g:CtagsSupportedFileTypes = "c^@python^@perl^@"

" ----- 
" Sometimes you'll get more results than you want and you can filter the
" output.

" To find out what languages ctags supports:
"                ctags --list-languages
" To find out what tags are supported for each language, execute:
"                ctags --list-kinds=<lang>
" For example:
"                ctags --list-kinds=vim
"                a  autocommand groups
"                f  function definitions
"                v  variable definitions

" Now, we can set ctags to just search for functions like so:
"                let g:ShowFunc_vim_Kinds = "f"
" To search for functions and autocommand groups:
"                let g:ShowFunc_vim_Kinds = "af"
"                let g:ShowFunc_vim_Kinds = "-a+f-v"
" To search for everything but variables:
"                let g:ShowFunc_vim_Kinds = "-v"
let g:ShowFunc_vim_Kinds = "-v"
let g:ShowFunc_php_Kinds = "-v"

" To set filters for other languages, simply set a global variable for them 
" by replacing the _vim_ with the vim filetype (same as ctags for all
" languages but c++, then use cpp).
"                let g:ShowFunc_cpp_Kinds = "-v"

"                                                                            }}}
" ------------------------------------------------------------------------------
" Exit if already loaded.                                                    {{{

if ( exists("loaded_showfunc") || &cp ) | finish | endif 
let g:loaded_showfunc=1 
			 
" Enable filetype detection 
filetype on

"                                                                            }}}
" ------------------------------------------------------------------------------
" AutoCommands:                                                              {{{

augroup showfunc_autocmd
  autocmd!
  autocmd BufEnter * call <SID>LastWindow()
augroup end

"                                                                            }}}
" ------------------------------------------------------------------------------
" Functions:                                                                 {{{

" Rotate through available scan types.
function! <SID>ChangeScanType()
	if g:ShowFuncScanType == "buffers"     | let g:ShowFuncScanType = "windows"
	elseif g:ShowFuncScanType == "windows" | let g:ShowFuncScanType = "current"
	elseif g:ShowFuncScanType == "current" | let g:ShowFuncScanType = "buffers"
  endif
	call <SID>ShowFuncOpen()
endfunction

" Rotate through available sort types.
function! <SID>ChangeSortType()
	if g:ShowFuncSortType == "no"            | let g:ShowFuncSortType = "yes"
	elseif g:ShowFuncSortType == "yes"       | let g:ShowFuncSortType = "foldcase"
	elseif g:ShowFuncSortType == "foldcase"  | let g:ShowFuncSortType = "no"
  endif
	call <SID>ShowFuncOpen()
endfunction

" Ctags binary tests
function! s:CtagsTest(path)
  " if the location of the ctags executable is not already configured, then 
  " attempt to find it....
  if a:path == "unk"
    let l:test_paths = "/usr/local/bin/ctags /usr/bin/ctags" .
      \ " C:\\gnu\\ctags\\ctags.exe "
    let l:rpath = "fail"  
    while l:test_paths != ''
      let l:pathcut = strpart(l:test_paths,0,stridx(l:test_paths,' '))
      if executable(l:pathcut)
        let l:rpath = s:CtagsVersionTest(l:pathcut)
        if l:rpath != "fail"
          break
        endif
      endif
      let l:test_paths = strpart(l:test_paths,stridx(l:test_paths,' ') + 1)
    endwhile
    if l:rpath == "fail"
      if !has("gui_running") || has("win32")
        echo "ShowFunc Error: Ctags binary not found.\n".
          \  "Please set g:showfuncctagsbin in your .vimrc.\n" 
      endif
    endif
  else
    " Else test the variable to see that it is actually an executable.
    if executable(a:path)
      let l:rpath = s:CtagsVersionTest(a:path)
    else
      if ( !has("gui_running") || has("win32") )
        echo "ShowFunc Error: Ctags binary not found.\n".
          \  "Your g:showfuncctagsbin may be set incorrectly.\n"
      endif
      let g:loaded_showfunc = 0
      let l:rpath = "fail"
    endif  
  endif
  return l:rpath
endfunction 

" Test to be sure we have Exuberant Ctags.
function! s:CtagsVersionTest(path) 
  " Test Ctags for correct ctags project.. 
  let l:test_str = strtrans(system(a:path . " -x  --version"))
  let ctagsvertest = strpart(l:test_str,0,15)
  if ctagsvertest != "Exuberant Ctags"
    if ( !has("gui_running") || has("win32") )
      echo "ShowFunc Error: Incorrect Version of Ctags.\n".
        \  "Download the correct version from http://ctags.sourceforge.net"
    endif
    let g:loaded_showfunc = 0
    let l:rpath = "fail"
  else
    let l:rpath = a:path
    " Set Ctags version variables.
    let g:CtagsMajorVersion = strpart(l:test_str,(stridx(l:test_str,"s ")+2),
      \ (stridx(l:test_str,".")-(stridx(l:test_str,"s ")+2))  )
    let l:test_str2 = strpart(l:test_str,(stridx(l:test_str,".")+1))
    if ((stridx(l:test_str2,".") < stridx(l:test_str2,",")) && (stridx(l:test_str2,".") >= 0))
      let g:CtagsSubVersion = strpart(l:test_str2,
        \ (stridx(l:test_str2,".")+1),(stridx(l:test_str2,",")-(stridx(l:test_str2,".")+1)))

      let g:CtagsMinorVersion = strpart(l:test_str2,0,
        \ (stridx(l:test_str2,".")))
    else
      let g:CtagsMinorVersion = strpart(l:test_str2,0,
        \ (stridx(l:test_str2,",")))
      let g:CtagsSubVersion = "0"
    endif
    " Test for correct versions.
    if g:CtagsMajorVersion < 5
      echo "Exuberant Ctags needs to be upgraded for ShowFunc to work."
      echo "Please visit http://ctags.sourceforge,net."
      let l:rpath = "fail"
    elseif g:CtagsMinorVersion <= 4
      echo "Exuberant Ctags should be upgraded, some features of the"
      echo "ShowFunc script may not work."
      echo "Please visit http://ctags.sourceforge,net."
    endif
    " Define default supported file types list for Ctags versions 5.5 and newer.
    if (!exists("g:CtagsSupportedFileTypes") && g:CtagsMajorVersion == 5 && 
      \ g:CtagsMinorVersion >= 5)
      let g:CtagsSupportedFileTypes = strtrans(system(l:rpath . 
        \ " -x --list-languages"))
    endif
  endif
  return l:rpath
endfunction

 " Display a simple help window.
function! <SID>DisplayHelp() 
  echo "ShowFunc Help:          \n".
    \  " c  Close                   \n".
    \  " r  Refresh                 \n".
    \  " s  Change Scan Sort  \n".
    \  " t  Change Scan Type \n"
endfunction

" Watch for last window and if its a CWindow, then close (vimtip#536).
function! <SID>LastWindow()
   if ( &buftype == "quickfix" )
    if winbufnr(2) == -1
      quit!
    endif
  endif
endfunction
 
" Determine the best window height for the new cwindow and open it.
function! s:OpenCWin()
  let l:mod_total = 0
  let l:win_count = 1
  " Determine correct window height
	windo let l:win_count =  l:win_count + 1
  if l:win_count <= 2 | let l:win_count = 4 | endif
  windo let l:mod_total = l:mod_total + winheight(0)/l:win_count |
  \ execute 'resize +'.l:mod_total
  " Open cwindow
  execute 'belowright copen '.l:mod_total
	let l:cwin_filelen = line("$")
  " Test for short output lists.
  if l:cwin_filelen < winheight(0)
    cclose
    " And adjust cwindow height accordingly.
    execute 'belowright copen '.l:cwin_filelen
  endif
  if v:version >= 700
    setlocal statusline=ShowFunc.vim\ Tag\ List
  endif
  " Set cwindow specific key mappings.
  nnoremap <buffer> <silent> c :cclose<CR>
  nnoremap <buffer> <silent> h :call <SID>DisplayHelp()<CR>
  nnoremap <buffer> <silent> r :call <SID>ShowFuncOpen()<CR>
  nnoremap <buffer> <silent> s :call <SID>ChangeSortType()<CR>
  nnoremap <buffer> <silent> t :call <SID>ChangeScanType()<CR>
  set nobuflisted
  return
endfunction

" Set Folds by filename.
function! s:ShowFuncFolds()
  let l:test_line = getline(v:lnum)
  let l:test_filename = strpart(l:test_line,0,stridx(l:test_line,'|'))
  if  g:FoldFileName == '' 
    let g:FoldFileName = l:test_filename
    return ">1"
	elseif g:FoldFileName == l:test_filename
    return "="
	else
    let g:FoldFileName = l:test_filename
    return ">1"
  endif
endfunction

" Set FoldText to filename and tag count.
function! ShowFuncFoldText()
  let l:line = ""
  let l:textwidth = &textwidth - 20
  let l:line = getline(v:foldstart)
  let l:line = strpart(l:line,0,stridx(l:line,'|'))
  if strlen(l:line) < l:textwidth
    let l:count =  59 - strlen(l:subline)
    while  strlen(l:line) < l:textwidth 
      let l:line = l:line." "
    endwhile
  endif
  let l:tag_count = v:foldend - v:foldstart + 1
  if l:tag_count <= 9 
    return v:folddashes."+ File: ".l:line." Tags:    ". l:tag_count." "
  elseif l:tag_count <= 99 
    return v:folddashes."+ File: ".l:line." Tags:   ". l:tag_count." "
  elseif l:tag_count <= 999 
    return v:folddashes."+ File: ".l:line." Tags:  ". l:tag_count." "
  else
    return v:folddashes."+ File: ".l:line." Tags: ". l:tag_count." "
  endif
endfunction  

" Set ctags options to call.
function! s:SetGrepPrg(sort)
  if  g:CtagsMinorVersion < 5 
    if ( &filetype == "asm"     || &filetype == "asp"     || &filetype == "awk"   ||
      \ &filetype == "beta"    || &filetype == "c"       || &filetype == "cobol" ||
      \ &filetype == "eiffel"  || &filetype == "fortran" || &filetype == "java"  ||
      \ &filetype == "lisp"    || &filetype == "lua"     || &filetype == "make"  ||
      \ &filetype == "pascal"  || &filetype == "perl"    || &filetype == "php"   ||
      \ &filetype == "python"  || &filetype == "rexx"    || &filetype == "ruby"  ||
      \ &filetype == "scheme"  || &filetype == "sh"      || &filetype == "slang" ||
      \ &filetype == "sql"     || &filetype == "tcl"     || &filetype == "vera"  ||
      \ &filetype == "verilog" || &filetype == "vim"     || &filetype == "yacc"  )
      let l:grep_return = g:showfuncctagsbin .' -x --language-force=' . &filetype . 
        \ ' --sort=' . a:sort
    elseif &filetype == "cpp" 
      let l:grep_return = g:showfuncctagsbin .' -x --language-force=c++ --sort=' . 
        \ a:sort
    else
       return "fail" 
    endif
  else
    if &filetype == "cpp" | let l:cfiletype = "c++"
    else | let l:cfiletype = &filetype | endif
    let l:filetest = s:TestFileType(l:cfiletype)
    if l:filetest != "false"
      if exists("g:ShowFunc_{&filetype}_Kinds")
        let l:grep_return = g:showfuncctagsbin . ' -x --language-force=' . 
          \ l:cfiletype . ' --' . l:cfiletype . '-kinds=' .
          \ g:ShowFunc_{&filetype}_Kinds . ' --sort=' . a:sort 
      else
        let l:grep_return = g:showfuncctagsbin . ' -x --language-force=' . 
          \ l:cfiletype . ' --sort=' . a:sort
      endif
    else | let l:grep_return = "fail" | endif
  endif
  return l:grep_return
endfunction 

function! <SID>ShowFuncOpen()
	set lazyredraw
  " Close any existing cwindows.
	cclose
  if &lines >= 8
		let l:count = 0
    let l:gf_s = &grepformat
    let l:gp_s = &grepprg
    set grepformat&vim
    set grepprg&vim
    let &grepformat = '%*\k%*\s%t%*\k%*\s%l%*\s%f\ %m' 
		if ( g:ShowFuncScanType == "buffers" )
      " Scan all open buffers.
	    let l:currbuf = bufnr("%")
	    bufdo! let &grepprg = s:SetGrepPrg(g:ShowFuncSortType) | 
      \ if &grepprg != "fail" | if &readonly == 0 | update | endif |
			\ if l:count == 0 | silent! grep! % | let l:count =  l:count + 1 |
			\ else | silent! grepadd! % | endif | endif
		  execute 'buffer '.l:currbuf
		elseif g:ShowFuncScanType == "windows"
		  " Scan all open windows.
	    windo let &grepprg = s:SetGrepPrg(g:ShowFuncSortType) | 
      \ if &grepprg != "fail" | if &readonly == 0 | update | endif |
			\ if l:count == 0 | silent! grep! %| let l:count =  l:count + 1 |
			\ else | silent! grepadd! % | endif | endif
		elseif g:ShowFuncScanType == "current"
		  " Scan current buffer only.
      let &grepprg = s:SetGrepPrg(g:ShowFuncSortType)
		  if &grepprg != "fail"
        if &readonly == 0 | update | endif
        silent! grep! %
		  else
        echohl WarningMsg
        echo "ShowFunc Error: Unknown FileType"
        echohl none
      endif
		endif
	  let &grepformat = l:gf_s
    let &grepprg = l:gp_s
		execute s:OpenCWin()
		if ( g:ShowFuncScanType == "buffers" || g:ShowFuncScanType ==  "windows" )
      " Do folding.
      let g:FoldFileName = ''
      setlocal foldexpr=s:ShowFuncFolds()
      setlocal foldmethod=expr
      setlocal foldtext=ShowFuncFoldText()
    endif
	else
    echohl WarningMsg
    echo "ShowFunc Error: Window too small.\n"
    echohl none
  endif
	set nolazyredraw
	redraw!
endfunction   

" Test for supported filetype.
function! s:TestFileType(type) 
  let l:supportedfiles = g:CtagsSupportedFileTypes
  while l:supportedfiles != "^@" && l:supportedfiles != "" 
    let l:sfcut = strpart(l:supportedfiles,0,stridx(l:supportedfiles,"^@"))
    if l:sfcut ==? a:type 
      return "true"
    endif
    let l:supportedfiles = strpart(l:supportedfiles,
      \ stridx(l:supportedfiles,'^@')+2)
  endwhile
  return "false"
endfunction
"                                                                            }}}
" ------------------------------------------------------------------------------
" Test Environment:                                                          {{{
" Test Ctags Binary to be sure its the correct version.
if exists("g:showfuncctagsbin")
  let g:showfuncctagsbin = s:CtagsTest(g:showfuncctagsbin)
endif
if (!exists("g:showfuncctagsbin") || g:showfuncctagsbin == "fail")
  let g:showfuncctagsbin = s:CtagsTest("unk")
endif

" If a suitable ctags binary cannot be found, remove autocommands,  clear 
" functions and exit script.
if g:showfuncctagsbin == "fail" 
  echo "ShowFunc exting.  (Cleaning up functions)"
  let g:loaded_showfunc = 0
  augroup! showfunc_autocmd
  delfunction <SID>ChangeScanType
  delfunction <SID>ChangeSortType
  delfunction s:CtagsTest
  delfunction s:CtagsVersionTest
  delfunction <SID>DisplayHelp
  delfunction <SID>LastWindow
  delfunction s:OpenCWin
  delfunction s:ShowFuncFolds
  delfunction s:ShowFuncFoldText
  delfunction s:SetGrepPrg
  delfunction <SID>ShowFuncOpen
  delfunction s:TestFileType
  finish
endif 

"                                                                            }}}
" ------------------------------------------------------------------------------
" Key Mappings:                                                              {{{
" To change the main key mapping, add this to your .vimrc file:
"   map <key> <PLug>ShowFunc

if ( !hasmapto('<PLUG>ShowFunc') && (maparg('<F1>') == '') )
	map  <F1> <Plug>ShowFunc
  map! <F1> <Plug>ShowFunc
elseif !hasmapto('<PLUG>ShowFunc')
  if ( !has("gui_running") || has("win32") )
    echo "ShowFunc Error: No Key mapped.\n".
      \  "<F1> is taken and a replacement was not assigned."
  endif
  let g:loaded_showfunc = 0
  finish
endif
noremap  <silent> <Plug>ShowFunc   :call <SID>ShowFuncOpen()<CR>
noremap! <silent> <Plug>ShowFunc   <ESC>:call <SID>ShowFuncOpen()<CR>

" Note: Cwindow specific key mappings can be found in the OpenCWin function. }}}
" ------------------------------------------------------------------------------
" Known Issues:                                                              {{{
" 1.  Error messages that occur as gvim is loading (on Linux) do not display in 
"     GUI windows.  When called from a menu or icon, it appears that gvim is hung
"     (it appears in the ps listings but no window appears).  To avoid this I 
"     have disabled the display of errors during gvim loading and the ShowFunc 
"     script simply exits.  
"                                                                            }}}
" ------------------------------------------------------------------------------
" Feature Wishlist:                                                          {{{
" 1.  If scan is set to "current", make cwindow update on buffer change (except
"     to the cwindow)
" 2.  Window size ratios should remain the same as ShowFunc opens and closes.
" 3.  Patch vim to allow for setlocal statusline.
" 4.  Expand error format format so that the tag type is grabbed by grep.
"                                                                            }}}
" ------------------------------------------------------------------------------
" Notes:                                                                     {{{
" 1. Best veiwed with AutoFold.vim (vimscript#925) and ShowFunc.vim
"    (vimscript#397).
"                                                                            }}}
" ------------------------------------------------------------------------------
" Version History:                                                           {{{
" 1.0      08-24-2002  Initial Release.
" 1.1      08-26-2002  Patches to Fortran (thanks to Ajit Thakkar), Pascal,
"                      and Python support.
" 1.1.1    08-26-2002  Fixed copy&paste errors.  ooops.
" 1.1.2    08-27-2002  Removed the Python patch.
" 1.1.3    08-31-2002  Fixed Fortran and Pascal patches, Thanks to Ajit Thakkar,
"                      and Engelbert Gruber.
" 1.2      09-22-2002  Fixed redraw bug so that it works with the Winmanager
"                      (vimscript#95) and Bufexplorer (vimscript#42) scripts.
" 1.2.1    10-17-2002  Added unknown filetype handling. Added status messages
"                      ('ShowFunc:').  Fixed key-mappings.
" 1.3Beta  11-16-2002  Beta: Multiple file handling.  Restructured script.
" 1.3Beta2 11-20-2002  Beta: Fixed Multiple file cwindow refresh issue (grep
"                      vs. grepadd).
" 1.3Beta3 11-29-2002  Beta: Split SetFileType into two ( SetGrepFormat, and
"                      SetGrepPrg ). Set &...&vim to  insure proper '\ multiline
"                      translation. Added keymapping testing to  protect against
"                      conflicting with existing user configurations and to make
"                      it easy to remap when necessary. Thanks to Luc Hermitte
" 1.3      12-01-2002  Fixed buffer display issue (Thanks to vimtip#133). Fixed
"                      window height test for TestWinH and OpenCWin.  Changed
"                      MultiWin (scans all open windows) to MultiBuf (scans all
"                      open buffers). Basic multiple file handling is complete.
" 1.4      12-21-2002  Changed user interface. Eliminated multiple key-mappings.
"                      Pressing F1 runs the default scan, and opens the cwindow.
"                      Scan sort and type can be changed by pressing the s and t
"                      keys respectively.  Unifed scan types into one function
"                      (ShowFuncOpen) and bought back the all open windows scan.
" 1.4.1    01-19-2003  Fixed multi-window scan display issue. Improved dynamic
"                      cwindow sizing.  Added basic help dialog.
" 1.4.2    03-13-2003  Rewrote the SetGrepFormat and SetGrepPrg functions. Added
"                      support for all tags for all languages that Exburent
"                      Ctags (ver. 5.4) supports.
" 1.4.3    03-15-2003  Automatically fold output on filename for multiple file
"                      scans (all buffers or windows).
" 1.4.4    03-17-2003  Improved error handling.  Improved SetFoldText().
" 1.4.5    03-22-2003  More error handling improvements, including tests for the 
"                      correct version of ctags, and keymap assignment.  I want
"                      to thank Mark Thomas for his assistance in finding and 
"                      fixing a bug in the ctags executable detection on Windows.  
" 1.5     09-21-2003   Created a more generic grep format so that explicit type 
"                      definitions are no longer necessary (eliminating the 
"                      SetGrepFormat function).  Modified the SetGrepPrg function 
"                      to detect Ctags versions earlier than 5.5.  Supportted 
"                      filetypes for Ctags versions 5.4 are statically 
"                      assigned.  
"                      With Ctags versions 5.5 (and later) supported filetypes 
"                      are detected dynamically (including those defined by 
"                      regular expressions (--regex-<LANG>).  
" 1.5.1   09-25-2003   Bug Fixes.
" 1.5.2   10-06-2003   Improved Exuberant Ctags version checking.  
" 1.5.3   10-15-2004   Fixed ShowFuncFoldText.
" 1.5.4   01-13-2005   Script cleanup.  Added MyLastWindow function (when
"                      closing windows, tests last window to see if its a
"                      Cwindow, if it is then close vim session). 
" 1.5.5   07-20-2005   Patches from two Windows users (David Rennalls and Bill 
"                      McCarthy).  Fixes in cleanup, documentaion, and autocmds.
" 1.5.6   02-28-2006   First Vim 7 patches.  Added setlocal statusline support 
"                      to update the cwindow name.
" 1.5.7   03-27-2006   Per request by Diederik Van der Boor, added ability to
"                      filter the variables kinds that ctags outputs (ver 5.5
"                      or newer).
"
"                                                                            }}}
" ------------------------------------------------------------------------------
" vim:tw=80:ts=2:sw=2:
