set more off

global input_clean_dir inputs_clean/

local stata_arguments = subinstr("`0'", "=", "(", .)
local stata_arguments = subinstr("`stata_arguments'", " ", ") ", .)

capture program drop cps_emp_benchmark
program define cps_emp_benchmark
syntax, cps_year(integer) out_file(string)

  * 2025 CPS ORG has only 11 months of published data; scale accordingly
  if `cps_year' == 2025 {
    local n_months = 11
  }
  else {
    local n_months = 12
  }

  load_epiextracts, begin(`cps_year'm1) end(`cps_year'm12) sample(org) keep(wageotc age cow1 emp orgwgt)
  keep if wageotc > 0 & wageotc != .
  assert age >= 16 & cow1 >= 1 & cow1 <= 5 & emp == 1

  replace orgwgt = orgwgt / `n_months'
  sum orgwgt
  local benchmark = `r(sum)'

  file open handle using "`out_file'", write replace
  file write handle "`benchmark'" _n
  file close handle

end

cps_emp_benchmark, `stata_arguments'
