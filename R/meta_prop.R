#' Meta-analysis of proportions
#'
#' Performs a meta-analysis of proportions using logit (\code{"PLOGIT"}) or
#' Freeman-Tukey double arcsine (\code{"PFT"}) transformation via
#' \code{meta::metaprop()}. Results are expressed as percentages on the
#' back-transformed scale. Prediction intervals, subgroup analysis, and
#' leave-one-out influence analysis are included by default.
#'
#' @param data A data frame with proportion data.
#' @param event Column name for event counts.
#' @param n Column name for total counts.
#' @param studylab Column name for study labels (optional).
#' @param subgroup Optional single character string naming a completely
#'   observed subgroup variable. At least two levels are required. Levels with
#'   only one study are allowed with a warning because their within-subgroup
#'   heterogeneity is not estimable. The default `NULL` performs no subgroup
#'   analysis.
#' @param model \code{"random"} (default) or \code{"fixed"}.
#' @param sm Summary measure: \code{"PLOGIT"} (logit, default) or
#'   \code{"PFT"} (Freeman-Tukey double arcsine -- preferred when proportions
#'   are near 0 or 1). Note that \code{"PFT"} results are back-transformed
#'   using \code{meta}'s built-in method; displayed values are always on the
#'   proportion percentage scale.
#' @param tau_method Tau\eqn{^2} estimator. Default \code{"REML"}.
#' @param ci_method CI method for the pooled estimate.
#'   \code{"HK"} (default), \code{"classic"}, or \code{"KR"}.
#' @param prediction_interval Logical. Compute a prediction interval (default
#'   \code{TRUE}).
#' @param missing_action How incomplete analysis rows are handled: `"exclude"`
#'   records and removes them, while `"error"` stops before fitting.
#' @param duplicate_action How duplicate study labels are handled: `"warn"`
#'   makes them unique and records the change, `"error"` stops, and
#'   `"make_unique"` records the change without warning.
#' @param singleton_action Handling of subgroup levels containing one study:
#'   `"warn"`, `"retain"`, `"omit"`, or `"error"`.
#' @param pool_method `"inverse"` for inverse-variance pooling or `"glmm"`
#'   for a random-intercept logistic GLMM. GLMM is available only with
#'   `sm = "PLOGIT"` and `model = "random"`.
#' @param verbose Logical. Print progress messages (default \code{FALSE}).
#'
#' @return An object of class \code{"meta_prop"}, a list containing:
#' \describe{
#'   \item{meta}{The fitted \pkg{meta} object on its analysis scale.}
#'   \item{table}{Study estimates, confidence limits, weights, and subgroup
#'   assignments on the percentage scale.}
#'   \item{meta.summary}{The pooled estimate, confidence interval, prediction
#'   interval, I-squared, and tau-squared.}
#'   \item{meta.subgroup.summary}{One pooled row per subgroup, or \code{NULL}.}
#'   \item{influence.analysis}{A tidy leave-one-out results table.}
#'   \item{influence.meta}{The underlying \code{metainf} object.}
#'   \item{model,measure,sm,tau_method,ci_method,subgroup}{Analysis settings.}
#' }
#'
#' @details
#' The model is fitted by \code{meta::metaprop()} using inverse-variance
#' weighting. PLOGIT results are back-transformed with the inverse logit. PFT
#' results use the approximate inverse Freeman--Tukey double-arcsine transform;
#' values returned by this package are percentages. For subgroup analyses,
#' the overall model and subgroup models are taken from the same fitted object,
#' and the reported subgroup-difference test is available through
#' \code{summary()}.
#'
#' @section CSV and Excel columns:
#' Use one row per study. The event and total-sample columns must be numeric,
#' with `0 <= event <= n` and `n > 0`. A study-label column and a completely
#' observed subgroup column are optional. Column headers need not literally be
#' `event`, `n`, `studylab`, or `subgroup`; pass the actual header names to the
#' corresponding arguments.
#'
#' @examples
#' \donttest{
#' data(dat_bcg, package = "metapropul")
#' result <- meta_prop(
#'   data     = dat_bcg,
#'   event    = "tpos",
#'   n        = "npos",
#'   studylab = "author"
#' )
#' summary(result)
#' }
#'
#' @importFrom stats plogis
#' @importFrom tibble tibble
#' @export
meta_prop <- function(data,
                      event,
                      n,
                      studylab = NULL,
                      subgroup = NULL,
                      model = "random",
                      sm = "PLOGIT",
                      tau_method = "REML",
                      ci_method = "HK",
                      prediction_interval = TRUE,
                      missing_action = c("exclude", "error"),
                      duplicate_action = c("warn", "error", "make_unique"),
                      singleton_action = c("warn", "retain", "omit", "error"),
                      pool_method = c("inverse", "glmm"),
                      verbose = FALSE) {
  if (verbose) message("Starting meta-analysis of proportions...")

  if (!requireNamespace("meta", quietly = TRUE)) {
    stop("The 'meta' package is required. Install with install.packages('meta').",
      call. = FALSE
    )
  }

  sm <- match.arg(sm, c("PLOGIT", "PFT"))
  model <- match.arg(model, c("random", "fixed"))
  pool_method <- match.arg(pool_method)
  ci_method <- match.arg(ci_method, c("HK", "classic", "KR"))
  tau_method <- match.arg(
    tau_method,
    c("REML", "PM", "DL", "ML", "HS", "SJ", "HE", "EB")
  )
  if (identical(sm, "PFT")) {
    warning(
      "Freeman-Tukey back-transformation is sample-size dependent and can be misleading; prefer sm = 'PLOGIT'.",
      call. = FALSE
    )
  }
  if (pool_method == "glmm" && (sm != "PLOGIT" || model != "random")) {
    stop("'pool_method = glmm' requires sm = 'PLOGIT' and model = 'random'.",
      call. = FALSE)
  }
  effective_tau_method <- if (pool_method == "glmm") "ML" else tau_method

  # -- Validation ---------------------------------------------------------------
  if (!inherits(data, "data.frame")) {
    stop("'data' must be a data frame.", call. = FALSE)
  }
  if (nrow(data) < 2L) {
    stop("'data' must contain at least 2 studies.", call. = FALSE)
  }
  for (col in c(event, n)) {
    if (!col %in% names(data)) {
      stop(sprintf("Column '%s' not found in data.", col), call. = FALSE)
    }
    if (!is.numeric(data[[col]])) {
      stop(sprintf("Column '%s' must be numeric.", col), call. = FALSE)
    }
  }
  if (any(data[[n]] <= 0, na.rm = TRUE)) {
    stop("Sample sizes ('n') must be positive.", call. = FALSE)
  }
  if (any(data[[event]] > data[[n]], na.rm = TRUE)) {
    stop("Event counts cannot exceed sample sizes.", call. = FALSE)
  }
  if (any(data[[event]] < 0, na.rm = TRUE)) {
    stop("Event counts cannot be negative.", call. = FALSE)
  }

  # -- Labels, exclusions & subgroup -------------------------------------------
  prepared <- .prepare_analysis_data(
    data, required = c(event, n), studylab = studylab, subgroup = subgroup,
    missing_action = missing_action, duplicate_action = duplicate_action,
    singleton_action = singleton_action
  )
  data <- prepared$data
  study_labels <- prepared$labels
  if (nrow(data) < 2L) {
    stop("Fewer than 2 complete studies remain for analysis.", call. = FALSE)
  }

  subgroup_var <- .validate_subgroup(data, subgroup, singleton_action)

  # -- Fit model ----------------------------------------------------------------
  meta_result <- meta::metaprop(
    event            = data[[event]],
    n                = data[[n]],
    studlab          = study_labels,
    sm               = sm,
    method           = if (pool_method == "inverse") "Inverse" else "GLMM",
    method.tau       = effective_tau_method,
    method.random.ci = ci_method,
    random           = (model == "random"),
    common           = (model == "fixed"),
    incr             = 0.5,
    prediction       = prediction_interval,
    subgroup         = subgroup_var,
    backtransf       = TRUE
  )

  # -- Back-transform helper ----------------------------------------------------
  # meta stores TE on the transformed scale (logit for PLOGIT, arcsine for PFT).
  # With backtransf = TRUE the meta object already carries back-transformed
  # values in $TE.predict etc., but for study-level TE we must transform manually.
  # For PFT: meta uses meta::backtransf.prop() internally. We replicate the
  # correct inverse: asin(sqrt(p)) -> p = sin^2(TE). For PLOGIT: plogis().
  .bt <- function(x) .backtransform_prop(x, sm) * 100

  # -- Study-level table --------------------------------------------------------
  # Honour prediction_interval=FALSE: null out predict slots if not requested.
  if (!prediction_interval) {
    meta_result$lower.predict <- NULL
    meta_result$upper.predict <- NULL
  }
  # Use per-study TE/lower/upper vectors (not pooled scalars).
  tidy_tbl <- tibble::tibble(
    Study = meta_result$studlab,
    Proportion = .bt(meta_result$TE),
    lower = .bt(meta_result$lower),
    upper = .bt(meta_result$upper),
    weight = if (model == "random") {
      meta_result$w.random / sum(meta_result$w.random) * 100
    } else {
      meta_result$w.fixed / sum(meta_result$w.fixed) * 100
    },
    subgroup = if (!is.null(subgroup)) subgroup_var else NA
  )

  # -- Subgroup summary ---------------------------------------------------------
  meta.subgroup.summary <- .subgroup_summary(
    meta_result, model, transform = .bt
  )

  # -- Pooled summary -----------------------------------------------------------
  if (model == "random") {
    pooled_est <- meta_result$TE.random
    pooled_lower <- meta_result$lower.random
    pooled_upper <- meta_result$upper.random
    pooled_pi_lo <- if (prediction_interval) meta_result$lower.predict else NULL
    pooled_pi_hi <- if (prediction_interval) meta_result$upper.predict else NULL
  } else {
    pooled_est <- meta_result$TE.common
    pooled_lower <- meta_result$lower.common
    pooled_upper <- meta_result$upper.common
    pooled_pi_lo <- NULL
    pooled_pi_hi <- NULL
  }

  pooled <- tibble::tibble(
    Estimate = .bt(pooled_est),
    lower = .bt(pooled_lower),
    upper = .bt(pooled_upper),
    pred.lower = if (!is.null(pooled_pi_lo) && !is.null(pooled_pi_lo) &&
      length(pooled_pi_lo) > 0 && !is.na(pooled_pi_lo)) {
      .bt(pooled_pi_lo)
    } else {
      NA_real_
    },
    pred.upper = if (!is.null(pooled_pi_hi) && !is.null(pooled_pi_hi) &&
      length(pooled_pi_hi) > 0 && !is.na(pooled_pi_hi)) {
      .bt(pooled_pi_hi)
    } else {
      NA_real_
    },
    # I2 from meta is 0-1 scale; store as-is, display code multiplies by 100
    I2 = meta_result$I2,
    Tau2 = meta_result$tau2
  )

  # -- Influence ----------------------------------------------------------------
  inf_random <- model == "random"
  inf_common <- model == "fixed"

  influence_obj <- tryCatch(
    meta::metainf(meta_result, random = inf_random, common = inf_common),
    error = function(e) NULL
  )

  influence_data <- if (!is.null(influence_obj)) {
    keep_rows <- influence_obj$studlab != " " & !is.na(influence_obj$TE)
    tibble::tibble(
      Study = influence_obj$studlab[keep_rows],
      Proportion = .bt(influence_obj$TE[keep_rows]),
      lower = .bt(influence_obj$lower[keep_rows]),
      upper = .bt(influence_obj$upper[keep_rows])
    )
  } else {
    NULL
  }

  structure(
    list(
      meta = meta_result,
      table = tidy_tbl,
      meta.summary = pooled,
      meta.subgroup.summary = meta.subgroup.summary,
      influence.analysis = influence_data,
      influence.meta = influence_obj,
      subgroup_test = .subgroup_test(meta_result),
      analysis_data = prepared$analysis_data,
      excluded_data = prepared$excluded_data,
      exclusion_log = prepared$exclusion_log,
      label_audit = prepared$label_audit,
      settings = list(input = "raw", prediction_interval = prediction_interval,
        pool_method = pool_method,
        missing_action = match.arg(missing_action),
        duplicate_action = match.arg(duplicate_action),
        singleton_action = match.arg(singleton_action)),
      model = model,
      measure = "Proportion",
      sm = sm,
      tau_method = effective_tau_method,
      ci_method = ci_method,
      subgroup = !is.null(subgroup)
    ),
    class = "meta_prop"
  )
}
