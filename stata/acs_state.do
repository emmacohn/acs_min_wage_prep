set more off

global input_clean_dir inputs_clean/

local stata_arguments = subinstr("`0'", "=", "(", .)
local stata_arguments = subinstr("`stata_arguments'", " ", ") ", .)

capture program drop acs_state
program define acs_state
syntax, acs_prep_file(string) acs_impute_do_file(string) cps_year(integer)


********************************************************************************
* Prepare ACS for ACS tables
********************************************************************************
use `acs_prep_file', clear


********************************************************************************
* Calibrate sample weights
********************************************************************************
* output: variable perwt0 perwt1 perwt2

rename perwt perwt0
gen perwt1 = perwt0
gen perwt2 = perwt1


********************************************************************************
* Impute wages based on CPS wage regression
********************************************************************************
* input: acs_state_calibratedweights.dta
* output: variable hrwage1

* only keep private & government sectors
keep if classwkrd >= 22 & classwkrd <= 28

* drop those working abroad
drop if pwstate > 56

gen hrwage1 = hrwage0


********************************************************************************
* Modify imputation based on CPS state wage location
********************************************************************************
* output: variable hrwage2
global cps_year `cps_year'
do `acs_impute_do_file'

keep adj_wkswork* age bpl citizen classwkr classwkrd educd empstatd empstat famsize famunit foodstmp ftotinc hasyouth_* hhincome hhwt hispan* hrwage0 hrwage1 hrwage2 incearn inctot incwage ind ind1990 marst metro met2013 nchild nfams occ parent_* pernum perwt0 perwt1 perwt2 poverty puma pwpuma pwstate rac* related serial sex statefips subfam uhrswork vetstatd wkswork2 year
compress
saveold ${input_clean_dir}acs_state.dta, replace version(13)

end

acs_state, `stata_arguments'
