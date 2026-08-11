#' Summary table for meta-analysis results
#'
#' Produces a publication-ready table from a supported metapropul
#' meta-analysis object. Includes study-level
#' estimates, a pooled row, and a footnote explaining I\eqn{^2}.
#'
#' @param meta_result A supported metapropul meta-analysis object.
#' @param title Optional character string for the table title. No title is
#'   added when `NULL` (the default).
#' @param save_as One of \code{"viewer"} (default), \code{"docx"} (Word), or
#'   \code{"pdf"}.
#' @param filename Optional file path. If \code{NULL}, a timestamped file is
#'   created in \code{tempdir()}.
#'
#' @return A \code{gt} table (invisibly when saving to file).
#'
#' @examples
#' \donttest{
#' data(dat_bcg, package = "metapropul")
#' result <- meta_prop(
#'   data = dat_bcg, event = "tpos", n = "npos",
#'   studylab = "author"
#' )
#' table_meta(result)
#' }
#'
#' @importFrom dplyr bind_rows
#' @importFrom tibble tibble
#' @export
table_meta <- function(meta_result,
                       title = NULL,
                       save_as = c("viewer", "docx", "pdf"),
                       filename = NULL) {
  save_as <- match.arg(save_as)

  if (!inherits(meta_result, c("meta_ratio", "meta_mean", "meta_prop",
      "meta_generic", "meta_cor", "meta_rate"))) {
    stop(
      "Only supports metapropul meta-analysis objects.",
      call. = FALSE
    )
  }

  gt_tbl <- if (inherits(meta_result, "meta_ratio")) {
    .table_meta_ratio(meta_result, title)
  } else if (inherits(meta_result, "meta_mean")) {
    .table_meta_mean(meta_result, title)
  } else if (inherits(meta_result, "meta_prop")) {
    .table_meta_prop(meta_result, title)
  } else {
    .table_meta_additional(meta_result, title)
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
      paste0("table_meta_", format(Sys.time(), "%Y%m%d%H%M%S"), ".", ext)
    )
  }

  gt::gtsave(gt_tbl, filename = filename)
  message("Table saved to: ", normalizePath(filename, mustWork = FALSE))
  invisible(gt_tbl)
}

#' @keywords internal
.table_meta_additional <- function(meta_result, title = NULL) {
  studies <- meta_result$table
  pooled <- meta_result$meta.summary
  display <- tibble::tibble(
    Study = c(studies$Study, "Pooled"),
    `Weight (%)` = c(studies$weight, NA_real_),
    `Estimate [95% CI]` = c(
      sprintf("%.3f [%.3f, %.3f]", studies$Estimate, studies$lower,
        studies$upper),
      sprintf("%.3f [%.3f, %.3f]", pooled$Estimate, pooled$lower,
        pooled$upper)
    )
  )
  gt::gt(display) |>
    .gt_optional_title(title) |>
    gt::fmt_number(columns = "Weight (%)", decimals = 1) |>
    gt::tab_style(style = gt::cell_text(weight = "bold"),
      locations = gt::cells_body(rows = Study == "Pooled")) |>
    gt::tab_source_note(.i2_footnote)
}

# -- Shared helpers ------------------------------------------------------------

.i2_footnote <- paste0(
  "I\u00b2 = proportion of total observed variability attributable to ",
  "between-study heterogeneity. Not a significance test; magnitude depends ",
  "on study precision and number of studies."
)

# Add a heading only when the caller explicitly requests one.
#' @keywords internal
.gt_optional_title <- function(table, title = NULL) {
  if (!is.null(title) && length(title) == 1L && nzchar(title)) {
    gt::tab_header(table, title = title)
  } else {
    table
  }
}

.pooled_vals <- function(m, model) {
  if (identical(model, "random")) {
    list(est = m$TE.random, lo = m$lower.random, hi = m$upper.random)
  } else {
    list(est = m$TE.common, lo = m$lower.common, hi = m$upper.common)
  }
}

