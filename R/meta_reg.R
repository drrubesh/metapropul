#' Meta-regression
#'
#' Performs meta-regression on a fitted \code{meta_ratio()},
#' \code{meta_mean()}, or \code{meta_prop()} object using
#' \code{metafor::rma()}.
#'
#' Coefficients are reported on the model scale and, where appropriate,
#' moderator effects are additionally shown on a back-transformed scale.
#' For ratio and proportion models, the intercept is not
#' back-transformed by default because it is often not interpretable
#' unless continuous moderators are centered.
#'
#' @param meta_object A fitted object from \code{meta_ratio()},
#'   \code{meta_mean()}, or \code{meta_prop()}.
#' @param data The original dataset used to fit the meta-analysis model.
#' @param moderators A formula specifying the moderators
#'   (e.g. \code{~ age + region}).
#' @param studylab Character string naming the study label column in
#'   \code{data}. This is required so studies are matched safely by
#'   label.
#' @param reference_levels Optional named character vector or named list mapping
#'   categorical moderators to their desired reference levels, for example
#'   \code{c(region = "Europe")}.
#' @param center Optional character vector naming numeric moderators to
#'   mean-center before fitting.
#' @param scale Optional character vector naming numeric moderators to
#'   standardise to mean zero and unit standard deviation. A variable cannot be
#'   listed in both \code{center} and \code{scale}.
#' @param test Inference method passed to \code{metafor::rma()}: \code{"z"}
#'   (default) or \code{"knha"} for Knapp--Hartung adjustment.
#' @param method Between-study variance estimator passed to
#'   [metafor::rma()]. The default inherits the estimator requested by the
#'   source meta-analysis when it is supported by `metafor`.
#' @param min_studies_per_parameter Positive number used to warn when the
#'   number of included studies per fitted coefficient is small. Default 10.
#'
#' @return An object of class \code{"meta_reg"} containing the fitted
#'   \code{metafor::rma} model, coefficient table, heterogeneity summary,
#'   R-squared analog, excluded study labels, measure metadata, and call.
#'
#' @section CSV and Excel columns:
#' Moderator columns are read from the same study-level dataset used for the
#' primary meta-analysis. A study-label column is required and must match the
#' fitted studies. Continuous moderators must be numeric; categorical
#' moderators may be character or factor. Subgroup analysis is not required
#' to fit meta-regression.
#'
#' @details
#' Study labels are matched rather than assumed to be in the same row order.
#' Studies with missing moderator values are excluded with a warning. Ratio
#' coefficients are fitted on the log scale and proportion coefficients on the
#' logit scale; non-intercept coefficients are additionally back-transformed.
#' The R-squared analog is the proportional reduction in tau-squared relative
#' to the original meta-analysis and is truncated to the interval 0--100%.
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
#'   moderators = ~ ablat,
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
                     studylab,
                     reference_levels = NULL,
                     center = NULL,
                     scale = NULL,
                     test = c("z", "knha"),
                     method = NULL,
                     min_studies_per_parameter = 10) {
  if (!inherits(meta_object, c("meta_prop", "meta_ratio", "meta_mean",
      "meta_generic", "meta_cor", "meta_rate"))) {
    stop(
      "meta_object must be from a supported metapropul meta-analysis.",
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

  test <- match.arg(test)
  supported_methods <- c("REML", "ML", "DL", "HE", "HS", "SJ", "EB", "PM")
  if (is.null(method)) method <- meta_object$tau_method
  method <- match.arg(method, supported_methods)
  if (!is.numeric(min_studies_per_parameter) ||
      length(min_studies_per_parameter) != 1L ||
      !is.finite(min_studies_per_parameter) ||
      min_studies_per_parameter <= 0) {
    stop("'min_studies_per_parameter' must be a positive number.", call. = FALSE)
  }

  if (missing(studylab) || is.null(studylab) || !nzchar(studylab)) {
    stop(
      "Provide 'studylab' to match studies safely between meta_object ",
      "and data.",
      call. = FALSE
    )
  }

  if (!studylab %in% names(data)) {
    stop(sprintf("Column '%s' not found in data.", studylab), call. = FALSE)
  }

  if (!requireNamespace("metafor", quietly = TRUE)) {
    stop(
      "The 'metafor' package is required. Install with ",
      "install.packages('metafor').",
      call. = FALSE
    )
  }

  if (inherits(meta_object, "meta_prop") &&
      !identical(meta_object$sm, "PLOGIT")) {
    stop(
      "meta_reg() currently supports meta_prop objects only when ",
      "sm = 'PLOGIT'.",
      call. = FALSE
    )
  }

  meta_obj <- meta_object$meta

  if (!inherits(meta_obj, "meta")) {
    stop(
      "meta_object does not contain a valid 'meta' component.",
      call. = FALSE
    )
  }

  if (is.null(meta_obj$studlab) ||
      is.null(meta_obj$TE) ||
      is.null(meta_obj$seTE)) {
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


  center <- unique(if (is.null(center)) character() else center)
  scale <- unique(if (is.null(scale)) character() else scale)
  if (length(intersect(center, scale)) > 0L) {
    stop("A moderator cannot be listed in both 'center' and 'scale'.",
      call. = FALSE
    )
  }
  transformed <- union(center, scale)
  invalid_transformed <- setdiff(transformed, mod_terms)
  if (length(invalid_transformed) > 0L) {
    stop("Centered/scaled variables must appear in 'moderators': ",
      paste(invalid_transformed, collapse = ", "), call. = FALSE
    )
  }
  non_numeric <- transformed[
    !vapply(regression_data[transformed], is.numeric, logical(1))
  ]
  if (length(non_numeric) > 0L) {
    stop("Only numeric moderators can be centered or scaled: ",
      paste(non_numeric, collapse = ", "), call. = FALSE
    )
  }

  preprocessing <- list(center = list(), scale = list(), reference_levels = list())
  for (variable in center) {
    value <- mean(regression_data[[variable]], na.rm = TRUE)
    regression_data[[variable]] <- regression_data[[variable]] - value
    preprocessing$center[[variable]] <- value
  }
  for (variable in scale) {
    value_mean <- mean(regression_data[[variable]], na.rm = TRUE)
    value_sd <- stats::sd(regression_data[[variable]], na.rm = TRUE)
    if (!is.finite(value_sd) || value_sd == 0) {
      stop(sprintf("Moderator '%s' has zero variance and cannot be scaled.", variable),
        call. = FALSE
      )
    }
    regression_data[[variable]] <-
      (regression_data[[variable]] - value_mean) / value_sd
    preprocessing$scale[[variable]] <- c(mean = value_mean, sd = value_sd)
  }

  if (!is.null(reference_levels)) {
    if (is.null(names(reference_levels)) || any(!nzchar(names(reference_levels)))) {
      stop("'reference_levels' must be named by moderator variable.", call. = FALSE)
    }
    for (variable in names(reference_levels)) {
      if (!variable %in% mod_terms) {
        stop(sprintf("Reference-level variable '%s' is not in 'moderators'.", variable),
          call. = FALSE
        )
      }
      reference <- as.character(reference_levels[[variable]])[1]
      values <- factor(regression_data[[variable]])
      if (!reference %in% levels(values)) {
        stop(sprintf("Reference level '%s' not found in moderator '%s'.",
          reference, variable), call. = FALSE
        )
      }
      regression_data[[variable]] <- stats::relevel(values, ref = reference)
      preprocessing$reference_levels[[variable]] <- reference
    }
  }

  regression_data$yi <- meta_obj$TE
  regression_data$vi <- meta_obj$seTE^2
  regression_data$.study_label_meta <- meta_studies

  cc <- stats::complete.cases(
    regression_data[, mod_terms, drop = FALSE]
  ) &
    is.finite(regression_data$yi) &
    is.finite(regression_data$vi)

  n_excluded <- sum(!cc)
  excluded_studies <- regression_data$.study_label_meta[!cc]

  if (sum(cc) < 2L) {
    stop(
      "Not enough complete studies available to fit meta-regression ",
      "after exclusions.",
      call. = FALSE
    )
  }

  if (n_excluded > 0L) {
    warning(
      paste0(
        n_excluded,
        " stud",
        if (n_excluded == 1L) "y was" else "ies were",
        " excluded due to missing moderator values or invalid model ",
        "inputs: ",
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
    method = method,
    test = test
  )

  n_parameters <- max(1L, nrow(reg_model$beta) - 1L)
  studies_per_parameter <- reg_model$k / n_parameters
  if (studies_per_parameter < min_studies_per_parameter) {
    warning(sprintf(
      paste0(
        "Meta-regression includes %.1f studies per coefficient (%d studies, ",
        "%d moderator coefficients), below the requested minimum of %.1f. Estimates may be unstable."
      ),
      studies_per_parameter, reg_model$k, n_parameters,
      min_studies_per_parameter
    ), call. = FALSE)
  }

  tau2_null <- meta_obj$tau2
  tau2_model <- reg_model$tau2

  if (!is.finite(tau2_null) || tau2_null < 1e-10) {
    r2_analog <- NA_real_
  } else {
    r2_analog <- 100 * (tau2_null - tau2_model) / tau2_null
    r2_analog <- max(0, min(100, r2_analog))
  }

  measure <- meta_object$measure
  is_ratio <- measure %in% c("OR", "RR", "HR")
  is_prop <- inherits(meta_object, "meta_prop")
  is_rate <- inherits(meta_object, "meta_rate")

  est_raw <- as.numeric(reg_model$beta)
  ci_lb_raw <- reg_model$ci.lb
  ci_ub_raw <- reg_model$ci.ub
  term_names <- rownames(reg_model$beta)

  is_intercept <- term_names == "intrcpt"

  est_bt <- rep(NA_real_, length(est_raw))
  ci_lb_bt <- rep(NA_real_, length(est_raw))
  ci_ub_bt <- rep(NA_real_, length(est_raw))

  if (is_ratio || is_rate) {
    est_bt[!is_intercept] <- exp(est_raw[!is_intercept])
    ci_lb_bt[!is_intercept] <- exp(ci_lb_raw[!is_intercept])
    ci_ub_bt[!is_intercept] <- exp(ci_ub_raw[!is_intercept])
    bt_label <- if (is_rate) "rate-ratio scale" else paste0(measure, " scale")
  } else if (is_prop) {
    # A PLOGIT coefficient is a change in log odds. Exponentiating a slope
    # gives an odds ratio; inverse-logit is appropriate only for a complete
    # predicted linear predictor, not for an isolated coefficient.
    est_bt[!is_intercept] <- exp(est_raw[!is_intercept])
    ci_lb_bt[!is_intercept] <- exp(ci_lb_raw[!is_intercept])
    ci_ub_bt[!is_intercept] <- exp(ci_ub_raw[!is_intercept])
    bt_label <- "odds-ratio scale"
  } else {
    bt_label <- NA_character_
  }

  tidy_tbl <- tibble::tibble(
    Term = term_names,
    Estimate = est_raw,
    CI.Lower = ci_lb_raw,
    CI.Upper = ci_ub_raw,
    p.value = reg_model$pval,
    Estimate_bt = est_bt,
    CI.Lower_bt = ci_lb_bt,
    CI.Upper_bt = ci_ub_bt,
    backtransformable = !is_intercept
  )

  attr(tidy_tbl, "bt_label") <- bt_label

  meta_summary <- tibble::tibble(
    tau2_null = tau2_null,
    tau2 = tau2_model,
    R2_analog = r2_analog,
    QE_pval = reg_model$QEp,
    QM = as.numeric(reg_model$QM),
    QM_pval = reg_model$QMp,
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
      source_settings = meta_object$settings,
      excluded_studies = excluded_studies,
      moderators = moderators,
      moderator_variables = mod_terms,
      model_data = regression_data,
      preprocessing = preprocessing,
      test = test,
      method = method,
      analysis_type = if (length(attr(stats::terms(moderators), "term.labels")) == 1L) {
        "univariable"
      } else {
        "multivariable"
      },
      n_parameters = n_parameters,
      studies_per_parameter = studies_per_parameter,
      call = match.call()
    ),
    class = "meta_reg"
  )
}
