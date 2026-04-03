#' Internal helper: Auto-adjust plot size for meta-analysis forest plots
#'
#' @param k Number of studies.
#' @param height Optional fixed height in inches. Overrides auto-sizing.
#' @param width Optional fixed width in inches. Overrides auto-sizing.
#' @param type Plot type: one of \code{"ratio"}, \code{"mean"}, \code{"prop"},
#'   \code{"subgroup"}, \code{"influence"}, \code{"cumulative"}.
#'
#' @return A list with \code{height}, \code{width}, and \code{fontsize}.
#' @keywords internal
.auto_plot_sizing <- function(k, height = NULL, width = NULL, type = "ratio") {
  if (!is.numeric(k) || length(k) != 1 || k <= 0) {
    stop("k must be a positive number indicating the number of studies.")
  }
  # Fontsize: reduce gradually as study count grows
  fontsize <- if (k > 200) 7L else if (k > 100) 8L else if (k > 50) 9L else if (k > 20) 10L else 11L
  # Row height in inches — keeps each row ~14pt minimum
  row_h <- switch(as.character(fontsize),
    "11" = 0.22,
    "10" = 0.20,
    "9" = 0.18,
    "8" = 0.16,
    "7" = 0.14
  )
  # Height: overhead (headers, pooled row, het stats, axis) + per-row content.
  # Influence plots have more header rows so use a larger overhead.
  # Cap behaviour:
  #   - Standard plots: cap at 45in (meta::forest can corrupt very tall pages)
  #   - Influence plots: no cap — user explicitly chose a large k analysis;
  #     let the PDF be as tall as needed and warn to export rather than view.
  # Overhead: influence plots have more header rows than standard forest plots
  is_influence <- identical(type, "influence")
  overhead <- if (is_influence) 6.0 else 4.5
  auto_height <- max(5, overhead + row_h * k * 1.35)
  # No hard cap here — forest functions apply viewer-specific caps where needed
  # Note for large k is emitted by the calling function (context-aware)
  # Width selection by type:
  #   subgroup: needs most space (subgroup column + per-group het stats)
  #   prop:     needs more than ratio/mean (effect/CI values on right)
  #   mean:     needs more than ratio — arm-level Mean (SD)/total columns
  #             are wide; BMJ layout adds even more (override applied in
  #             forest_meta_mean when layout == "bmj")
  #   large k:  benefits from extra width regardless
  is_sub <- identical(type, "subgroup")
  is_prop <- identical(type, "prop")
  is_mean <- identical(type, "mean")
  is_large <- k > 50
  auto_width <- if (is_sub && is_large) {
    18
  } else if (is_sub) {
    16
  } else if (is_prop && is_large) {
    14
  } else if (is_large || is_prop) {
    12
  } else if (is_mean) {
    14
  } else {
    10
  }
  list(
    height   = if (is.null(height)) auto_height else height,
    width    = if (is.null(width)) auto_width else width,
    fontsize = fontsize
  )
}
