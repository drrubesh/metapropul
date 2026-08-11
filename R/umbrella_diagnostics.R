#' Diagnose primary-study evidence within each source meta-analysis
#'
#' Reconstructs diagnostics separately for every outcome--review combination.
#' It never merges primary studies from different reviews into a new estimate.
#'
#' @param data Long-format primary-study estimates.
#' @param outcome,review,study Columns identifying outcome, source review, and study.
#' @param effect,lower,upper Estimate and confidence-limit columns.
#' @param participants Optional participant-count column used to identify the largest study.
#' @param effect_scale `"ratio"` or `"identity"`.
#' @param ci_level Confidence level of supplied intervals.
#' @param method Tau-squared estimator passed to [metafor::rma()].
#' @param alpha Significance threshold.
#' @param expected_effect `"largest"` or `"reported"`. For `"reported"`, supply
#'   `reported_effect` as a column containing the source meta-analysis estimate.
#' @param reported_effect Optional reported pooled-effect column.
#' @param min_egger Minimum primary studies for Egger testing.
#' @param duplicate_action Handling of conflicting duplicate rows within the
#'   same review: `"error"`, `"precision"`, or `"first"`.
#' @param tolerance Numerical equivalence tolerance.
#' @return An `umbrella_primary_diagnostics` object. Its summary has one row per
#'   source review result and can be passed to [classify_umbrella()].
#' @section CSV and Excel columns:
#' Use one row per primary-study estimate within a source review. Outcome,
#' review, study, effect, lower limit, and upper limit are required;
#' participants are optional. Every outcome--review group must contain at
#' least two unique primary studies. Studies from different reviews are never
#' combined into a new pooled estimate.
#' @export
diagnose_umbrella_primary <- function(data, outcome, review, study, effect,
                                      lower, upper, participants = NULL,
                                      effect_scale = c("ratio", "identity"),
                                      ci_level = 0.95, method = "REML", alpha = 0.05,
                                      expected_effect = c("largest", "reported"),
                                      reported_effect = NULL, min_egger = 10L,
                                      duplicate_action = c("error", "precision", "first"),
                                      tolerance = sqrt(.Machine$double.eps)) {
  if (!inherits(data, "data.frame")) stop("'data' must be a data frame.", call. = FALSE)
  effect_scale <- match.arg(effect_scale); expected_effect <- match.arg(expected_effect)
  duplicate_action <- match.arg(duplicate_action)
  method <- match.arg(method, c("REML", "DL", "PM", "ML", "HE", "HS", "SJ", "EB"))
  columns <- Filter(Negate(is.null), c(outcome, review, study, effect, lower, upper, participants, reported_effect))
  missing_columns <- setdiff(columns, names(data))
  if (length(missing_columns)) stop("Column(s) not found: ", paste(missing_columns, collapse = ", "), call. = FALSE)
  if (expected_effect == "reported" && is.null(reported_effect)) stop("Supply 'reported_effect' when expected_effect = 'reported'.", call. = FALSE)
  if (!is.numeric(ci_level) || ci_level <= 0 || ci_level >= 1) stop("'ci_level' must be between 0 and 1.", call. = FALSE)
  if (!is.numeric(alpha) || alpha <= 0 || alpha >= 1) stop("'alpha' must be between 0 and 1.", call. = FALSE)
  if (!is.numeric(min_egger) || min_egger < 3 || min_egger != as.integer(min_egger)) stop("'min_egger' must be an integer of at least 3.", call. = FALSE)
  if (!is.numeric(tolerance) || tolerance < 0 || !is.finite(tolerance)) stop("'tolerance' must be non-negative and finite.", call. = FALSE)
  for (column in c(effect, lower, upper)) if (!is.numeric(data[[column]])) stop(sprintf("Column '%s' must be numeric.", column), call. = FALSE)
  if (!is.null(participants) && (!is.numeric(data[[participants]]) || any(data[[participants]] < 0, na.rm = TRUE))) stop("Participant counts must be numeric and non-negative.", call. = FALSE)
  invalid <- !is.finite(data[[effect]]) | !is.finite(data[[lower]]) | !is.finite(data[[upper]]) |
    data[[lower]] > data[[effect]] | data[[effect]] > data[[upper]]
  if (effect_scale == "ratio") invalid <- invalid | data[[lower]] <= 0 | data[[effect]] <= 0 | data[[upper]] <= 0
  if (any(invalid)) stop("Effects must have finite ordered limits; ratio estimates must be positive.", call. = FALSE)
  work <- data
  work$.outcome <- as.character(data[[outcome]]); work$.review <- as.character(data[[review]]); work$.study <- as.character(data[[study]])
  if (anyNA(work$.outcome) || anyNA(work$.review) || anyNA(work$.study)) stop("Outcome, review, and study identifiers cannot be missing.", call. = FALSE)
  z_ci <- stats::qnorm(1 - (1 - ci_level) / 2)
  work$.yi <- if (effect_scale == "ratio") log(data[[effect]]) else data[[effect]]
  work$.sei <- if (effect_scale == "ratio") (log(data[[upper]]) - log(data[[lower]])) / (2 * z_ci) else (data[[upper]] - data[[lower]]) / (2 * z_ci)
  key <- interaction(work$.outcome, work$.review, work$.study, drop = TRUE, lex.order = TRUE)
  retained <- integer(); audit <- list()
  for (rows in split(seq_len(nrow(work)), key)) {
    if (length(rows) == 1L) { retained <- c(retained, rows); next }
    values <- cbind(work$.yi[rows], work$.sei[rows]); centre <- values[1, ]
    equivalent <- all(abs(sweep(values, 2, centre, "-")) <= tolerance * pmax(1, abs(values)))
    if (!equivalent && duplicate_action == "error") stop(sprintf("Conflicting duplicate estimates in review '%s' for study '%s'.", work$.review[rows[1]], work$.study[rows[1]]), call. = FALSE)
    chosen <- if (!equivalent && duplicate_action == "precision") rows[which.min(work$.sei[rows])] else rows[1]
    retained <- c(retained, chosen)
    audit[[length(audit) + 1L]] <- tibble::tibble(Outcome = work$.outcome[rows[1]], Review = work$.review[rows[1]], Study = work$.study[rows[1]], Occurrences = length(rows), Conflicting = !equivalent, RetainedRow = chosen)
  }
  deduplicated <- work[sort(retained), , drop = FALSE]
  audit <- if (length(audit)) dplyr::bind_rows(audit) else tibble::tibble(Outcome = character(), Review = character(), Study = character(), Occurrences = integer(), Conflicting = logical(), RetainedRow = integer())
  analysis_key <- interaction(deduplicated$.outcome, deduplicated$.review, drop = TRUE, lex.order = TRUE)
  groups <- split(seq_len(nrow(deduplicated)), analysis_key)
  if (any(lengths(groups) < 2L)) stop("Every source meta-analysis requires at least two unique primary studies.", call. = FALSE)
  models <- lapply(groups, function(rows) metafor::rma(yi = deduplicated$.yi[rows], sei = deduplicated$.sei[rows], method = method))
  critical <- stats::qnorm(1 - alpha / 2); transform <- if (effect_scale == "ratio") exp else identity
  summaries <- lapply(names(groups), function(name) {
    rows <- groups[[name]]; yi <- deduplicated$.yi[rows]; sei <- deduplicated$.sei[rows]
    largest <- if (is.null(participants) || all(is.na(deduplicated[[participants]][rows]))) which.min(sei) else which.max(replace(deduplicated[[participants]][rows], is.na(deduplicated[[participants]][rows]), -Inf))
    theta <- if (expected_effect == "largest") yi[largest] else {
      reported <- unique(deduplicated[[reported_effect]][rows]); reported <- reported[!is.na(reported)]
      if (length(reported) != 1L) stop(sprintf("Reported effect must be constant within '%s'.", name), call. = FALSE)
      if (effect_scale == "ratio") log(reported) else reported
    }
    power <- stats::pnorm(-critical - theta / sei) + 1 - stats::pnorm(critical - theta / sei)
    observed <- sum(2 * stats::pnorm(-abs(yi / sei)) < alpha); expected <- sum(power)
    excess_p <- if (observed <= expected || expected <= 0 || expected >= length(rows)) 1 else {
      statistic <- (observed - expected)^2 / expected + ((length(rows) - observed) - (length(rows) - expected))^2 / (length(rows) - expected)
      stats::pchisq(statistic, 1, lower.tail = FALSE)
    }
    egger <- if (length(rows) >= min_egger) tryCatch(metafor::regtest(models[[name]], predictor = "sei"), error = function(e) NULL) else NULL
    tibble::tibble(Outcome = deduplicated$.outcome[rows[1]], Review = deduplicated$.review[rows[1]],
      PrimaryStudies = length(rows), LargestStudy = deduplicated$.study[rows[largest]],
      LargestEstimate = transform(yi[largest]), LargestStudyP = 2 * stats::pnorm(-abs(yi[largest] / sei[largest])),
      SmallStudyZ = if (is.null(egger)) NA_real_ else egger$zval, SmallStudyP = if (is.null(egger)) NA_real_ else egger$pval,
      SmallStudyAvailable = !is.null(egger), ObservedSignificant = observed, ExpectedSignificant = expected,
      ExcessSignificanceP = excess_p, ExcessSignificance = observed > expected && excess_p < alpha)
  })
  structure(list(summary = dplyr::bind_rows(summaries), data = deduplicated,
    duplicate_audit = audit, models = models, settings = list(effect_scale = effect_scale,
      method = method, expected_effect = expected_effect)), class = "umbrella_primary_diagnostics")
}

