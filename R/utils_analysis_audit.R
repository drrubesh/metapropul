# Prepare study labels and an explicit row-level inclusion audit.
#' @keywords internal
.prepare_analysis_data <- function(data, required, studylab = NULL,
                                   subgroup = NULL,
                                   missing_action = c("exclude", "error"),
                                   duplicate_action = c("warn", "error", "make_unique"),
                                   singleton_action = c("warn", "retain", "omit", "error")) {
  missing_action <- match.arg(missing_action)
  duplicate_action <- match.arg(duplicate_action)
  singleton_action <- match.arg(singleton_action)

  if (is.null(studylab)) {
    original_labels <- paste0("Study_", seq_len(nrow(data)))
  } else {
    if (!studylab %in% names(data)) {
      stop(sprintf("Column '%s' not found in data.", studylab), call. = FALSE)
    }
    original_labels <- as.character(data[[studylab]])
    bad_label <- is.na(original_labels) | !nzchar(trimws(original_labels))
    if (any(bad_label)) {
      stop("Study labels cannot be missing or empty.", call. = FALSE)
    }
  }

  duplicated_labels <- duplicated(original_labels) |
    duplicated(original_labels, fromLast = TRUE)
  if (any(duplicated_labels) && duplicate_action == "error") {
    stop(
      sprintf("Duplicate study label(s): %s.",
        paste(unique(original_labels[duplicated_labels]), collapse = ", ")),
      call. = FALSE
    )
  }
  if (any(duplicated_labels) && duplicate_action == "warn") {
    warning(
      sprintf(
        "Duplicate study label(s) were made unique: %s. See 'label_audit' in the result.",
        paste(unique(original_labels[duplicated_labels]), collapse = ", ")
      ),
      call. = FALSE
    )
  }
  final_labels <- make.unique(original_labels)

  audit_columns <- unique(c(required, subgroup))
  complete <- stats::complete.cases(data[, audit_columns, drop = FALSE])
  reason <- rep(NA_character_, nrow(data))
  if (any(!complete)) {
    reason[!complete] <- vapply(which(!complete), function(i) {
      missing <- audit_columns[vapply(data[i, audit_columns, drop = FALSE],
        function(x) is.na(x[[1]]), logical(1))]
      paste0("Missing: ", paste(missing, collapse = ", "))
    }, character(1))
    if (missing_action == "error") {
      stop(
        sprintf("%d row(s) contain missing analysis data.", sum(!complete)),
        call. = FALSE
      )
    }
    warning(
      sprintf("%d study row(s) excluded because required analysis data were missing.",
        sum(!complete)),
      call. = FALSE
    )
  }

  if (!is.null(subgroup)) {
    counts <- table(as.character(data[[subgroup]][complete]))
    singleton_levels <- names(counts)[counts < 2L]
    singleton_rows <- complete & as.character(data[[subgroup]]) %in% singleton_levels
    if (length(singleton_levels) && singleton_action == "error") {
      stop(sprintf("Subgroup level(s) with fewer than two studies: %s.",
        paste(singleton_levels, collapse = ", ")), call. = FALSE)
    }
    if (length(singleton_levels) && singleton_action == "omit") {
      complete[singleton_rows] <- FALSE
      reason[singleton_rows] <- paste0("Singleton subgroup: ",
        as.character(data[[subgroup]][singleton_rows]))
      warning(sprintf("%d singleton-subgroup study row(s) excluded.",
        sum(singleton_rows)), call. = FALSE)
    }
  }

  row_audit <- tibble::tibble(
    SourceRow = seq_len(nrow(data)),
    OriginalStudy = original_labels,
    Study = final_labels,
    Included = complete,
    Reason = reason
  )
  label_audit <- row_audit[duplicated_labels,
    c("SourceRow", "OriginalStudy", "Study"), drop = FALSE]

  list(
    data = data[complete, , drop = FALSE],
    labels = final_labels[complete],
    analysis_data = data[complete, , drop = FALSE],
    excluded_data = data[!complete, , drop = FALSE],
    exclusion_log = row_audit[!complete, , drop = FALSE],
    row_audit = row_audit,
    label_audit = label_audit
  )
}

# Extract the model's subgroup-difference test in a stable tidy form.
#' @keywords internal
.subgroup_test <- function(meta_result) {
  statistic <- meta_result$Q.b.random
  df <- meta_result$df.Q.b.random
  p_value <- meta_result$pval.Q.b.random
  method <- "random-effects subgroup difference"
  if (is.null(statistic) || !length(statistic) || !is.finite(statistic)) {
    statistic <- meta_result$Q.b.common
    df <- meta_result$df.Q.b.common
    p_value <- meta_result$pval.Q.b.common
    method <- "common-effect subgroup difference"
  }
  if (is.null(statistic) || !length(statistic)) return(NULL)
  tibble::tibble(
    statistic = as.numeric(statistic),
    df = as.numeric(df),
    p.value = as.numeric(p_value),
    method = method
  )
}
