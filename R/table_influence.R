#' Leave-one-out influence table
#'
#' Produces a publication-ready table of leave-one-out pooled estimates from a
#' \code{meta_ratio}, \code{meta_mean}, or \code{meta_prop} object.
#'
#' @param object A \code{meta_ratio}, \code{meta_mean}, or \code{meta_prop}
#'   object.
#' @param title Optional character string for the table title. If \code{NULL}
#'   (default), an auto-constructed title is used.
#' @param include_heterogeneity Logical. Include I\eqn{^2} and Tau\eqn{^2}
#'   columns (default \code{TRUE}).
#' @param save_as One of \code{"viewer"} (default), \code{"docx"}, or
#'   \code{"pdf"}.
#' @param filename Optional file path. If \code{NULL}, a timestamped file is
#'   created in \code{tempdir()} when saving to file.
#'
#' @return A \code{gt} table, invisibly if saved to file.
#'
#' @examples
#' \donttest{
#' data(dat_bcg, package = "metapropul")
#' result <- meta_prop(
#'   data = dat_bcg,
#'   event = "tpos",
#'   n = "npos",
#'   studylab = "author"
#' )
#' table_influence(result)
#' }
#'
#' @importFrom tibble tibble
#' @importFrom tidyselect all_of
#' @export
table_influence <- function(object,
                            title = NULL,
                            include_heterogeneity = TRUE,
                            save_as = c("viewer", "docx", "pdf"),
                            filename = NULL) {
  save_as <- match.arg(save_as)

  if (!inherits(object, c("meta_prop", "meta_ratio", "meta_mean"))) {
    stop(
      "Only supports meta_prop, meta_ratio, or meta_mean objects.",
      call. = FALSE
    )
  }

  infl <- if (inherits(object, "meta_prop")) {
    object$influence.meta
  } else {
    object$influence.analysis
  }

  if (!inherits(infl, "metainf")) {
    stop(
      "No valid metainf object found. Run meta_ratio(), meta_mean(), or meta_prop() first.",
      call. = FALSE
    )
  }

  required_fields <- c("studlab", "TE", "lower", "upper")
  missing_fields <- required_fields[!vapply(required_fields, function(x) !is.null(infl[[x]]), logical(1))]

  if (length(missing_fields) > 0L) {
    stop(
      sprintf(
        "Influence analysis object is missing required field(s): %s.",
        paste(missing_fields, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  keep <- !is.na(infl$studlab) &
    infl$studlab != " " &
    !is.na(infl$TE) &
    !is.na(infl$lower) &
    !is.na(infl$upper)

  if (!any(keep)) {
    stop(
      "No valid leave-one-out influence results available to tabulate.",
      call. = FALSE
    )
  }

  is_prop <- inherits(object, "meta_prop")
  is_ratio <- inherits(object, "meta_ratio")

  if (is_prop) {
    est <- round(.backtransform_prop(infl$TE[keep], object$sm) * 100, 2)
    lower <- round(.backtransform_prop(infl$lower[keep], object$sm) * 100, 2)
    upper <- round(.backtransform_prop(infl$upper[keep], object$sm) * 100, 2)
  } else if (is_ratio) {
    est <- round(exp(infl$TE[keep]), 2)
    lower <- round(exp(infl$lower[keep]), 2)
    upper <- round(exp(infl$upper[keep]), 2)
  } else {
    est <- round(infl$TE[keep], 2)
    lower <- round(infl$lower[keep], 2)
    upper <- round(infl$upper[keep], 2)
  }

  df <- tibble::tibble(
    Study = infl$studlab[keep],
    `Estimate [95% CI]` = paste0(est, " [", lower, " \u2013 ", upper, "]")
  )

  i2_col <- "I\u00b2 (% variability)"
  tau2_col <- "Tau\u00b2"

  if (isTRUE(include_heterogeneity)) {
    if (!is.null(infl$I2)) {
      df[[i2_col]] <- vapply(infl$I2[keep], .format_i2, numeric(1))
    }

    if (!is.null(infl$tau2)) {
      df[[tau2_col]] <- round(infl$tau2[keep], 4)
    }
  }

  col_label <- switch(object$measure,
    Proportion = "Pooled Proportion (%)",
    "Mean Difference" = "Mean Difference [95% CI]",
    SMD = "SMD [95% CI]",
    OR = "Odds Ratio [95% CI]",
    RR = "Risk Ratio [95% CI]",
    HR = "Hazard Ratio [95% CI]",
    "Estimate [95% CI]"
  )

  k <- nrow(df)
  tbl_title <- if (!is.null(title)) {
    title
  } else {
    sprintf(
      "Leave-one-out influence analysis (k = %d stud%s)",
      k,
      if (k == 1L) "y" else "ies"
    )
  }

  gt_tbl <- gt::gt(df) |>
    gt::tab_header(title = tbl_title) |>
    gt::cols_label(`Estimate [95% CI]` = col_label)

  if (isTRUE(include_heterogeneity) && i2_col %in% names(df)) {
    gt_tbl <- gt_tbl |>
      gt::tab_footnote(
        footnote = .i2_footnote,
        locations = gt::cells_column_labels(
          columns = tidyselect::all_of(i2_col)
        )
      )
  }

  if (identical(save_as, "viewer")) {
    print(gt_tbl)
    return(invisible(gt_tbl))
  }

  ext <- switch(save_as,
    docx = "docx",
    pdf = "pdf"
  )

  if (is.null(filename)) {
    filename <- file.path(
      tempdir(),
      paste0(
        "table_influence_",
        format(Sys.time(), "%Y%m%d%H%M%S"),
        ".",
        ext
      )
    )
  }

  gt::gtsave(gt_tbl, filename = filename)
  message("Table saved to: ", normalizePath(filename, mustWork = FALSE))

  invisible(gt_tbl)
}
