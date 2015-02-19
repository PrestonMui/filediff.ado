* filediff: compare files
* Panel data in mind

program define filediff

version 13.1
syntax varlist using/, idvars(varlist)
	
quietly {

	local eps = 0.00001

	* Check that 
	isid `idvars'
	* confirm using
	isid `idvars' using "`using'"

	keep `idvars' `varlist'

	foreach var of varlist `varlist' {
		ren `var' `var'_master
	}

	tempvar tempmerge
	merge 1:1 `idvars' using "`using'", keepusing(`varlist') generate(`tempmerge')

	foreach var of varlist `varlist' {
		ren `var' `var'_using
	}

	order make `tempmerge'
	foreach var of local varlist {
		order `var'_master `var'_using, last
	}

	tokenize `varlist'

	* Table for `1'
		noisily di in smcl _n in gr /*
		*/ _col(41) "{hline 1} difference (using - master) {hline 1}" _n /* 
		*/ _col(1)  "`1'" /*
		*/ _col(29) "count" _col(41) "minimum" /* 
		*/ _col(55) "mean" /*
		*/ _col(66) "maximum" _n /*
		*/ "{hline 72}"

	* JOINT OBSERVATIONS
	count if !missing(`1'_master) & !missing(`1'_using) & `tempmerge'==3
	local joint = r(N)

	if `joint' {

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
		
		* USING > MASTER
		count if `diff' > `eps' & !missing(`diff')
		if r(N) {
			local c = r(N)
			sum `diff' if `diff' > `eps' & !missing(`diff'), meanonly
			noisily di in gr "using > master" _col(25) /*
				*/ in ye %9.0f `c' _col(39) /*
				*/ %9.0g r(min) _col(52) /*
				*/ %9.0g r(mean) _col(64) /*
				*/ %9.0g r(max)
		}

		* USING~=MASTER
		count if abs(`diff')<=`eps' & `diff'!=0 & !missing(`diff')
		if r(N) {
			local c = r(N)
			sum `diff' if abs(`diff')<=`eps' & `diff'!=0 & !missing(`diff'), meanonly
			noisily di in gr "using ≈ master" _col(25) /*
				*/ in ye %9.0f `c' _col(39) /*
				*/ %9.0g r(min) _col(52) /*
				*/ %9.0g r(mean) _col(64) /*
				*/ %9.0g r(max)
		}

		* Using == MASTER
		count if abs(`diff')==0 & !missing(`diff')
		if r(N) {
			local c = r(N)
			sum `diff' if `diff'==0 & !missing(`diff'), meanonly
			noisily di in gr "using == master" _col(25) /*
				*/ in ye %9.0f `c' _col(39) /*
				*/ %9.0g r(min) _col(52) /*
				*/ %9.0g r(mean) _col(64) /*
				*/ %9.0g r(max)
		}

		noisily di in smcl in gr _col(24) "{hline 10}"

		* ALL JOINTLY DEFINED
		sum `diff' if !missing(`diff') & `tempmerge'==3, meanonly
		noisily di in gr "jointly defined" _col(25) /*
			*/ in ye %9.0f `joint' _col(39) /*
			*/ %9.0g r(min) _col(52) /*
			*/ %9.0g r(mean) _col(64) /*
			*/ %9.0g r(max)

		noisily di "{hline 72}"

		* JOINT OBSERVATIONS WITH MISSINGS
		count if (missing(`1'_master) | !missing(`1'_using)) & `tempmerge'==3
		local jointmissings = r(N)

		* * Missings
		* count if abs(`diff')==0 & !missing(`diff')
		* if r(N) {
		* 	local c = r(N)
		* 	sum `diff' if `diff'==0 & !missing(`diff'), meanonly
		* 	noisily di in gr "using == master" _col(25) /*
		* 		*/ in ye %9.0f `c' _col(39) /*
		* 		*/ %9.0g r(min) _col(52) /*
		* 		*/ %9.0g r(mean) _col(64) /*
		* 		*/ %9.0g r(max)
		* }

		* noisily di in smcl in gr _col(24) "{hline 10}"
	
	}

	* foreach var of varlist {
	* 	gen vardiff
	* 	order varold varnew vardiff, last
	* }

	* REPORT
	* Merge statistics
	* Variable Compare statistics

}

end
