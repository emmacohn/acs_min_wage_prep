set more off

global input_clean_dir inputs_clean/

local stata_arguments = subinstr("`0'", "=", "(", .)
local stata_arguments = subinstr("`stata_arguments'", " ", ") ", .)

capture program drop acs_state
program define acs_state
syntax, acs_prep_file(string) acs_impute_do_file(string) cps_year(integer) acs_tables_file(string) calibrate_do_file(string) acs_reg_do_file(string)

* ACS state employment tables (from acs_demo_data()) used to rake weights
global acs_tables_file `acs_tables_file'


********************************************************************************
* Prepare ACS for ACS tables
********************************************************************************
use `acs_prep_file', clear

gen byte agegroup = .
replace agegroup = 1 if age >= 16 & age <= 19
replace agegroup = 2 if age >= 20 & age <= 24
replace agegroup = 3 if age >= 25 & age <= 34
replace agegroup = 4 if age >= 35 & age <= 44
replace agegroup = 5 if age >= 45 & age <= 54
replace agegroup = 6 if age >= 55 & age <= 64
replace agegroup = 7 if age >= 65
assert agegroup ~= .

gen byte raceagegroup = .
replace raceagegroup = 11 if race == 1 & age >= 16 & age <= 64
replace raceagegroup = 12 if race == 1 & age >= 65
replace raceagegroup = 21 if race == 2 & age >= 16 & age <= 64
replace raceagegroup = 22 if race == 2 & age >= 65
replace raceagegroup = 31 if race >= 3 & age >= 16 & age <= 64
replace raceagegroup = 32 if race >= 3 & age >= 65
assert raceagegroup ~= .

cap drop hispanic
gen byte hispanic = hispan >= 1 & hispan <= 4
gen byte hispagegroup = .
replace hispagegroup = 11 if hispanic == 1 & age >= 16 & age <= 64
replace hispagegroup = 12 if hispanic == 1 & age >= 65
replace hispagegroup = 21 if hispanic == 0 & age >= 16 & age <= 64
replace hispagegroup = 22 if hispanic == 0 & age >= 65
assert hispagegroup ~= .

gen byte educgroup = .
replace educgroup = 1 if educd <= 61 & age >= 25 & age <= 64
replace educgroup = 2 if educd >= 63 & educd <= 64 & age >= 25 & age <= 64
replace educgroup = 3 if educd >= 65 & educd <= 81 & age >= 25 & age <= 64
replace educgroup = 4 if educd >= 101 & age >= 25 & age <= 64
replace educgroup = 5 if age < 25 | age > 64
assert educgroup ~= .


********************************************************************************
* Calibrate sample weights
********************************************************************************
* output: variable perwt0 perwt1 perwt2
do `calibrate_do_file'


********************************************************************************
* Impute wages based on CPS wage regression
********************************************************************************
* input: acs_state_calibratedweights.dta
* output: variable hrwage1

* only keep private & government sectors
keep if classwkrd >= 22 & classwkrd <= 28

* drop those working abroad
drop if pwstate > 56

global cps_year `cps_year'
do `acs_reg_do_file'

********************************************************************************
* Modify imputation based on CPS state wage location
********************************************************************************
* output: variable hrwage2
do `acs_impute_do_file'

keep adj_wkswork* age bpl citizen classwkr classwkrd educd empstatd empstat famsize famunit foodstmp ftotinc hasyouth_* hhincome hhwt hispan* hrwage0 hrwage1 hrwage2 incearn inctot incwage ind ind1990 marst metro met2013 nchild nfams occ parent_* pernum perwt0 perwt1 perwt2 poverty puma pwpuma pwstate rac* related serial sex statefips subfam uhrswork vetstatd wkswork2 year
compress
saveold ${input_clean_dir}acs_state.dta, replace version(13)

end

acs_state, `stata_arguments'
