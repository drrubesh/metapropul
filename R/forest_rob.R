#' Combined forest plot and risk-of-bias traffic lights
#'
#' Adds a study-level risk-of-bias table to a fitted meta-analysis and draws
#' the forest estimates and coloured domain judgements in one aligned figure.
#' This is useful for review manuscripts in which readers need to compare each
#' study's effect estimate with its methodological limitations.
#'
#' @param x A supported metapropul meta-analysis object.
#' @param rob_data A data frame containing one row per study and risk-of-bias
#'   judgements in separate columns.
#' @param studylab Character string naming the study-label column in
#'   `rob_data`. Labels must match the fitted study labels in `x`.
#' @param tool Character string specifying the appraisal tool. See
#'   [plot_rob()] for supported values.
#' @param domains Character vector naming the judgement columns. When an
#'   overall column is included, identify it with `overall`.
#' @param overall Optional character string naming the overall-judgement
#'   column. If `NULL`, a column in `domains` named `overall` (ignoring case)
#'   is detected automatically.
#' @param levels Optional allowed judgement levels for `tool = "Custom"`.
#' @param colours Optional named colours for `tool = "Custom"`.
#' @param has_overall Logical indicating whether a custom tool has an overall
#'   judgement.
#' @param title Optional plot title. No title is drawn by default.
#' @param new Logical passed to the forest engine. The default `FALSE` avoids
#'   an empty first page when a combined plot is written to a file device.
#' @param ... Further arguments passed to [forest_meta()], including
#'   `save_as`, `filename`, `width`, and `height`.
#'
#' @return Invisibly returns `TRUE`, as does [forest_meta()].
#'
#' @details
#' Study labels are matched exactly and reordered internally to the fitted
#' meta-analysis. Missing fitted studies and duplicate labels are errors,
#' because either condition could place a judgement beside the wrong estimate.
#' Extra rows in `rob_data` are ignored with a warning. Up to ten non-overall
#' domains are supported by the underlying forest-plot engine.
#'
#' @examples
#' \donttest{
#' data(dat_bcg, package = "metapropul")
#' fit <- meta_prop(dat_bcg, "tpos", "npos", "author")
#' labels <- fit$meta$studlab
#' rob <- data.frame(
#'   study = labels,
#'   randomization = rep(c("Low", "Some concerns"), length.out = length(labels)),
#'   reporting = rep(c("Low", "High"), length.out = length(labels)),
#'   overall = rep(c("Low", "High"), length.out = length(labels))
#' )
#' forest_rob(
#'   fit, rob, studylab = "study", tool = "Custom",
#'   domains = c("randomization", "reporting", "overall"),
#'   levels = c("Low", "Some concerns", "High")
#' )
#' }
#'
#' @export
forest_rob <- function(x,
                       rob_data,
                       studylab,
                       tool = "GENERIC",
                       domains = NULL,
                       overall = NULL,
                       levels = NULL,
                       colours = NULL,
                       has_overall = TRUE,
                       title = NULL,
                       new = FALSE,
                       ...) {
  if (!inherits(x, c("meta_ratio", "meta_mean", "meta_prop",
      "meta_generic", "meta_cor", "meta_rate"))) {
    stop("'x' must be a supported metapropul meta-analysis object.", call. = FALSE)
  }

  template <- .get_rob_template(tool, domains, levels, colours, has_overall)
  if (is.null(domains)) domains <- template$domains
  if (is.null(domains) || !length(domains)) {
    stop("'domains' must be provided for this tool.", call. = FALSE)
  }
  .validate_rob_data(rob_data, studylab, domains, template)

  meta_labels <- as.character(x$meta$studlab)
  rob_labels <- as.character(rob_data[[studylab]])
  if (anyDuplicated(rob_labels)) {
    stop("'rob_data' contains duplicate study labels.", call. = FALSE)
  }
  missing_labels <- setdiff(meta_labels, rob_labels)
  if (length(missing_labels)) {
    stop(sprintf("Risk-of-bias data are missing fitted study label(s): %s",
      paste(missing_labels, collapse = ", ")), call. = FALSE)
  }
  extra_labels <- setdiff(rob_labels, meta_labels)
  if (length(extra_labels)) {
    warning(sprintf("Ignoring risk-of-bias row(s) not present in the model: %s",
      paste(extra_labels, collapse = ", ")), call. = FALSE)
  }

  if (is.null(overall)) {
    detected <- domains[tolower(domains) == "overall"]
    if (length(detected)) overall <- detected[[1L]]
  }
  if (!is.null(overall) && !overall %in% domains) {
    stop("'overall' must also be included in 'domains'.", call. = FALSE)
  }
  item_domains <- setdiff(domains, overall %||% character())
  if (!length(item_domains)) {
    stop("At least one non-overall ROB domain is required.", call. = FALSE)
  }
  if (length(item_domains) > 10L) {
    stop("A maximum of ten non-overall ROB domains is supported.", call. = FALSE)
  }

  ordered <- rob_data[match(meta_labels, rob_labels), , drop = FALSE]
  args <- stats::setNames(as.list(ordered[item_domains]),
    paste0("item", seq_along(item_domains)))
  args$studlab <- meta_labels
  if (!is.null(overall)) args$overall <- ordered[[overall]]
  args$data <- x$meta
  args$domains <- item_domains
  args$categories <- template$levels
  args$col <- unname(template$colours[template$levels])
  symbol_key <- tolower(template$levels)
  args$symbols <- ifelse(
    grepl("low|good", symbol_key), "+",
    ifelse(grepl("high|serious|critical|poor", symbol_key), "-", "?")
  )
  args$warn <- FALSE

  combined <- x
  combined$meta <- do.call(meta::rob, args)
  forest_meta(combined, title = title, new = new, ...)
}