#' Compare prespecified review-selection strategies
#'
#' Selects one reported review result per outcome under different strategies.
#' It does not pool review estimates.
#' @param object An `umbrella_review` object.
#' @param overlap Optional `umbrella_overlap` object, required for `"lowest_overlap"`.
#' @param strategies Any of `"highest_quality"`, `"lowest_risk_of_bias"`,
#'   `"most_recent"`, `"most_comprehensive"`, `"largest_participant_count"`,
#'   `"lowest_overlap"`, or `"user_selected"`.
#' @param user_selected Named character vector mapping outcomes to reviews.
#' @param tie_break How tied strategies are resolved: `"most_recent"`,
#'   `"largest"`, `"first"`, or `"error"`.
#' @param missing_action Handling when a strategy has no usable ranking data:
#'   `"warn"`, `"exclude"`, or `"error"`.
#' @return An `umbrella_selection_sensitivity` table with one selected reported
#'   result per outcome and strategy; no synthesis is performed.
#' @export
sensitivity_umbrella_overlap <- function(object, overlap = NULL,
                                         strategies = c("highest_quality", "most_recent", "most_comprehensive", "lowest_overlap"),
                                         user_selected = NULL,
                                         tie_break = c("most_recent", "largest", "first", "error"),
                                         missing_action = c("warn", "exclude", "error")) {
  if (!inherits(object, "umbrella_review")) stop("'object' must be an umbrella_review object.", call. = FALSE)
  allowed <- c("highest_quality", "lowest_risk_of_bias", "most_recent", "most_comprehensive", "largest_participant_count", "lowest_overlap", "user_selected")
  strategies <- match.arg(strategies, allowed, several.ok = TRUE)
  tie_break <- match.arg(tie_break); missing_action <- match.arg(missing_action)
  if ("lowest_overlap" %in% strategies && !inherits(overlap, "umbrella_overlap")) stop("Supply 'overlap' for lowest_overlap selection.", call. = FALSE)
  if ("user_selected" %in% strategies && (is.null(user_selected) || is.null(names(user_selected)))) stop("'user_selected' must be named by outcome.", call. = FALSE)
  d <- object$results
  quality_score <- function(x) unname(c("critically low" = 1, low = 2, moderate = 3, high = 4)[tolower(x)])
  rob_score <- function(x) unname(c(high = 1, "some concerns" = 2, moderate = 2, low = 3)[tolower(x)])
  overlap_score <- function(outcome, review) {
    p <- overlap$pairwise
    if (!identical(outcome, "Overall") && outcome %in% p$Outcome) p <- p[p$Outcome == outcome, , drop = FALSE]
    values <- p$Jaccard[p$Review1 == review | p$Review2 == review]
    if (!length(values)) 0 else mean(values, na.rm = TRUE)
  }
  selected <- list()
  for (strategy in strategies) for (outcome_name in unique(d$Outcome)) {
    candidates <- d[d$Outcome == outcome_name, , drop = FALSE]
    if (strategy == "user_selected") {
      index <- match(user_selected[[outcome_name]], candidates$Review)
    } else {
      score <- switch(strategy,
        highest_quality = quality_score(candidates$Quality),
        lowest_risk_of_bias = rob_score(candidates$RiskOfBias),
        most_recent = candidates$Year,
        most_comprehensive = candidates$Studies,
        largest_participant_count = candidates$Participants,
        lowest_overlap = -vapply(candidates$Review,
          function(r) overlap_score(outcome_name, r), numeric(1)))
      usable <- which(is.finite(score))
      if (!length(usable)) {
        message <- sprintf("No usable '%s' ranking data for outcome '%s'.",
          strategy, outcome_name)
        if (missing_action == "error") stop(message, call. = FALSE)
        if (missing_action == "warn") warning(message, call. = FALSE)
        next
      }
      tied <- usable[score[usable] == max(score[usable])]
      if (length(tied) > 1L && tie_break == "error") {
        stop(sprintf("Tied '%s' candidates for outcome '%s'.", strategy,
          outcome_name), call. = FALSE)
      }
      if (length(tied) > 1L && tie_break == "most_recent") {
        years <- replace(candidates$Year[tied], is.na(candidates$Year[tied]), -Inf)
        tied <- tied[years == max(years)]
      }
      if (length(tied) > 1L && tie_break == "largest") {
        sizes <- replace(candidates$Participants[tied],
          is.na(candidates$Participants[tied]), -Inf)
        if (all(!is.finite(sizes))) sizes <- replace(candidates$Studies[tied],
          is.na(candidates$Studies[tied]), -Inf)
        tied <- tied[sizes == max(sizes)]
      }
      index <- tied[1L]
    }
    if (!length(index) || is.na(index) || !is.finite(index)) next
    row <- candidates[index, , drop = FALSE]; row$Strategy <- strategy
    selected[[length(selected) + 1L]] <- row
  }
  result <- if (length(selected)) dplyr::bind_rows(selected) else tibble::tibble()
  structure(result, class = c("umbrella_selection_sensitivity", class(result)))
}
