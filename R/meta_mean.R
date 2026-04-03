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
#' @param subgroup Column name for subgroup variable (optional).
#' @param model \code{"random"} (default) or \code{"fixed"}.
#' @param measure \code{"MD"} (default) or \code{"SMD"}.
#' @param tau_method Tau\eqn{^2} estimator. Default \code{"REML"}.
#' @param ci_method CI method for the pooled estimate.
#'   \code{"HK"} (default), \code{"classic"}, or \code{"KR"}.
#' @param prediction_interval Logical. Compute a prediction interval (default
#'   \code{TRUE}).
#' @param verbose Logical. Print progress messages (default \code{FALSE}).
#'
#' @return An object of class \code{"meta_mean"}.
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

  # -- Labels & subgroup --------------------------------------------------------
  if (!is.null(studylab)) {
    if (!studylab %in% names(data)) {
      stop(sprintf("Column '%s' not found in data.", studylab), call. = FALSE)
    }
    study_labels <- as.character(data[[studylab]])
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
    Estimate = round(meta_result$TE, 3),
    lower = round(meta_result$lower, 3),
    upper = round(meta_result$upper, 3),
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
      Estimate = round(sg_est, 3),
      lower    = round(sg_lower, 3),
      upper    = round(sg_upper, 3),
      Tau2     = round(meta_result$tau2.w, 4),
      I2       = round(meta_result$I2.w * 100, 1)
    )
  }

  # -- Influence analysis -------------------------------------------------------
  inf_random <- model == "random"
  inf_common <- model == "fixed"
  influence <- tryCatch(
    {
      inf <- meta::metainf(meta_result,
        random = inf_random, common = inf_common
      )
      inf$studlab <- make.unique(inf$studlab)
      inf
    },
    error = function(e) NULL
  )

  structure(
    list(
      meta                  = meta_result,
      table                 = tidy_tbl,
      meta.subgroup.summary = meta.subgroup.summary,
      influence.analysis    = influence,
      model                 = model,
      measure               = measure,
      tau_method            = tau_method,
      ci_method             = ci_method,
      subgroup              = !is.null(subgroup)
    ),
    class = "meta_mean"
  )
}
