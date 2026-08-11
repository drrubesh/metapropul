#' Influence forest plot
#'
#' Draws a leave-one-out influence forest plot from a \code{meta_ratio},
#' \code{meta_mean}, or \code{meta_prop} object.
#'
#' @param object A \code{meta_ratio}, \code{meta_mean}, or \code{meta_prop}
#'   object.
#' @param title Optional character string printed above the plot. No title is
#'   drawn when `NULL` (the default).
#' @param layout Layout style. One of \code{"meta"} (default),
#'   \code{"JAMA"}, \code{"BMJ"}, or \code{"meta"}.
#' @param prediction Logical; if \code{TRUE}, show prediction intervals.
#'   Default is \code{FALSE}.
#' @param save_as One of \code{"viewer"} (default), \code{"pdf"},
#'   \code{"png"}, or \code{"tiff"}.
#' @param filename Optional file path. If \code{NULL} and
#'   \code{save_as != "viewer"}, a timestamped file is created in
#'   \code{tempdir()}.
#' @param width Optional plot width in inches (overrides auto-sizing).
#' @param height Optional plot height in inches (overrides auto-sizing).
#' @param ... Additional arguments passed to \code{meta::forest()}.
#'
#' @return Invisibly returns \code{TRUE}.
#'
#' @examples
#' \donttest{
#' data(dat_bcg, package = "metapropul")
#' result <- meta_prop(
#'   data = dat_bcg, event = "tpos", n = "npos",
#'   studylab = "author"
#' )
#' forest_influence(result)
#' forest_influence(result, title = "BCG vaccine -- leave-one-out analysis")
#' }
#'
#' @export
forest_influence <- function(object,
                             title = NULL,
                             layout = "meta",
                             prediction = FALSE,
                             save_as = c("viewer", "pdf", "png", "tiff"),
                             filename = NULL,
                             width = NULL,
                             height = NULL,
                             ...) {
  save_as <- match.arg(save_as)

  if (!inherits(object, c("meta_prop", "meta_ratio", "meta_mean"))) {
    stop(
      "Object must be of class meta_prop, meta_ratio, or meta_mean.",
      call. = FALSE
    )
  }

  infl_obj <- object$influence.meta

  if (is.null(infl_obj) || !inherits(infl_obj, "metainf")) {
    stop(
      "No valid influence analysis found. Ensure the object contains ",
      "a raw 'metainf' object in $influence.meta.",
      call. = FALSE
    )
  }

  k <- length(infl_obj$studlab)
  sizing <- .auto_plot_sizing(
    k,
    height = height,
    width = width,
    type = "influence"
  )
  height <- sizing$height
  width <- sizing$width
  fontsize <- sizing$fontsize
  spacing <- sizing$spacing

  if (is.null(filename) && save_as != "viewer") {
    ext <- switch(
      save_as,
      pdf = "pdf",
      png = "png",
      tiff = "tiff"
    )
    filename <- file.path(
      tempdir(),
      paste0(
        "influence_plot_",
        format(Sys.time(), "%Y%m%d%H%M%S"),
        ".",
        ext
      )
    )
  }

  .forest_open(save_as, filename, width, height)
  if (save_as != "viewer") {
    on.exit(grDevices::dev.off(), add = TRUE)
  }

  is_prop <- inherits(object, "meta_prop")
  plot_title <- title

  # Temporary plotting copy:
  # keep raw metainf object intact in the result, but suppress
  # prediction intervals for plotting unless explicitly requested.
  plot_obj <- infl_obj

  if (!prediction) {
    plot_obj$prediction <- FALSE
    plot_obj$lower.predict <- rep(NA_real_, length(plot_obj$TE))
    plot_obj$upper.predict <- rep(NA_real_, length(plot_obj$TE))
    plot_obj$lower.predict.pooled <- NA_real_
    plot_obj$upper.predict.pooled <- NA_real_
    plot_obj$text.predict <- ""
  }

  meta::forest(
    x                 = plot_obj,
    layout            = layout,
    prediction        = prediction,
    print.pred        = prediction,
    smlab             = "Leave-One-Out Meta-Analysis",
    leftcols          = "studlab",
    leftlabs          = "Study",
    rightcols         = c("effect", "ci", "tau2", "tau", "I2"),
    rightlabs         = c(
      if (is_prop) "Proportion (%)" else object$measure,
      "95% CI", "Tau\u00b2", "Tau", "I\u00b2"
    ),
    just.addcols      = "right",
    squaresize        = 0.5,
    col.bg            = "blue",
    col.border        = "blue",
    col.diamond       = "blue",
    col.diamond.lines = "blue",
    fontsize          = fontsize,
    spacing           = spacing,
    fs.hetstat        = max(6, fontsize - 1L),
    xlab              = if (is_prop) "Proportion (%)" else NULL,
    pscale            = if (is_prop) 100 else 1,
    ...
  )

  .forest_add_title(plot_title)

  if (save_as != "viewer") {
    message(sprintf(
      "Influence plot saved to: %s",
      normalizePath(filename, mustWork = FALSE)
    ))
  } else {
    message(
      "Influence plot displayed in Plots pane. Use save_as = 'pdf', ",
      "'png', or 'tiff' for publication-quality export."
    )
    if (k > 40) {
      message(
        "Tip: export to PDF/PNG for large plots - Viewer margins may ",
        "clip rows."
      )
    }
  }

  invisible(TRUE)
}
