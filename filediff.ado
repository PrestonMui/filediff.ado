* filediff: compare files
* Panel data in mind

program define filediff

version 13.1
syntax varlist using/, idvars(varlist)
	
	local eps = 0.00001

	* Check that 
	isid `idvars'
	* confirm using
	isid `idvars' using "`using'"

	keep `idvars' `varlist'

	foreach var of varlist `varlist' {
		ren `var' `var'_master
	}

	merge 1:1 `idvars' using "`using'", keepusing(`varlist')

	foreach var of varlist `varlist' {
		ren `var' `var'_using
	}

	order make _merge
	foreach var of local varlist {
		order `var'_master `var'_using, last
	}

	tokenize `varlist'

	* Table for `1'
		noisily di in smcl _n in gr /*
		*/ _col(41) "{hline 1} difference (using - master) {hline 1}" _n /* 
		*/ _col(29) "count" _col(41) "minimum" /* 
		*/ _col(54) "average" /*
		*/ _col(66) "maximum" _n /*
		*/ "{hline 72}"

	* JOINT OBSERVATIONS
	count if !missing(`1'_master) & !missing(`1'_using) & _merge==3
	local joint = r(N)

	if `joint' > 0 {
		tempvar diff
		gen float `diff' = `1'_using - `1'_master if !missing(`1'_master) & !missing(`1'_using)
		
		* USING < MASTER (allowing for eps difference)
		count if `diff' < (-1) * `eps' & !missing(`diff')
		if r(N) {
			local c = r(N)
			sum `diff' if `diff' < (-1) * `eps' & !missing(`diff'), meanonly
			noisily di in gr "using < master" _col(25) /*
				*/ in ye %9.0f `c' _col(39) /*
				*/ %9.0g r(min) _col(52) /*
				*/ %9.0g r(mean) _col(64) /*
				*/ %9.0g r(max)
		}
		else {
			nois di in gr "using < master" _col(25) /*
				*/ in ye %9.0f `c'
		}

		* USING~=MASTER
		count if `diff' < (-1) * `eps' & !missing(`diff')
		if r(N) {
			local c = r(N)
			sum `diff' if `diff' < (-1) * `eps' & !missing(`diff'), meanonly
			noisily di in gr "using < master" _col(25) /*
				*/ in ye %9.0f `c' _col(39) /*
				*/ %9.0g r(min) _col(52) /*
				*/ %9.0g r(mean) _col(64) /*
				*/ %9.0g r(max)
		}
		else {
			nois di in gr "using < master" _col(25) /*
				*/ in ye %9.0f `c'
		}
	}

	* foreach var of varlist {
	* 	gen vardiff
	* 	order varold varnew vardiff, last
	* }

	* REPORT
	* Merge statistics
	* Variable Compare statistics

end
