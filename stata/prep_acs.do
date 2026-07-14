set more off

global input_clean_dir inputs_clean/

local stata_arguments = subinstr("`0'", "=", "(", .)
local stata_arguments = subinstr("`stata_arguments'", " ", ") ", .)

capture program drop acs_prep
program define acs_prep
syntax, acs_raw_file(string) acs_raw_file_base(string)


********************************************************************************
* Load IPUMS ACS
********************************************************************************
!gunzip -k `acs_raw_file'
use `acs_raw_file_base', clear
erase `acs_raw_file_base'


********************************************************************************
* Family relations
********************************************************************************
gen byte youth = age < 18
gegen byte hasyouth_fam = max(youth), by(year serial famunit)
gegen byte hasyouth_sfam = max(youth), by(year serial famunit subfam)
gen byte parent_fam = nchild >= 1 & hasyouth_fam == 1
gen byte parent_sfam = nchild >= 1 & hasyouth_sfam == 1


********************************************************************************
* ACS sample restrictions
********************************************************************************
* exlude under 16
drop if age < 16

* nonmissing, positive wage income
replace incwage = . if incwage >= 999998
keep if incwage > 0 & incwage ~= .

* with positive income, all entries nonzero for hours & weeks worked
assert uhrswork > 0 & wkswork2 > 0

* drop armed forces
drop if (9670 <= ind & ind <= 9890) | (9800 <= occ & occ <= 9830)

* ONLY KEEP EMPLOYED
keep if empstat == 1


********************************************************************************
* Define place of work state & PUMA
********************************************************************************
rename statefip statefips

gen pwpuma = pwpuma00
gen pwstate = pwstate2

* place of work is missing if currently not at work (even though employed/worked last year)
* assign place of residence in these cases (about 13% of pos inc, or only 2% of posinc and employed)
replace pwpuma = puma if pwpuma00 == 0
replace pwstate = statefips if pwpuma00 == 0

assert pwpuma > 0 & pwpuma ~= .
assert pwstate > 0 & pwstate ~= .


********************************************************************************
* Impute weeks worked
********************************************************************************
* output variable: adj_wkswork0 and adj_wkswork1
gen adj_wkswork0 = .
replace adj_wkswork0 = 0.5 * ( 1 + 13) if wkswork2 == 1
replace adj_wkswork0 = 0.5 * (14 + 26) if wkswork2 == 2
replace adj_wkswork0 = 0.5 * (27 + 39) if wkswork2 == 3
replace adj_wkswork0 = 0.5 * (40 + 47) if wkswork2 == 4
replace adj_wkswork0 = 0.5 * (48 + 49) if wkswork2 == 5
replace adj_wkswork0 = 0.5 * (50 + 52) if wkswork2 == 6

gen adj_wkswork1 = adj_wkswork0

********************************************************************************
* Create initial hourly wages
********************************************************************************
gen hrwage0 = incwage / (uhrswork * adj_wkswork1)
assert hrwage0 >= 0 & hrwage0 ~= .


********************************************************************************
* Save preparatory data
********************************************************************************
keep adj_wkswork* age bpl citizen classwkr classwkrd educd empstatd empstat famsize famunit foodstmp ftotinc hasyouth_* hhincome hhwt hispan* hrwage0 incearn inctot incwage ind ind1990 marst metro met2013 nchild nfams occ parent_* pernum perwt poverty puma pwpuma pwstate rac* related serial sex statefips subfam uhrswork vetstatd wkswork2 year
compress
saveold ${input_clean_dir}acs_prep.dta, replace version(13)

end

acs_prep, `stata_arguments'