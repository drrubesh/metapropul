#' Meta-analysis of means (MD or SMD)
#'
#' Performs a meta-analysis of continuous outcomes using mean difference (MD)
#' or standardised mean difference (SMD). Accepts either raw group-level
#' statistics or pre-computed effect sizes with confidence intervals.
#'
#' @param data A data frame containing the meta-analysis data.
#' @param mean.e Column name for the mean in the experimental group.
#' @param sd.e Column name for the SD in the experimental group.
#' @param n.e Column name for the sample size in the experimental group.
#' @param mean.c Column name for the mean in the control group.
#' @param sd.c Column name for the SD in the control group.
#' @param n.c Column name for the sample size in the control group.
#' @param effect Column name for a pre-computed effect size (MD or SMD).
#'   Optional alternative to supplying raw group data.
#' @param lower Column name for the lower CI bound of \code{effect}.
#' @param upper Column name for the upper CI bound of \code{effect}.
#' @param ci_level Confidence level for pre-computed CIs. Default \code{0.95}.
#' @param studylab Column name for study labels (optional).
#' @param subgroup Optional single character string naming a completely
#'   observed subgroup variable with at least two levels. The default `NULL`
#'   performs no subgroup analysis.
#' @param model \code{"random"} (default) or \code{"fixed"}.
#' @param measure \code{"MD"} (default) or \code{"SMD"}.
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
#' @param verbose Logical. Print progress messages (default \code{FALSE}).
#'
#' @return An object of class \code{"meta_mean"} containing the fitted
#'   \pkg{meta} object, a tidy study table, optional subgroup summary, tidy and
#'   raw leave-one-out influence results, and the requested model settings.
#'
#' @details
#' Raw arm-level inputs are fitted with \code{meta::metacont()}. Pre-computed
#' MD or SMD estimates are fitted with \code{meta::metagen()}; their standard
#' errors are reconstructed from \code{lower}, \code{upper}, and
#' \code{ci_level}. Subgroup estimates are extracted from that same fitted
#' model, so the confidence-interval and heterogeneity methods remain
#' consistent with the overall analysis.
#'
#' @section CSV and Excel columns:
#' Use one row per independent comparison. Raw data require numeric columns
#' for treatment mean, SD, and sample size and control mean, SD, and sample
#' size. Pre-computed data require numeric `effect`, `lower`, and `upper`
#' columns on the MD or SMD scale. To pool a continuous effect supplied with a
#' standard error or variance, use [meta_generic()] with
#' `backtransform = "identity"`. Column headers may differ because each is
#' mapped by its argument.
#'
#' @examples
#' \donttest{
#' data(dat_normand1999, package = "metapropul")
#' result <- meta_mean(
#'   data     = dat_normand1999,
#'   mean.e   = "m1i", sd.e = "sd1i", n.e = "n1i",
#'   mean.c   = "m2i", sd.c = "sd2i", n.c = "n2i",
#'   studylab = "source"
#' )
#' summary(result)
#' }
#'
#' @importFrom stats qnorm
#' @importFrom tibble tibble
#' @export
meta_mean <- function(data,
                      mean.e = NULL,
                      sd.e = NULL,
                      n.e = NULL,
                      mean.c = NULL,
                      sd.c = NULL,
                      n.c = NULL,
                      effect = NULL,
                      lower = NULL,
                      upper = NULL,
                      ci_level = 0.95,
                      studylab = NULL,
                      subgroup = NULL,
                      model = "random",
                      measure = "MD",
                      tau_method = "REML",
                      ci_method = "HK",
                      prediction_interval = TRUE,
                      missing_action = c("exclude", "error"),
                      duplicate_action = c("warn", "error", "make_unique"),
                      singleton_action = c("warn", "retain", "omit", "error"),
                      verbose = FALSE) {
  if (verbose) message("Starting meta-analysis of means...")

  if (!requireNamespace("meta", quietly = TRUE)) {
    stop("The 'meta' package is required. Install with install.packages('meta').",
      call. = FALSE
    )
  }

  measure <- match.arg(measure, c("MD", "SMD"))
  model <- match.arg(model, c("random", "fixed"))
  ci_method <- match.arg(ci_method, c("HK", "classic", "KR"))
  tau_method <- match.arg(
    tau_method,
    c("REML", "PM", "DL", "ML", "HS", "SJ", "HE", "EB")
  )

  # -- Validate basic structure -------------------------------------------------
  if (!inherits(data, "data.frame")) {
    stop("'data' must be a data frame.", call. = FALSE)
  }
  if (nrow(data) < 2L) {
    stop("'data' must contain at least 2 studies.", call. = FALSE)
  }
  if (!is.numeric(ci_level) || length(ci_level) != 1L ||
    ci_level <= 0 || ci_level >= 1) {
    stop("'ci_level' must be a single number between 0 and 1.", call. = FALSE)
  }

  has_raw <- !is.null(mean.e) && !is.null(n.e) && !is.null(mean.c) && !is.null(n.c)
  has_pre <- !is.null(effect)

  if (has_raw && has_pre) {
    stop(
      "Supply either raw group data or pre-computed effects, not both.",
      call. = FALSE
    )
  }

  if (!has_raw && !has_pre) {
    stop("Provide either raw group data (mean.e, sd.e, n.e, mean.c, sd.c, n.c) ",
      "or pre-computed effect sizes (effect, lower, upper).",
      call. = FALSE
    )
  }

  # -- Validate raw path --------------------------------------------------------
  if (has_raw) {
    if (is.null(sd.e) || is.null(sd.c)) {
      stop("'sd.e' and 'sd.c' are required for the raw data path.", call. = FALSE)
    }
    for (col in c(mean.e, sd.e, n.e, mean.c, sd.c, n.c)) {
      if (!col %in% names(data)) {
        stop(sprintf("Column '%s' not found in data.", col), call. = FALSE)
      }
      if (!is.numeric(data[[col]])) {
        stop(sprintf("Column '%s' must be numeric.", col), call. = FALSE)
      }
    }
    if (any(data[[n.e]] <= 0, na.rm = TRUE) || any(data[[n.c]] <= 0, na.rm = TRUE)) {
      stop("Sample sizes must be positive.", call. = FALSE)
    }
    if (any(data[[sd.e]] <= 0, na.rm = TRUE) || any(data[[sd.c]] <= 0, na.rm = TRUE)) {
      stop("Standard deviations must be positive.", call. = FALSE)
    }
  }

  # -- Validate pre-computed path -----------------------------------------------
  if (has_pre) {
    if (is.null(lower) || is.null(upper)) {
      stop("Please provide 'lower' and 'upper' bounds when supplying 'effect'.",
        call. = FALSE
      )
    }
    for (col in c(effect, lower, upper)) {
      if (!col %in% names(data)) {
        stop(sprintf("Column '%s' not found in data.", col), call. = FALSE)
      }
      if (!is.numeric(data[[col]])) {
        stop(sprintf("Column '%s' must be numeric.", col), call. = FALSE)
      }
    }
    if (any(data[[lower]] > data[[upper]], na.rm = TRUE)) {
      stop("'lower' must be <= 'upper' for all rows.", call. = FALSE)
    }
  }

  # -- Labels, exclusions & subgroup -------------------------------------------
  required <- if (has_raw) c(mean.e, sd.e, n.e, mean.c, sd.c, n.c) else
    c(effect, lower, upper)
  prepared <- .prepare_analysis_data(
    data, required = required, studylab = studylab, subgroup = subgroup,
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
  if (has_raw) {
    meta_result <- meta::metacont(
      n.e              = data[[n.e]],
      mean.e           = data[[mean.e]],
      sd.e             = data[[sd.e]],
      n.c              = data[[n.c]],
      mean.c           = data[[mean.c]],
      sd.c             = data[[sd.c]],
      studlab          = study_labels,
      sm               = measure,
      method.tau       = tau_method,
      method.random.ci = ci_method,
      common           = (model == "fixed"),
      random           = (model == "random"),
      prediction       = prediction_interval,
      subgroup         = subgroup_var
    )
  } else {
    z_val <- stats::qnorm(1 - (1 - ci_level) / 2)
    meta_result <- meta::metagen(
      TE               = data[[effect]],
      seTE             = (data[[upper]] - data[[lower]]) / (2 * z_val),
      studlab          = study_labels,
      sm               = measure,
      method.tau       = tau_method,
      method.random.ci = ci_method,
      common           = (model == "fixed"),
      random           = (model == "random"),
      prediction       = prediction_interval,
      subgroup         = subgroup_var
    )
  }

  # -- Study-level table --------------------------------------------------------
  # Honour prediction_interval=FALSE: null out predict slots if not requested.
  if (!prediction_interval) {
    meta_result$lower.predict <- NULL
    meta_result$upper.predict <- NULL
  }
  # Use per-study TE/lower/upper vectors, not pooled scalars.
  tidy_tbl <- tibble::tibble(
    Study = meta_result$studlab,
    Estimate = meta_result$TE,
    lower = meta_result$lower,
    upper = meta_result$upper,
    weight = if (model == "random") {
      meta_result$w.random / sum(meta_result$w.random) * 100
    } else {
      meta_result$w.fixed / sum(meta_result$w.fixed) * 100
    },
    subgroup = if (!is.null(subgroup)) subgroup_var else NA
  )

  # -- Subgroup summary ---------------------------------------------------------
  meta.subgroup.summary <- .subgroup_summary(meta_result, model)

  # -- Influence analysis -------------------------------------------------------
  inf_random <- model == "random"
  inf_common <- model == "fixed"

  influence_obj <- tryCatch(
    {
      inf <- meta::metainf(
        meta_result,
        random = inf_random,
        common = inf_common
      )
      inf$studlab <- make.unique(inf$studlab)
      inf
    },
    error = function(e) NULL
  )

  influence_data <- if (!is.null(influence_obj)) {
    tibble::tibble(
      Study = influence_obj$studlab,
      Estimate = influence_obj$TE,
      lower = influence_obj$lower,
      upper = influence_obj$upper,
      p.value = influence_obj$pval,
      Tau2 = influence_obj$tau2,
      I2 = influence_obj$I2 * 100
    )
  } else {
    NULL
  }

  structure(
    list(
      meta                  = meta_result,
      table                 = tidy_tbl,
      meta.subgroup.summary = meta.subgroup.summary,
      influence.analysis    = influence_data,
      influence.meta        = influence_obj,
      subgroup_test         = .subgroup_test(meta_result),
      analysis_data         = prepared$analysis_data,
      excluded_data         = prepared$excluded_data,
      exclusion_log         = prepared$exclusion_log,
      label_audit           = prepared$label_audit,
      settings              = list(input = if (has_raw) "raw" else "precomputed",
        prediction_interval = prediction_interval,
        missing_action = match.arg(missing_action),
        duplicate_action = match.arg(duplicate_action),
        singleton_action = match.arg(singleton_action)),
      model                 = model,
      measure               = measure,
      tau_method            = tau_method,
      ci_method             = ci_method,
      subgroup              = !is.null(subgroup)
    ),
    class = "meta_mean"
  )
}
