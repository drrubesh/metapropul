#' Forest plot for meta-analysis results
#'
#' Produces a publication-ready forest plot from a \code{meta_ratio},
#' \code{meta_mean}, or \code{meta_prop} object. The appropriate plotting
#' method is selected automatically based on the class of \code{x}.
#'
#' @param x A \code{meta_ratio}, \code{meta_mean}, or \code{meta_prop}
#'   object.
#' @param ... Additional arguments passed to the class-specific plotting
#'   method.
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
    stop(
      "'x' must be a meta_ratio, meta_mean, or meta_prop object.",
      call. = FALSE
    )
  }
}

# -- internal helpers ------------------------------------------------------

.forest_filename <- function(save_as) {
  ext <- switch(
    save_as,
    pdf = "pdf",
    png = "png",
    tiff = "tiff"
  )

  file.path(
    tempdir(),
    paste0(
      "forest_plot_",
      format(Sys.time(), "%Y%m%d%H%M%S"),
      ".",
      ext
    )
  )
}

.forest_open <- function(save_as, filename, width, height) {
  if (save_as == "pdf") {
    grDevices::pdf(filename, width = width, height = height)
  } else if (save_as == "png") {
    grDevices::png(
      filename,
      width = width,
      height = height,
      units = "in",
      res = 300
    )
  } else if (save_as == "tiff") {
    tiff_args <- list(
      filename = filename,
      width = width,
      height = height,
      units = "in",
      res = 300
    )

    if (Sys.info()[["sysname"]] != "Darwin") {
      tiff_args$compression <- "lzw"
    }

    do.call(grDevices::tiff, tiff_args)
  }
}

