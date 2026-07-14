STATA_PATH <- Sys.getenv("STATA_PATH", "/usr/local/stata15/stata-mp")

do_file_target <- function(do_file,
                           ...,
                           .outputs,
                           .stata_path = STATA_PATH,
                           .remove_log = TRUE) {

  stata_args <- list(...) %>%
    unlist() %>%
    imap_chr(\(x, idx) paste0(idx, "=", x)) %>%
    str_flatten(" ")

  cmd <- paste(.stata_path, "-b do", do_file, stata_args)
  system(cmd)

  if (.remove_log) {
    file_base <- fs::path_ext_remove(basename(do_file))
    log_file <- paste0(file_base, ".log")
    if (file.exists(log_file)) file.remove(log_file)
  }

  .outputs
}
