# Build the common metapropul result structure for additional inverse-variance
# model families.
#' @keywords internal
.additional_meta_result <- function(meta_result, prepared, class, model,
                                    measure, transform = identity,
                                    tau_method, ci_method, subgroup,
                                    prediction_interval, settings = list()) {
  weights <- if (model == "random") meta_result$w.random else meta_result$w.common
  weight_total <- sum(weights, na.rm = TRUE)
  weights <- if (is.finite(weight_total) && weight_total > 0)
    weights / weight_total * 100 else rep(NA_real_, length(meta_result$TE))
  table <- tibble::tibble(
    Study = meta_result$studlab,
    Estimate = transform(meta_result$TE),
    lower = transform(meta_result$lower),
    upper = transform(meta_result$upper),
    weight = weights,
    subgroup = if (!is.null(subgroup)) meta_result$subgroup else NA
  )
  pooled_te <- if (model == "random") meta_result$TE.random else meta_result$TE.common
  pooled_lo <- if (model == "random") meta_result$lower.random else meta_result$lower.common
  pooled_hi <- if (model == "random") meta_result$upper.random else meta_result$upper.common
  pooled <- tibble::tibble(
    Estimate = transform(pooled_te), lower = transform(pooled_lo),
    upper = transform(pooled_hi),
    pred.lower = if (model == "random" && prediction_interval &&
      length(meta_result$lower.predict)) transform(meta_result$lower.predict) else NA_real_,
    pred.upper = if (model == "random" && prediction_interval &&
      length(meta_result$upper.predict)) transform(meta_result$upper.predict) else NA_real_,
    I2 = meta_result$I2, Tau2 = meta_result$tau2
  )
  influence_meta <- tryCatch(meta::metainf(meta_result,
    random = model == "random", common = model == "fixed"),
    error = function(e) NULL)
  influence <- if (is.null(influence_meta)) NULL else tibble::tibble(
    Study = influence_meta$studlab,
    Estimate = transform(influence_meta$TE),
    lower = transform(influence_meta$lower),
    upper = transform(influence_meta$upper),
    p.value = influence_meta$pval,
    Tau2 = influence_meta$tau2,
    I2 = influence_meta$I2 * 100
  )
  structure(list(
    meta = meta_result, table = table, meta.summary = pooled,
    meta.subgroup.summary = .subgroup_summary(meta_result, model,
      transform = transform),
    subgroup_test = .subgroup_test(meta_result),
    influence.analysis = influence, influence.meta = influence_meta,
    analysis_data = prepared$analysis_data,
    excluded_data = prepared$excluded_data,
    exclusion_log = prepared$exclusion_log,
    label_audit = prepared$label_audit,
    model = model, measure = measure, tau_method = tau_method,
    ci_method = ci_method, subgroup = !is.null(subgroup),
    settings = settings
  ), class = class)
}

