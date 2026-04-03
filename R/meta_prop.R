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
#' @param subgroup Column name for subgroup variable (optional).
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
#' @param verbose Logical. Print progress messages (default \code{FALSE}).
#'
#' @return An object of class \code{"meta_prop"}.
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
                      verbose = FALSE) {
  if (verbose) message("Starting meta-analysis of proportions...")

  if (!requireNamespace("meta", quietly = TRUE)) {
    stop("The 'meta' package is required. Install with install.packages('meta').",
      call. = FALSE
    )
  }

  sm <- match.arg(sm, c("PLOGIT", "PFT"))
  model <- match.arg(model, c("random", "fixed"))
  ci_method <- match.arg(ci_method, c("HK", "classic", "KR"))
  tau_method <- match.arg(
    tau_method,
    c("REML", "PM", "DL", "ML", "HS", "SJ", "HE", "EB")
  )

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

  # -- Labels & subgroup --------------------------------------------------------
  if (!is.null(studylab)) {
    if (!studylab %in% names(data)) {
      stop(sprintf("Column '%s' not found in data.", studylab), call. = FALSE)
    }
    study_labels <- make.unique(as.character(data[[studylab]]))
  } else {
    study_labels <- paste0("Study_", seq_len(nrow(data)))
  }

  if (!is.null(subgroup)) {
    if (!subgroup %in% names(data)) {
      stop(sprintf("Column '%s' not found in data.", subgroup), call. = FALSE)
    }
    subgroup_var <- data[[subgroup]]
  } else {
    subgroup_var <- NULL
  }

  # -- Fit model ----------------------------------------------------------------
  meta_result <- meta::metaprop(
    event            = data[[event]],
    n                = data[[n]],
    studlab          = study_labels,
    sm               = sm,
    method           = "Inverse",
    method.tau       = tau_method,
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
  .bt <- if (sm == "PLOGIT") {
    function(x) stats::plogis(x) * 100
  } else {
    # PFT inverse: sin^2(x), clamped to [0, 1]
    function(x) pmin(pmax(sin(x)^2, 0), 1) * 100
  }

  # -- Study-level table --------------------------------------------------------
  # Honour prediction_interval=FALSE: null out predict slots if not requested.
  if (!prediction_interval) {
    meta_result$lower.predict <- NULL
    meta_result$upper.predict <- NULL
  }
  # Use per-study TE/lower/upper vectors (not pooled scalars).
  tidy_tbl <- tibble::tibble(
    Study = meta_result$studlab,
    Proportion = round(.bt(meta_result$TE), 1),
    lower = round(.bt(meta_result$lower), 1),
    upper = round(.bt(meta_result$upper), 1),
    weight = round(if (model == "random") {
      meta_result$w.random / sum(meta_result$w.random) * 100
    } else {
      meta_result$w.fixed / sum(meta_result$w.fixed) * 100
    }, 1),
    subgroup = if (!is.null(subgroup)) subgroup_var else NA
  )

  # -- Subgroup summary ---------------------------------------------------------
  meta.subgroup.summary <- NULL
  if (!is.null(subgroup) && !is.null(meta_result$subgroup.levels)) {
    if (model == "random") {
      sg_est <- meta_result$TE.random.w
      sg_lower <- meta_result$lower.random.w
      sg_upper <- meta_result$upper.random.w
    } else {
      sg_est <- meta_result$TE.common.w
      sg_lower <- meta_result$lower.common.w
      sg_upper <- meta_result$upper.common.w
    }
    meta.subgroup.summary <- tibble::tibble(
      Subgroup = meta_result$subgroup.levels,
      Estimate = round(.bt(sg_est), 1),
      lower    = round(.bt(sg_lower), 1),
      upper    = round(.bt(sg_upper), 1),
      Tau2     = round(meta_result$tau2.w, 4),
      I2       = round(meta_result$I2.w * 100, 1)
    )
  }

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
    Estimate = round(.bt(pooled_est), 1),
    lower = round(.bt(pooled_lower), 1),
    upper = round(.bt(pooled_upper), 1),
    pred.lower = if (!is.null(pooled_pi_lo) && !is.null(pooled_pi_lo) &&
      length(pooled_pi_lo) > 0 && !is.na(pooled_pi_lo)) {
      round(.bt(pooled_pi_lo), 1)
    } else {
      NA_real_
    },
    pred.upper = if (!is.null(pooled_pi_hi) && !is.null(pooled_pi_hi) &&
      length(pooled_pi_hi) > 0 && !is.na(pooled_pi_hi)) {
      round(.bt(pooled_pi_hi), 1)
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
      Study      = influence_obj$studlab[keep_rows],
      Proportion = round(.bt(influence_obj$TE[keep_rows]), 1),
      lower      = round(.bt(influence_obj$lower[keep_rows]), 1),
      upper      = round(.bt(influence_obj$upper[keep_rows]), 1)
    )
  } else {
    NULL
  }

  structure(
    list(
      meta                  = meta_result,
      table                 = tidy_tbl,
      meta.summary          = pooled,
      meta.subgroup.summary = meta.subgroup.summary,
      influence.analysis    = influence_data,
      influence.meta        = influence_obj,
      model                 = model,
      measure               = "Proportion",
      sm                    = sm,
      tau_method            = tau_method,
      ci_method             = ci_method,
      subgroup              = !is.null(subgroup)
    ),
    class = "meta_prop"
  )
}
