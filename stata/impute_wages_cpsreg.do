* create new variables in ACS to match CPS

local cps_year ${cps_year}

* EDUCATION
gen new_educ = .
* Less than 1st grade
replace new_educ = 1 if educd == 2 | educd == 11 | educd == 12
* 1st-4th grade
replace new_educ = 2 if 14 <= educd & educd <= 17
* 5th-6th grade
replace new_educ = 3 if 22 <= educd & educd <= 23
* 7th-8th grade
replace new_educ = 4 if 25 <= educd & educd <= 26
* 9th grade
replace new_educ = 5 if educd == 30
* 10th grade
replace new_educ = 6 if educd == 40
* 11th grade
replace new_educ = 7 if educd == 50
* 12th grade, no diploma
replace new_educ = 8 if educd == 61
* HS grad, GED
replace new_educ = 9 if 63 <= educd & educd <= 64
* Some college, no degree
replace new_educ = 10 if educd == 65 | educd == 71
* Associate's degree (not specified)
replace new_educ = 11 if educd == 81
* Bachelor’s degree
replace new_educ = 13 if educd == 101
* Master's degree
replace new_educ = 14 if educd == 114
* Professional degree
replace new_educ = 15 if educd == 115
* Doctoral degree
replace new_educ = 16 if educd == 116
assert new_educ ~= .

* race & ethnicity
* combine hispanic ethnicity and race to get a better match to CPS
* without doing this, the ACS will show lower white share of population
* and a sizable share of "Other major" race, for which there is no comparable category in the CPS race definitions
cap drop hispanic
gen hispanic = hispan >= 1 & hispan <= 4
gen new_race = .
* White
replace new_race = 1 if race == 1
* Black
replace new_race = 2 if race == 2
* Other
replace new_race = 4 if race >= 3 & race ~= .
replace new_race = 3 if hispanic == 1
assert new_race ~= .

* age
forvalues i = 2 / 5 {
	gen age`i' = age^`i'
}

* female
gen female = sex == 2

* Major industry
gen majorind = .
* Agriculture, forestry, fishing, and hunting
replace majorind = 1 if 170 <= ind & ind <= 290
* Mining
replace majorind = 2 if 370 <= ind & ind <= 490
* Construction
replace majorind = 3 if ind == 770
* Manufacturing
replace majorind = 4 if 1070 <= ind & ind <= 3990
* Wholesale & retail trade
replace majorind = 5 if 4070 <= ind & ind <= 5791
* Transportation & utilities
replace majorind = 6 if (6070 <= ind & ind <= 6390) | (570 <= ind & ind <= 690)
* Information
replace majorind = 7 if 6470 <= ind & ind <= 6781
* Financial activities
replace majorind = 8 if 6870 <= ind & ind <= 7190
* Professional and business services
replace majorind = 9 if 7270 <= ind & ind <= 7790
* Educational and health services
replace majorind = 10 if 7860 <= ind & ind <= 8470
* Leisure and hospitality
replace majorind = 11 if 8560 <= ind & ind <= 8690
* Other services
replace majorind = 12 if 8770 <= ind & ind <= 9290
* Public administration
replace majorind = 13 if 9370 <= ind & ind <= 9590
assert majorind ~= .

* Major occupation
gen majorocc = .
* Management, business, and financial occupations
replace majorocc = 1 if 10 <= occ & occ <= 960
* Professional and related occupations
replace majorocc = 2 if 1005 <= occ & occ <= 3550
* Service occupations
replace majorocc = 3 if 3600 <= occ & occ <= 4655
* Sales and related occupations
replace majorocc = 4 if 4700 <= occ & occ <= 4965
* Office and administrative support occupations
replace majorocc = 5 if 5000 <= occ & occ <= 5940
* Farming, fishing, and forestry occupations
replace majorocc = 6 if 6005 <= occ & occ <= 6130
* Construction and extraction occupations
replace majorocc = 7 if 6200 <= occ & occ <= 6950
* Installation, maintenance, and repair occupations
replace majorocc = 8 if 7000 <= occ & occ <= 7640
* Production occupations
replace majorocc = 9 if 7700 <= occ & occ <= 8990
*	Transportation and material moving occupations
replace majorocc = 10 if 9000 <= occ & occ <= 9760
assert majorocc ~= .

* part/full-time
gen parttime = uhrswork <= 34

gen new_married = marst >= 1 & marst <= 2

tempfile acs
save `acs'

* CPS
* five years of CPS ORG ending in cps_year
local cps_start_year = `cps_year' - 4
load_epiextracts, begin(`cps_start_year'm1) end(`cps_year'm12) sample(org) keep(wageotc age female hispanic raceorig married gradeatn mind03 mocc03 hoursu1i statefips orgwgt paidhre a_earnhour a_weekpay) sourcedir(/data/cps/org/epi)

keep if wageotc > 0 & wageotc ~= .

gen byte imputed = 0
replace imputed = 1 if paidhre == 1 & a_earnhour == 1
replace imputed = 1 if paidhre == 0 & a_weekpay == 1
keep if imputed == 0

gen logwage = log(wageotc)

gen majorocc = mocc03
assert majorocc ~= .
gen majorind = mind03
assert majorind ~= .

* education
gen new_educ = gradeatn
* collapse Associate's degrees into one category
replace new_educ = 11 if gradeatn == 12
assert new_educ ~= .

* race & ethnicity
gen new_race = .
* White
replace new_race = 1 if raceorig == 1
* Black
replace new_race = 2 if raceorig == 2
* Other
replace new_race = 4 if raceorig >= 3 & raceorig ~= .
replace new_race = 3 if hispanic == 1
assert new_race ~= .

forvalues i = 2/5 {
	gen age`i' = age^`i'
}

* marital status
gen new_married = married
assert new_married ~= .

* part/full-time
gen parttime = hoursu1i <= 34

* gender-specific wage predictions
forvalues i = 0 / 1 {
	reg logwage age age2-age5 i.new_educ i.new_race i.new_married i.majorind i.majorocc i.parttime i.year i.statefips [aw=orgwgt] if female == `i'
	eststo female`i'
}

use `acs', clear
gen predlogwage = .
forvalues i = 0 / 1 {
	estimates restore female`i'
	predict predlogwage`i' if female == `i', xb
	replace predlogwage = predlogwage`i' if female == `i'
	drop predlogwage`i'
}
gen regpredwage = exp(predlogwage)
drop predlogwage
egen hrwage1 = rowmean(regpredwage hrwage0)
