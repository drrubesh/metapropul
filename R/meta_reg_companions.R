#' Predict from a meta-regression model
#'
#' Computes fitted meta-regression effects, confidence intervals, and
#' prediction intervals at user-supplied moderator values. The centering,
#' scaling, and categorical reference-level decisions recorded by
#' \code{meta_reg()} are applied automatically.
#'
#' @param object A \code{meta_reg} object.
#' @param newdata Data frame containing every moderator used by the fitted
#'   model. Interactions are constructed from the original formula.
#' @param level Confidence level between 0 and 1.
#' @param scale Output scale: \code{"response"} back-transforms ratio and
#'   PLOGIT proportion models, \code{"model"} retains the linear-predictor
#'   scale, and \code{"auto"} selects the response scale when available.
#' @param ... Reserved for future methods.
#'
#' @return A tibble containing the supplied moderator values and columns
#'   \code{estimate}, \code{conf.low}, \code{conf.high}, \code{pred.low},
#'   \code{pred.high}, and \code{scale}.
#' @section CSV and Excel columns:
#' Prediction data use one row per requested moderator combination and must
#' contain the same moderator column names, types, and categorical levels used
#' to fit `object`. They do not require effect estimates or study labels.
#' @export
predict_meta_reg <- function(object, newdata, level = 0.95,
                             scale = c("auto", "response", "model"), ...) {
  if (!inherits(object, "meta_reg")) {
    stop("'object' must be a meta_reg object.", call. = FALSE)
  }
  if (!inherits(newdata, "data.frame") || nrow(newdata) < 1L) {
    stop("'newdata' must be a non-empty data frame.", call. = FALSE)
  }
  if (!is.numeric(level) || length(level) != 1L || level <= 0 || level >= 1) {
    stop("'level' must be a single number between 0 and 1.", call. = FALSE)
  }
  scale <- match.arg(scale)

  missing_variables <- setdiff(object$moderator_variables, names(newdata))
  if (length(missing_variables)) {
    stop("Missing moderator column(s) in 'newdata': ",
      paste(missing_variables, collapse = ", "), call. = FALSE
    )
  }

  processed <- newdata
  prep <- object$preprocessing
  for (variable in names(prep$center)) {
    processed[[variable]] <- processed[[variable]] - prep$center[[variable]]
  }
  for (variable in names(prep$scale)) {
    values <- prep$scale[[variable]]
    processed[[variable]] <- (processed[[variable]] - values[["mean"]]) /
      values[["sd"]]
  }
  for (variable in object$moderator_variables) {
    if (is.factor(object$model_data[[variable]])) {
      processed[[variable]] <- factor(
        processed[[variable]], levels = levels(object$model_data[[variable]])
      )
      if (anyNA(processed[[variable]])) {
        stop(sprintf("'newdata$%s' contains an unseen categorical level.", variable),
          call. = FALSE
        )
      }
    }
  }

  design <- stats::model.matrix(object$moderators, data = processed)
  expected <- colnames(object$meta$X)
  expected <- setdiff(expected, "intrcpt")
  available <- setdiff(colnames(design), "(Intercept)")
  if (!setequal(expected, available)) {
    stop("Could not construct a prediction design matrix matching the fitted model.",
      call. = FALSE
    )
  }
  newmods <- design[, expected, drop = FALSE]
  prediction <- stats::predict(object$meta, newmods = newmods, level = level * 100)

  response_available <- object$measure %in% c("OR", "RR", "HR", "Proportion",
    "Correlation", "Incidence rate")
  use_response <- identical(scale, "response") ||
    (identical(scale, "auto") && response_available)
  if (identical(scale, "response") && !response_available) {
    warning("No back-transformation is defined for this measure; using model scale.",
      call. = FALSE
    )
    use_response <- FALSE
  }
  transform <- if (use_response && object$measure %in% c("OR", "RR", "HR")) {
    exp
  } else if (use_response && identical(object$measure, "Proportion")) {
    function(x) stats::plogis(x) * 100
  } else if (use_response && identical(object$measure, "Correlation")) {
    tanh
  } else if (use_response && identical(object$measure, "Incidence rate")) {
    rate_scale <- object$source_settings$irscale
    function(x) exp(x) * rate_scale
  } else {
    identity
  }

  result <- tibble::as_tibble(newdata)
  result$estimate <- transform(as.numeric(prediction$pred))
  result$conf.low <- transform(as.numeric(prediction$ci.lb))
  result$conf.high <- transform(as.numeric(prediction$ci.ub))
  result$pred.low <- transform(as.numeric(prediction$pi.lb))
  result$pred.high <- transform(as.numeric(prediction$pi.ub))
  result$scale <- if (use_response) "response" else "model"
  result
}

