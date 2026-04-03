#' Meta-regression
#'
#' Performs meta-regression on a fitted \code{meta_ratio}, \code{meta_mean},
#' or \code{meta_prop} object using \code{metafor::rma()}.
#' Coefficients are reported on the model scale and, where appropriate,
#' on a back-transformed scale.
#'
#' @param meta_object A fitted object from \code{meta_ratio()},
#'   \code{meta_mean()}, or \code{meta_prop()}.
#' @param data The original dataset used to fit the meta-analysis model.
#' @param moderators A formula specifying the moderators
#'   (e.g. \code{~ age + region}).
#' @param studylab Character string naming the study label column in
#'   \code{data}. This is required so studies are matched safely by label.
#'
#' @return An object of class \code{"meta_reg"}.
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
#' reg <- meta_reg(
#'   meta_object = result,
#'   data = dat_bcg,
#'   moderators = ~ablat,
#'   studylab = "author"
#' )
#' summary(reg)
#' }
#'
#' @importFrom tibble tibble
#' @importFrom stats complete.cases
#' @export
meta_reg <- function(meta_object,
                     data,
                     moderators,
                     studylab) {
  if (!inherits(meta_object, c("meta_prop", "meta_ratio", "meta_mean"))) {
    stop(
      "meta_object must be from meta_prop(), meta_ratio(), or meta_mean().",
      call. = FALSE
    )
  }

  if (missing(data) || !inherits(data, "data.frame")) {
    stop("'data' must be a data frame.", call. = FALSE)
  }

  if (missing(moderators)) {
    stop(
      "Provide a moderators formula, e.g. ~ age or ~ region + dose.",
      call. = FALSE
    )
  }

  if (!inherits(moderators, "formula")) {
    stop("'moderators' must be a formula.", call. = FALSE)
  }

  if (missing(studylab) || is.null(studylab) || !nzchar(studylab)) {
    stop(
      "Provide 'studylab' to match studies safely between meta_object and data.",
      call. = FALSE
    )
  }

  if (!studylab %in% names(data)) {
    stop(sprintf("Column '%s' not found in data.", studylab), call. = FALSE)
  }

  if (!requireNamespace("metafor", quietly = TRUE)) {
    stop(
      "The 'metafor' package is required. Install with install.packages('metafor').",
      call. = FALSE
    )
  }

  if (inherits(meta_object, "meta_prop") && !identical(meta_object$sm, "PLOGIT")) {
    stop(
      "meta_reg() currently supports meta_prop objects only when sm = 'PLOGIT'.",
      call. = FALSE
    )
  }

  meta_obj <- meta_object$meta
  if (!inherits(meta_obj, "meta")) {
    stop("meta_object does not contain a valid 'meta' component.", call. = FALSE)
  }

  if (is.null(meta_obj$studlab) || is.null(meta_obj$TE) || is.null(meta_obj$seTE)) {
    stop(
      "meta_object$meta must contain 'studlab', 'TE', and 'seTE'.",
      call. = FALSE
    )
  }

  meta_studies <- make.unique(as.character(meta_obj$studlab))
  data_labels <- make.unique(as.character(data[[studylab]]))

  matched_idx <- match(meta_studies, data_labels)

  if (anyNA(matched_idx)) {
    missing_n <- sum(is.na(matched_idx))
    stop(
      paste0(
        "Mismatch: ", missing_n,
        " study label(s) in meta_object were not found in data. ",
        "Check that 'studylab' values match exactly."
      ),
      call. = FALSE
    )
  }

  regression_data <- data[matched_idx, , drop = FALSE]

  mod_terms <- all.vars(moderators)

  if (length(mod_terms) == 0L) {
    stop(
      "'moderators' must include at least one moderator variable.",
      call. = FALSE
    )
  }

  missing_cols <- mod_terms[!mod_terms %in% names(regression_data)]
  if (length(missing_cols) > 0L) {
    stop(
      sprintf(
        "Moderator column(s) not found in data: %s",
        paste(missing_cols, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  regression_data$yi <- meta_obj$TE
  regression_data$vi <- meta_obj$seTE^2
  regression_data$.study_label_meta <- meta_studies

  cc <- stats::complete.cases(regression_data[, mod_terms, drop = FALSE]) &
    is.finite(regression_data$yi) &
    is.finite(regression_data$vi)

  n_excluded <- sum(!cc)

  excluded_studies <- regression_data$.study_label_meta[!cc]

  if (sum(cc) < 2L) {
    stop(
      "Not enough complete studies available to fit meta-regression after exclusions.",
      call. = FALSE
    )
  }

  if (n_excluded > 0L) {
    warning(
      paste0(
        n_excluded, " stud", if (n_excluded == 1L) "y was" else "ies were",
        " excluded due to missing moderator values or invalid model inputs: ",
        paste(excluded_studies, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  regression_data <- regression_data[cc, , drop = FALSE]

  reg_model <- metafor::rma(
    yi = regression_data$yi,
    vi = regression_data$vi,
    mods = moderators,
    data = regression_data,
    method = "REML"
  )

  tau2_null <- meta_obj$tau2
  tau2_model <- reg_model$tau2

  if (!is.finite(tau2_null) || tau2_null < 1e-10) {
    r2_analog <- NA_real_
  } else {
    r2_analog <- 100 * (tau2_null - tau2_model) / tau2_null
    r2_analog <- round(max(0, min(100, r2_analog)), 2)
  }

  measure <- meta_object$measure
  is_ratio <- measure %in% c("OR", "RR", "HR")
  is_prop <- inherits(meta_object, "meta_prop")

  est_raw <- as.numeric(reg_model$beta)
  ci_lb_raw <- reg_model$ci.lb
  ci_ub_raw <- reg_model$ci.ub

  if (is_ratio) {
    est_bt <- round(exp(est_raw), 3)
    ci_lb_bt <- round(exp(ci_lb_raw), 3)
    ci_ub_bt <- round(exp(ci_ub_raw), 3)
    bt_label <- paste0(measure, " (back-transformed)")
  } else if (is_prop) {
    est_bt <- round(.backtransform_prop(est_raw, meta_object$sm) * 100, 2)
    ci_lb_bt <- round(.backtransform_prop(ci_lb_raw, meta_object$sm) * 100, 2)
    ci_ub_bt <- round(.backtransform_prop(ci_ub_raw, meta_object$sm) * 100, 2)
    bt_label <- "Proportion (%)"
  } else {
    est_bt <- NA_real_
    ci_lb_bt <- NA_real_
    ci_ub_bt <- NA_real_
    bt_label <- NA_character_
  }

  tidy_tbl <- tibble::tibble(
    Term = rownames(reg_model$beta),
    Estimate = round(est_raw, 4),
    CI.Lower = round(ci_lb_raw, 4),
    CI.Upper = round(ci_ub_raw, 4),
    p.value = reg_model$pval,
    Estimate_bt = est_bt,
    CI.Lower_bt = ci_lb_bt,
    CI.Upper_bt = ci_ub_bt
  )

  attr(tidy_tbl, "bt_label") <- bt_label

  meta_summary <- tibble::tibble(
    tau2_null = round(tau2_null, 4),
    tau2 = round(tau2_model, 4),
    R2_analog = r2_analog,
    QE_pval = reg_model$QEp,
    QM = as.numeric(reg_model$QM),
    k_included = reg_model$k,
    k_excluded = n_excluded
  )

  structure(
    list(
      model = "meta-regression",
      meta = reg_model,
      table = tidy_tbl,
      meta.summary = meta_summary,
      r2_analog = r2_analog,
      measure = measure,
      sm = if (!is.null(meta_object$sm)) meta_object$sm else NULL,
      excluded_studies = excluded_studies,
      call = match.call()
    ),
    class = "meta_reg"
  )
}
