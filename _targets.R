source("./packages.R")
lapply(list.files("./R", full.names = TRUE), source)
tar_source()

#API keys
census_key <- Sys.getenv("CENSUS_API_KEY")

tar_assign({
  # pipeline parameters
  acs_ipums_raw = tar_file("inputs_raw/usa_00055.dta.gz")
  cps_year = 2025 |> tar_target() # CPS year for wage percentiles; wage regression uses cps_year - 4 to cps_year
  # CPS ORG window (YYYYmM) for state employment scaling; most recent 12 months
  cps_begin = "2025m10" |> tar_target()
  cps_end = "2026m9" |> tar_target()
  acs_tables_year = 2024 |> tar_target() #change this for the acs raking to demos weights

  #ACS data
  acs_input <- acs_demo_data(census_key, acs_tables_year = acs_tables_year) |>
    tar_target()

  # ACS 5-year state employment tables used to rake weights
  acs_tables_file = write_acs_tables(acs_input, "inputs_clean/acs_tables_state.dta") |>
    tar_file()

  # do-files
  dofile_prep_acs = tar_file("stata/prep_acs.do")
  dofile_acs_state = tar_file("stata/acs_state.do")
  dofile_acs_wage_impute = tar_file("stata/impute_wages_cpsloc.do")
  dofile_acs_wage_reg = tar_file("stata/impute_wages_cpsreg.do")
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
    cps_begin = cps_begin,
    cps_end = cps_end,
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
    acs_tables_file = acs_tables_file,
    calibrate_do_file = dofile_calibrate_weights,
    acs_reg_do_file = dofile_acs_wage_reg,
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
  })