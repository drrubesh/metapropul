# Validate a subgroup variable before passing it to meta.
#' @keywords internal
.validate_subgroup <- function(data, subgroup,
                               singleton_action = c("warn", "retain", "omit", "error")) {
  singleton_action <- match.arg(singleton_action)
  if (is.null(subgroup)) {
    return(NULL)
  }
  if (!is.character(subgroup) || length(subgroup) != 1L || !nzchar(subgroup)) {
    stop("'subgroup' must be NULL or a single non-empty column name.", call. = FALSE)
  }
  if (!subgroup %in% names(data)) {
    stop(sprintf("Column '%s' not found in data.", subgroup), call. = FALSE)
  }

  values <- data[[subgroup]]
  observed <- values[!is.na(values)]
  levels_observed <- unique(as.character(observed))

  if (length(observed) == 0L) {
    stop("The subgroup variable contains only missing values.", call. = FALSE)
  }
  if (length(levels_observed) < 2L) {
    stop("Subgroup analysis requires at least two observed subgroup levels.",
      call. = FALSE
    )
  }
  if (anyNA(values)) {
    stop(
      sprintf(
        "The subgroup variable contains %d missing value%s; assign every study to a subgroup or remove those studies explicitly.",
        sum(is.na(values)), if (sum(is.na(values)) == 1L) "" else "s"
      ),
      call. = FALSE
    )
  }

  counts <- table(as.character(observed))
  singleton <- names(counts)[counts < 2L]
  if (length(singleton) > 0L && singleton_action == "warn") {
    warning(
      sprintf(
        "Subgroup level(s) with fewer than two studies: %s. Within-subgroup heterogeneity cannot be estimated reliably.",
        paste(singleton, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  values
}

# Extract subgroup estimates consistently from a fitted meta object.
#' @keywords internal
.subgroup_summary <- function(meta_result, model, transform = identity,
                              digits = NULL) {
  levels <- meta_result$subgroup.levels
  if (is.null(levels) || length(levels) == 0L) {
    return(NULL)
  }

  if (identical(model, "random")) {
    estimate <- meta_result$TE.random.w
    lower <- meta_result$lower.random.w
    upper <- meta_result$upper.random.w
  } else {
    estimate <- meta_result$TE.common.w
    lower <- meta_result$lower.common.w
    upper <- meta_result$upper.common.w
  }

  result <- tibble::tibble(
    Subgroup = as.character(levels),
    Estimate = transform(estimate),
    lower = transform(lower),
    upper = transform(upper),
    Tau2 = meta_result$tau2.w,
    I2 = vapply(meta_result$I2.w, .format_i2, numeric(1))
  )
  if (!is.null(digits)) {
    numeric <- vapply(result, is.numeric, logical(1))
    result[numeric] <- lapply(result[numeric], round, digits = digits)
  }
  result
}