.forest_close <- function(save_as, filename, k) {
  if (save_as != "viewer") {
    message(sprintf(
      "Forest plot saved to: %s",
      normalizePath(filename, mustWork = FALSE)
    ))
  } else {
    message(
      "Forest plot displayed in Viewer. Use save_as = 'pdf' or 'png' ",
      "for publication-quality export."
    )

    if (k > 40) {
      message(
        "Tip: export to PDF/PNG for large plots - Viewer margins may ",
        "clip rows."
      )
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
  measure_str <- switch(
    measure,
    OR = "Odds Ratio",
    RR = "Risk Ratio",
    HR = "Hazard Ratio",
    MD = "Mean Difference",
    SMD = "Standardised Mean Difference",
    Proportion = "Proportion",
    measure
  )

  sprintf("Forest plot - %s (k = %d)", measure_str, k)
}

.forest_add_title <- function(title) {
  if (!is.null(title) && nzchar(title)) {
    tryCatch(
      graphics::mtext(title, side = 3, line = 1, font = 2, cex = 0.95),
      error = function(e) invisible(NULL)
    )
  }
}

.forest_bottom_rows <- function(k, has_subgroup = FALSE) {
  if (has_subgroup) {
    return(2L)
  }

  if (k <= 10) {
    return(2L)
  }

  if (k <= 20) {
    return(3L)
  }

  1L
}

# --- ROB helpers ----------------------------------------------------------

.forest_match_rob <- function(meta_studlab,
                              rob_data = NULL,
                              rob_studylab = NULL,
                              rob_overall = "overall",
                              rob_style = c("text", "short")) {
  rob_style <- match.arg(rob_style)

  if (is.null(rob_data)) {
    return(NULL)
  }

  if (!inherits(rob_data, "data.frame")) {
    stop("'rob_data' must be a data frame.", call. = FALSE)
  }

  if (is.null(rob_studylab) || !nzchar(rob_studylab)) {
    stop(
      "Please provide 'rob_studylab' when 'rob_data' is supplied.",
      call. = FALSE
    )
  }

  if (!rob_studylab %in% names(rob_data)) {
    stop(
      sprintf("Column '%s' not found in rob_data.", rob_studylab),
      call. = FALSE
    )
  }

  if (!rob_overall %in% names(rob_data)) {
    stop(
      sprintf("Column '%s' not found in rob_data.", rob_overall),
      call. = FALSE
    )
  }

  meta_labels <- as.character(meta_studlab)
  rob_labels <- as.character(rob_data[[rob_studylab]])

  idx <- match(meta_labels, rob_labels)

  rob_vals <- rep("", length(meta_labels))
  rob_vals[!is.na(idx)] <- as.character(rob_data[[rob_overall]][idx[!is.na(idx)]])

  if (rob_style == "short") {
    rob_vals <- dplyr::recode(
      rob_vals,
      "Low" = "L",
      "Some concerns" = "SC",
      "High" = "H",
      .default = rob_vals
    )
  }

  data.frame(
    studlab = meta_labels,
    rob_text = rob_vals,
    stringsAsFactors = FALSE
  )
}

# -- Layout resolution -----------------------------------------------------

.resolve_layout <- function(layout, k, type = c("ratio", "mean")) {
  type <- match.arg(type)
  lo <- tolower(layout)

  if (type == "ratio") {
    if (k > 30) {
      if (lo != "meta") {
        message(sprintf(
          paste0(
            "Note: Layout switched from '%s' to 'meta' for ",
            "k = %d > 30 (metagen path)."
          ),
          layout,
          k
        ))
      }
      return("meta")
    }

    if (lo %in% c("revman5", "meta")) {
      return("meta")
    }
  } else {
    if (lo == "revman5" && k > 30) {
      message(sprintf(
        "Note: Layout switched from '%s' to 'meta' for k = %d > 30.",
        layout,
        k
      ))
      return("meta")
    }
  }

  lo
}

# -- forest_meta_ratio -----------------------------------------------------

#' @noRd
forest_meta_ratio <- function(x,
                              title = NULL,
                              filename = NULL,
                              save_as = c("viewer", "pdf", "png", "tiff"),
                              layout = "RevMan5",
                              height = NULL,
                              width = NULL,
                              rob_data = NULL,
                              rob_studylab = NULL,
                              rob_overall = "overall",
                              show_rob = FALSE,
                              rob_style = c("text", "short"),
                              rob_colname = "ROB",
                              ...) {
  if (!inherits(x, "meta_ratio")) {
    stop("Input must be a 'meta_ratio' object.", call. = FALSE)
  }

  save_as <- match.arg(save_as)
  rob_style <- match.arg(rob_style)

  m <- x$meta
  k <- length(m$studlab)
  byvar <- .forest_byvar(x)
  has_subgroup <- !is.null(byvar)

  rob_df <- if (show_rob) {
    .forest_match_rob(
      meta_studlab = m$studlab,
      rob_data = rob_data,
      rob_studylab = rob_studylab,
      rob_overall = rob_overall,
      rob_style = rob_style
    )
  } else {
    NULL
  }
  has_rob <- isTRUE(show_rob) && !is.null(rob_df)

  sizing <- .auto_plot_sizing(
    k,
    height,
    width,
    type = if (has_subgroup) "subgroup" else "ratio"
  )

  height <- sizing$height
  width <- sizing$width
  fontsize <- sizing$fontsize
  bottom_rows <- .forest_bottom_rows(k, has_subgroup)

  if (has_rob && is.null(match.call()$width)) {
    width <- width + 1.5
  }

  if (save_as == "viewer" && height > 45) {
    height <- 45

    if (is.null(match.call()$height)) {
      message(sprintf(
        paste0(
          "Note: k = %d is large - plot capped at 45in for Viewer. ",
          "Use save_as = 'pdf' for the full plot."
        ),
        k
      ))
    }
  }

  if (is.null(filename) && save_as != "viewer") {
    filename <- .forest_filename(save_as)
  }

  .forest_open(save_as, filename, width, height)

  if (save_as != "viewer") {
    on.exit(grDevices::dev.off(), add = TRUE)
  }

  or_label <- switch(
    x$measure,
    OR = "Odds Ratio",
    RR = "Risk Ratio",
    HR = "Hazard Ratio",
    "Effect Size"
  )

  effective_layout <- .resolve_layout(layout, k, type = "ratio")
  plot_title <- if (is.null(title)) {
    .forest_auto_title(x$measure, k)
  } else {
    title
  }

  if (k > 30) {
    plot_obj <- suppressWarnings(meta::metagen(
      TE = m$TE,
      seTE = m$seTE,
      studlab = m$studlab,
      sm = m$sm,
      common = m$common,
      random = m$random,
      prediction = TRUE,
      tau.preset = sqrt(m$tau2),
      subgroup = byvar
    ))

    if (has_rob) {
      plot_obj$data <- rob_df
      rightcols <- c("effect", "ci", "w.random", "rob_text")
      rightlabs <- c(or_label, "95%-CI", "Weight", rob_colname)
    } else {
      rightcols <- FALSE
      rightlabs <- NULL
    }

    class(plot_obj) <- c("metagen", "meta")

    bare_args <- list(
      x = plot_obj,
      sortvar = plot_obj$TE,
      smlab = or_label,
      leftcols = "studlab",
      leftlabs = "Study",
      rightcols = rightcols,
      rightlabs = rightlabs,
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
      fs.hetstat = max(6, fontsize - 2),
      col.square = "blue",
      col.square.lines = "blue",
      col.diamond = "blue",
      col.diamond.lines = "blue",
      col.predict = "darkgreen",
      addrows.below.left = if (has_subgroup) 0L else 1L,
      addrows.below.overall = bottom_rows
    )

    if (has_subgroup) {
      bare_args$subgroup.name <- "Subgroup"
    }

    do.call(meta::forest, c(bare_args, list(...)))
  } else {
    plot_obj <- m

    if (has_rob) {
      plot_obj$data <- rob_df
      rightcols <- c("effect", "ci", "w.random", "rob_text")
      rightlabs <- c("OR", "95%-CI", "Weight", rob_colname)
    } else {
      rightcols <- FALSE
      rightlabs <- NULL
    }

    forest_args <- list(
      x = plot_obj,
      sortvar = m$TE,
      leftlabs = "Study",
      label.e = "Exp",
      label.c = "Ctrl",
      rightcols = rightcols,
      rightlabs = rightlabs,
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
      fs.hetstat = max(6, fontsize - 2),
      addrows.below.left = if (has_subgroup) 0L else 1L,
      addrows.below.overall = bottom_rows,
      col.square = "blue",
      col.square.lines = "blue",
      col.diamond = "blue",
      col.diamond.lines = "blue",
      col.predict = "darkgreen",
      layout = effective_layout,
      refline = 1,
      logscale = TRUE
    )

    if (has_subgroup) {
      forest_args$x <- update(
        forest_args$x,
        subgroup = byvar,
        subgroup.name = "Subgroup"
      )
    }

    do.call(meta::forest, c(forest_args, list(...)))
  }

  .forest_add_title(plot_title)
  if (has_rob && rob_style == "short") {
    graphics::mtext(
      "ROB: L = Low, SC = Some concerns, H = High",
      side = 1,
      line = 3,
      adj = 0,
      cex = 0.8
    )
  }
  .forest_close(save_as, filename, k)
  invisible(TRUE)
}

# -- forest_meta_mean ------------------------------------------------------

#' @noRd
forest_meta_mean <- function(x,
                             title = NULL,
                             filename = NULL,
                             save_as = c("viewer", "pdf", "png", "tiff"),
                             layout = "RevMan5",
                             height = NULL,
                             width = NULL,
                             rob_data = NULL,
                             rob_studylab = NULL,
                             rob_overall = "overall",
                             show_rob = FALSE,
                             rob_style = c("text", "short"),
                             rob_colname = "ROB",
                             ...) {
  if (!inherits(x, "meta_mean")) {
    stop("Input must be a 'meta_mean' object.", call. = FALSE)
  }

  save_as <- match.arg(save_as)
  rob_style <- match.arg(rob_style)

  m <- x$meta
  k <- length(m$studlab)
  byvar <- .forest_byvar(x)
  has_subgroup <- !is.null(byvar)
  user_width <- width

  rob_df <- if (show_rob) {
    .forest_match_rob(
      meta_studlab = m$studlab,
      rob_data = rob_data,
      rob_studylab = rob_studylab,
      rob_overall = rob_overall,
      rob_style = rob_style
    )
  } else {
    NULL
  }
  has_rob <- !is.null(rob_df)

  sizing <- .auto_plot_sizing(
    k,
    height,
    width,
    type = if (has_subgroup) "subgroup" else "mean"
  )

  height <- sizing$height
  width <- sizing$width
  fontsize <- sizing$fontsize
  bottom_rows <- .forest_bottom_rows(k, has_subgroup)

  if (has_rob && is.null(match.call()$width)) {
    width <- width + 1.5
  }

  if (save_as == "viewer" && height > 45) {
    height <- 45

    if (is.null(match.call()$height)) {
      message(sprintf(
        paste0(
          "Note: k = %d is large - plot capped at 45in for Viewer. ",
          "Use save_as = 'pdf' for the full plot."
        ),
        k
      ))
    }
  }

  if (is.null(user_width) && tolower(layout) == "bmj") {
    width <- max(width, 18)
  }

  if (is.null(filename) && save_as != "viewer") {
    filename <- .forest_filename(save_as)
  }

  .forest_open(save_as, filename, width, height)

  if (save_as != "viewer") {
    on.exit(grDevices::dev.off(), add = TRUE)
  }

  smlab <- if (identical(x$measure, "SMD")) {
    "SMD"
  } else {
    "Mean Difference"
  }

  effective_layout <- .resolve_layout(layout, k, type = "mean")
  plot_title <- if (is.null(title)) {
    .forest_auto_title(x$measure, k)
  } else {
    title
  }

  plot_obj <- m

  if (has_rob) {
    plot_obj$data <- rob_df
    rightcols <- c("effect", "ci", "w.random", "rob_text")
    rightlabs <- c("Estimate", "95%-CI", "Weight", rob_colname)
  } else {
    rightcols <- FALSE
    rightlabs <- NULL
  }

  mean_args <- list(
    x = plot_obj,
    sortvar = m$TE,
    leftlabs = c("Study", "N (Exp/Ctrl)"),
    rightcols = rightcols,
    rightlabs = rightlabs,
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
    fs.hetstat = max(6, fontsize - 2),
    addrows.below.left = if (has_subgroup) 0L else 1L,
    addrows.below.overall = bottom_rows,
    col.square = "blue",
    col.square.lines = "blue",
    col.diamond = "blue",
    col.diamond.lines = "blue",
    col.predict = "darkgreen",
    layout = effective_layout,
    refline = 0
  )

  if (has_subgroup) {
    mean_args$x <- update(
      mean_args$x,
      subgroup = byvar,
      subgroup.name = "Subgroup"
    )
  }

  do.call(meta::forest, c(mean_args, list(...)))

  .forest_add_title(plot_title)
  if (has_rob && rob_style == "short") {
    graphics::mtext(
      "ROB: L = Low, SC = Some concerns, H = High",
      side = 1,
      line = 3,
      adj = 0,
      cex = 0.8
    )
  }
  .forest_close(save_as, filename, k)
  invisible(TRUE)
}

# -- forest_meta_prop ------------------------------------------------------

#' @noRd
forest_meta_prop <- function(x,
                             title = NULL,
                             filename = NULL,
                             save_as = c("viewer", "pdf", "png", "tiff"),
                             layout = "RevMan5",
                             height = NULL,
                             width = NULL,
                             rob_data = NULL,
                             rob_studylab = NULL,
                             rob_overall = "overall",
                             show_rob = FALSE,
                             rob_style = c("text", "short"),
                             rob_colname = "ROB",
                             ...) {
  if (!inherits(x, "meta_prop")) {
    stop("Input must be a 'meta_prop' object.", call. = FALSE)
  }

  save_as <- match.arg(save_as)
  rob_style <- match.arg(rob_style)

  m <- x$meta
  k <- length(m$studlab)
  byvar <- .forest_byvar(x)
  has_subgroup <- !is.null(byvar)

  rob_df <- if (show_rob) {
    .forest_match_rob(
      meta_studlab = m$studlab,
      rob_data = rob_data,
      rob_studylab = rob_studylab,
      rob_overall = rob_overall,
      rob_style = rob_style
    )
  } else {
    NULL
  }
  has_rob <- !is.null(rob_df)

  sizing <- .auto_plot_sizing(
    k,
    height,
    width,
    type = if (has_subgroup) "subgroup" else "prop"
  )

  height <- sizing$height
  width <- sizing$width
  fontsize <- sizing$fontsize
  bottom_rows <- .forest_bottom_rows(k, has_subgroup)

  if (has_rob && is.null(match.call()$width)) {
    width <- width + 1.5
  }

  if (save_as == "viewer" && height > 45) {
    height <- 45

    if (is.null(match.call()$height)) {
      message(sprintf(
        paste0(
          "Note: k = %d is large - plot capped at 45in for Viewer. ",
          "Use save_as = 'pdf' for the full plot."
        ),
        k
      ))
    }
  }

  if (is.null(filename) && save_as != "viewer") {
    filename <- .forest_filename(save_as)
  }

  .forest_open(save_as, filename, width, height)

  if (save_as != "viewer") {
    on.exit(grDevices::dev.off(), add = TRUE)
  }

  upper_ci_max <- max(m$upper, na.rm = TRUE) * 100
  predict_upper <- if (!is.null(m$upper.predict)) {
    max(m$upper.predict, na.rm = TRUE) * 100
  } else {
    0
  }

  xlim_max <- ceiling(max(upper_ci_max, predict_upper) / 5) * 5
  xlim_max <- max(xlim_max, 10)

  plot_title <- if (is.null(title)) {
    .forest_auto_title("Proportion", k)
  } else {
    title
  }

  plot_obj <- m

  if (has_subgroup) {
    plot_obj <- update(plot_obj, subgroup = byvar, subgroup.name = "Subgroup")
  }

  if (has_rob) {
    plot_obj$data <- rob_df
    rightcols <- c("effect", "ci", "w.random", "rob_text")
    rightlabs <- c("Proportion (%)", "95%-CI", "Weight", rob_colname)
  } else {
    rightcols <- FALSE
    rightlabs <- NULL
  }

  prop_args <- list(
    x = plot_obj,
    print.tau2 = TRUE,
    print.Q = TRUE,
    print.pval.Q = TRUE,
    print.I2 = TRUE,
    print.w = TRUE,
    pooled.totals = TRUE,
    prediction = TRUE,
    print.pred = TRUE,
    weight.study = "random",
    leftcols = c("studlab", "event", "n"),
    leftlabs = c("Study", "Events", "Total"),
    rightcols = rightcols,
    rightlabs = rightlabs,
    xlab = "Proportion (%)",
    smlab = "",
    text.random = "Total (95% CI)",
    text.common = "Total (95% CI)",
    xlim = c(0, xlim_max),
    pscale = 100,
    squaresize = 0.5,
    fontsize = fontsize,
    fs.hetstat = max(6, fontsize - 2),
    addrows.below.left = if (has_subgroup) 0L else 1L,
    addrows.below.overall = bottom_rows,
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
  if (has_rob && rob_style == "short") {
    graphics::mtext(
      "ROB: L = Low, SC = Some concerns, H = High",
      side = 1,
      line = 3,
      adj = 0,
      cex = 0.8
    )
  }
  .forest_close(save_as, filename, k)
  invisible(TRUE)
}
