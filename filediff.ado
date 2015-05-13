* filediff: compare files
* Panel data in mind

program define filediff

version 13.1
syntax varlist using/, idvars(varlist) [EPSilon(real 0.00001)]

quietly {

	tempfile originalmaster
	save `originalmaster'

	local eps = `epsilon'

	* Check that idvars are ids
	isid `idvars'
	isid `idvars' using "`using'"

	keep `idvars' `varlist'
	cap confirm variable _merge
	if _rc==0 {
		noisily di "Sorry, you cannot have a variable named _merge. Rename and try again. Thanks."
		use `originalmaster', clear
		exit
	}

	foreach var of varlist `varlist' {
		cap confirm variable `var'
		if _rc {
			noisily di "Variable `var' does not exist in the master dataset."
			use `originalmaster', clear
			exit
		}
		cap confirm variable `var'_master
		if _rc==0 {
			noisily di "Sorry, you cannot diff `var' and have a variable called `var'_master"
			use `originalmaster', clear
			exit
		}
		ren `var' `var'_master
	}

	merge 1:1 `idvars' using "`using'", keepusing(`varlist')

	foreach var of varlist `varlist' {
		cap confirm variable `var'
		if _rc {
			noisily di "Variable `var' does not exist in the using dataset."
			use `originalmaster', clear
			exit
		}
		cap confirm variable `var'_using
		if _rc==0 {
			noisily di "Sorry, you cannot diff `var' and have a variable called `var'_using"
			use `originalmaster', clear
			exit
		}
		ren `var' `var'_using
		
		* Confirm numerics match to numerics, strings to strings
		local type1 : type `var'_master
		local type2 : type `var'_using
		if substr(`"`type1'"',1,3)=="str" & substr(`"`type2'"',1,3)!="str" {
			noisily di "Error: `var' is string in master but numeric in using"
			use `originalmaster', clear
			exit
		}
		if substr(`"`type1'"',1,3)!="str" & substr(`"`type2'"',1,3)=="str" {
			noisily di "Error: `var' is string in using but numeric in master"
			use `originalmaster', clear
			exit
		}
	}

	order `idvars' _merge
	foreach var of local varlist {
		order `var'_master `var'_using, last
	}

	foreach var of local varlist {

		local type1 : type `var'_master

		if substr(`"`type1'"',1,3)=="str" {
			noisily di _newline(1)
			noisily di as result "Comparison for string variable `var'"
			
			* Table for `var'
			noisily di in smcl _n in gr /*
			*/ _col(1)  "`var'" /*
			*/ _col(29) "count" /*
			*/ _col(41) "master==using" /* 
			*/ _col(60) "master!=using" _n /*
			*/ "{hline 72}"

			* JOINT OBSERVATIONS
			count if !missing(`var'_master) & !missing(`var'_using) & _merge==3
			local joint = r(N)

			if `joint' {
				count if `var'_master==`var'_using & _merge==3 & !missing(`var'_master) & !missing(`var'_using)
				local cmatch = r(N)
				count if `var'_master!=`var'_using & _merge==3 & !missing(`var'_master) & !missing(`var'_using)
				local cnomatch = r(N)

				noisily di in gr _col(1) "jointly defined" /*
					*/ in ye _col(25) %9.0f `joint' /*
					*/ _col(45) %9.0f `cmatch'  /*
					*/ _col(64) %9.0f `cnomatch'
			}

			* JOINT OBSERVATIONS WITH MISSINGS
			count if (missing(`var'_master) | missing(`var'_using)) & _merge==3
			local jointmissings = r(N)
			if `jointmissings' {
				
				* Missing in Master
				count if missing(`var'_master) & !missing(`var'_using) & _merge==3
				if r(N) {
					local c = r(N)
					noisily di in gr "missing in master only" _col(25) in ye %9.0f `c' _col(39)				
				}

				* Missing in Using
				count if !missing(`var'_master) & missing(`var'_using) & _merge==3
				if r(N) {
					local c = r(N)
					noisily di in gr "missing in using only" _col(25) in ye %9.0f `c' _col(39)				
				}

				* Missing in Both
				count if missing(`var'_master) & missing(`var'_using) & _merge==3
				if r(N) {
					local c = r(N)
					noisily di in gr "missing in both" _col(25) in ye %9.0f `c' _col(39)				
				}
			}
		}

		if substr(`"`type1'"',1,3)!="str" {

			noisily di _newline(1)
			noisily di as result "Comparison for numeric variable `var'"
			* Table for `var'
				noisily di in smcl _n in gr /*
				*/ _col(41) "{hline 1} difference (using - master) {hline 1}" _n /* 
				*/ _col(1)  "`var'" /*
				*/ _col(29) "count" _col(41) "minimum" /* 
				*/ _col(55) "mean" /*
				*/ _col(66) "maximum" _n /*
				*/ "{hline 72}"

			* JOINT OBSERVATIONS
			count if !missing(`var'_master) & !missing(`var'_using) & _merge==3
			local joint = r(N)

			if `joint' {

				tempvar diff
				gen float `diff' = `var'_using - `var'_master if !missing(`var'_master) & !missing(`var'_using)
				
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

				noisily di in smcl in gr _col(24) "{hline 50}"

				* ALL JOINTLY DEFINED
				sum `diff' if !missing(`diff') & _merge==3, meanonly
				noisily di in gr "jointly defined" _col(25) /*
					*/ in ye %9.0f `joint' _col(39) /*
					*/ %9.0g r(min) _col(52) /*
					*/ %9.0g r(mean) _col(64) /*
					*/ %9.0g r(max)

				* JOINT OBSERVATIONS WITH MISSINGS
				count if (missing(`var'_master) | missing(`var'_using)) & _merge==3
				local jointmissings = r(N)
				if `jointmissings' {
					
					* Missing in Master
					count if missing(`var'_master) & !missing(`var'_using) & _merge==3
					if r(N) {
						local c = r(N)
						noisily di in gr "missing in master only" _col(25) in ye %9.0f `c' _col(39)				
					}

					* Missing in Using
					count if !missing(`var'_master) & missing(`var'_using) & _merge==3
					if r(N) {
						local c = r(N)
						noisily di in gr "missing in using only" _col(25) in ye %9.0f `c' _col(39)				
					}

					* Missing in Both
					count if missing(`var'_master) & missing(`var'_using) & _merge==3
					if r(N) {
						local c = r(N)
						noisily di in gr "missing in both" _col(25) in ye %9.0f `c' _col(39)				
					}				
				}
			}
		}
	}
	* REPORT
	* Merge statistics
	noisily di _newline(1)
	noisily di as result "Merge statistics"
	noisily tab _merge
	nois dis _n
	nois di "Note: In variable comparisons, only observations where both master and using match on `idvars' are matched"

}

end
