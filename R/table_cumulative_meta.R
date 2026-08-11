#' Cumulative meta-analysis table
#'
#' Produces a step-by-step table of cumulative pooled estimates, adding one
#' study at a time in the order they appear in the data.
#'
#' \strong{Study ordering:} Sort your data by year before fitting the model
#' for a meaningful cumulative analysis:
#' \preformatted{
#' dat <- dat[order(dat$year), ]
#' result <- meta_ratio(data = dat, ...)
#' table_cumulative_meta(result)
#' }
#'
#' @param object A \code{meta_ratio}, \code{meta_mean}, or \code{meta_prop}
#'   object.
#' @param title Optional character string for the table title. No title is
#'   added when `NULL` (the default).
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
#' dat_bcg <- dat_bcg[order(dat_bcg$year), ]
#' result <- meta_prop(
#'   data = dat_bcg,
#'   event = "tpos",
#'   n = "npos",
#'   studylab = "author"
#' )
#' table_cumulative_meta(result)
#' }
#'
#' @importFrom tibble tibble
#' @importFrom tidyselect all_of
#' @export
table_cumulative_meta <- function(object,
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

  meta_obj <- object$meta

  if (!inherits(meta_obj, "meta")) {
    stop("meta field not found in object.", call. = FALSE)
  }

  cum <- meta::metacum(meta_obj)

  required_fields <- c("studlab", "TE", "lower", "upper")
  missing_fields <- required_fields[
    !vapply(required_fields, function(x) !is.null(cum[[x]]), logical(1))
  ]

  if (length(missing_fields) > 0L) {
    stop(
      sprintf(
        "Cumulative meta-analysis object is missing required field(s): %s.",
        paste(missing_fields, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  keep <- !is.na(cum$TE) &
    !is.na(cum$lower) &
    !is.na(cum$upper) &
    !is.na(cum$studlab)

  if (!any(keep)) {
    stop(
      "No valid cumulative meta-analysis results available to tabulate.",
      call. = FALSE
    )
  }

  is_prop <- inherits(object, "meta_prop")
  is_ratio <- inherits(object, "meta_ratio")

  if (is_prop) {
    est <- signif(.backtransform_prop(cum$TE[keep], object$sm) * 100, 3)
    lower <- signif(.backtransform_prop(cum$lower[keep], object$sm) * 100, 3)
    upper <- signif(.backtransform_prop(cum$upper[keep], object$sm) * 100, 3)
  } else if (is_ratio) {
    est <- signif(exp(cum$TE[keep]), 3)
    lower <- signif(exp(cum$lower[keep]), 3)
    upper <- signif(exp(cum$upper[keep]), 3)
  } else {
    est <- signif(cum$TE[keep], 3)
    lower <- signif(cum$lower[keep], 3)
    upper <- signif(cum$upper[keep], 3)
  }

  df <- tibble::tibble(
    Step = seq_len(sum(keep)),
    `Study Added` = cum$studlab[keep],
    `Estimate [95% CI]` = paste0(est, " [", lower, " \u2013 ", upper, "]")
  )

  i2_col <- "I\u00b2 (% variability)"
  tau2_col <- "Tau\u00b2"

  if (isTRUE(include_heterogeneity)) {
    if (!is.null(cum$I2)) {
      df[[i2_col]] <- vapply(cum$I2[keep], .format_i2, numeric(1))
    }

    if (!is.null(cum$tau2)) {
      df[[tau2_col]] <- round(cum$tau2[keep], 4)
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

  gt_tbl <- gt::gt(df) |>
    .gt_optional_title(title) |>
    gt::cols_label(
      Step = "Step",
      `Study Added` = "Study",
      `Estimate [95% CI]` = col_label
    ) |>
    gt::tab_style(
      style = gt::cell_text(weight = "bold"),
      locations = gt::cells_body(rows = nrow(df))
    )

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
        "table_cumulative_meta_",
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
