* filediff: compare files
* Panel data in mind

version 13.1

capture program drop filediff
program define filediff

	syntax varlist, trythis(varlist)

	disp `trythis'

end