#' Forest plot for meta-analysis results
#'
#' Produces a publication-ready forest plot from a \code{meta_ratio},
#' \code{meta_mean}, or \code{meta_prop} object. The appropriate plotting
#' method is selected automatically based on the class of \code{x}.
#'
#' @param x A \code{meta_ratio}, \code{meta_mean}, or \code{meta_prop} object.
#' @param ... Additional arguments passed to the class-specific plotting method.
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
#' forest_meta(result)
#' }
#'
#' @importFrom graphics mtext
#' @importFrom stats update
#' @export
forest_meta <- function(x, ...) {
  if (inherits(x, "meta_ratio")) {
    forest_meta_ratio(x, ...)
  } else if (inherits(x, "meta_mean")) {
    forest_meta_mean(x, ...)
  } else if (inherits(x, "meta_prop")) {
    forest_meta_prop(x, ...)
  } else {
    stop("'x' must be a meta_ratio, meta_mean, or meta_prop object.",
      call. = FALSE
    )
  }
}

# -- internal helpers ----------------------------------------------------------

.forest_filename <- function(save_as) {
  ext <- switch(save_as,
    pdf = "pdf",
    png = "png",
    tiff = "tiff"
  )
  file.path(tempdir(), paste0(
    "forest_plot_",
    format(Sys.time(), "%Y%m%d%H%M%S"), ".", ext
  ))
}

.forest_open <- function(save_as, filename, width, height) {
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
  # viewer: no device \u2014 RStudio renders to Plots pane naturally
}

.forest_close <- function(save_as, filename, k) {
  if (save_as != "viewer") {
    message(sprintf(
      "Forest plot saved to: %s",
      normalizePath(filename, mustWork = FALSE)
    ))
  } else {
    message("Forest plot displayed in Viewer. Use save_as = 'pdf' or 'png' for publication-quality export.")
    if (k > 40) {
      message("Tip: export to PDF/PNG for large plots \u2014 Viewer margins may clip rows.")
    }
  }
}

.forest_byvar <- function(x) {
  tbl <- x$table
  if (isTRUE(x$subgroup) && !all(is.na(tbl$subgroup))) {
    v <- tbl$subgroup
    attr(v, "label") <- "Subgroup"
    v
  } else {
    NULL
  }
}

.forest_auto_title <- function(measure, k) {
  measure_str <- switch(measure,
    OR         = "Odds Ratio",
    RR         = "Risk Ratio",
    HR         = "Hazard Ratio",
    MD         = "Mean Difference",
    SMD        = "Standardised Mean Difference",
    Proportion = "Proportion",
    measure
  )
  sprintf("Forest plot - %s (k\u00a0=\u00a0%d)", measure_str, k)
}

.forest_add_title <- function(title) {
  if (!is.null(title) && nzchar(title)) {
    tryCatch(
      graphics::mtext(title, side = 3, line = 1, font = 2, cex = 0.95),
      error = function(e) invisible(NULL)
    )
  }
}

# -- Layout resolution ---------------------------------------------------------
# See session notes for full rationale on layout switching rules.
.resolve_layout <- function(layout, k, type = c("ratio", "mean")) {
  type <- match.arg(type)
  lo <- tolower(layout)
  if (type == "ratio") {
    if (k > 30) {
      if (lo != "meta") {
        message(sprintf(
          "Note: Layout switched from '%s' to 'meta' for k = %d > 30 (metagen path).",
          layout, k
        ))
      }
      return("meta")
    } else {
      if (lo %in% c("revman5", "meta")) {
        return("meta")
      }
    }
  } else {
    if (lo == "revman5" && k > 30) {
      message(sprintf(
        "Note: Layout switched from '%s' to 'meta' for k = %d > 30.",
        layout, k
      ))
      return("meta")
    }
  }
  lo
}

