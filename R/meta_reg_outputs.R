#' Tabulate meta-regression results
#'
#' Creates a publication-ready coefficient table with confidence intervals,
#' p-values, model metadata, and optional back-transformed moderator effects.
#'
#' @param object A \code{meta_reg} object.
#' @param backtransform Logical; include back-transformed effects when defined.
#' @param title Optional table title.
#' @param save_as One of \code{"viewer"}, \code{"docx"}, or \code{"pdf"}.
#' @param filename Optional output path when saving.
#'
#' @return A \pkg{gt} table, invisibly when saved.
#' @export
table_meta_reg <- function(object, backtransform = TRUE, title = NULL,
                           save_as = c("viewer", "docx", "pdf"),
                           filename = NULL) {
  if (!inherits(object, "meta_reg")) {
    stop("'object' must be a meta_reg object.", call. = FALSE)
  }
  save_as <- match.arg(save_as)
  data <- object$table
  data$`Estimate [95% CI]` <- sprintf(
    "%.3f [%.3f, %.3f]", data$Estimate, data$CI.Lower, data$CI.Upper
  )
  display <- data[, c("Term", "Estimate [95% CI]", "p.value")]
  names(display)[3] <- "p-value"

  if (isTRUE(backtransform) && any(data$backtransformable)) {
    display$`Back-transformed [95% CI]` <- ifelse(
      data$backtransformable,
      sprintf("%.3f [%.3f, %.3f]", data$Estimate_bt,
        data$CI.Lower_bt, data$CI.Upper_bt),
      ""
    )
  }
  gt_table <- gt::gt(display) |>
    .gt_optional_title(title) |>
    gt::fmt_number(columns = "p-value", decimals = 3) |>
    gt::tab_source_note(sprintf(
      "k = %d; inference = %s; residual tau-squared = %.4f; R-squared analog = %s",
      object$meta$k, object$test, object$meta$tau2,
      if (is.na(object$r2_analog)) "NA" else paste0(object$r2_analog, "%")
    ))

  if (identical(save_as, "viewer")) {
    print(gt_table)
    return(invisible(gt_table))
  }
  if (is.null(filename)) {
    filename <- file.path(tempdir(), paste0(
      "meta_reg_table_", format(Sys.time(), "%Y%m%d%H%M%S"), ".", save_as
    ))
  }
  gt::gtsave(gt_table, filename)
  message("Table saved to: ", normalizePath(filename, mustWork = FALSE))
  invisible(gt_table)
}

