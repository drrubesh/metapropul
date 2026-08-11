#' Construct an umbrella-review evidence object
#'
#' Organises results reported by systematic reviews and meta-analyses without
#' pooling them. Each input row remains a separate research synthesis.
#'
#' @param data A data frame with one row per reported meta-analysis result.
#' @param outcome,review Column names identifying the outcome and review.
#' @param effect,lower,upper Columns containing the reported estimate and CI.
#' @param measure Optional column identifying the reported effect measure, such
#'   as `"OR"`, `"RR"`, or `"MD"`.
#' @param studies,participants,i2,p_value,pred_lower,pred_upper,year Optional
#'   columns containing reported review characteristics and statistics.
#' @param quality,risk_of_bias,certainty Optional columns containing AMSTAR 2,
#'   ROBIS, or GRADE results supplied by reviewers.
#' @param effect_scale `"ratio"` or `"identity"`.
#' @param duplicate_action Handling of repeated outcome--review records:
#'   `"warn"`, `"error"`, or `"allow"`.
#'
#' @return An `umbrella_review` object containing standardised review-level
#'   results and metadata. No new pooled estimate is calculated.
#' @section CSV and Excel columns:
#' Use one row per reported meta-analysis result. Outcome, review, effect,
#' lower-limit, and upper-limit columns are required. Effect limits must be
#' ordered and ratio-scale values must be positive. All other mapped review
#' characteristics are optional.
#' @export
umbrella_review <- function(data, outcome, review, effect, lower, upper,
                            studies = NULL, participants = NULL, i2 = NULL,
                            p_value = NULL, pred_lower = NULL, pred_upper = NULL,
                            year = NULL, quality = NULL, risk_of_bias = NULL,
                            certainty = NULL, measure = NULL,
                            effect_scale = c("ratio", "identity"),
                            duplicate_action = c("warn", "error", "allow")) {
  if (!inherits(data, "data.frame")) stop("'data' must be a data frame.", call. = FALSE)
  effect_scale <- match.arg(effect_scale)
  duplicate_action <- match.arg(duplicate_action)
  mapping <- list(outcome = outcome, review = review, effect = effect,
    lower = lower, upper = upper, measure = measure, studies = studies, participants = participants,
    i2 = i2, p_value = p_value, pred_lower = pred_lower,
    pred_upper = pred_upper, year = year, quality = quality,
    risk_of_bias = risk_of_bias, certainty = certainty)
  columns <- unlist(mapping, use.names = FALSE)
  columns <- columns[!is.na(columns) & nzchar(columns)]
  missing_columns <- setdiff(columns, names(data))
  if (length(missing_columns)) stop("Column(s) not found: ",
    paste(missing_columns, collapse = ", "), call. = FALSE)
  for (column in c(effect, lower, upper)) {
    if (!is.numeric(data[[column]])) stop(sprintf("Column '%s' must be numeric.", column), call. = FALSE)
  }
  invalid <- !is.finite(data[[effect]]) | !is.finite(data[[lower]]) |
    !is.finite(data[[upper]]) | data[[lower]] > data[[effect]] |
    data[[effect]] > data[[upper]]
  if (effect_scale == "ratio") invalid <- invalid | data[[lower]] <= 0 |
    data[[effect]] <= 0 | data[[upper]] <= 0
  if (any(invalid)) stop("Reported effects must have finite ordered limits; ratio estimates must be positive.", call. = FALSE)
  outcome_value <- as.character(data[[outcome]])
  review_value <- as.character(data[[review]])
  if (anyNA(outcome_value) || anyNA(review_value) ||
      any(!nzchar(outcome_value)) || any(!nzchar(review_value))) {
    stop("Outcome and review identifiers cannot be missing or empty.", call. = FALSE)
  }
  duplicate_key <- duplicated(paste(outcome_value, review_value, sep = "\r")) |
    duplicated(paste(outcome_value, review_value, sep = "\r"), fromLast = TRUE)
  if (any(duplicate_key) && duplicate_action == "error") {
    stop("Repeated outcome--review records were found.", call. = FALSE)
  }
  if (any(duplicate_key) && duplicate_action == "warn") {
    warning("Repeated outcome--review records were retained; verify that they represent distinct analyses.",
      call. = FALSE)
  }
  optional <- function(name, default = NA) {
    column <- mapping[[name]]
    if (is.null(column)) rep(default, nrow(data)) else data[[column]]
  }
  null <- if (effect_scale == "ratio") 1 else 0
  conclusion <- ifelse(data[[upper]] < null, "Below null",
    ifelse(data[[lower]] > null, "Above null", "No clear effect"))
  results <- tibble::tibble(
    Outcome = outcome_value, Review = review_value,
    Measure = as.character(optional("measure", NA_character_)),
    Estimate = data[[effect]], lower = data[[lower]], upper = data[[upper]],
    Studies = optional("studies", NA_integer_),
    Participants = optional("participants", NA_real_), I2 = optional("i2", NA_real_),
    p.value = optional("p_value", NA_real_), pred.lower = optional("pred_lower", NA_real_),
    pred.upper = optional("pred_upper", NA_real_), Year = optional("year", NA_integer_),
    Quality = as.character(optional("quality", NA_character_)),
    RiskOfBias = as.character(optional("risk_of_bias", NA_character_)),
    Certainty = as.character(optional("certainty", NA_character_)),
    Conclusion = conclusion, SourceRow = seq_len(nrow(data))
  )
  numeric_fields <- c("Studies", "Participants", "I2", "p.value", "pred.lower", "pred.upper", "Year")
  for (field in numeric_fields) {
    if (!is.numeric(results[[field]])) stop(sprintf("Mapped field '%s' must be numeric.", field), call. = FALSE)
  }
  if (any(results$Studies < 0, na.rm = TRUE) || any(results$Participants < 0, na.rm = TRUE)) {
    stop("Study and participant counts cannot be negative.", call. = FALSE)
  }
  if (any(results$I2 < 0 | results$I2 > 100, na.rm = TRUE)) {
    stop("I-squared values must lie between 0 and 100.", call. = FALSE)
  }
  if (any(results$p.value < 0 | results$p.value > 1, na.rm = TRUE)) {
    stop("Reported p-values must lie between 0 and 1.", call. = FALSE)
  }
  known_measures <- unique(stats::na.omit(results$Measure))
  if (length(known_measures) > 0L) {
    incompatible <- if (effect_scale == "ratio")
      !toupper(known_measures) %in% c("OR", "RR", "HR", "IRR", "ROM") else
      toupper(known_measures) %in% c("OR", "RR", "HR", "IRR", "ROM")
    if (any(incompatible)) {
      stop("The supplied effect measure is incompatible with 'effect_scale'.",
        call. = FALSE)
    }
  }
  structure(list(results = results, data = data, mapping = mapping,
    settings = list(effect_scale = effect_scale, null = null,
      duplicate_action = duplicate_action),
    summary = list(reviews = length(unique(review_value)),
      outcomes = length(unique(outcome_value)),
      outcomes_with_multiple_reviews = sum(table(outcome_value) > 1L))),
    class = "umbrella_review")
}

