* 0th stage adjustment:
* no need to scale to single year, as we're using 5-year ACS
gen perwt0 = perwt
drop perwt

* 1st stage adjustment:
* proportion according to population allocation factor (none for states; identical to perwt0)
gen perwt1 = perwt0

* 2nd stage adjustment
* rake to match ACS tables

* prep for ipfraking
* variable to total for ipfraking
gen byte _one = 1

tempfile acsmicrodata
save `acsmicrodata'

use ${output}acs_tables_state.dta, clear
levelsof statefips, local(statefipslevels)

foreach i of numlist `statefipslevels' {
	use if statefips == `i' using ${output}acs_tables_state.dta, clear

	* AGE
	mkmat emp1619 emp2024 emp2534 emp3544 emp4554 emp5564 emp6599, matrix(age)
	matrix rownames age = agegroup
	matrix colnames age = _one:1 _one:2 _one:3 _one:4 _one:5 _one:6 _one:7
	mat li age

	* RACE-AGE
	mkmat empwhite1664 empwhite6599 empblack1664 empblack6599 empother1664 empother6599, matrix(raceage)
	matrix rownames raceage = raceagegroup
	matrix colnames raceage = _one:11 _one:12 _one:21 _one:22 _one:31 _one:32
	mat li raceage

	* HISPANIC ETHNICITY-AGE
	mkmat emphispanic1664 emphispanic6599 empnonhispanic1664 empnonhispanic6599, matrix(hispage)
	matrix rownames hispage = hispagegroup
	matrix colnames hispage = _one:11 _one:12 _one:21 _one:22
	mat li hispage

	* EDUC
	mkmat emplths emphs empscol empcol empedother, matrix(educ)
	matrix rownames educ = educgroup
	matrix colnames educ = _one:1 _one:2 _one:3 _one:4 _one:5
	mat li educ

	* rake the data
	di _n(3) "Raking state `i'" _n(3)
	use if statefips == `i' using `acsmicrodata', clear
	ipfraking [pw=perwt1], ctotal(age raceage hispage educ) generate(perwt2)
	tempfile state`i'
	save `state`i''
}

local counter = 0
foreach i of numlist `statefipslevels' {
	local counter = `counter' + 1
	if `counter' == 1 use `state`i'', clear
	else append using `state`i''
}

drop _one