#' Plot meta-regression results and diagnostics
#'
#' Draws a moderator relationship with confidence and prediction bands, or a
#' residual, fitted-value, or influence diagnostic plot.
#'
#' @param object A \code{meta_reg} object.
#' @param type Plot type: \code{"bubble"}, \code{"residual"},
#'   \code{"fitted"}, or \code{"influence"}.
#' @param moderator Moderator name for a bubble plot. If omitted, the sole
#'   moderator in a univariable model is used.
#' @param level Confidence level for bubble-plot intervals.
#' @param prediction Logical; show the prediction band on bubble plots.
#' @param points Number of grid points for a continuous moderator.
#' @param title Optional plot title.
#' @param save_as One of \code{"viewer"}, \code{"pdf"}, \code{"png"}, or
#'   \code{"tiff"}.
#' @param filename Optional output path.
#' @param width,height Output dimensions in inches.
#'
#' @return A \pkg{ggplot2} object, invisibly when saved.
#' @export
plot_meta_reg <- function(object,
                          type = c("bubble", "residual", "fitted", "influence"),
                          moderator = NULL, level = 0.95, prediction = TRUE,
                          points = 100L, title = NULL,
                          save_as = c("viewer", "pdf", "png", "tiff"),
                          filename = NULL, width = 9, height = 7) {
  if (!inherits(object, "meta_reg")) {
    stop("'object' must be a meta_reg object.", call. = FALSE)
  }
  type <- match.arg(type)
  save_as <- match.arg(save_as)
  diagnostics <- diagnose_meta_reg(object)

  if (type == "bubble") {
    if (is.null(moderator)) {
      if (length(object$moderator_variables) != 1L) {
        stop("Supply 'moderator' for multivariable models.", call. = FALSE)
      }
      moderator <- object$moderator_variables
    }
    if (!moderator %in% object$moderator_variables) {
      stop("'moderator' is not present in the fitted model.", call. = FALSE)
    }
    model_values <- object$model_data[[moderator]]
    if (!is.numeric(model_values)) {
      stop("Bubble plots currently require a numeric moderator.", call. = FALSE)
    }
    to_original <- function(variable, value) {
      if (variable %in% names(object$preprocessing$center)) {
        value <- value + object$preprocessing$center[[variable]]
      }
      if (variable %in% names(object$preprocessing$scale)) {
        setting <- object$preprocessing$scale[[variable]]
        value <- value * setting[["sd"]] + setting[["mean"]]
      }
      value
    }
    values <- to_original(moderator, model_values)
    grid_data <- list()
    for (variable in object$moderator_variables) {
      value <- object$model_data[[variable]]
      if (variable == moderator) {
        grid_data[[variable]] <- seq(min(values), max(values), length.out = points)
      } else if (is.numeric(value)) {
        grid_data[[variable]] <- rep(to_original(variable,
          mean(value, na.rm = TRUE)), points)
      } else {
        grid_data[[variable]] <- factor(rep(levels(value)[1L], points),
          levels = levels(value))
      }
    }
    grid_data <- as.data.frame(grid_data)
    pred <- predict_meta_reg(object, grid_data, level = level, scale = "model")
    observed <- data.frame(
      x = values, y = object$model_data$yi,
      weight = 1 / object$model_data$vi
    )
    p <- ggplot2::ggplot(observed, ggplot2::aes(x = x, y = y))
    if (isTRUE(prediction)) {
      p <- p + ggplot2::geom_ribbon(
        data = pred, ggplot2::aes(x = .data[[moderator]], ymin = pred.low,
          ymax = pred.high), inherit.aes = FALSE, fill = "#9ecae1", alpha = 0.25
      )
    }
    p <- p +
      ggplot2::geom_ribbon(
        data = pred, ggplot2::aes(x = .data[[moderator]], ymin = conf.low,
          ymax = conf.high), inherit.aes = FALSE, fill = "#3182bd", alpha = 0.25
      ) +
      ggplot2::geom_line(
        data = pred, ggplot2::aes(x = .data[[moderator]], y = estimate),
        inherit.aes = FALSE, colour = "#08519c", linewidth = 0.9
      ) +
      ggplot2::geom_point(ggplot2::aes(size = weight), alpha = 0.65) +
      ggplot2::scale_size_area(max_size = 10, guide = "none") +
      ggplot2::labs(x = moderator, y = "Effect (model scale)")
  } else {
    d <- diagnostics$studies
    if (type == "residual") {
      p <- ggplot2::ggplot(d, ggplot2::aes(x = fitted, y = standardized_residual)) +
        ggplot2::geom_hline(yintercept = c(-2, 0, 2), linetype = c(2, 1, 2),
          colour = c("#b2182b", "grey40", "#b2182b")) +
        ggplot2::geom_point(ggplot2::aes(colour = influential), size = 2.5) +
        ggplot2::labs(x = "Fitted effect", y = "Standardized residual")
    } else if (type == "fitted") {
      p <- ggplot2::ggplot(d, ggplot2::aes(x = fitted, y = observed)) +
        ggplot2::geom_abline(slope = 1, intercept = 0, linetype = 2) +
        ggplot2::geom_point(ggplot2::aes(colour = influential), size = 2.5) +
        ggplot2::labs(x = "Fitted effect", y = "Observed effect")
    } else {
      p <- ggplot2::ggplot(d, ggplot2::aes(x = stats::reorder(Study, cooks_distance),
        y = cooks_distance)) +
        ggplot2::geom_col(ggplot2::aes(fill = influential)) +
        ggplot2::coord_flip() +
        ggplot2::labs(x = NULL, y = "Cook's distance")
    }
  }

  p <- p + ggplot2::theme_minimal(base_size = 11) +
    ggplot2::labs(title = title)
  if (type %in% c("residual", "fitted")) {
    p <- p + ggplot2::scale_colour_manual(
      name = "Influential", values = c(`FALSE` = "#F8766D", `TRUE` = "#00BFC4"),
      breaks = c(FALSE, TRUE), labels = c("No", "Yes")
    )
  } else if (identical(type, "influence")) {
    p <- p + ggplot2::scale_fill_manual(
      name = "Influential", values = c(`FALSE` = "#F8766D", `TRUE` = "#00BFC4"),
      breaks = c(FALSE, TRUE), labels = c("No", "Yes")
    )
  }
  if (save_as == "viewer") return(p)
  if (is.null(filename)) {
    filename <- file.path(tempdir(), paste0("meta_reg_", type, ".", save_as))
  }
  ggplot2::ggsave(filename, p, width = width, height = height, dpi = 300)
  message("Meta-regression plot saved to: ", normalizePath(filename, mustWork = FALSE))
  invisible(p)
}
