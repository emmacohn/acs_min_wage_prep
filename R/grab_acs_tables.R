acs_demo_data <- function(census_key, acs_tables_year, survey = "acs5") {
  # civilian employed by sex x age (B23001), race/ethnicity x sex x age
  # (C23002A white alone, C23002B black alone, C23002I hispanic), and
  # education for ages 25-64 (B23006); same columns as clean_acs_tables_state.do
  age_vars <- c(
    male1619 = "B23001_007", male2021 = "B23001_014", male2224 = "B23001_021",
    male2529 = "B23001_028", male3034 = "B23001_035", male3544 = "B23001_042",
    male4554 = "B23001_049", male5559 = "B23001_056", male6061 = "B23001_063",
    male6264 = "B23001_070", male6569 = "B23001_075", male7074 = "B23001_080",
    male7599 = "B23001_085",
    female1619 = "B23001_093", female2021 = "B23001_100", female2224 = "B23001_107",
    female2529 = "B23001_114", female3034 = "B23001_121", female3544 = "B23001_128",
    female4554 = "B23001_135", female5559 = "B23001_142", female6061 = "B23001_149",
    female6264 = "B23001_156", female6569 = "B23001_161", female7074 = "B23001_166",
    female7599 = "B23001_171"
  )

  race_vars <- c(
    empwhitemale1664 = "C23002A_007", empwhitemale6599 = "C23002A_012",
    empwhitefemale1664 = "C23002A_020", empwhitefemale6599 = "C23002A_025",
    empblackmale1664 = "C23002B_007", empblackmale6599 = "C23002B_012",
    empblackfemale1664 = "C23002B_020", empblackfemale6599 = "C23002B_025",
    emphispanicmale1664 = "C23002I_007", emphispanicmale6599 = "C23002I_012",
    emphispanicfemale1664 = "C23002I_020", emphispanicfemale6599 = "C23002I_025"
  )

  educ_vars <- c(
    emplths = "B23006_006", emphs = "B23006_013",
    empscol = "B23006_020", empcol = "B23006_027"
  )

  get_acs(
    geography = "state",
    variables = c(age_vars, race_vars, educ_vars),
    year = acs_tables_year,
    survey = survey,
    output = "wide",
    key = census_key
  ) |>
    select(GEOID, all_of(paste0(names(c(age_vars, race_vars, educ_vars)), "E"))) |>
    rename_with(\(x) str_remove(x, "E$"), -GEOID) |>
    mutate(statefips = as.numeric(GEOID), .before = 1, .keep = "unused") |>
    filter(statefips != 72) |> # remove PR
    mutate(
      emp1619 = male1619 + female1619,
      emp2024 = male2021 + male2224 + female2021 + female2224,
      emp2534 = male2529 + male3034 + female2529 + female3034,
      emp3544 = male3544 + female3544,
      emp4554 = male4554 + female4554,
      emp5564 = male5559 + male6061 + male6264 + female5559 + female6061 + female6264,
      emp6599 = male6569 + male7074 + male7599 + female6569 + female7074 + female7599,
      empmale = male1619 + male2021 + male2224 + male2529 + male3034 + male3544 +
        male4554 + male5559 + male6061 + male6264 + male6569 + male7074 + male7599,
      empfemale = female1619 + female2021 + female2224 + female2529 + female3034 +
        female3544 + female4554 + female5559 + female6061 + female6264 +
        female6569 + female7074 + female7599,
      emp = empmale + empfemale,
      empmale1664 = male1619 + male2021 + male2224 + male2529 + male3034 +
        male3544 + male4554 + male5559 + male6061 + male6264,
      empfemale1664 = female1619 + female2021 + female2224 + female2529 + female3034 +
        female3544 + female4554 + female5559 + female6061 + female6264,
      empmale6599 = empmale - empmale1664,
      empfemale6599 = empfemale - empfemale1664,

      empwhite1664 = empwhitemale1664 + empwhitefemale1664,
      empwhite6599 = empwhitemale6599 + empwhitefemale6599,
      empblack1664 = empblackmale1664 + empblackfemale1664,
      empblack6599 = empblackmale6599 + empblackfemale6599,
      emphispanic1664 = emphispanicmale1664 + emphispanicfemale1664,
      emphispanic6599 = emphispanicmale6599 + emphispanicfemale6599,

      empothermale1664 = empmale1664 - (empwhitemale1664 + empblackmale1664),
      empotherfemale1664 = empfemale1664 - (empwhitefemale1664 + empblackfemale1664),
      empothermale6599 = empmale6599 - (empwhitemale6599 + empblackmale6599),
      empotherfemale6599 = empfemale6599 - (empwhitefemale6599 + empblackfemale6599),
      empother1664 = empothermale1664 + empotherfemale1664,
      empother6599 = empothermale6599 + empotherfemale6599,

      empnonhispanicmale1664 = empmale1664 - emphispanicmale1664,
      empnonhispanicfemale1664 = empfemale1664 - emphispanicfemale1664,
      empnonhispanicmale6599 = empmale6599 - emphispanicmale6599,
      empnonhispanicfemale6599 = empfemale6599 - emphispanicfemale6599,
      empnonhispanic1664 = empnonhispanicmale1664 + empnonhispanicfemale1664,
      empnonhispanic6599 = empnonhispanicmale6599 + empnonhispanicfemale6599,

      empedother = empmale + empfemale - (emplths + emphs + empscol + empcol)
    ) |>
    select(statefips, starts_with("emp")) |>
    arrange(statefips)
}

write_acs_tables <- function(acs_tables, path) {
  write_dta(acs_tables, path, version = 13)
  path
}
