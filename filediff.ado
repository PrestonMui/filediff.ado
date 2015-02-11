* filediff: compare files
* Panel data in mind

program define filediff

version 13.1
syntax varlist using, idvars(varlist) [TOLerance()]

	isid `idvars'

	keep `idvars' `diff'

	disp "`using'"

	* Make a list of tempvars to use for the old variables
	* Rename variables to old variables

	merge 1:1 `idvars' using USINGFILE, keepusing(....)

	order `idvars'
	foreach var of varlist {
		gen vardiff
		order varold varnew vardiff, last
	}

	* REPORT
	* Merge statistics
	* Variable Compare statistics

end
