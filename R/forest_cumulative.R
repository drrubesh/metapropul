#' Cumulative forest plot
#'
#' Produces a cumulative forest plot from a \code{meta_ratio},
#' \code{meta_mean}, or \code{meta_prop} object. Each row shows the pooled
#' estimate after sequentially adding one more study in the order supplied.
#'
#' \strong{Study ordering:} Sort your data by publication year before fitting
#' to show when evidence first became conclusive:
#' \preformatted{
#' dat <- dat[order(dat$year), ]
#' result <- meta_ratio(data = dat, ...)
#' forest_cumulative(result)
#' }
#'
#' @param object A \code{meta_ratio}, \code{meta_mean}, or \code{meta_prop}
#'   object.
#' @param title Optional character string printed above the plot. If
#'   \code{NULL} (default), an auto-constructed title is used. Set to
#'   \code{""} to suppress.
#' @param save_as One of \code{"viewer"} (default), \code{"pdf"},
#'   \code{"png"}, or \code{"tiff"}.
#' @param filename Optional file path. If \code{NULL} and
#'   \code{save_as != "viewer"}, a timestamped file is created in
#'   \code{tempdir()}.
#' @param layout Forest plot layout passed to \code{meta::forest()}. One of
#'   \code{"RevMan5"} (default), \code{"JAMA"}, \code{"BMJ"}, or
#'   \code{"meta"}.
#' @param width Optional plot width in inches (overrides auto-sizing).
#' @param height Optional plot height in inches (overrides auto-sizing).
#' @param ... Additional arguments passed to \code{meta::forest()}.
#'
#' @return Invisibly returns \code{TRUE}.
#'
#' @examples
#' \donttest{
#' data(dat_bcg, package = "metapropul")
#' dat_bcg <- dat_bcg[order(dat_bcg$year), ]
#' result <- meta_prop(
#'   data = dat_bcg, event = "tpos", n = "npos",
#'   studylab = "author"
#' )
#' forest_cumulative(result)
#' forest_cumulative(result, title = "BCG vaccine -- cumulative evidence")
#' }
#'
#' @export
forest_cumulative <- function(object,
                              title = NULL,
                              layout = "RevMan5",
                              save_as = c("viewer", "pdf", "png", "tiff"),
                              filename = NULL,
                              width = NULL,
                              height = NULL,
                              ...) {
  save_as <- match.arg(save_as)

  if (!inherits(object, c("meta_ratio", "meta_mean", "meta_prop"))) {
    stop("Only supports meta_ratio, meta_mean, or meta_prop objects.",
      call. = FALSE
    )
  }

  meta_obj <- object$meta
  if (!inherits(meta_obj, "meta")) {
    stop("Meta-analysis object not found in 'meta' field.", call. = FALSE)
  }

  cum_obj <- tryCatch(
    meta::metacum(meta_obj),
    error = function(e) {
      stop("Cumulative meta-analysis failed: ", e$message, call. = FALSE)
    }
  )

  k <- length(cum_obj$studlab)

  sizing <- .auto_plot_sizing(k,
    height = height, width = width,
    type = "ratio"
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
      "cumulative_meta_plot_", format(Sys.time(), "%Y%m%d%H%M%S"), ".", ext
    ))
  }
  .forest_open(save_as, filename, width, height)
  if (save_as != "viewer") on.exit(grDevices::dev.off(), add = TRUE)

  # -- Plot ---------------------------------------------------------------------
  is_prop <- inherits(object, "meta_prop")
  plot_title <- if (is.null(title)) {
    sprintf(
      "Cumulative meta-analysis - %s (k\u00a0=\u00a0%d)",
      object$measure, k
    )
  } else {
    title
  }

  forest_args <- list(
    x        = cum_obj,
    layout   = tolower(layout),
    fontsize = fontsize,
    xlab     = if (is_prop) "Proportion (%)" else NULL,
    pscale   = if (is_prop) 100 else 1
  )
  do.call(meta::forest, c(forest_args, list(...)))

  .forest_add_title(plot_title)
  .forest_close(save_as, filename, k)
  invisible(TRUE)
}
