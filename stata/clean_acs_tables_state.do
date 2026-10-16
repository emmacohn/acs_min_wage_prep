import delim ${acsdata}ACS_19_5YR_B23001_sex_age_state.csv, varnames(1) rowrange(3) clear
gen statefips = substr(geo_id, 10, 11)
destring statefips, replace 
destring b23001*, replace
rename b23001_007e male1619
rename b23001_014e male2021
rename b23001_021e male2224
rename b23001_028e male2529
rename b23001_035e male3034
rename b23001_042e male3544
rename b23001_049e male4554
rename b23001_056e male5559
rename b23001_063e male6061
rename b23001_070e male6264
rename b23001_075e male6569
rename b23001_080e male7074
rename b23001_085e male7599
rename b23001_093e female1619
rename b23001_100e female2021
rename b23001_107e female2224
rename b23001_114e female2529
rename b23001_121e female3034
rename b23001_128e female3544
rename b23001_135e female4554
rename b23001_142e female5559
rename b23001_149e female6061
rename b23001_156e female6264
rename b23001_161e female6569
rename b23001_166e female7074
rename b23001_171e female7599

gen emp1619 = male1619 + female1619
gen emp2024 = male2021 + male2224 + female2021 + female2224
gen emp2534 = male2529 + male3034 + female2529 + female3034
gen emp3544 = male3544 + female3544
gen emp4554 = male4554 + female4554
gen emp5564 = male5559 + male6061 + male6264 + female5559 + female6061 + female6264
gen emp6599 = male6569 + male7074 + male7599 + female6569 + female7074 + female7599
egen empmale = rowtotal(male*)
egen empfemale = rowtotal(female*)
gen emp = empmale + empfemale
gen empmale1664 = male1619 + male2021 + male2224 + male2529 + male3034 + male3544 + male4554 + male5559 + male6061 + male6264
gen empfemale1664 = female1619 + female2021 + female2224 + female2529 + female3034 + female3544 + female4554 + female5559 + female6061 + female6264
gen empmale6599 = empmale - empmale1664
gen empfemale6599 = empfemale - empfemale1664

keep statefips emp*
tempfile age
save `age'

foreach race in hispanic white black {
	import delim ${acsdata}ACS_19_5YR_C23002_`race'_state.csv, varnames(1) rowrange(3) clear
	gen statefips = substr(geo_id, 10, 11)
	destring statefips, replace
	destring c23002*, replace
	rename *_0* _.*
	rename _07e emp`race'male1664
	rename _12e emp`race'male6599
	rename _20e emp`race'female1664
	rename _25e emp`race'female6599
	gen emp`race'1664 = emp`race'male1664 + emp`race'female1664
	gen emp`race'6599 = emp`race'male6599 + emp`race'female6599

	keep statefips emp*
	tempfile `race'
	save ``race''
}

import delim ${acsdata}ACS_19_5YR_B23006_educ_state.csv, varnames(1) rowrange(3) clear
gen statefips = substr(geo_id, 10, 11)
destring statefips, replace
destring b23006*, replace
rename b23006_006e emplths
rename b23006_013e emphs
rename b23006_020e empscol
rename b23006_027e empcol

keep statefips emp*
tempfile educ
save `educ'

use `age', clear
foreach race in hispanic white black {
	merge 1:1 statefips using ``race'', assert(3) nogenerate
}
merge 1:1 statefips using `educ', assert(3) nogenerate

gen empothermale1664 = empmale1664 - (empwhitemale1664 + empblackmale1664)
gen empotherfemale1664 = empfemale1664 - (empwhitefemale1664 + empblackfemale1664)
gen empothermale6599 = empmale6599 - (empwhitemale6599 + empblackmale6599)
gen empotherfemale6599 = empfemale6599 - (empwhitefemale6599 + empblackfemale6599)
gen empother1664 = empothermale1664 + empotherfemale1664
gen empother6599 = empothermale6599 + empotherfemale6599

gen empnonhispanicmale1664 = empmale1664 - emphispanicmale1664
gen empnonhispanicfemale1664 = empfemale1664 - emphispanicfemale1664
gen empnonhispanicmale6599 = empmale6599 - emphispanicmale6599
gen empnonhispanicfemale6599 = empfemale6599 - emphispanicfemale6599
gen empnonhispanic1664 = empnonhispanicmale1664 + empnonhispanicfemale1664
gen empnonhispanic6599 = empnonhispanicmale6599 + empnonhispanicfemale6599

gen empedother = empmale + empfemale - (emplths + emphs + empscol + empcol)

* remove PR
drop if statefips == 72
