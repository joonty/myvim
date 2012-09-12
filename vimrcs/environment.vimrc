" Import the $PATH variable from the user's bashrc

let s:scriptpath=$HOME."/.profile"

if filereadable(s:scriptpath)
	let s:envraw=system("source ".s:scriptpath." && echo $PATH && echo $GEM_HOME")
    let s:env = split(s:envraw,"\n")
	let $PATH=s:env[0]
	let $GEM_HOME=s:env[1]
endif
