#' Baujat plot
#'
#' Displays each study's contribution to overall heterogeneity (x-axis) versus
#' its influence on the pooled estimate (y-axis). Studies exceeding a threshold
#' on either axis are labelled automatically to reduce overplotting.
#'
#' @param object A \code{meta_prop}, \code{meta_ratio}, or \code{meta_mean}
#'   object.
#' @param title Optional character string for the plot title. If \code{NULL}
#'   (default), \code{"Baujat Plot"} is used. Set to \code{""} to suppress.
#' @param save_as One of \code{"viewer"} (default), \code{"pdf"},
#'   \code{"png"}, or \code{"tiff"}.
#' @param filename Optional file name for export.
#' @param width Width in inches (default 10).
#' @param height Height in inches (default 8).
#' @param label_threshold Numeric. A study is labelled if its x or y value
#'   exceeds \code{mean + label_threshold * sd} on that axis. Default
#'   \code{1.0}; increase for fewer labels.
#' @param ... Currently unused; reserved for future arguments.
#'
#' @return Invisibly returns a data frame with columns \code{studlab},
#'   \code{het_contribution}, and \code{influence}.
#'
#' @examples
#' \donttest{
#' data(dat_bcg, package = "metapropul")
#' result <- meta_prop(
#'   data = dat_bcg, event = "tpos", n = "npos",
#'   studylab = "author"
#' )
#' plot_baujat(result)
#' plot_baujat(result, title = "BCG vaccine \u2014 Baujat plot")
#' }
#'
#' @importFrom graphics abline axis grid par plot text
#' @importFrom grDevices adjustcolor
#' @importFrom stats sd
#' @export
plot_baujat <- function(object,
                        title = NULL,
                        save_as = c("viewer", "pdf", "png", "tiff"),
                        filename = NULL,
                        width = 10,
                        height = 8,
                        label_threshold = 1.0,
                        ...) {
  save_as <- match.arg(save_as)

  if (!inherits(object, c("meta_prop", "meta_ratio", "meta_mean"))) {
    stop("Only supports meta_prop, meta_ratio, or meta_mean objects.",
      call. = FALSE
    )
  }

  m <- object$meta
  if (!inherits(m, "meta")) {
    stop("object$meta must be of class 'meta'.", call. = FALSE)
  }

  infl <- tryCatch(
    meta::metainf(m, pooled = "random"),
    error = function(e) {
      stop("Could not compute leave-one-out estimates: ", e$message, call. = FALSE)
    }
  )

  k <- length(m$studlab)
  loo_estimates <- infl$TE[2:(k + 1L)]

  x_vals <- m$w.random * (m$TE - m$TE.random)^2
  y_vals <- (m$TE.random - loo_estimates)^2

  het_thresh <- mean(x_vals, na.rm = TRUE) +
    label_threshold * stats::sd(x_vals, na.rm = TRUE)
  inf_thresh <- mean(y_vals, na.rm = TRUE) +
    label_threshold * stats::sd(y_vals, na.rm = TRUE)
  label_vec <- x_vals > het_thresh | y_vals > inf_thresh

  # -- Device -------------------------------------------------------------------
  if (save_as != "viewer") {
    if (is.null(filename)) {
      ext <- switch(save_as,
        pdf = "pdf",
        png = "png",
        tiff = "tiff"
      )
      filename <- file.path(tempdir(), paste0(
        "baujat_plot_", format(Sys.time(), "%Y%m%d%H%M%S"), ".", ext
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

  # -- Draw ---------------------------------------------------------------------
  old_scipen <- getOption("scipen")
  on.exit(options(scipen = old_scipen), add = TRUE)
  options(scipen = 999)

  plot_title <- if (is.null(title)) "Baujat Plot" else title

  graphics::plot(
    x_vals, y_vals,
    pch = 19,
    col = grDevices::adjustcolor("steelblue", alpha.f = 0.7),
    cex = 0.9,
    xlab = "Contribution to overall heterogeneity",
    ylab = "Influence on overall result",
    main = plot_title,
    las = 1,
    yaxt = "n",
    panel.first = graphics::grid(
      lty = "dashed",
      col = grDevices::adjustcolor("grey70", 0.6)
    )
  )

  y_ticks <- graphics::axTicks(2)
  y_labels <- format(y_ticks, scientific = FALSE)
  max_nchar <- max(nchar(y_labels))
  left_mar <- max(4.5, 3 + max_nchar * 0.25)
  op_mar <- graphics::par(mar = c(5, left_mar, 4, 2) + 0.1)
  on.exit(graphics::par(op_mar), add = TRUE)
  graphics::axis(2, at = y_ticks, labels = y_labels, las = 1)

  graphics::abline(
    v = mean(x_vals, na.rm = TRUE),
    h = mean(y_vals, na.rm = TRUE),
    lty = 2, col = "grey50"
  )

  if (any(label_vec, na.rm = TRUE)) {
    graphics::text(
      x      = x_vals[label_vec],
      y      = y_vals[label_vec],
      labels = m$studlab[label_vec],
      pos    = 4,
      cex    = 0.75,
      offset = 0.4
    )
  }

  if (save_as != "viewer") {
    message(sprintf(
      "Baujat plot saved to: %s",
      normalizePath(filename, mustWork = FALSE)
    ))
  } else {
    message("Baujat plot displayed in Viewer. Use save_as = 'pdf', 'png', or 'tiff' to export.")
  }

  invisible(data.frame(
    studlab          = m$studlab,
    het_contribution = x_vals,
    influence        = y_vals
  ))
}
