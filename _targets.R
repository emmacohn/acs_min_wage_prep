source("./packages.R")
lapply(list.files("./R", full.names = TRUE), source)

#REF_STATE_BASE <- "~/projects/bzipperer/rtwa_2025_17/inputs_clean/clean_acs_state_base.dta"
# that's not on spriggs

tar_assign({
  # pipeline parameters
  acs_ipums_raw = tar_file("inputs_raw/usa_00058.dta.gz")
  acs_tables_dir = tar_file("inputs_raw/acs_tables") # ACS 5-year state tables used to rake weights
  cps_year = 2025 |> tar_target() # most recent year of cps data

  # do-files
  dofile_prep_acs = tar_file("stata/prep_acs.do")
  dofile_acs_state = tar_file("stata/acs_state.do")
  dofile_acs_wage_impute = tar_file("stata/impute_wages_cpsloc.do")
  dofile_acs_tables = tar_file("stata/clean_acs_tables_state.do")
  dofile_calibrate_weights = tar_file("stata/calibrate_weights_acs_state.do")
  dofile_clean_acs = tar_file("stata/clean_acs.do")
  dofile_cps_emp_benchmark = tar_file("stata/cps_emp_benchmark.do")

  # prep ACS
  acs_prep = do_file_target(
    dofile_prep_acs,
    acs_raw_file = acs_ipums_raw,
    acs_raw_file_base = fs::path_ext_remove(acs_ipums_raw),
    .outputs = "inputs_clean/acs_prep.dta"
  ) |>
    tar_file()

  # CPS wage-earner employment by state
  cps_emp_benchmark_file = do_file_target(
    dofile_cps_emp_benchmark,
    cps_year = cps_year,
    out_file = "inputs_clean/cps_emp_benchmark_state.csv",
    .outputs = "inputs_clean/cps_emp_benchmark_state.csv"
  ) |>
    tar_file()

  # ACS state wages (CPS-percentile imputation)
  acs_state_wages = do_file_target(
    dofile_acs_state,
    acs_prep_file = acs_prep,
    acs_impute_do_file = dofile_acs_wage_impute,
    cps_year = cps_year,
    acs_tables_dir = acs_tables_dir,
    acs_tables_do_file = dofile_acs_tables,
    calibrate_do_file = dofile_calibrate_weights,
    .outputs = "inputs_clean/acs_state.dta"
  ) |>
    tar_file()

  # Final clean state base
  acs_state_base = do_file_target(
    dofile_clean_acs,
    acs_raw_file = acs_state_wages,
    cps_emp_benchmark_file = cps_emp_benchmark_file,
    .outputs = "inputs_clean/clean_acs_state_base.dta"
  ) |>
    tar_file()

  # Parquet sibling
  acs_state_base_parquet = dta_to_parquet(
    acs_state_base,
    "inputs_clean/clean_acs_state_base.parquet"
  ) |>
    tar_file()

  # Reproducibility check vs. rtwa_2025_17 baseline
  # ref_state_base = tar_file(REF_STATE_BASE)

  #repro_report = reproducibility_report(
  #  acs_state_base,
  #  ref_state_base
  # ) |>
  #  tar_target()
  })