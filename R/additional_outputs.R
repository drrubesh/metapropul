#' Validate risk-of-bias data
#'
#' Checks study labels, domain columns, and judgement levels against a supported
#' risk-of-bias template without creating a plot.
#'
#' @param rob_data A data frame containing study labels and judgements.
#' @param studylab Study-label column.
#' @param tool Risk-of-bias or appraisal tool; see [plot_rob()].
#' @param domains Optional domain columns.
#' @param levels Optional allowed levels for a custom tool.
#' @param colours Optional custom colours.
#' @param has_overall Whether a custom tool has an overall judgement.
#' @return A list containing the resolved template, validated domains, and a
#'   frequency table of judgements.
#' @export
validate_rob <- function(rob_data, studylab, tool = "GENERIC", domains = NULL,
                         levels = NULL, colours = NULL, has_overall = TRUE) {
  template <- .get_rob_template(tool, domains, levels, colours, has_overall)
  if (is.null(domains)) domains <- template$domains
  if (is.null(domains) || !length(domains)) {
    stop("'domains' must be provided for this tool.", call. = FALSE)
  }
  .validate_rob_data(rob_data, studylab, domains, template)
  long <- .prepare_rob_long(rob_data, studylab, domains)
  frequencies <- dplyr::count(long, Domain, Judgement, name = "Studies",
    .drop = FALSE)
  structure(list(valid = TRUE, template = template, domains = domains,
    frequencies = frequencies), class = "rob_validation")
}

#' Tabulate subgroup meta-analysis results
#'
#' Returns full-precision subgroup estimates and the test for subgroup
#' differences, or formats them as a `gt` table.
#'
#' @param object A `meta_ratio`, `meta_mean`, or `meta_prop` object fitted with
#'   a subgroup variable.
#' @param output `"gt"` or `"data"`.
#' @param digits Display precision for `output = "gt"`.
#' @param title Optional table title.
#' @return A `gt` table or a list containing subgroup estimates and the
#'   subgroup-difference test.
#' @export
table_subgroups <- function(object, output = c("gt", "data"), digits = 3L,
                            title = NULL) {
  if (!inherits(object, c("meta_ratio", "meta_mean", "meta_prop"))) {
    stop("'object' must be a supported metapropul meta-analysis.", call. = FALSE)
  }
  output <- match.arg(output)
  estimates <- object$meta.subgroup.summary
  if (is.null(estimates) || !nrow(estimates)) {
    stop("The object does not contain a subgroup analysis.", call. = FALSE)
  }
  result <- list(estimates = estimates, test = object$subgroup_test)
  if (output == "data") return(result)
  display <- estimates
  numeric <- vapply(display, is.numeric, logical(1))
  display[numeric] <- lapply(display[numeric], round, digits = digits)
  note <- if (is.null(object$subgroup_test)) {
    "Test for subgroup differences unavailable."
  } else sprintf("Test for subgroup differences: Q = %.*f, df = %g, p = %s.",
    digits, object$subgroup_test$statistic, object$subgroup_test$df,
    format.pval(object$subgroup_test$p.value, digits = digits, eps = 10^-digits))
  gt::gt(display) |>
    .gt_optional_title(title) |>
    gt::tab_source_note(note)
}

#' Tabulate publication-bias method availability
#'
#' @param object A result returned by [publication_bias()].
#' @param output `"gt"` or `"data"`.
#' @param title Optional title.
#' @return A `gt` table or availability tibble.
#' @export
table_publication_bias <- function(object, output = c("gt", "data"),
                                   title = NULL) {
  if (!inherits(object, "publication_bias_result")) {
    stop("'object' must be returned by publication_bias().", call. = FALSE)
  }
  output <- match.arg(output)
  if (output == "data") return(object$status)
  gt::gt(object$status) |>
    .gt_optional_title(title) |>
    gt::tab_source_note(
      "Trim-and-fill is a sensitivity analysis and should not be interpreted as a correction for publication bias."
    )
}