#' Quantify primary-study overlap across reviews
#'
#' Calculates the corrected covered area (CCA), pairwise overlap, and citation
#' matrix from long-format review--primary-study membership data.
#'
#' @param data A data frame with one row per review--study membership.
#' @param review,study Columns identifying reviews and primary studies.
#' @param outcome Optional outcome column for outcome-specific CCA.
#' @param included Optional column containing inclusion indicators. Use
#'   `TRUE`/`1` for an included primary study, `FALSE`/`0` when the study was
#'   eligible but not included, and `NA` for structural missingness (for
#'   example, when a study was not eligible for a review). When omitted, every
#'   row is treated as an included review--study membership.
#' @return An `umbrella_overlap` object with CCA summaries, pairwise measures,
#'   and a logical citation matrix.
#' @section CSV and Excel columns:
#' Use long format with one row per review--primary-study membership. Review
#' and study identifiers are required. Outcome and an inclusion indicator are
#' optional; inclusion values may only be `TRUE`/`FALSE`, `1`/`0`, or `NA`.
#' @export
study_overlap <- function(data, review, study, outcome = NULL, included = NULL) {
  if (!inherits(data, "data.frame")) stop("'data' must be a data frame.", call. = FALSE)
  columns <- Filter(Negate(is.null), c(review, study, outcome, included))
  missing_columns <- setdiff(columns, names(data))
  if (length(missing_columns)) stop("Column(s) not found: ", paste(missing_columns, collapse = ", "), call. = FALSE)
  clean <- unique(data[, columns, drop = FALSE])
  if (anyNA(clean[[review]]) || anyNA(clean[[study]])) stop("Review and study identifiers cannot be missing.", call. = FALSE)
  if (!is.null(included)) {
    indicator <- clean[[included]]
    valid <- is.na(indicator) | indicator %in% c(TRUE, FALSE, 1, 0)
    if (!all(valid)) stop("'included' must contain only TRUE/FALSE, 1/0, or NA.", call. = FALSE)
    clean$.included <- as.logical(indicator)
    key_columns <- Filter(Negate(is.null), c(review, study, outcome))
    duplicate_keys <- duplicated(clean[key_columns]) |
      duplicated(clean[key_columns], fromLast = TRUE)
    if (any(duplicate_keys)) {
      stop("Each review--study--outcome cell must have one inclusion value.", call. = FALSE)
    }
  } else {
    clean$.included <- TRUE
  }
  clean$.group <- if (is.null(outcome)) "Overall" else as.character(clean[[outcome]])
  interpret <- function(x) ifelse(is.na(x), NA_character_, ifelse(x <= 0.05, "Slight",
    ifelse(x <= 0.10, "Moderate", ifelse(x <= 0.15, "High", "Very high"))))
  make_matrix <- function(d) {
    studies <- sort(unique(as.character(d[[study]])))
    reviews <- sort(unique(as.character(d[[review]])))
    out <- matrix(if (is.null(included)) FALSE else NA,
      nrow = length(studies), ncol = length(reviews),
      dimnames = list(studies, reviews))
    out[cbind(match(as.character(d[[study]]), studies),
      match(as.character(d[[review]]), reviews))] <- d$.included
    out
  }
  cca_from_matrix <- function(mat) {
    included_cells <- !is.na(mat) & mat
    active_rows <- rowSums(included_cells) > 0L
    active_cols <- colSums(included_cells) > 0L
    mat <- mat[active_rows, active_cols, drop = FALSE]
    N <- sum(!is.na(mat) & mat)
    r <- nrow(mat)
    c <- ncol(mat)
    structural <- sum(is.na(mat))
    denominator <- r * c - r - structural
    cca <- if (c > 1L && r > 1L && denominator > 0L)
      (N - r) / denominator else NA_real_
    list(N = N, r = r, c = c, structural = structural, CCA = cca, matrix = mat)
  }
  group_matrices <- lapply(split(clean, clean$.group), make_matrix)
  overall <- dplyr::bind_rows(lapply(names(group_matrices), function(label) {
    values <- cca_from_matrix(group_matrices[[label]])
    cca <- values$CCA
    tibble::tibble(Outcome = label, Occurrences = values$N,
      UniqueStudies = values$r, Reviews = values$c,
      StructuralMissing = values$structural, CCA = cca,
      CCA.percent = 100 * cca, Interpretation = interpret(cca))
  }))
  pairs <- list()
  for (label in names(group_matrices)) {
    mat <- group_matrices[[label]]
    ids <- colnames(mat)
    if (length(ids) < 2L) next
    for (pair in utils::combn(ids, 2, simplify = FALSE)) {
      pair_values <- cca_from_matrix(mat[, pair, drop = FALSE])
      pair_mat <- pair_values$matrix
      pair_included <- !is.na(pair_mat) & pair_mat
      shared <- if (nrow(pair_mat)) sum(rowSums(pair_included) == 2L) else 0L
      union_n <- pair_values$r
      occurrences <- pair_values$N
      pair_cca <- pair_values$CCA
      sizes <- if (ncol(pair_mat)) colSums(pair_included) else c(0L, 0L)
      pairs[[length(pairs) + 1L]] <- tibble::tibble(Outcome = label,
        Review1 = pair[1], Review2 = pair[2], Shared = shared, Union = union_n,
        Occurrences = occurrences, Reviews = 2L,
        StructuralMissing = pair_values$structural,
        Jaccard = if (union_n > 0L) shared / union_n else NA_real_, CCA = pair_cca,
        CCA.percent = 100 * pair_cca,
        Overlap.minimum = if (length(sizes) && min(sizes) > 0L)
          shared / min(sizes) else NA_real_)
    }
  }
  pairwise <- if (length(pairs)) dplyr::bind_rows(pairs) else tibble::tibble(
    Outcome = character(), Review1 = character(), Review2 = character(), Shared = integer(),
    Union = integer(), Occurrences = integer(), Reviews = integer(),
    StructuralMissing = integer(),
    Jaccard = numeric(), CCA = numeric(), CCA.percent = numeric(),
    Overlap.minimum = numeric())
  matrices <- group_matrices
  matrix <- make_matrix(clean)
  structure(list(overall = overall, pairwise = pairwise, matrix = matrix,
    matrices = matrices,
    data = clean, mapping = list(review = review, study = study,
      outcome = outcome, included = included)),
    class = "umbrella_overlap")
}

#' @export
print.umbrella_review <- function(x, ...) {
  cat("\nUmbrella review\n---------------\n")
  cat("Systematic reviews/meta-analyses:", x$summary$reviews, "\n")
  cat("Outcomes:", x$summary$outcomes, "\n")
  cat("Outcomes represented by multiple reviews:",
    x$summary$outcomes_with_multiple_reviews, "\n")
  cat("Effect scale:", x$settings$effect_scale, "\n")
  invisible(x)
}