#' Generic inverse-variance meta-analysis
#'
#' Pools study effects already expressed on their analysis scale. Supply a
#' standard error, variance, or confidence interval. For log ratio effects set
#' `backtransform = "exp"`; the input effect and uncertainty must then be on
#' the log scale.
#'
#' @param data A data frame.
#' @param effect Effect column on the analysis scale.
#' @param se,variance Optional standard-error or variance column.
#' @param lower,upper Optional confidence limits used to reconstruct the SE.
#' @param ci_level Confidence level of supplied limits.
#' @param studylab,subgroup Optional study-label and subgroup columns.
#'   `subgroup = NULL` (default) performs no subgroup analysis.
#' @param model `"random"` or `"fixed"`.
#' @param measure Descriptive effect-measure label.
#' @param backtransform `"identity"` or `"exp"`.
#' @param tau_method,ci_method,prediction_interval Model controls.
#' @param missing_action,duplicate_action,singleton_action Audit policies.
#' @return An object of class `meta_generic`.
#' @section CSV and Excel columns:
#' Use one row per study and provide an effect column plus exactly one
#' uncertainty representation: standard error, variance, or both confidence
#' limits. For log OR, log RR, or log HR with a standard error, supply the log
#' effect and set `backtransform = "exp"`. Study-label and subgroup columns are
#' optional and may contain text.
#' @export
meta_generic <- function(data, effect, se = NULL, variance = NULL,
                         lower = NULL, upper = NULL, ci_level = 0.95,
                         studylab = NULL, subgroup = NULL,
                         model = c("random", "fixed"), measure = "Generic effect",
                         backtransform = c("identity", "exp"),
                         tau_method = "REML", ci_method = "HK",
                         prediction_interval = TRUE,
                         missing_action = c("exclude", "error"),
                         duplicate_action = c("warn", "error", "make_unique"),
                         singleton_action = c("warn", "retain", "omit", "error")) {
  if (!inherits(data, "data.frame")) stop("'data' must be a data frame.", call. = FALSE)
  model <- match.arg(model); backtransform <- match.arg(backtransform)
  tau_method <- match.arg(tau_method, c("REML", "PM", "DL", "ML", "HS", "SJ", "HE", "EB"))
  ci_method <- match.arg(ci_method, c("HK", "classic", "KR"))
  modes <- c(!is.null(se), !is.null(variance), !is.null(lower) || !is.null(upper))
  if (sum(modes) != 1L) stop("Supply exactly one of 'se', 'variance', or both 'lower' and 'upper'.", call. = FALSE)
  if (modes[3] && (is.null(lower) || is.null(upper))) stop("Supply both 'lower' and 'upper'.", call. = FALSE)
  required <- c(effect, if (!is.null(se)) se else if (!is.null(variance)) variance else c(lower, upper))
  missing_cols <- setdiff(required, names(data)); if (length(missing_cols)) stop("Column(s) not found: ", paste(missing_cols, collapse = ", "), call. = FALSE)
  if (!all(vapply(data[required], is.numeric, logical(1)))) stop("Effect and uncertainty columns must be numeric.", call. = FALSE)
  prepared <- .prepare_analysis_data(data, required, studylab, subgroup,
    missing_action, duplicate_action, singleton_action)
  d <- prepared$data
  if (nrow(d) < 2L) stop("At least two complete studies are required.", call. = FALSE)
  sei <- if (!is.null(se)) d[[se]] else if (!is.null(variance)) sqrt(d[[variance]]) else {
    z <- stats::qnorm(1 - (1 - ci_level) / 2)
    (d[[upper]] - d[[lower]]) / (2 * z)
  }
  if (any(!is.finite(sei) | sei <= 0)) stop("Standard errors must be positive and finite.", call. = FALSE)
  subgroup_value <- .validate_subgroup(d, subgroup, singleton_action)
  fit <- meta::metagen(TE = d[[effect]], seTE = sei, studlab = prepared$labels,
    sm = measure, common = model == "fixed", random = model == "random",
    prediction = prediction_interval, method.tau = tau_method,
    method.random.ci = ci_method, subgroup = subgroup_value)
  transform <- if (backtransform == "exp") exp else identity
  .additional_meta_result(fit, prepared, "meta_generic", model, measure,
    transform, tau_method, ci_method, subgroup, prediction_interval,
    list(input_scale = "analysis", backtransform = backtransform,
      prediction_interval = prediction_interval))
}

#' Meta-analysis of correlations
#'
#' Pools correlations using Fisher's z transformation and returns estimates on
#' the correlation scale.
#'
#' @param data A data frame.
#' @param cor Correlation column with values strictly between -1 and 1.
#' @param n Sample-size column; values must exceed 3.
#' @param studylab,subgroup Optional study-label and subgroup columns.
#'   `subgroup = NULL` (default) performs no subgroup analysis.
#' @param model,tau_method,ci_method,prediction_interval Model controls.
#' @param missing_action,duplicate_action,singleton_action Audit policies.
#' @return An object of class `meta_cor`.
#' @section CSV and Excel columns:
#' Use one row per study with numeric correlation and sample-size columns.
#' Correlations must lie strictly between -1 and 1 and sample sizes must exceed
#' 3. Study-label and subgroup columns are optional.
#' @export
meta_cor <- function(data, cor, n, studylab = NULL, subgroup = NULL,
                     model = c("random", "fixed"), tau_method = "REML",
                     ci_method = "HK", prediction_interval = TRUE,
                     missing_action = c("exclude", "error"),
                     duplicate_action = c("warn", "error", "make_unique"),
                     singleton_action = c("warn", "retain", "omit", "error")) {
  if (!inherits(data, "data.frame")) stop("'data' must be a data frame.", call. = FALSE)
  model <- match.arg(model); tau_method <- match.arg(tau_method, c("REML", "PM", "DL", "ML", "HS", "SJ", "HE", "EB")); ci_method <- match.arg(ci_method, c("HK", "classic", "KR"))
  if (!all(c(cor, n) %in% names(data))) stop("Correlation or sample-size column not found.", call. = FALSE)
  if (!is.numeric(data[[cor]]) || !is.numeric(data[[n]])) stop("Correlations and sample sizes must be numeric.", call. = FALSE)
  if (any(abs(data[[cor]]) >= 1, na.rm = TRUE)) stop("Correlations must lie strictly between -1 and 1.", call. = FALSE)
  if (any(data[[n]] <= 3, na.rm = TRUE)) stop("Correlation sample sizes must exceed 3.", call. = FALSE)
  prepared <- .prepare_analysis_data(data, c(cor, n), studylab, subgroup,
    missing_action, duplicate_action, singleton_action); d <- prepared$data
  if (nrow(d) < 2L) stop("At least two complete studies are required.", call. = FALSE)
  subgroup_value <- .validate_subgroup(d, subgroup, singleton_action)
  fit <- meta::metacor(cor = d[[cor]], n = d[[n]], studlab = prepared$labels,
    sm = "ZCOR", common = model == "fixed", random = model == "random",
    prediction = prediction_interval, method.tau = tau_method,
    method.random.ci = ci_method, subgroup = subgroup_value)
  .additional_meta_result(fit, prepared, "meta_cor", model, "Correlation",
    tanh, tau_method, ci_method, subgroup, prediction_interval,
    list(transformation = "Fisher z", prediction_interval = prediction_interval))
}