#' Diagnose a meta-regression model
#'
#' Produces coefficient-level collinearity measures and study-level residual
#' and influence diagnostics without drawing a plot.
#'
#' @param object A \code{meta_reg} object.
#' @param vif_threshold Numeric threshold used to flag coefficient-level VIFs.
#' @param cook_threshold Optional Cook's-distance threshold. By default
#'   \code{4 / k} is used.
#'
#' @return An object of class \code{"meta_reg_diagnostics"} containing
#'   study influence measures, coefficient-level collinearity measures,
#'   condition indices, and the raw metafor influence object.
#' @export
diagnose_meta_reg <- function(object, vif_threshold = 5,
                              cook_threshold = NULL) {
  if (!inherits(object, "meta_reg")) {
    stop("'object' must be a meta_reg object.", call. = FALSE)
  }
  if (!is.numeric(vif_threshold) || length(vif_threshold) != 1L ||
      vif_threshold <= 0) {
    stop("'vif_threshold' must be positive.", call. = FALSE)
  }

  model <- object$meta
  influence <- stats::influence(model)
  standardized <- stats::rstandard(model)$z
  fitted_values <- stats::fitted(model)
  cooks <- influence$inf$cook.d
  dfbeta_names <- setdiff(names(influence$dfbs), c("slab", "digits"))
  max_dfbeta <- if (length(dfbeta_names)) {
    dfbeta_matrix <- do.call(cbind, lapply(dfbeta_names,
      function(name) influence$dfbs[[name]]))
    apply(dfbeta_matrix, 1L, function(x) {
      finite <- is.finite(x)
      if (any(finite)) max(abs(x[finite])) else NA_real_
    })
  } else rep(NA_real_, model$k)
  if (is.null(cook_threshold)) cook_threshold <- 4 / model$k

  studies <- tibble::tibble(
    Study = object$model_data$.study_label_meta,
    observed = object$model_data$yi,
    fitted = as.numeric(fitted_values),
    residual = object$model_data$yi - as.numeric(fitted_values),
    standardized_residual = as.numeric(standardized),
    cooks_distance = as.numeric(cooks),
    leverage = as.numeric(influence$inf$hat),
    dffits = as.numeric(influence$inf$dffits),
    covariance_ratio = as.numeric(influence$inf$cov.r),
    max_abs_dfbeta = as.numeric(max_dfbeta),
    influential = abs(standardized_residual) > 2 |
      cooks_distance > cook_threshold
  )

  x <- model$X[, colnames(model$X) != "intrcpt", drop = FALSE]
  if (ncol(x) == 0L) {
    collinearity <- tibble::tibble(Term = character(), VIF = numeric(),
      flagged = logical())
  } else if (ncol(x) == 1L) {
    collinearity <- tibble::tibble(
      Term = colnames(x), VIF = 1, flagged = FALSE
    )
  } else {
    correlation <- stats::cor(x)
    inverse <- tryCatch(solve(correlation), error = function(e) NULL)
    vif <- if (is.null(inverse)) rep(Inf, ncol(x)) else diag(inverse)
    collinearity <- tibble::tibble(
      Term = colnames(x), VIF = as.numeric(vif),
      flagged = as.numeric(vif) >= vif_threshold
    )
  }

  scaled_x <- scale(model$X, center = TRUE, scale = FALSE)
  scaled_x <- scaled_x[, apply(scaled_x, 2L, function(z)
    any(is.finite(z) & abs(z) > 0)),
    drop = FALSE]
  singular_values <- if (ncol(scaled_x)) svd(scaled_x, nu = 0, nv = 0)$d else numeric()
  condition <- tibble::tibble(
    Dimension = seq_along(singular_values),
    ConditionIndex = if (length(singular_values))
      max(singular_values) / singular_values else numeric(),
    flagged = if (length(singular_values))
      max(singular_values) / singular_values >= 30 else logical()
  )

  structure(
    list(
      studies = studies,
      collinearity = collinearity,
      condition = condition,
      influence = influence,
      thresholds = list(vif = vif_threshold, cook = cook_threshold)
    ),
    class = "meta_reg_diagnostics"
  )
}
