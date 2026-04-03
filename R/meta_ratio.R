#' Meta-analysis of ratio measures
#'
#' Conducts a meta-analysis of ratio effect measures using either raw
#' event-count data or pre-computed study-level effect estimates with
#' confidence intervals.
#'
#' Two input formats are supported:
#' \itemize{
#'   \item Raw 2 x 2 data using \code{event.e}, \code{n.e},
#'   \code{event.c}, and \code{n.c}
#'   \item Pre-computed effect sizes using \code{effect}, \code{lower},
#'   and \code{upper}
#' }
#'
#' The function supports odds ratios (OR), risk ratios (RR), and hazard
#' ratios (HR). Hazard ratios require pre-computed effect sizes and
#' cannot be derived from raw event-count data.
#'
#' @param data A data frame containing the meta-analysis dataset.
#'
#' @param event.e Character string giving the column name for the number
#'   of events in the experimental or exposed group.
#'
#' @param n.e Character string giving the column name for the total
#'   number of participants in the experimental or exposed group.
#'
#' @param event.c Character string giving the column name for the number
#'   of events in the control or unexposed group.
#'
#' @param n.c Character string giving the column name for the total
#'   number of participants in the control or unexposed group.
#'
#' @param effect Character string giving the column name for the
#'   pre-computed study effect estimate. Supported measures are OR, RR,
#'   and HR, depending on \code{measure}.
#'
#' @param lower Character string giving the column name for the lower
#'   confidence interval bound of the pre-computed effect estimate.
#'
#' @param upper Character string giving the column name for the upper
#'   confidence interval bound of the pre-computed effect estimate.
#'
#' @param ci_level Numeric scalar giving the confidence level used for
#'   pre-computed effect sizes, typically \code{0.95}. This is used to
#'   derive the standard error from \code{lower} and \code{upper}.
#'
#' @param studylab Optional character string giving the column name for
#'   study labels. If omitted, labels are auto-generated as
#'   \code{"Study_1"}, \code{"Study_2"}, and so on.
#'
#' @param subgroup Optional character string giving the column name for
#'   a subgroup variable used in subgroup meta-analysis.
#'
#' @param model Character string specifying the meta-analytic model:
#'   \code{"random"} for random-effects or \code{"fixed"} for
#'   fixed-effect analysis.
#'
#' @param measure Character string specifying the effect measure:
#'   \code{"OR"} for odds ratio, \code{"RR"} for risk ratio, or
#'   \code{"HR"} for hazard ratio.
#'
#' @param tau_method Character string specifying the method used to
#'   estimate between-study variance tau-squared in random-effects
#'   models. Options are \code{"REML"} (restricted maximum likelihood),
#'   \code{"PM"} (Paule-Mandel), \code{"DL"} (DerSimonian-Laird),
#'   \code{"ML"} (maximum likelihood), \code{"HS"} (Hunter-Schmidt),
#'   \code{"SJ"} (Sidik-Jonkman), \code{"HE"} (Hedges), and
#'   \code{"EB"} (empirical Bayes).
#'
#' @param ci_method Character string specifying the method used for
#'   random-effects confidence intervals. Options are \code{"HK"}
#'   (Hartung-Knapp), \code{"classic"}, and \code{"KR"}.
#'
#' @param prediction_interval Logical; if \code{TRUE}, a prediction
#'   interval is computed for the pooled random-effects estimate where
#'   applicable.
#'
#' @param verbose Logical; if \code{TRUE}, progress messages are printed
#'   during model fitting.
#'
#' @return An object of class \code{"meta_ratio"} containing:
#' \itemize{
#'   \item \code{meta}: the fitted \pkg{meta} object
#'   \item \code{table}: a tidy study-level summary table
#'   \item \code{meta.subgroup.summary}: subgroup pooled estimates, if
#'   subgroup analysis was requested
#'   \item \code{influence.analysis}: leave-one-out influence analysis
#'   \item model settings such as \code{model}, \code{measure},
#'   \code{tau_method}, and \code{ci_method}
#' }
#'
#' @details
#' If raw event-count data are supplied, the function fits the model
#' using \code{meta::metabin()}. If pre-computed effect sizes are
#' supplied, the function log-transforms the estimates and derives
#' standard errors from the reported confidence intervals before fitting
#' the model using \code{meta::metagen()}.
#'
#' Studies with non-finite log-transformed values are excluded with a
#' warning when pre-computed effect sizes are used.
#'
#' @examples
#' data(dat_bcg, package = "metapropul")
#'
#' result <- meta_ratio(
#'   data = dat_bcg,
#'   event.e = "tpos",
#'   n.e = "npos",
#'   event.c = "cpos",
#'   n.c = "cneg",
#'   studylab = "author"
#' )
#'
#' @export
meta_ratio <- function(data,
                       event.e = NULL,
                       n.e = NULL,
                       event.c = NULL,
                       n.c = NULL,
                       effect = NULL,
                       lower = NULL,
                       upper = NULL,
                       ci_level = 0.95,
                       studylab = NULL,
                       subgroup = NULL,
                       model = "random",
                       measure = "OR",
                       tau_method = "REML",
                       ci_method = "HK",
                       prediction_interval = TRUE,
                       verbose = FALSE) {
  if (verbose) message("Starting meta-analysis of ratios...")

  if (!requireNamespace("meta", quietly = TRUE)) {
    stop("The 'meta' package is required. Install with install.packages('meta').",
      call. = FALSE
    )
  }

  # -- Input validation ---------------------------------------------------------
  if (!inherits(data, "data.frame")) {
    stop("'data' must be a data frame.", call. = FALSE)
  }
  if (nrow(data) < 2L) {
    stop("'data' must contain at least 2 studies.", call. = FALSE)
  }
  if (!is.numeric(ci_level) || length(ci_level) != 1L ||
    ci_level <= 0 || ci_level >= 1) {
    stop("'ci_level' must be a single number between 0 and 1 (e.g. 0.95).",
      call. = FALSE
    )
  }

  has_events <- !is.null(event.e) && !is.null(event.c)
  has_pre <- !is.null(effect)

  if (has_events) {
    if (is.null(n.e) || is.null(n.c)) {
      stop("Please provide 'n.e' and 'n.c' when supplying event counts.",
        call. = FALSE
      )
    }
    for (col in c(event.e, n.e, event.c, n.c)) {
      if (!col %in% names(data)) {
        stop(sprintf("Column '%s' not found in data.", col), call. = FALSE)
      }
      if (!is.numeric(data[[col]])) {
        stop(sprintf("Column '%s' must be numeric.", col), call. = FALSE)
      }
    }
    if (any(data[[event.e]] > data[[n.e]], na.rm = TRUE) ||
      any(data[[event.c]] > data[[n.c]], na.rm = TRUE)) {
      stop("Event counts cannot exceed sample sizes.", call. = FALSE)
    }
    if (any(data[[n.e]] <= 0, na.rm = TRUE) ||
      any(data[[n.c]] <= 0, na.rm = TRUE)) {
      stop("Sample sizes must be positive.", call. = FALSE)
    }
  }

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

  if (!has_events && !has_pre) {
    stop("Provide either event counts (event.e, event.c) or effect sizes (effect, lower, upper).",
      call. = FALSE
    )
  }

  measure <- match.arg(measure, c("OR", "RR", "HR"))
  model <- match.arg(model, c("random", "fixed"))
  ci_method <- match.arg(ci_method, c("HK", "classic", "KR"))
  tau_method <- match.arg(
    tau_method,
    c("REML", "PM", "DL", "ML", "HS", "SJ", "HE", "EB")
  )

  # HR cannot be computed from 2x2 event counts -- requires pre-computed effect
  if (measure == "HR" && has_events) {
    stop("'HR' requires pre-computed effect sizes (effect, lower, upper). ",
      "Hazard ratios cannot be derived from raw event counts.",
      call. = FALSE
    )
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

  common <- model == "fixed"
  random <- model == "random"

  # -- Fit model ----------------------------------------------------------------
  if (has_events) {
    meta_result <- meta::metabin(
      event.e          = data[[event.e]],
      n.e              = data[[n.e]],
      event.c          = data[[event.c]],
      n.c              = data[[n.c]],
      studlab          = study_labels,
      sm               = measure,
      method.tau       = tau_method,
      method.random.ci = ci_method,
      common           = common,
      random           = random,
      prediction       = prediction_interval,
      subgroup         = subgroup_var
    )
  } else {
    log_effect <- log(data[[effect]])
    log_lower <- log(data[[lower]])
    log_upper <- log(data[[upper]])
    bad_idx <- which(!is.finite(log_effect) | !is.finite(log_lower) |
      !is.finite(log_upper))
    if (length(bad_idx) > 0L) {
      warning(
        sprintf(
          "%d stud%s excluded (non-finite log-transformed values): %s",
          length(bad_idx),
          if (length(bad_idx) == 1L) "y" else "ies",
          paste(study_labels[bad_idx], collapse = ", ")
        ),
        call. = FALSE
      )
      keep <- setdiff(seq_len(nrow(data)), bad_idx)
      data <- data[keep, , drop = FALSE]
      study_labels <- study_labels[keep]
      subgroup_var <- if (!is.null(subgroup_var)) subgroup_var[keep] else NULL
      log_effect <- log_effect[keep]
      log_lower <- log_lower[keep]
      log_upper <- log_upper[keep]
    }
    z_val <- stats::qnorm(1 - (1 - ci_level) / 2)
    meta_result <- meta::metagen(
      TE               = log_effect,
      seTE             = (log_upper - log_lower) / (2 * z_val),
      studlab          = study_labels,
      sm               = measure,
      method.tau       = tau_method,
      method.random.ci = ci_method,
      common           = common,
      random           = random,
      prediction       = prediction_interval,
      subgroup         = subgroup_var
    )
  }

  # -- Study-level table -------------------------------------------------------
  # Honour prediction_interval=FALSE: meta pkg computes lower/upper.predict
  # regardless of prediction=FALSE. Null them out so summary() respects the flag
  if (!prediction_interval) {
    meta_result$lower.predict <- NULL
    meta_result$upper.predict <- NULL
  }
  # Use per-study TE/lower/upper (vectors), not pooled estimates (scalars).
  # meta$TE, meta$lower, meta$upper are study-level on the log scale.
  tidy_tbl <- tibble::tibble(
    Study = meta_result$studlab,
    Estimate = round(exp(meta_result$TE), 3),
    lower = round(exp(meta_result$lower), 3),
    upper = round(exp(meta_result$upper), 3),
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
      Estimate = round(exp(sg_est), 3),
      lower    = round(exp(sg_lower), 3),
      upper    = round(exp(sg_upper), 3),
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
    class = "meta_ratio"
  )
}
