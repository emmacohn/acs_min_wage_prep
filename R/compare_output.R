wtd_quantile <- function(x, w, probs) {
  keep <- !is.na(x) & !is.na(w) & w > 0
  x <- x[keep]; w <- w[keep]
  ord <- order(x)
  x <- x[ord]; w <- w[ord]
  cw <- cumsum(w) / sum(w)
  vapply(probs, function(p) x[which(cw >= p)[1]], numeric(1))
}

wtd_mean <- function(x, w) {
  keep <- !is.na(x) & !is.na(w) & w > 0
  sum(x[keep] * w[keep]) / sum(w[keep])
}

compare_counts <- function(new, ref) {
  by_state_new <- new |> count(statefips, wt = NULL, name = "n") |> rename(n_new = n)
  by_state_ref <- ref |> count(statefips, wt = NULL, name = "n") |> rename(n_ref = n)
  by_state <- full_join(by_state_new, by_state_ref, by = "statefips") |>
    mutate(
      metric = paste0("n_obs_statefips_", statefips),
      diff = n_new - n_ref,
      pct_diff = diff / n_ref
    ) |>
    transmute(metric, new = n_new, ref = n_ref, diff, pct_diff)

  total <- tibble(
    metric = "n_obs_total",
    new = nrow(new),
    ref = nrow(ref),
    diff = nrow(new) - nrow(ref),
    pct_diff = (nrow(new) - nrow(ref)) / nrow(ref)
  )

  bind_rows(total, by_state)
}

wage_summary <- function(df, group_var = NULL) {
  probs <- c(0.10, 0.25, 0.50, 0.75, 0.90)
  pname <- paste0("p", probs * 100)

  summarize_one <- function(d) {
    q <- wtd_quantile(d$hrwage0, d$perwt0, probs)
    tibble(
      stat = c("mean", pname),
      value = c(wtd_mean(d$hrwage0, d$perwt0), q)
    )
  }

  if (is.null(group_var)) {
    summarize_one(df) |> mutate(group = "overall", .before = 1)
  } else {
    df |>
      group_by(across(all_of(group_var))) |>
      group_modify(~ summarize_one(.x)) |>
      ungroup() |>
      mutate(group = paste0(group_var, "_", .data[[group_var]])) |>
      select(group, stat, value)
  }
}

compare_wage <- function(new, ref, group_var = NULL) {
  s_new <- wage_summary(new, group_var) |> rename(new = value)
  s_ref <- wage_summary(ref, group_var) |> rename(ref = value)
  full_join(s_new, s_ref, by = c("group", "stat")) |>
    mutate(
      metric = paste0(group, "_hrwage0_", stat),
      diff = new - ref,
      pct_diff = diff / ref
    ) |>
    select(metric, new, ref, diff, pct_diff)
}

reproducibility_report <- function(new_file, ref_file) {
  new <- haven::read_dta(new_file)
  ref <- haven::read_dta(ref_file)

  bind_rows(
    compare_counts(new, ref),
    compare_wage(new, ref),
    compare_wage(new, ref, "statefips"),
    compare_wage(new, ref, "pwstate")
  )
}
