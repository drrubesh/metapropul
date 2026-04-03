#' Bubble plot for meta-regression
#'
#' Displays a bubble plot for a \code{meta_reg} object using
#' \code{metafor::regplot()}. Bubble size is proportional to study weight.
#' For categorical moderators, one panel is produced per level with automatic
#' grid layout (up to 6 levels).
#'
#' \strong{y-axis note:} Values are on the model scale (log for ratio measures,
#' logit for proportions, raw for means).
#'
#' @param meta_reg_object A \code{meta_reg} object from \code{meta_reg()}.
#' @param moderator Character. Moderator variable to plot. Required when the
#'   model has multiple predictors. If \code{NULL} and only one predictor
#'   exists, that predictor is used automatically.
#' @param title Optional character string printed above the plot (or grid). If
#'   \code{NULL} (default), an auto-constructed title is used. Set to
#'   \code{""} to suppress.
#' @param plot_all_levels Logical. For categorical moderators, produce a panel
#'   per dummy variable (default \code{TRUE}).
#' @param max_levels Integer. Maximum categorical levels to plot (default 6).
#' @param save_as One of \code{"viewer"} (default), \code{"pdf"},
#'   \code{"png"}, or \code{"tiff"}.
#' @param filename Optional file path. If \code{NULL} and
#'   \code{save_as != "viewer"}, a timestamped file is created in
#'   \code{tempdir()}.
#' @param width,height Export dimensions per panel in inches (default 10\,x\,8).
#' @param ... Additional arguments passed to \code{metafor::regplot()}.
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
#' reg <- meta_reg(result,
#'   data = dat_bcg, moderators = ~ablat,
#'   studylab = "author"
#' )
#' bubble_plot(reg)
#' bubble_plot(reg, title = "BCG vaccine -- latitude moderator")
#' }
#'
#' @importFrom graphics mtext par
#' @export
bubble_plot <- function(meta_reg_object,
                        moderator = NULL,
                        title = NULL,
                        plot_all_levels = TRUE,
                        max_levels = 6L,
                        save_as = c("viewer", "pdf", "png", "tiff"),
                        filename = NULL,
                        width = 10,
                        height = 8,
                        ...) {
  save_as <- match.arg(save_as)

  if (!inherits(meta_reg_object, "meta_reg")) {
    stop("Input must be a 'meta_reg' object.", call. = FALSE)
  }

  model <- meta_reg_object$meta
  model_matrix <- model$X
  mod_cols <- colnames(model_matrix)
  data_used <- model$data

  # -- Resolve moderator terms ---------------------------------------------------
  if (is.null(moderator)) {
    if (ncol(model_matrix) > 2) {
      stop("Specify the 'moderator' argument when multiple predictors are present.",
        call. = FALSE
      )
    }
    terms_to_plot <- list(list(name = mod_cols[2L], index = 2L))
  } else {
    is_cat <- is.factor(data_used[[moderator]]) ||
      is.character(data_used[[moderator]])

    if (is_cat) {
      dummy_terms <- grep(paste0("^", moderator), mod_cols, value = TRUE)
      if (length(dummy_terms) == 0) {
        stop("No dummy variables found for moderator: '", moderator, "'.",
          call. = FALSE
        )
      }
      if (!plot_all_levels) dummy_terms <- dummy_terms[1L]
      if (length(dummy_terms) > max_levels) {
        warning(sprintf(
          "Moderator '%s' has %d levels \u2014 plotting only the first %d. Increase max_levels to see all.",
          moderator, length(dummy_terms), max_levels
        ), call. = FALSE)
        dummy_terms <- dummy_terms[seq_len(max_levels)]
      }
      terms_to_plot <- lapply(dummy_terms, function(t) {
        list(name = t, index = which(mod_cols == t))
      })
    } else {
      if (moderator %in% mod_cols) {
        idx <- which(mod_cols == moderator)
      } else {
        matches <- grep(paste0("^", moderator), mod_cols, ignore.case = TRUE)
        if (length(matches) == 0) {
          stop("Could not find moderator '", moderator, "' in model matrix.",
            call. = FALSE
          )
        }
        if (length(matches) > 1) {
          message(
            "Multiple matches for '", moderator,
            "'. Using: ", mod_cols[matches[1L]]
          )
        }
        idx <- matches[1L]
      }
      terms_to_plot <- list(list(name = mod_cols[idx], index = idx))
    }
  }

  n_plots <- length(terms_to_plot)
  mfrow <- if (n_plots == 1L) {
    c(1, 1)
  } else if (n_plots == 2L) {
    c(1, 2)
  } else if (n_plots == 3L) {
    c(1, 3)
  } else if (n_plots == 4L) {
    c(2, 2)
  } else if (n_plots <= 6L) {
    c(2, 3)
  } else {
    c(3, 3)
  }

  out_width <- width * mfrow[2L]
  out_height <- height * mfrow[1L]

  # -- Device -------------------------------------------------------------------
  if (save_as != "viewer") {
    if (is.null(filename)) {
      ext <- switch(save_as,
        pdf = "pdf",
        png = "png",
        tiff = "tiff"
      )
      filename <- file.path(tempdir(), paste0(
        "bubble_plot_", format(Sys.time(), "%Y%m%d%H%M%S"), ".", ext
      ))
    }
    if (save_as == "pdf") {
      grDevices::pdf(filename, width = out_width, height = out_height)
    } else if (save_as == "png") {
      grDevices::png(filename,
        width = out_width, height = out_height,
        units = "in", res = 300
      )
    } else if (save_as == "tiff") {
      tiff_args <- list(
        filename = filename, width = out_width,
        height = out_height, units = "in", res = 300
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
  graphics::par(mfrow = mfrow)

  # -- Draw panels ---------------------------------------------------------------
  for (term in terms_to_plot) {
    message("Plotting: ", term$name)
    tryCatch(
      metafor::regplot(model, mod = term$index, ...),
      error = function(e) {
        message("Failed to plot '", term$name, "': ", e$message)
      }
    )
  }

  # Overall title \u2014 printed after panels so mtext outer works
  plot_title <- if (is.null(title)) {
    mod_name <- if (!is.null(moderator)) moderator else if (length(terms_to_plot) > 0) terms_to_plot[[1]]$name else "moderator"
    sprintf("Meta-regression bubble plot - %s", mod_name)
  } else {
    title
  }

  if (nzchar(plot_title)) {
    if (n_plots > 1L) {
      graphics::mtext(plot_title,
        side = 3, line = -1.5, outer = TRUE,
        font = 2, cex = 0.95
      )
    } else {
      graphics::mtext(plot_title, side = 3, line = 1, font = 2, cex = 0.95)
    }
  }

  if (save_as != "viewer") {
    message(sprintf(
      "Bubble plot saved to: %s",
      normalizePath(filename, mustWork = FALSE)
    ))
  } else {
    message("Bubble plot displayed in Viewer. Use save_as = 'pdf', 'png', or 'tiff' to export.")
  }

  invisible(TRUE)
}
