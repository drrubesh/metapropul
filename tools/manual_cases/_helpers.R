required <- c("devtools", "gt", "ggplot2", "meta", "metafor", "metasens")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Install required packages: ", paste(missing, collapse = ", "))
devtools::load_all(quiet = TRUE)
.case_log <- new.env(parent = emptyenv())
.case_log$lines <- character()
.case_log$output <- NULL
.case_add <- function(...) {
  line <- paste0(...)
  .case_log$lines <- c(.case_log$lines, line)
  message(line)
  invisible(line)
}
case_begin <- function(title, question, dataset, output) {
  .case_log$lines <- character()
  .case_log$output <- output
  .case_add("# ", title, "\n")
  .case_add("**Clinical question.** ", question, "\n")
  .case_add("**Data.** ", dataset, "\n")
  .case_add("This is an executable analyst-led review. PASS statements are software checks; ",
    "the surrounding text explains why each analysis is performed and what must be inspected.\n")
}
case_section <- function(title) .case_add("\n## ", title, "\n")
case_text <- function(...) .case_add(paste0(...), "\n")
case_value <- function(label, value) .case_add("- **", label, ":** ", value)
case_review <- function(...) .case_add("- [ ] **Reviewer check:** ", paste0(...))
case_finish <- function(files = character()) {
  case_section("Manual review checklist")
  if (length(files)) {
    for (file in files) case_review("Open `", file, "` and confirm labels, scale, confidence intervals, and annotations.")
  }
  case_review("Confirm the written interpretation agrees with the numerical and graphical output.")
  report <- file.path(.case_log$output, "CASE-STUDY.md")
  writeLines(.case_log$lines, report, useBytes = TRUE)
  manual_check(file.exists(report) && file.info(report)$size > 0, "narrative CASE-STUDY.md")
  message("\nNarrative report: ", report)
  invisible(report)
}
fmt_num <- function(x, digits = 3L) formatC(x, digits = digits, format = "f")
pooled_text <- function(object) {
  fit <- object$meta
  random <- isTRUE(fit$random)
  estimate <- if (random) fit$TE.random else fit$TE.common
  lower <- if (random) fit$lower.random else fit$lower.common
  upper <- if (random) fit$upper.random else fit$upper.common
  transform <- if (inherits(object, "meta_ratio")) {
    exp
  } else if (inherits(object, "meta_prop")) {
    function(x) stats::plogis(x) * 100
  } else if (inherits(object, "meta_cor")) {
    tanh
  } else if (inherits(object, "meta_rate")) {
    function(x) exp(x) * (object$settings$irscale %||% 1)
  } else if (inherits(object, "meta_generic") &&
    identical(object$settings$backtransform, "exp")) {
    exp
  } else {
    identity
  }
  vals <- transform(c(estimate, lower, upper))
  sprintf("%s [%s, %s]", fmt_num(vals[1]), fmt_num(vals[2]), fmt_num(vals[3]))
}
i2_text <- function(object) paste0(fmt_num(object$meta$I2 * 100, 1), "%")
`%||%` <- function(x, y) if (is.null(x)) y else x
manual_check <- function(ok, label) {
  if (!isTRUE(ok)) stop("FAILED: ", label, call. = FALSE)
  message("PASS: ", label)
}
manual_output_dir <- function(case) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) > 1L) stop("Supply at most one output directory.")
  path <- if (length(args)) args[[1]] else file.path(tempdir(), paste0("metapropul-", case))
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  normalizePath(path, mustWork = TRUE)
}
save_gt_html <- function(expr, filename) {
  invisible(utils::capture.output(value <- suppressMessages(force(expr))))
  gt::gtsave(value, filename)
  manual_check(file.exists(filename) && file.info(filename)$size > 0, basename(filename))
  invisible(value)
}
check_artifacts <- function(directory, files) {
  paths <- file.path(directory, files)
  manual_check(all(file.exists(paths) & file.info(paths)$size > 0), "all figure artifacts")
}