#' Meta-analysis of incidence rates
#'
#' Pools event rates per unit of person-time on the log incidence-rate scale.
#'
#' @param data A data frame.
#' @param event Event-count column.
#' @param time Person-time column.
#' @param studylab,subgroup Optional study-label and subgroup columns.
#'   `subgroup = NULL` (default) performs no subgroup analysis.
#' @param model,tau_method,ci_method,prediction_interval Model controls.
#' @param irscale Scaling factor for displayed rates, such as 1000.
#' @param irunit Person-time unit label.
#' @param incr Continuity correction for zero-event studies.
#' @param missing_action,duplicate_action,singleton_action Audit policies.
#' @return An object of class `meta_rate`.
#' @section CSV and Excel columns:
#' Use one row per study with numeric event-count and person-time columns.
#' Events must be non-negative and person-time must be positive. Study-label
#' and subgroup columns are optional.
#' @export
meta_rate <- function(data, event, time, studylab = NULL, subgroup = NULL,
                      model = c("random", "fixed"), tau_method = "REML",
                      ci_method = "HK", prediction_interval = TRUE,
                      irscale = 1, irunit = "person-years", incr = 0.5,
                      missing_action = c("exclude", "error"),
                      duplicate_action = c("warn", "error", "make_unique"),
                      singleton_action = c("warn", "retain", "omit", "error")) {
  if (!inherits(data, "data.frame")) stop("'data' must be a data frame.", call. = FALSE)
  model <- match.arg(model); tau_method <- match.arg(tau_method, c("REML", "PM", "DL", "ML", "HS", "SJ", "HE", "EB")); ci_method <- match.arg(ci_method, c("HK", "classic", "KR"))
  if (!all(c(event, time) %in% names(data))) stop("Event or person-time column not found.", call. = FALSE)
  if (!is.numeric(data[[event]]) || !is.numeric(data[[time]])) stop("Events and person-time must be numeric.", call. = FALSE)
  if (any(data[[event]] < 0, na.rm = TRUE) || any(data[[time]] <= 0, na.rm = TRUE)) stop("Events must be non-negative and person-time positive.", call. = FALSE)
  if (!is.numeric(irscale) || length(irscale) != 1L || irscale <= 0) stop("'irscale' must be positive.", call. = FALSE)
  prepared <- .prepare_analysis_data(data, c(event, time), studylab, subgroup,
    missing_action, duplicate_action, singleton_action); d <- prepared$data
  if (nrow(d) < 2L) stop("At least two complete studies are required.", call. = FALSE)
  subgroup_value <- .validate_subgroup(d, subgroup, singleton_action)
  fit <- meta::metarate(event = d[[event]], time = d[[time]],
    studlab = prepared$labels, sm = "IRLN", method = "Inverse", incr = incr,
    common = model == "fixed", random = model == "random",
    prediction = prediction_interval, method.tau = tau_method,
    method.random.ci = ci_method, subgroup = subgroup_value,
    irscale = irscale, irunit = irunit)
  transform <- function(x) exp(x) * irscale
  .additional_meta_result(fit, prepared, "meta_rate", model, "Incidence rate",
    transform, tau_method, ci_method, subgroup, prediction_interval,
    list(irscale = irscale, irunit = irunit, incr = incr,
      prediction_interval = prediction_interval))
}

#' @export
summary.meta_generic <- function(object, ...) summary(object$meta, ...)
#' @export
summary.meta_cor <- function(object, ...) summary(object$meta, ...)
#' @export
summary.meta_rate <- function(object, ...) summary(object$meta, ...)
#' @export
print.meta_generic <- function(x, ...) { print(summary(x$meta, ...)); invisible(x) }
#' @export
print.meta_cor <- function(x, ...) { print(summary(x$meta, ...)); invisible(x) }
#' @export
print.meta_rate <- function(x, ...) { print(summary(x$meta, ...)); invisible(x) }
