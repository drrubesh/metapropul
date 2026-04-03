#' DOI plot for publication bias (small meta-analyses)
#'
#' Displays a DOI plot and LFK index using \code{metasens::doiplot()}.
#' Recommended for meta-analyses with fewer than 10 studies, where Egger's
#' and Begg's tests have low power. For larger analyses, use
#' \code{publication_bias()} instead.
#'
#' @param object A \code{meta_ratio}, \code{meta_mean}, or \code{meta_prop}
#'   object.
#' @param title Optional character string for the plot title. If \code{NULL}
#'   (default), an auto-constructed title is used. Set to \code{""} to
#'   suppress.
#' @param save_as One of \code{"viewer"} (default), \code{"pdf"},
#'   \code{"png"}, or \code{"tiff"}.
#' @param filename Optional file path. If \code{NULL} and
#'   \code{save_as != "viewer"}, a timestamped file is created in
#'   \code{tempdir()}.
#' @param width,height Plot dimensions in inches (default 7\,x\,7).
#' @param ... Additional arguments passed to \code{metasens::doiplot()}.
#'
#' @return Invisibly returns \code{NULL}.
#'
#' @examples
#' \donttest{
#' data(dat_bcg, package = "metapropul")
#' # Use only first 9 studies so k < 10
#' small <- dat_bcg[1:9, ]
#' result <- meta_prop(
#'   data = small, event = "tpos", n = "npos",
#'   studylab = "author"
#' )
#' doi_plot(result)
#' doi_plot(result, title = "BCG vaccine (small sample) -- DOI plot")
#' }
#'
#' @importFrom graphics par
#' @export
doi_plot <- function(object,
                     title = NULL,
                     save_as = c("viewer", "pdf", "png", "tiff"),
                     filename = NULL,
                     width = 7,
                     height = 7,
                     ...) {
  save_as <- match.arg(save_as)

  if (!requireNamespace("metasens", quietly = TRUE)) {
    stop("The 'metasens' package is required.", call. = FALSE)
  }

  if (!inherits(object, c("meta_ratio", "meta_mean", "meta_prop"))) {
    stop("Only supports meta_ratio, meta_mean, or meta_prop objects.",
      call. = FALSE
    )
  }

  meta_obj <- object$meta
  k <- meta_obj$k

  message("\nDOI Plot for Publication Bias")
  message("--------------------------------")
  message("Total studies included: ", k)

  if (k >= 10) {
    message("Note: DOI plots are primarily used for meta-analyses with fewer than 10 studies.")
    message("Use publication_bias() for larger analyses.")
    return(invisible(NULL))
  }

  # -- Device -------------------------------------------------------------------
  if (save_as != "viewer") {
    if (is.null(filename)) {
      ext <- switch(save_as,
        pdf = "pdf",
        png = "png",
        tiff = "tiff"
      )
      filename <- file.path(tempdir(), paste0(
        "doi_plot_", format(Sys.time(), "%Y%m%d%H%M%S"), ".", ext
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
    on.exit(grDevices::dev.off(), add = TRUE)
  }

  op <- graphics::par(no.readonly = TRUE)
  on.exit(graphics::par(op), add = TRUE)
  graphics::par(mar = c(5, 5, 4, 2))

  tryCatch(
    metasens::doiplot(meta_obj$TE, meta_obj$seTE,
      xlab = "Effect Size", lfkindex = TRUE, ...
    ),
    error = function(e) message("Failed to generate DOI plot: ", e$message)
  )

  # Title via mtext so it doesn't interfere with doiplot's own layout
  plot_title <- if (is.null(title)) {
    sprintf(
      "DOI plot - %s (k\u00a0=\u00a0%d stud%s)",
      object$measure, k, if (k == 1L) "y" else "ies"
    )
  } else {
    title
  }
  if (nzchar(plot_title)) {
    graphics::mtext(plot_title, side = 3, line = 1, font = 2, cex = 0.9)
  }

  # -- Close ---------------------------------------------------------------------
  if (save_as != "viewer") {
    message(sprintf(
      "DOI plot saved to: %s",
      normalizePath(filename, mustWork = FALSE)
    ))
  } else {
    message("DOI plot displayed in Viewer. Use save_as = 'pdf', 'png', or 'tiff' to export.")
  }

  invisible(NULL)
}
