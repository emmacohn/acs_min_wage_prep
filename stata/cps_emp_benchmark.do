set more off

global input_clean_dir inputs_clean/

local stata_arguments = subinstr("`0'", "=", "(", .)
local stata_arguments = subinstr("`stata_arguments'", " ", ") ", .)

capture program drop cps_emp_benchmark
program define cps_emp_benchmark
syntax, cps_year(integer) out_file(string)

  load_epiextracts, begin(`cps_year'm1) end(`cps_year'm12) sample(org) keep(wageotc age cow1 emp orgwgt statefips)
  keep if wageotc > 0 & wageotc != .
  assert age >= 16 & cow1 >= 1 & cow1 <= 5 & emp == 1

  * average monthly weight over the months actually loaded (2025m10 was not collected)
  egen byte month_tag = tag(year month)
  count if month_tag
  local n_months = r(N)
  replace orgwgt = orgwgt / `n_months'

  * wage-earner employment by state of residence
  collapse (sum) cps_stateemp = orgwgt, by(statefips)
  format cps_stateemp %15.2f
  export delimited statefips cps_stateemp using "`out_file'", nolabel replace

end

cps_emp_benchmark, `stata_arguments'
