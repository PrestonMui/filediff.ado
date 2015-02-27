* test_filediff

clear all
set more off

cap program drop filediff
use "auto1", clear
	filediff price mpg model using "auto2", idvars(make)
	
