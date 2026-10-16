* calculate quantiles in ACS and match to appropriate percentiles in CPS
*
* 1. To calculate quantiles in ACS, linearly interpolate them according to ACS percentiles.
* To calculate ACS percentiles, linearly interpolate those
* 2. To calculate percentiles in CPS, linearly interpolate them
* 3. To match ACS linearly interpolate quantiles to appropriate CPS percentiles, linearly interpolate between CPS (linearlly interpolated) percentiles

local cps_year ${cps_year}

tempfile allacs
save `allacs'

* calculate linearally interpolated percentiles by state year in ACS
binipolate hrwage1 [pw=perwt2], binsize(0.25) p(1(1)99) by(year statefips) collapsefun(gcollapse)
rename percentile xtile
rename hrwage1_binned pctile
tempfile acspctile
save `acspctile'

* grab pctiles from CPS
load_epiextracts, begin(`cps_year'm1) end(`cps_year'm12) sample(org) keep(wageotc statefips paidhre a_earnhour a_weekpay)
keep if wageotc > 0 & wageotc ~= .

gen byte imputed = 0
replace imputed = 1 if paidhre == 1 & a_earnhour == 1
replace imputed = 1 if paidhre == 0 & a_weekpay == 1
keep if imputed == 0

binipolate wageotc [pw=orgwgt], binsize(0.25) p(1(1)99) by(statefips) collapsefun(gcollapse)
rename percentile xtile
rename wageotc_binned pctile
tempfile cpspctile
save `cpspctile'

* calculate linearly interpolated quantile categories in ACS
use `allacs', clear
* add acs percentiles to the data for use as cutpoints
* do this by a merge:
bysort statefips year: gen xtile = _n
merge 1:1 statefips year xtile using `acspctile', assert(1 3) nogenerate
drop xtile
* calculate xtile for each wage using pctile cutpoints
gquantiles xtile = hrwage1 [pw=perwt2], xtile by(year statefips) cutpoints(pctile) cutby
drop pctile
* calculate pctile for surrounding xtiles
merge m:1 statefips year xtile using `acspctile', keep(1 3)
rename xtile xtile1
rename pctile acs_pctile1
gen xtile = xtile1 - 1
merge m:1 statefips year xtile using `acspctile', keep(1 3) nogenerate
rename xtile xtile0
rename pctile acs_pctile0
* linearly interpolate xtile from surrounding xtiles using associated pctiles & wage value
gen xtile_ipolate = xtile1 + [(xtile1-xtile0)/(acs_pctile1-acs_pctile0)]*(hrwage1-acs_pctile1)
* deal with edge cases
* assign xtile_ipolate=99 if xtile1=100
* assign  xtile_ipolate=1 if xtile0=0
replace xtile_ipolate = 99 if xtile1 == 100
replace xtile_ipolate = 1 if xtile0 == 0

* merge CPS percentiles
rename xtile1 xtile
merge m:1 statefips xtile using `cpspctile', keep(1 3) nogenerate
rename pctile cps_pctile1
rename xtile xtile1
rename xtile0 xtile
merge m:1 statefips xtile using `cpspctile', keep(1 3) nogenerate
rename pctile cps_pctile0
rename xtile xtile0

* linearly interpolate wage using CPS percentiles and ACS (interpolated) quantile
gen hrwage2 = cps_pctile1 + [(cps_pctile1-cps_pctile0)/(xtile1-xtile0)]*(xtile_ipolate-xtile1)
* deal with edge cases
* assign pctile0 if xtile1 == 100
* assign pctile1 if xtile0 == 0
replace hrwage2 = cps_pctile0 if xtile1 == 100
replace hrwage2 = cps_pctile1 if xtile0 == 0

drop *pctile* *xtile*
