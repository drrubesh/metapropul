#' Meta-analysis of ratio measures
#'
#' Conducts a meta-analysis of ratio effect measures using either raw
#' event-count data or pre-computed study-level effect estimates with
#' confidence intervals, or log-ratio estimates with standard errors.
#'
#' Two input formats are supported:
#' \itemize{
#'   \item Raw 2 x 2 data using \code{event.e}, \code{n.e},
#'   \code{event.c}, and \code{n.c}
#'   \item Pre-computed effect sizes using \code{effect}, \code{lower},
#'   and \code{upper}
#'   \item Log OR, log RR, or log HR estimates using \code{effect} and
#'   \code{se}, with \code{effect_scale = "log"}
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
#' @param se Optional character string giving the standard-error column for a
#'   pre-computed log ratio. When supplied, set `effect_scale = "log"` and do
#'   not supply `lower` or `upper`.
#' @param effect_scale Scale of pre-computed `effect`, `lower`, and `upper`:
#'   `"ratio"` (default) for OR/RR/HR values, or `"log"` for log OR/log RR/log
#'   HR values. Standard-error input is supported only on the log scale.
#'
#' @param ci_level Numeric scalar giving the confidence level used for
#'   pre-computed effect sizes, typically \code{0.95}. This is used to
#'   derive the standard error from \code{lower} and \code{upper}.
#'
#' @param studylab Optional character string giving the column name for
#'   study labels. If omitted, labels are auto-generated as
#'   \code{"Study_1"}, \code{"Study_2"}, and so on.
#'
#' @param subgroup Optional single character string giving a completely
#'   observed subgroup column. At least two observed levels are required.
#'   Singleton levels are retained with a warning. The default `NULL` performs
#'   no subgroup analysis; subgroup analysis must be requested explicitly.
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
#' @param incr Continuity correction added to zero cells for raw binary data.
#' @param method_incr When to apply `incr`: `"only0"`, `"if0all"`, `"all"`,
#'   or `"user"`, corresponding to `meta::metabin()`'s `method.incr`.
#' @param allstudies Logical; apply the continuity correction to all studies.
#' @param missing_action How incomplete analysis rows are handled: `"exclude"`
#'   records and removes them, while `"error"` stops before fitting.
#' @param duplicate_action How duplicate study labels are handled: `"warn"`
#'   (default) makes them unique and records the change, `"error"` stops, and
#'   `"make_unique"` records the change without warning.
#' @param singleton_action Handling of subgroup levels containing one study:
#'   `"warn"`, `"retain"`, `"omit"`, or `"error"`.
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
#' supplied on the ratio scale, the function log-transforms the estimates and
#' derives standard errors from the reported confidence intervals. Log-scale
#' confidence limits or a log-scale standard error may instead be supplied
#' directly. All pre-computed paths are fitted with \code{meta::metagen()}.
#'
#' When pre-computed effect sizes are used, studies with non-finite
#' log-transformed values are excluded with a warning. This commonly
#' occurs when odds ratios, risk ratios, or confidence intervals are not
#' finite, for example because of zero cells or invalid bounds.
#'
#' Results from the raw-data and pre-computed effect-size paths may
#' differ if zero-cell corrections were applied in the original study
#' calculations or if raw event counts are analysed with continuity
#' corrections internally by \pkg{meta}.
#'
#' @section CSV and Excel columns:
#' Use one row per independent study comparison. For OR or RR from counts,
#' provide numeric columns corresponding to `event.e`, `n.e`, `event.c`, and
#' `n.c`. For a reported OR, RR, or HR, provide `effect`, `lower`, and `upper`
#' on the ratio scale. Alternatively provide a log effect and its standard
#' error using `effect`, `se`, and `effect_scale = "log"`. Study-label and
#' subgroup columns may contain text. Column headers do not need to use these
#' exact names because arguments map the user's headers explicitly.
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
                       se = NULL,
                       effect_scale = c("ratio", "log"),
                       ci_level = 0.95,
                       studylab = NULL,
                       subgroup = NULL,
                       model = "random",
                       measure = "OR",
                       tau_method = "REML",
                       ci_method = "HK",
                       prediction_interval = TRUE,
                       incr = 0.5,
                       method_incr = c("only0", "if0all", "all", "user"),
                       allstudies = FALSE,
                       missing_action = c("exclude", "error"),
                       duplicate_action = c("warn", "error", "make_unique"),
                       singleton_action = c("warn", "retain", "omit", "error"),
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
  if (!is.numeric(incr) || length(incr) != 1L || !is.finite(incr) || incr < 0) {
    stop("'incr' must be a single non-negative finite number.", call. = FALSE)
  }
  method_incr <- match.arg(method_incr)
  if (!is.logical(allstudies) || length(allstudies) != 1L || is.na(allstudies)) {
    stop("'allstudies' must be TRUE or FALSE.", call. = FALSE)
  }

  has_events <- !is.null(event.e) && !is.null(event.c)
  has_pre <- !is.null(effect)
  effect_scale <- match.arg(effect_scale)

  if (has_events && has_pre) {
    stop(
      "Supply either raw event counts or pre-computed effects, not both.",
      call. = FALSE
    )
  }

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
    if (any(data[[event.e]] < 0, na.rm = TRUE) ||
      any(data[[event.c]] < 0, na.rm = TRUE)) {
      stop("Event counts must be non-negative.", call. = FALSE)
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
    has_ci <- !is.null(lower) || !is.null(upper)
    has_se <- !is.null(se)
    if (has_ci == has_se) {
      stop("With 'effect', supply either 'se' or both 'lower' and 'upper'.",
        call. = FALSE)
    }
    if (has_ci && (is.null(lower) || is.null(upper))) {
      stop("Supply both 'lower' and 'upper'.", call. = FALSE)
    }
    if (has_se && effect_scale != "log") {
      stop("Standard-error input requires 'effect_scale = \"log\"'.",
        call. = FALSE)
    }
    pre_cols <- c(effect, if (has_se) se else c(lower, upper))
    for (col in pre_cols) {
      if (!col %in% names(data)) {
        stop(sprintf("Column '%s' not found in data.", col), call. = FALSE)
      }
      if (!is.numeric(data[[col]])) {
        stop(sprintf("Column '%s' must be numeric.", col), call. = FALSE)
      }
    }
    if (has_ci && any(data[[lower]] > data[[upper]], na.rm = TRUE)) {
      stop("'lower' must be <= 'upper' for all rows.", call. = FALSE)
    }
    if (has_se && any(!is.finite(data[[se]]) | data[[se]] <= 0, na.rm = TRUE)) {
      stop("Standard errors must be positive and finite.", call. = FALSE)
    }
  }

  if (!has_events && !has_pre) {
    stop("Provide either event counts or pre-computed effect sizes with CI/SE.",
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

  # -- Labels, exclusions & subgroup -------------------------------------------
  required <- if (has_events) c(event.e, n.e, event.c, n.c) else {
    c(effect, if (!is.null(se)) se else c(lower, upper))
  }
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
      incr             = incr,
      method.incr      = method_incr,
      allstudies       = allstudies,
      method.tau       = tau_method,
      method.random.ci = ci_method,
      common           = common,
      random           = random,
      prediction       = prediction_interval,
      subgroup         = subgroup_var
    )
  } else {
    log_effect <- if (effect_scale == "ratio") log(data[[effect]]) else data[[effect]]
    log_lower <- if (is.null(se)) {
      if (effect_scale == "ratio") log(data[[lower]]) else data[[lower]]
    } else NULL
    log_upper <- if (is.null(se)) {
      if (effect_scale == "ratio") log(data[[upper]]) else data[[upper]]
    } else NULL
    se_effect <- if (!is.null(se)) data[[se]] else {
      z_val <- stats::qnorm(1 - (1 - ci_level) / 2)
      (log_upper - log_lower) / (2 * z_val)
    }
    bad_idx <- which(!is.finite(log_effect) | !is.finite(se_effect) |
      se_effect <= 0)
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
      if (nrow(data) < 2L) {
        stop(
          "Fewer than 2 studies remain after excluding non-finite effect sizes.",
          call. = FALSE
        )
      }
      study_labels <- study_labels[keep]
      subgroup_var <- if (!is.null(subgroup_var)) subgroup_var[keep] else NULL
      log_effect <- log_effect[keep]
      se_effect <- se_effect[keep]
    }
    meta_result <- meta::metagen(
      TE               = log_effect,
      seTE             = se_effect,
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
    Estimate = exp(meta_result$TE),
    lower = exp(meta_result$lower),
    upper = exp(meta_result$upper),
    weight = if (model == "random") {
      meta_result$w.random / sum(meta_result$w.random) * 100
    } else {
      meta_result$w.fixed / sum(meta_result$w.fixed) * 100
    },
    subgroup = if (!is.null(subgroup)) subgroup_var else NA
  )

  # -- Subgroup summary ---------------------------------------------------------
  meta.subgroup.summary <- .subgroup_summary(
    meta_result, model, transform = exp
  )

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
      Estimate = exp(influence_obj$TE),
      lower = exp(influence_obj$lower),
      upper = exp(influence_obj$upper),
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
      settings              = list(input = if (has_events) "raw" else "precomputed",
        effect_scale = if (has_events) NA_character_ else effect_scale,
        uncertainty = if (has_events) NA_character_ else if (!is.null(se)) "se" else "ci",
        prediction_interval = prediction_interval,
        continuity_correction = if (has_events) incr else NA_real_,
        method_incr = if (has_events) method_incr else NA_character_,
        allstudies = if (has_events) allstudies else NA,
        missing_action = match.arg(missing_action),
        duplicate_action = match.arg(duplicate_action),
        singleton_action = match.arg(singleton_action)),
      model                 = model,
      measure               = measure,
      tau_method            = tau_method,
      ci_method             = ci_method,
      subgroup              = !is.null(subgroup)
    ),
    class = "meta_ratio"
  )
}