# -- forest_meta_ratio ---------------------------------------------------------
#' @noRd
forest_meta_ratio <- function(x,
                              title = NULL,
                              filename = NULL,
                              save_as = c("viewer", "pdf", "png", "tiff"),
                              layout = "RevMan5",
                              height = NULL,
                              width = NULL,
                              ...) {
  if (!inherits(x, "meta_ratio")) {
    stop("Input must be a 'meta_ratio' object.", call. = FALSE)
  }
  save_as <- match.arg(save_as)

  m <- x$meta
  k <- length(m$studlab)
  byvar <- .forest_byvar(x)

  sizing <- .auto_plot_sizing(k, height, width,
    type = if (!is.null(byvar)) "subgroup" else "ratio"
  )
  height <- sizing$height
  width <- sizing$width
  fontsize <- sizing$fontsize

  if (save_as == "viewer" && height > 45) {
    height <- 45
    if (is.null(match.call()$height)) {
      message(sprintf(
        "Note: k = %d is large \u2014 plot capped at 45in for Viewer. Use save_as = 'pdf' for the full plot.", k
      ))
    }
  }

  if (is.null(filename) && save_as != "viewer") {
    filename <- .forest_filename(save_as)
  }
  .forest_open(save_as, filename, width, height)
  if (save_as != "viewer") on.exit(grDevices::dev.off(), add = TRUE)

  or_label <- switch(x$measure,
    OR = "Odds Ratio",
    RR = "Risk Ratio",
    HR = "Hazard Ratio",
    "Effect Size"
  )
  effective_layout <- .resolve_layout(layout, k, type = "ratio")
  fs_het <- if (!is.null(byvar)) max(6, fontsize - 2) else max(7, fontsize - 1)
  plot_title <- if (is.null(title)) .forest_auto_title(x$measure, k) else title

  if (k > 30) {
    plot_obj <- suppressWarnings(meta::metagen(
      TE         = m$TE,
      seTE       = m$seTE,
      studlab    = m$studlab,
      sm         = m$sm,
      common     = m$common,
      random     = m$random,
      prediction = TRUE,
      tau.preset = sqrt(m$tau2),
      subgroup   = byvar
    ))
    class(plot_obj) <- c("metagen", "meta")

    bare_args <- list(
      x = plot_obj,
      sortvar = plot_obj$TE,
      smlab = or_label,
      leftcols = c("studlab", "effect", "ci", "w.random"),
      leftlabs = c("Study", or_label, "95% CI", "Weight"),
      rightcols = FALSE,
      backtransf = TRUE,
      text.random = "Total (95% CI)",
      text.common = "Total (95% CI)",
      refline = 1,
      layout = effective_layout,
      prediction = TRUE,
      print.pred = TRUE,
      print.I2 = TRUE,
      print.tau2 = TRUE,
      print.Q = TRUE,
      fontsize = fontsize,
      fs.hetstat = fs_het,
      col.square = "blue",
      col.square.lines = "blue",
      col.diamond = "blue",
      col.diamond.lines = "blue",
      col.predict = "darkgreen",
      addrows.below.left = if (!is.null(byvar)) 0L else 1L
    )
    if (!is.null(byvar)) bare_args$subgroup.name <- "Subgroup"
    do.call(meta::forest, c(bare_args, list(...)))
  } else {
    forest_args <- list(
      x = m,
      sortvar = m$TE,
      leftlabs = "Study",
      label.e = "Exp",
      label.c = "Ctrl",
      print.w = TRUE,
      pooled.totals = TRUE,
      text.random = "Total (95% CI)",
      text.common = "Total (95% CI)",
      prediction = TRUE,
      print.pred = TRUE,
      print.I2 = TRUE,
      print.tau2 = TRUE,
      print.Q = TRUE,
      smlab = or_label,
      fontsize = fontsize,
      fs.hetstat = fs_het,
      addrows.below.left = if (!is.null(byvar)) 0L else 1L,
      col.square = "blue",
      col.square.lines = "blue",
      col.diamond = "blue",
      col.diamond.lines = "blue",
      col.predict = "darkgreen",
      layout = effective_layout,
      refline = 1,
      logscale = TRUE
    )
    if (!is.null(byvar)) {
      forest_args$x <- update(forest_args$x,
        subgroup      = byvar,
        subgroup.name = "Subgroup"
      )
    }
    do.call(meta::forest, c(forest_args, list(...)))
  }

  .forest_add_title(plot_title)
  .forest_close(save_as, filename, k)
  invisible(TRUE)
}

