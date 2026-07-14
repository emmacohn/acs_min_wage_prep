dta_to_parquet <- function(dta_file, parquet_file) {
  haven::read_dta(dta_file) |>
    rename(perwt = perwt0, hrwage = hrwage0) |>
    arrow::write_parquet(parquet_file)
  parquet_file
}
