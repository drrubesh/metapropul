#' Influence forest plot
#'
#' Draws a leave-one-out influence forest plot from a \code{meta_ratio},
#' \code{meta_mean}, or \code{meta_prop} object.
#'
#' @param object A \code{meta_ratio}, \code{meta_mean}, or \code{meta_prop}
#'   object.
#' @param title Optional character string printed above the plot. If
#'   \code{NULL} (default), an auto-constructed title is used. Set to
#'   \code{""} to suppress.
#' @param layout Layout style. One of \code{"RevMan5"} (default),
#'   \code{"JAMA"}, \code{"BMJ"}, or \code{"meta"}.
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
                             layout = "RevMan5",
                             save_as = c("viewer", "pdf", "png", "tiff"),
                             filename = NULL,
                             width = NULL,
                             height = NULL,
                             ...) {
  save_as <- match.arg(save_as)

  if (!inherits(object, c("meta_prop", "meta_ratio", "meta_mean"))) {
    stop("Object must be of class meta_prop, meta_ratio, or meta_mean.",
      call. = FALSE
    )
  }

  infl_obj <- if (inherits(object, "meta_prop")) {
    object$influence.meta
  } else {
    object$influence.analysis
  }

  if (is.null(infl_obj) || !inherits(infl_obj, "metainf")) {
    stop("No valid influence analysis found. Ensure the object was created with default settings.",
      call. = FALSE
    )
  }

  k <- length(infl_obj$studlab)
  sizing <- .auto_plot_sizing(k,
    height = height, width = width,
    type = "influence"
  )
  height <- sizing$height
  width <- sizing$width
  fontsize <- sizing$fontsize

  # -- Device -------------------------------------------------------------------
  if (is.null(filename) && save_as != "viewer") {
    ext <- switch(save_as,
      pdf = "pdf",
      png = "png",
      tiff = "tiff"
    )
    filename <- file.path(tempdir(), paste0(
      "influence_plot_", format(Sys.time(), "%Y%m%d%H%M%S"), ".", ext
    ))
  }

  if (save_as == "pdf") {
    grDevices::pdf(filename, width = width, height = height)
  } else if (save_as == "png") {
    grDevices::png(filename,
      width = width, height = height,
      units = "in", res = 300
    )
  } else if (save_as == "tiff") {
    tiff_args <- list(
      filename = filename, width = width, height = height,
      units = "in", res = 300
    )
    if (Sys.info()[["sysname"]] != "Darwin") {
      tiff_args$compression <- "lzw"
    }
    do.call(grDevices::tiff, tiff_args)
  }
  if (save_as != "viewer") on.exit(grDevices::dev.off(), add = TRUE)

  # -- Plot ---------------------------------------------------------------------
  is_prop <- inherits(object, "meta_prop")
  plot_title <- if (is.null(title)) {
    sprintf(
      "Leave-one-out influence analysis - %s (k\u00a0=\u00a0%d)",
      object$measure, k
    )
  } else {
    title
  }

  meta::forest(
    x                 = infl_obj,
    layout            = tolower(layout),
    smlab             = "Leave-One-Out Meta-Analysis",
    just.addcols      = "right",
    squaresize        = 0.5,
    col.bg            = "blue",
    col.border        = "blue",
    col.diamond       = "blue",
    col.diamond.lines = "blue",
    fontsize          = fontsize,
    fs.hetstat        = max(6, fontsize - 1L),
    xlab              = if (is_prop) "Proportion (%)" else NULL,
    pscale            = if (is_prop) 100 else 1,
    ...
  )

  .forest_add_title(plot_title)

  # -- Close ---------------------------------------------------------------------
  if (save_as != "viewer") {
    message(sprintf(
      "Influence plot saved to: %s",
      normalizePath(filename, mustWork = FALSE)
    ))
  } else {
    message("Influence plot displayed in Plots pane. Use save_as = 'pdf', 'png', or 'tiff' for publication-quality export.")
    if (k > 40) {
      message("Tip: export to PDF/PNG for large plots \u2014 Viewer margins may clip rows.")
    }
  }

  invisible(TRUE)
}
