
"{{{ PHPQA stuff
" Turn autorun off, and turn it back on in individual
" project settings
let g:phpqa_codecoverage_autorun = 0
let g:phpqa_messdetector_autorun = 0
let g:phpqa_codesniffer_autorun = 0
"}}}

"{{{ PHPDoc
let g:pdv_cfg_Author = "Jon Cairns <jon@22blue.co.uk>"
let g:pdv_cfg_Copyright = "Copyright (c) Green Gorilla ".strftime("%Y")
let g:pdv_cfg_License = ""
let g:pdv_cfg_Version = ""
let g:pdv_cfg_php4always = 0
"}}}

" PHPUnit stuff
let g:phpunit_cmd = "caketest"
let g:phpunit_args = "--no-colors --stderr"
"
"PHP
let php_sql_query=1
let php_htmlInStrings=1

