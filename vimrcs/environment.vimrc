" Import the $PATH variable from the user's bashrc

let s:scriptpath=$HOME."/.bashrc"

if filereadable(s:scriptpath)
	let s:pathop=system("source ".s:scriptpath." && echo $PATH")
	exec 'let $PATH="'.s:pathop.'"'
endif