# -- forest_meta_mean ----------------------------------------------------------
#' @noRd
forest_meta_mean <- function(x,
                             title = NULL,
                             filename = NULL,
                             save_as = c("viewer", "pdf", "png", "tiff"),
                             layout = "RevMan5",
                             height = NULL,
                             width = NULL,
                             ...) {
  if (!inherits(x, "meta_mean")) {
    stop("Input must be a 'meta_mean' object.", call. = FALSE)
  }
  save_as <- match.arg(save_as)

  m <- x$meta
  k <- length(m$studlab)
  byvar <- .forest_byvar(x)
  user_width <- width

  sizing <- .auto_plot_sizing(k, height, width,
    type = if (!is.null(byvar)) "subgroup" else "mean"
  )
  height <- sizing$height
  width <- sizing$width
  fontsize <- sizing$fontsize

  if (save_as == "viewer" && height > 45) {
    height <- 45
    if (is.null(match.call()$height)) {
      message(sprintf(
        "Note: k = %d is large \u2014 plot capped at 45in for Viewer. Use save_as = 'pdf' for the full plot.", k
      ))
    }
  }
  if (is.null(user_width) && tolower(layout) == "bmj") width <- max(width, 18)

  if (is.null(filename) && save_as != "viewer") {
    filename <- .forest_filename(save_as)
  }
  .forest_open(save_as, filename, width, height)
  if (save_as != "viewer") on.exit(grDevices::dev.off(), add = TRUE)

  smlab <- if (identical(x$measure, "SMD")) "SMD" else "Mean Difference"
  effective_layout <- .resolve_layout(layout, k, type = "mean")
  fs_het <- if (!is.null(byvar)) max(6, fontsize - 2) else max(7, fontsize - 1)
  plot_title <- if (is.null(title)) .forest_auto_title(x$measure, k) else title

  mean_args <- list(
    x = m,
    sortvar = m$TE,
    leftlabs = c("Study", "N (Exp/Ctrl)"),
    rightlabs = c("Mean Difference [95% CI]", "Weight"),
    print.w = TRUE,
    label.e = "Experimental",
    label.c = "Control",
    text.random = "Total (95% CI)",
    text.common = "Total (95% CI)",
    prediction = TRUE,
    print.pred = TRUE,
    print.I2 = TRUE,
    print.tau2 = TRUE,
    print.Q = TRUE,
    smlab = smlab,
    fontsize = fontsize,
    fs.hetstat = fs_het,
    addrows.below.left = if (!is.null(byvar)) 0L else 1L,
    col.square = "blue",
    col.square.lines = "blue",
    col.diamond = "blue",
    col.diamond.lines = "blue",
    col.predict = "darkgreen",
    layout = effective_layout,
    refline = 0
  )
  if (!is.null(byvar)) {
    mean_args$x <- update(mean_args$x,
      subgroup      = byvar,
      subgroup.name = "Subgroup"
    )
  }
  do.call(meta::forest, c(mean_args, list(...)))

  .forest_add_title(plot_title)
  .forest_close(save_as, filename, k)
  invisible(TRUE)
}

# -- forest_meta_prop ----------------------------------------------------------
#' @noRd
forest_meta_prop <- function(x,
                             title = NULL,
                             filename = NULL,
                             save_as = c("viewer", "pdf", "png", "tiff"),
                             layout = "RevMan5",
                             height = NULL,
                             width = NULL,
                             ...) {
  if (!inherits(x, "meta_prop")) {
    stop("Input must be a 'meta_prop' object.", call. = FALSE)
  }
  save_as <- match.arg(save_as)

  m <- x$meta
  k <- length(m$studlab)
  byvar <- .forest_byvar(x)

  sizing <- .auto_plot_sizing(k, height, width,
    type = if (!is.null(byvar)) "subgroup" else "prop"
  )
  height <- sizing$height
  width <- sizing$width
  fontsize <- sizing$fontsize

  if (save_as == "viewer" && height > 45) {
    height <- 45
    if (is.null(match.call()$height)) {
      message(sprintf(
        "Note: k = %d is large \u2014 plot capped at 45in for Viewer. Use save_as = 'pdf' for the full plot.", k
      ))
    }
  }

  if (is.null(filename) && save_as != "viewer") {
    filename <- .forest_filename(save_as)
  }
  .forest_open(save_as, filename, width, height)
  if (save_as != "viewer") on.exit(grDevices::dev.off(), add = TRUE)

  upper_ci_max <- max(m$upper, na.rm = TRUE) * 100
  predict_upper <- if (!is.null(m$upper.predict)) {
    max(m$upper.predict, na.rm = TRUE) * 100
  } else {
    0
  }
  xlim_max <- ceiling(max(upper_ci_max, predict_upper) / 5) * 5
  xlim_max <- max(xlim_max, 10)

  fs_het <- if (!is.null(byvar)) max(6, fontsize - 2) else max(7, fontsize - 1)
  plot_title <- if (is.null(title)) .forest_auto_title("Proportion", k) else title

  if (!is.null(byvar)) {
    m <- update(m, subgroup = byvar, subgroup.name = "Subgroup")
  }

  prop_args <- list(
    x = m,
    print.tau2 = TRUE,
    print.Q = TRUE,
    print.pval.Q = TRUE,
    print.I2 = TRUE,
    print.w = TRUE,
    pooled.totals = TRUE,
    prediction = TRUE,
    print.pred = TRUE,
    weight.study = "random",
    leftcols = c("studlab", "event", "n", "w.random", "effect", "ci"),
    leftlabs = c("Study", "Events", "Total", "Weight", "Proportion (%)", "95% CI"),
    rightcols = FALSE,
    xlab = "Proportion (%)",
    smlab = "",
    text.random = "Total (95% CI)",
    text.common = "Total (95% CI)",
    xlim = c(0, xlim_max),
    pscale = 100,
    squaresize = 0.5,
    fontsize = fontsize,
    fs.hetstat = fs_het,
    addrows.below.left = if (!is.null(byvar)) 0L else 1L,
    col.square = "blue",
    col.square.lines = "blue",
    col.diamond = "blue",
    col.diamond.lines = "blue",
    col.predict = "darkgreen",
    layout = tolower(layout),
    digits = 2,
    refline = 0
  )
  do.call(meta::forest, c(prop_args, list(...)))

  .forest_add_title(plot_title)
  .forest_close(save_as, filename, k)
  invisible(TRUE)
}