# -- .table_meta_ratio ---------------------------------------------------------
#' @noRd
.table_meta_ratio <- function(meta_result, title = NULL) {
  m <- meta_result$meta
  tbl <- meta_result$table
  k <- nrow(tbl)

  col_label <- switch(meta_result$measure,
    OR = "Odds Ratio [95% CI]",
    RR = "Risk Ratio [95% CI]",
    HR = "Hazard Ratio [95% CI]",
    "Effect [95% CI]"
  )

  df <- tibble::tibble(
    Study = tbl$Study,
    Events = if (!is.null(m$event.e)) {
      paste0(m$event.e, "/", m$n.e, " vs ", m$event.c, "/", m$n.c)
    } else {
      NA_character_
    },
    `Weight (%)` = round(tbl$weight, 1),
    `Estimate [95% CI]` = paste0(
      round(tbl$Estimate, 2), " [",
      round(tbl$lower, 2), " \u2013 ",
      round(tbl$upper, 2), "]"
    )
  )

  pv <- .pooled_vals(m, meta_result$model)

  pooled_row <- tibble::tibble(
    Study = "Pooled",
    Events = "",
    `Weight (%)` = NA_real_,
    `Estimate [95% CI]` = paste0(
      round(exp(pv$est), 2), " [",
      round(exp(pv$lo), 2), " \u2013 ",
      round(exp(pv$hi), 2), "]",
      "  (I\u00b2\u00a0=\u00a0", .format_i2(m$I2), "%)"
    )
  )

  dplyr::bind_rows(df, pooled_row) |>
    gt::gt() |>
    .gt_optional_title(title) |>
    gt::cols_label(`Estimate [95% CI]` = col_label) |>
    gt::tab_style(
      style = gt::cell_text(weight = "bold"),
      locations = gt::cells_body(rows = Study == "Pooled")
    ) |>
    gt::tab_footnote(
      footnote = .i2_footnote,
      locations = gt::cells_body(
        columns = `Estimate [95% CI]`,
        rows = Study == "Pooled"
      )
    )
}

# -- .table_meta_mean ----------------------------------------------------------
#' @noRd
.table_meta_mean <- function(meta_result, title = NULL) {
  m <- meta_result$meta
  tbl <- meta_result$table
  k <- nrow(tbl)

  col_label <- if (identical(meta_result$measure, "SMD")) {
    "SMD [95% CI]"
  } else {
    "Mean Difference [95% CI]"
  }

  has_arms <- !is.null(m$mean.e) && !is.null(m$sd.e)
  has_n <- !is.null(m$n.e) && !is.null(m$n.c)

  df <- tibble::tibble(
    Study = tbl$Study,
    `Mean (SD)` = if (has_arms) {
      paste0(
        round(m$mean.e, 2), " (", round(m$sd.e, 2), ") vs ",
        round(m$mean.c, 2), " (", round(m$sd.c, 2), ")"
      )
    } else {
      NA_character_
    },
    Total = if (has_n) m$n.e + m$n.c else NA_real_,
    `Weight (%)` = round(tbl$weight, 1),
    `Estimate [95% CI]` = paste0(
      round(tbl$Estimate, 2), " [",
      round(tbl$lower, 2), " \u2013 ",
      round(tbl$upper, 2), "]"
    )
  )

  pv <- .pooled_vals(m, meta_result$model)

  pooled_row <- tibble::tibble(
    Study = "Pooled",
    `Mean (SD)` = "",
    Total = NA_real_,
    `Weight (%)` = NA_real_,
    `Estimate [95% CI]` = paste0(
      round(pv$est, 2), " [",
      round(pv$lo, 2), " \u2013 ",
      round(pv$hi, 2), "]",
      "  (I\u00b2\u00a0=\u00a0", .format_i2(m$I2), "%)"
    )
  )

  dplyr::bind_rows(df, pooled_row) |>
    gt::gt() |>
    .gt_optional_title(title) |>
    gt::cols_label(`Estimate [95% CI]` = col_label) |>
    gt::tab_style(
      style = gt::cell_text(weight = "bold"),
      locations = gt::cells_body(rows = Study == "Pooled")
    ) |>
    gt::tab_footnote(
      footnote = .i2_footnote,
      locations = gt::cells_body(
        columns = `Estimate [95% CI]`,
        rows = Study == "Pooled"
      )
    )
}

# -- .table_meta_prop ----------------------------------------------------------
#' @noRd
.table_meta_prop <- function(meta_result, title = NULL) {
  m <- meta_result$meta
  tbl <- meta_result$table
  s <- meta_result$meta.summary
  k <- nrow(tbl)

  df <- tibble::tibble(
    Study = tbl$Study,
    Events = m$event,
    Total = m$n,
    `Weight (%)` = round(tbl$weight, 1),
    `Proportion [95% CI]` = paste0(
      round(tbl$Proportion, 1), "% [",
      round(tbl$lower, 1), " \u2013 ",
      round(tbl$upper, 1), "]"
    )
  )

  pooled_row <- tibble::tibble(
    Study = "Pooled",
    Events = NA_real_,
    Total = NA_real_,
    `Weight (%)` = NA_real_,
    `Proportion [95% CI]` = paste0(
      round(s$Estimate, 1), "% [",
      round(s$lower, 1), " \u2013 ",
      round(s$upper, 1), "]",
      "  (I\u00b2\u00a0=\u00a0", .format_i2(s$I2), "%)"
    )
  )

  dplyr::bind_rows(df, pooled_row) |>
    gt::gt() |>
    .gt_optional_title(title) |>
    gt::tab_style(
      style = gt::cell_text(weight = "bold"),
      locations = gt::cells_body(rows = Study == "Pooled")
    ) |>
    gt::tab_footnote(
      footnote = .i2_footnote,
      locations = gt::cells_body(
        columns = `Proportion [95% CI]`,
        rows = Study == "Pooled"
      )
    )
}
