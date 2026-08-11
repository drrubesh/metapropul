#' Leave-one-out heterogeneity plot
#'
#' Plots I\eqn{^2} or Tau\eqn{^2} from a leave-one-out meta-analysis to show
#' how much each study contributes to between-study heterogeneity.
#'
#' \strong{Interpreting I\eqn{^2}:} I\eqn{^2} is the proportion of total
#' observed variability attributable to between-study heterogeneity -- not a
#' test for it, and not a fixed-threshold measure of its magnitude. A high
#' I\eqn{^2} does not automatically mean heterogeneity is clinically important;
#' use Tau\eqn{^2} and the prediction interval for that judgement.
#'
#' @param object A \code{meta_prop}, \code{meta_ratio}, or \code{meta_mean}
#'   object.
#' @param stat \code{"I2"} (default) or \code{"tau2"}.
#' @param title Optional character string for the plot title. No title is
#'   drawn when `NULL` (the default).
#' @param save_as One of \code{"viewer"} (default), \code{"pdf"},
#'   \code{"png"}, or \code{"tiff"}.
#' @param filename Optional file name for saving.
#' @param width,height Export dimensions in inches. Default width is 10; height
#'   is chosen automatically if \code{NULL}.
#' @param ... Additional arguments passed to \code{graphics::plot()}.
#'
#' @return Invisibly returns \code{TRUE}.
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
#' plot_heterogeneity(result)
#' plot_heterogeneity(result, stat = "tau2")
#' }
#'
#' @importFrom graphics axis box grid par plot
#' @export
plot_heterogeneity <- function(object,
                               stat = c("I2", "tau2"),
                               title = NULL,
                               save_as = c("viewer", "pdf", "png", "tiff"),
                               filename = NULL,
                               width = 10,
                               height = NULL,
                               ...) {
  stat <- match.arg(stat)
  save_as <- match.arg(save_as)

  if (!inherits(object, c("meta_prop", "meta_ratio", "meta_mean"))) {
    stop(
      "Only supports meta_prop, meta_ratio, or meta_mean objects.",
      call. = FALSE
    )
  }

  infl_obj <- object$influence.meta

  if (is.null(infl_obj) || !inherits(infl_obj, "metainf")) {
    stop(
      "No valid leave-one-out object found in $influence.meta for plotting ",
      "heterogeneity.",
      call. = FALSE
    )
  }

  if (is.null(infl_obj$studlab)) {
    stop(
      "Study labels are missing from the leave-one-out object.",
      call. = FALSE
    )
  }

  study_labels <- infl_obj$studlab

  if (identical(stat, "I2")) {
    if (is.null(infl_obj$I2)) {
      stop(
        "I2 values are not available in the leave-one-out object.",
        call. = FALSE
      )
    }
    het_vals <- vapply(infl_obj$I2, .format_i2, numeric(1))
  } else {
    if (is.null(infl_obj$tau2)) {
      stop(
        "Tau2 values are not available in the leave-one-out object.",
        call. = FALSE
      )
    }
    het_vals <- infl_obj$tau2
  }

  keep <- !is.na(het_vals) & !is.na(study_labels)

  if (!any(keep)) {
    stop("No valid heterogeneity estimates to plot.", call. = FALSE)
  }

  het_vals <- het_vals[keep]
  study_labels <- study_labels[keep]

  k <- length(het_vals)

  if (is.null(height)) {
    height <- min(45, max(12, 0.35 * k))
  }

  plot_title <- title

  if (!identical(save_as, "viewer")) {
    if (is.null(filename)) {
      ext <- switch(
        save_as,
        pdf = "pdf",
        png = "png",
        tiff = "tiff"
      )
      filename <- file.path(
        tempdir(),
        paste0(
          "heterogeneity_plot_",
          format(Sys.time(), "%Y%m%d%H%M%S"),
          ".",
          ext
        )
      )
    }

    if (identical(save_as, "pdf")) {
      grDevices::pdf(filename, width = width, height = height)
    } else if (identical(save_as, "png")) {
      grDevices::png(
        filename,
        width = width,
        height = height,
        units = "in",
        res = 300
      )
    } else if (identical(save_as, "tiff")) {
      tiff_args <- list(
        filename = filename,
        width = width,
        height = height,
        units = "in",
        res = 300
      )
      if (!identical(Sys.info()[["sysname"]], "Darwin")) {
        tiff_args$compression <- "lzw"
      }
      do.call(grDevices::tiff, tiff_args)
    }

    on.exit(grDevices::dev.off(), add = TRUE)
  }

  op <- graphics::par(mgp = c(7, 0.5, 0))
  on.exit(graphics::par(op), add = TRUE)

  ylim_use <- if (identical(stat, "I2")) {
    c(0, 100)
  } else {
    rng <- range(het_vals, na.rm = TRUE)
    upper_lim <- if (rng[2] <= 0) 1 else rng[2] * 1.1
    c(0, upper_lim)
  }

  graphics::plot(
    x = seq_along(het_vals),
    y = het_vals,
    type = "b",
    pch = 19,
    lwd = 2,
    main = plot_title,
    xlab = "Study omitted",
    ylab = if (identical(stat, "I2")) {
      expression(I^2 ~ "(%)")
    } else {
      expression(tau^2)
    },
    xaxt = "n",
    ylim = ylim_use,
    cex.main = 0.85,
    ...
  )

  label_spacing <- if (k > 50L) 5L else 1L

  graphics::axis(
    side = 1,
    at = seq.int(1L, k, by = label_spacing),
    labels = study_labels[seq.int(1L, k, by = label_spacing)],
    las = 2,
    cex.axis = 0.7
  )
  graphics::axis(2)
  graphics::grid()
  graphics::box()

  if (!identical(save_as, "viewer")) {
    message(
      "Heterogeneity plot saved to: ",
      normalizePath(filename, mustWork = FALSE)
    )
  } else {
    message(
      "Heterogeneity plot displayed in Viewer. ",
      "Use save_as = 'pdf', 'png', or 'tiff' to export."
    )
  }

  invisible(TRUE)
}
