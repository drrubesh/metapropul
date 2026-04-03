#' Publication bias assessment
#'
#' Performs Egger's and Begg's tests, computes trim-and-fill, and optionally
#' displays one or more publication bias plots arranged in a grid automatically.
#'
#' @param object A meta-analysis object from \code{meta_ratio()},
#'   \code{meta_mean()}, or \code{meta_prop()}.
#' @param plot_method Character vector of plot methods. Any combination of
#'   \code{"original"}, \code{"trimfill"}, \code{"contour"},
#'   \code{"limitmeta"}. If \code{NULL} (default), no plot is produced.
#' @param title Optional character string used as the overall plot title
#'   (printed via \code{mtext()} above the grid). If \code{NULL} (default),
#'   each panel uses its own label. Set to \code{""} to suppress.
#' @param save_as \code{"viewer"} (default), \code{"pdf"}, \code{"png"}, or
#'   \code{"tiff"}.
#' @param filename Optional filename for export.
#' @param width,height Export dimensions in inches (default 10 x 8).
#'
#' @return Invisibly returns a list with Begg's test, Egger's test,
#'   trim-and-fill, and limit meta-analysis results where available.
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
#' publication_bias(result)
#' publication_bias(
#'   result,
#'   plot_method = c("original", "trimfill"),
#'   title = "BCG vaccine -- publication bias"
#' )
#' }
#'
#' @importFrom graphics mtext par
#' @export
publication_bias <- function(object,
                             plot_method = NULL,
                             title = NULL,
                             save_as = c("viewer", "pdf", "png", "tiff"),
                             filename = NULL,
                             width = 10,
                             height = 8) {
  save_as <- match.arg(save_as)

  if (!inherits(object, c("meta_prop", "meta_ratio", "meta_mean"))) {
    stop(
      "object must be from meta_prop(), meta_ratio(), or meta_mean().",
      call. = FALSE
    )
  }

  if (!requireNamespace("meta", quietly = TRUE)) {
    stop("The 'meta' package is required.", call. = FALSE)
  }
  if (!requireNamespace("metafor", quietly = TRUE)) {
    stop("The 'metafor' package is required.", call. = FALSE)
  }
  if (!requireNamespace("metasens", quietly = TRUE)) {
    stop("The 'metasens' package is required.", call. = FALSE)
  }

  meta_obj <- object$meta
  if (!inherits(meta_obj, "meta")) {
    stop("object does not contain a valid 'meta' component.", call. = FALSE)
  }

  k <- meta_obj$k
  is_prop <- inherits(object, "meta_prop")

  if (is_prop && !identical(object$sm, "PLOGIT")) {
    stop(
      "publication_bias() currently supports meta_prop objects only when sm = 'PLOGIT'.",
      call. = FALSE
    )
  }

  if (!is.numeric(k) || length(k) != 1L || is.na(k)) {
    stop("Could not determine the number of studies in object$meta.", call. = FALSE)
  }

  if (k < 10) {
    message("Publication bias tests are not recommended when k < 10 studies.")
    message("Consider using doi_plot() for smaller meta-analyses.")
    return(invisible(NULL))
  }

  results <- list()

  begg <- tryCatch(
    meta::metabias(meta_obj, method.bias = "rank"),
    error = function(e) NULL
  )

  egger <- tryCatch(
    meta::metabias(meta_obj, method.bias = "linreg"),
    error = function(e) NULL
  )

  results$begg <- begg
  results$egger <- egger

  if (!is.null(egger)) {
    egger_z <- egger$statistic
    egger_p <- egger$p.value
    egger_int <- tryCatch(egger$estimate[1], error = function(e) NA_real_)

    egger_interp <- if (egger_p < 0.05) {
      "suggests possible bias or small-study effects"
    } else if (egger_p < 0.10) {
      "borderline; interpret cautiously"
    } else {
      "no evidence of asymmetry detected"
    }

    message(sprintf(
      "Egger's test: z = %.2f, p = %.4f, intercept = %.3f -- %s",
      egger_z, egger_p, egger_int, egger_interp
    ))

    if (is_prop) {
      message("Note: Egger's test was run on the logit-transformed scale for proportion data.")
    }
  }

  if (!is.null(begg)) {
    begg_z <- begg$statistic
    begg_p <- begg$p.value

    begg_interp <- if (begg_p < 0.05) {
      "suggests rank asymmetry in the funnel plot"
    } else if (begg_p < 0.10) {
      "borderline; interpret cautiously"
    } else {
      "no evidence of rank asymmetry detected"
    }

    message(sprintf(
      "Begg's test (rank correlation): z = %.2f, p = %.4f -- %s",
      begg_z, begg_p, begg_interp
    ))
  }

  tf <- tryCatch(
    meta::trimfill(meta_obj),
    error = function(e) NULL
  )

  if (!is.null(tf)) {
    results$trimfill <- tf
    k_imputed <- tf$k0

    if (inherits(object, "meta_ratio")) {
      est_adj <- exp(tf$TE.random)
      lo_adj <- exp(tf$lower.random)
      hi_adj <- exp(tf$upper.random)

      measure_lbl <- switch(object$measure,
        OR = "OR",
        RR = "RR",
        HR = "HR",
        "Effect"
      )

      message(sprintf(
        "Trim-and-fill: %d studies imputed -- adjusted %s = %.2f [%.2f; %.2f]",
        k_imputed, measure_lbl, est_adj, lo_adj, hi_adj
      ))
    } else if (inherits(object, "meta_mean")) {
      mean_lbl <- if (!is.null(object$measure)) object$measure else "effect"

      message(sprintf(
        "Trim-and-fill: %d studies imputed -- adjusted %s = %.3f [%.3f; %.3f]",
        k_imputed, mean_lbl, tf$TE.random, tf$lower.random, tf$upper.random
      ))
    } else if (is_prop) {
      est_adj <- .backtransform_prop(tf$TE.random, object$sm) * 100
      lo_adj <- .backtransform_prop(tf$lower.random, object$sm) * 100
      hi_adj <- .backtransform_prop(tf$upper.random, object$sm) * 100

      message(sprintf(
        "Trim-and-fill: %d studies imputed -- adjusted proportion = %.2f%% [%.2f%%; %.2f%%]",
        k_imputed, est_adj, lo_adj, hi_adj
      ))
    }

    trim_interp <- if (k_imputed == 0) {
      "No asymmetry detected; trim-and-fill imputed 0 studies."
    } else if (k_imputed <= 3) {
      "Minimal asymmetry; a small number of studies were imputed."
    } else {
      "Meaningful asymmetry suggested; review the original estimate carefully."
    }

    message("Interpretation: ", trim_interp)
  }

  if (is_prop) {
    message("Note: For proportion outcomes, publication bias tests were run on the logit-transformed scale.")
  }

  if (!is.null(plot_method)) {
    plot_method <- tolower(gsub("countour", "contour", plot_method))
    plot_method <- match.arg(
      plot_method,
      choices = c("original", "trimfill", "contour", "limitmeta"),
      several.ok = TRUE
    )
    plot_method <- unique(plot_method)
    n_plots <- length(plot_method)

    op <- graphics::par(no.readonly = TRUE)
    on.exit(graphics::par(op), add = TRUE)

    if (!identical(save_as, "viewer")) {
      if (is.null(filename)) {
        ext <- switch(save_as,
          pdf = "pdf",
          png = "png",
          tiff = "tiff"
        )
        methods <- paste(plot_method, collapse = "_")
        filename <- file.path(
          tempdir(),
          paste0(
            "publication_bias_",
            methods,
            "_",
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

    mfrow <- if (n_plots == 1L) {
      c(1, 1)
    } else if (n_plots == 2L) {
      c(1, 2)
    } else if (n_plots == 3L) {
      c(1, 3)
    } else {
      c(2, 2)
    }

    graphics::par(mfrow = mfrow, oma = if (!is.null(title) && nzchar(title) && n_plots > 1L) c(0, 0, 3, 0) else c(0, 0, 0, 0))

    for (pm in plot_method) {
      if (identical(pm, "original")) {
        tryCatch(
          meta::funnel(meta_obj, main = "Funnel Plot"),
          error = function(e) message("Could not plot original funnel plot: ", e$message)
        )
      }

      if (identical(pm, "trimfill")) {
        if (!is.null(tf)) {
          tryCatch(
            meta::funnel(tf, main = "Trim-and-Fill Funnel"),
            error = function(e) message("Could not plot trim-and-fill funnel plot: ", e$message)
          )
        }
      }

      if (identical(pm, "contour")) {
        rma_obj <- tryCatch(
          metafor::rma.uni(yi = meta_obj$TE, sei = meta_obj$seTE, method = "REML"),
          error = function(e) NULL
        )

        if (!is.null(rma_obj)) {
          tryCatch(
            metafor::funnel(
              rma_obj,
              main = "Contour-Enhanced Funnel Plot",
              level = c(90, 95, 99),
              shade = c("white", "gray85", "gray70"),
              refline = 0,
              legend = TRUE
            ),
            error = function(e) {
              message("Could not plot contour-enhanced funnel plot: ", e$message)
            }
          )
        }
      }

      if (identical(pm, "limitmeta")) {
        lm_obj <- tryCatch(
          metasens::limitmeta(meta_obj),
          error = function(e) {
            message("limitmeta() failed: ", e$message)
            NULL
          }
        )

        if (!is.null(lm_obj)) {
          results$limitmeta <- lm_obj
          tryCatch(
            metasens::funnel.limitmeta(
              lm_obj,
              backtransf = TRUE,
              main = "Limit Meta-Analysis"
            ),
            error = function(e) {
              message("Could not plot limit meta-analysis funnel plot: ", e$message)
            }
          )
        }
      }
    }

    if (!is.null(title) && nzchar(title) && n_plots > 1L) {
      graphics::mtext(title, side = 3, line = 1, outer = TRUE, font = 2, cex = 0.95)
    }

    if (!identical(save_as, "viewer")) {
      message(
        "Publication bias plot saved to: ",
        normalizePath(filename, mustWork = FALSE)
      )
    } else {
      message(
        "Publication bias plot displayed in Viewer. ",
        "Use save_as = 'pdf', 'png', or 'tiff' to export."
      )
    }
  }

  invisible(results)
}
