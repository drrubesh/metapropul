#' Classify statistical credibility in an umbrella review
#'
#' Applies an Ioannidis-style quantitative evidence classification to each
#' reported meta-analysis separately. This is not GRADE, AMSTAR 2, or ROBIS.
#'
#' @param object An `umbrella_review` object.
#' @param diagnostics Optional data frame or `umbrella_primary_diagnostics`
#'   containing outcome/review-level largest-study and bias diagnostics.
#' @param strong_p,highly_suggestive_p,suggestive_p,nominal_p Thresholds for
#'   evidence Classes I--IV.
#' @param min_participants Minimum participant/case count for Classes I--III.
#' @param max_i2 Maximum I-squared for Class I.
#' @return Review results with criterion flags and `EvidenceClass`.
#' @export
classify_umbrella <- function(object, diagnostics = NULL, strong_p = 1e-6,
                              highly_suggestive_p = 1e-6,
                              suggestive_p = 1e-3, nominal_p = 0.05,
                              min_participants = 1000, max_i2 = 50) {
  if (!inherits(object, "umbrella_review")) stop("'object' must be an umbrella_review object.", call. = FALSE)
  d <- object$results
  if (inherits(diagnostics, "umbrella_primary_diagnostics")) diagnostics <- diagnostics$summary
  if (!is.null(diagnostics)) {
    required <- c("Outcome", "Review", "LargestStudyP", "SmallStudyP", "ExcessSignificanceP")
    if (!inherits(diagnostics, "data.frame") || !all(required %in% names(diagnostics))) {
      stop("'diagnostics' must contain outcome- and review-specific primary-study diagnostics.", call. = FALSE)
    }
    d <- merge(d, diagnostics[, required], by = c("Outcome", "Review"), all.x = TRUE, sort = FALSE)
  } else {
    d$LargestStudyP <- d$SmallStudyP <- d$ExcessSignificanceP <- NA_real_
  }
  null <- object$settings$null
  prediction_excludes <- (d$pred.lower > null & d$pred.upper > null) |
    (d$pred.lower < null & d$pred.upper < null)
  adequate <- !is.na(d$Participants) & d$Participants >= min_participants
  largest <- !is.na(d$LargestStudyP) & d$LargestStudyP < 0.05
  no_small <- !is.na(d$SmallStudyP) & d$SmallStudyP >= 0.10
  no_excess <- !is.na(d$ExcessSignificanceP) & d$ExcessSignificanceP >= 0.10
  diagnostics_available <- !is.na(d$LargestStudyP) & !is.na(d$SmallStudyP) &
    !is.na(d$ExcessSignificanceP)
  class_i <- !is.na(d$p.value) & d$p.value < strong_p & adequate &
    !is.na(d$I2) & d$I2 < max_i2 & prediction_excludes & largest & no_small & no_excess
  class_ii <- !is.na(d$p.value) & d$p.value < highly_suggestive_p & adequate & largest
  class_iii <- !is.na(d$p.value) & d$p.value < suggestive_p & adequate
  class_iv <- !is.na(d$p.value) & d$p.value < nominal_p
  value <- ifelse(class_i, "Class I - convincing", ifelse(class_ii,
    "Class II - highly suggestive", ifelse(class_iii, "Class III - suggestive",
      ifelse(class_iv, "Class IV - weak", "Not significant"))))
  d$AdequateSize <- adequate; d$PredictionExcludesNull <- prediction_excludes
  d$LargestStudySignificant <- largest; d$NoSmallStudyEvidence <- no_small
  d$NoExcessSignificance <- no_excess
  d$DiagnosticsAvailable <- diagnostics_available
  d$CriteriaUnavailable <- ifelse(diagnostics_available, NA_character_,
    "Largest-study, small-study, or excess-significance diagnostics unavailable")
  d$EvidenceClass <- factor(value, levels = c("Class I - convincing",
    "Class II - highly suggestive", "Class III - suggestive",
    "Class IV - weak", "Not significant"), ordered = TRUE)
  tibble::as_tibble(d)
}

#' Record structured GRADE judgements
#'
#' Calculates a final certainty category from reviewer-supplied judgements. It
#' does not infer GRADE domains from statistical results.
#' @param object An `umbrella_review` object.
#' @param starting_certainty Starting level (`"high"`, `"moderate"`, `"low"`,
#'   or `"very_low"`), supplied as a scalar, vector, or column name.
#' @param risk_of_bias,inconsistency,indirectness,imprecision,publication_bias
#'   Reviewer judgements: `"not_serious"`, `"serious"`, or `"very_serious"`.
#' @param upgrade Reviewer-supplied upgrade: `"none"`, `"one"`, or `"two"`.
#' @param rationale Optional scalar, vector, or source-data column recording the
#'   justification for the certainty judgement.
#' @param assessor Optional assessor name or identifier.
#' @param assessment_date Optional assessment date.
#' @return Review results with GRADE domains and final `GRADE` certainty.
#' @export
grade_umbrella <- function(object, starting_certainty,
                           risk_of_bias = "not_serious",
                           inconsistency = "not_serious",
                           indirectness = "not_serious",
                           imprecision = "not_serious",
                           publication_bias = "not_serious",
                           upgrade = "none", rationale = NA_character_,
                           assessor = NA_character_, assessment_date = Sys.Date()) {
  if (!inherits(object, "umbrella_review")) stop("'object' must be an umbrella_review object.", call. = FALSE)
  d <- object$results; n <- nrow(d)
  resolve <- function(value, name) {
    if (length(value) == 1L && is.character(value) && value %in% names(object$data)) value <- object$data[[value]]
    if (length(value) == 1L) value <- rep(value, n)
    if (length(value) != n) stop(sprintf("'%s' must be scalar, length n, or a column name.", name), call. = FALSE)
    as.character(value)
  }
  start <- resolve(starting_certainty, "starting_certainty")
  domains <- list(RiskOfBias = resolve(risk_of_bias, "risk_of_bias"),
    Inconsistency = resolve(inconsistency, "inconsistency"),
    Indirectness = resolve(indirectness, "indirectness"),
    Imprecision = resolve(imprecision, "imprecision"),
    PublicationBias = resolve(publication_bias, "publication_bias"))
  allowed_start <- c("very_low", "low", "moderate", "high")
  allowed_domain <- c("not_serious", "serious", "very_serious")
  if (any(!start %in% allowed_start)) stop("Invalid starting certainty.", call. = FALSE)
  if (any(!unlist(domains) %in% allowed_domain)) stop("GRADE domains must be not_serious, serious, or very_serious.", call. = FALSE)
  upgrade_value <- resolve(upgrade, "upgrade")
  if (any(!upgrade_value %in% c("none", "one", "two"))) stop("'upgrade' must be none, one, or two.", call. = FALSE)
  score <- match(start, allowed_start)
  downgrade <- c(not_serious = 0, serious = 1, very_serious = 2)
  for (domain in domains) score <- score - unname(downgrade[domain])
  score <- score + unname(c(none = 0, one = 1, two = 2)[upgrade_value])
  score <- pmin(4, pmax(1, score))
  for (name in names(domains)) d[[name]] <- domains[[name]]
  d$StartingCertainty <- start; d$Upgrade <- upgrade_value
  d$Rationale <- resolve(rationale, "rationale")
  d$Assessor <- resolve(assessor, "assessor")
  d$AssessmentDate <- resolve(as.character(assessment_date), "assessment_date")
  d$GRADE <- factor(allowed_start[score], levels = allowed_start, ordered = TRUE)
  tibble::as_tibble(d)
}

#' Store AMSTAR 2 or ROBIS review-quality assessments
#' @param object An `umbrella_review` object.
#' @param tool `"AMSTAR2"` or `"ROBIS"`.
#' @param overall Scalar, vector, or source-data column with overall judgements.
#' @param domains Optional data frame of domain-level judgements with one row per result.
#' @param validate Logical; validate overall judgements against the selected
#'   tool's conventional categories.
#' @return A quality-assessment table of class `umbrella_review_quality`.
#' @export
assess_review_quality <- function(object, tool = c("AMSTAR2", "ROBIS"), overall,
                                  domains = NULL, validate = TRUE) {
  if (!inherits(object, "umbrella_review")) stop("'object' must be an umbrella_review object.", call. = FALSE)
  tool <- match.arg(tool); n <- nrow(object$results)
  if (length(overall) == 1L && is.character(overall) && overall %in% names(object$data)) overall <- object$data[[overall]]
  if (length(overall) == 1L) overall <- rep(overall, n)
  if (length(overall) != n) stop("'overall' must be scalar, length n, or a column name.", call. = FALSE)
  if (!is.null(domains) && (!inherits(domains, "data.frame") || nrow(domains) != n)) stop("'domains' must have one row per review result.", call. = FALSE)
  if (!is.logical(validate) || length(validate) != 1L || is.na(validate)) {
    stop("'validate' must be TRUE or FALSE.", call. = FALSE)
  }
  if (validate) {
    allowed <- if (tool == "AMSTAR2")
      c("high", "moderate", "low", "critically low") else
      c("low", "high", "unclear")
    invalid <- !tolower(as.character(overall)) %in% allowed & !is.na(overall)
    if (any(invalid)) {
      stop(sprintf("Invalid %s overall judgement(s): %s.", tool,
        paste(unique(as.character(overall)[invalid]), collapse = ", ")),
        call. = FALSE)
    }
  }
  result <- object$results[, c("Outcome", "Review")]
  result$Tool <- tool; result$Overall <- as.character(overall)
  if (!is.null(domains)) result <- dplyr::bind_cols(result, domains)
  structure(tibble::as_tibble(result), class = c("umbrella_review_quality", class(tibble::as_tibble(result))))
}

#' Create a review-by-review umbrella table
#' @param object An `umbrella_review` object.
#' @param classification Optional output from [classify_umbrella()].
#' @param grade Optional output from [grade_umbrella()].
#' @param title Optional title.
#' @param save_as `"viewer"`, `"docx"`, or `"pdf"`.
#' @param filename Optional output path.
#' @return A `gt` table, invisibly when saved.
#' @export
table_umbrella <- function(object, classification = NULL, grade = NULL,
                           title = NULL, save_as = c("viewer", "docx", "pdf"), filename = NULL) {
  if (!inherits(object, "umbrella_review")) stop("'object' must be an umbrella_review object.", call. = FALSE)
  save_as <- match.arg(save_as); d <- object$results
  if (!is.null(classification)) d$Credibility <- as.character(classification$EvidenceClass[match(paste(d$Outcome, d$Review), paste(classification$Outcome, classification$Review))])
  if (!is.null(grade)) d$GRADE <- as.character(grade$GRADE[match(paste(d$Outcome, d$Review), paste(grade$Outcome, grade$Review))])
  display <- tibble::tibble(Outcome = d$Outcome, Review = d$Review,
    `Reported estimate [95% CI]` = sprintf("%.3f [%.3f, %.3f]", d$Estimate, d$lower, d$upper),
    Studies = d$Studies, Participants = d$Participants, `I2 (%)` = d$I2,
    Conclusion = d$Conclusion)
  if ("Credibility" %in% names(d)) display$Credibility <- d$Credibility
  if ("GRADE" %in% names(d)) display$GRADE <- d$GRADE
  result <- gt::gt(display, groupname_col = "Outcome") |>
    .gt_optional_title(title) |>
    gt::tab_source_note("Each row is a reported meta-analysis result; no review-level pooling was performed.")
  if (save_as == "viewer") { print(result); return(invisible(result)) }
  if (is.null(filename)) filename <- file.path(tempdir(), paste0("umbrella_table.", save_as))
  gt::gtsave(result, filename); message("Table saved to: ", normalizePath(filename, mustWork = FALSE)); invisible(result)
}

#' Plot reported meta-analysis results in an umbrella review
#' @param object An `umbrella_review` object.
#' @param classification Optional output from [classify_umbrella()] for colours.
#' @param title Optional title.
#' @param save_as `"viewer"`, `"pdf"`, `"png"`, or `"tiff"`.
#' @param filename Optional output path.
#' @param width,height Output dimensions in inches.
#' @return A `ggplot2` object with one interval per reported meta-analysis and no pooled diamond.
#' @export
plot_umbrella <- function(object, classification = NULL, title = NULL,
                          save_as = c("viewer", "pdf", "png", "tiff"),
                          filename = NULL, width = 9, height = 7) {
  if (!inherits(object, "umbrella_review")) stop("'object' must be an umbrella_review object.", call. = FALSE)
  save_as <- match.arg(save_as); d <- object$results
  d$Label <- paste0(d$Outcome, " - ", d$Review)
  ordering <- order(d$Outcome, d$Estimate)
  d$Label <- factor(d$Label, levels = unique(d$Label[ordering]))
  if (!is.null(classification)) d$EvidenceClass <- classification$EvidenceClass[match(paste(d$Outcome, d$Review), paste(classification$Outcome, classification$Review))]
  p <- ggplot2::ggplot(d, ggplot2::aes(x = Estimate, y = Label)) +
    ggplot2::geom_errorbar(ggplot2::aes(xmin = lower, xmax = upper), orientation = "y", width = 0.18) +
    ggplot2::geom_vline(xintercept = object$settings$null, linetype = 2, colour = "grey45") +
    ggplot2::labs(x = "Reported meta-analysis estimate", y = NULL, title = title) +
    ggplot2::theme_minimal(base_size = 11)
  if ("EvidenceClass" %in% names(d)) p <- p + ggplot2::geom_point(ggplot2::aes(colour = EvidenceClass), size = 3) + ggplot2::labs(colour = "Credibility") else p <- p + ggplot2::geom_point(size = 3, colour = "#08519c")
  if (object$settings$effect_scale == "ratio") p <- p + ggplot2::scale_x_log10()
  if (save_as == "viewer") return(p)
  if (is.null(filename)) filename <- file.path(tempdir(), paste0("umbrella_plot.", save_as))
  ggplot2::ggsave(filename, p, width = width, height = height, dpi = 300); message("Umbrella plot saved to: ", normalizePath(filename, mustWork = FALSE)); invisible(p)
}

#' Plot citation matrices, pairwise overlap, or CCA
#' @param object An `umbrella_overlap` object.
#' @param type Plot type: `"citation_matrix"`, `"jaccard"`, `"cca"`, or
#'   `"cca_summary"`. `"cca"` draws a triangular pairwise CCA heatmap in the
#'   style established by the `ccaR` package; diagonal cells show the number
#'   of studies unique to that review and its total number of included studies.
#'   `"cca_summary"` draws
#'   outcome-level overall CCA bars.
#' @param title Optional title.
#' @param save_as `"viewer"`, `"pdf"`, `"png"`, or `"tiff"`.
#' @param filename Optional output path.
#' @param width,height Output dimensions in inches.
#' @return A `ggplot2` object, invisibly when saved.
#' @export
plot_study_overlap <- function(object, type = c("citation_matrix", "jaccard", "cca", "cca_summary"), title = NULL,
                               save_as = c("viewer", "pdf", "png", "tiff"), filename = NULL,
                               width = 9, height = 7) {
  if (!inherits(object, "umbrella_overlap")) stop("'object' must be an umbrella_overlap object.", call. = FALSE)
  type <- match.arg(type); save_as <- match.arg(save_as)
  if (type == "citation_matrix") {
    matrices <- if (!is.null(object$matrices)) object$matrices else
      list(Overall = object$matrix)
    d <- dplyr::bind_rows(lapply(names(matrices), function(outcome) {
      value <- as.data.frame(as.table(matrices[[outcome]]))
      names(value) <- c("Study", "Review", "Included")
      value$Outcome <- outcome
      value
    }))
    p <- ggplot2::ggplot(d, ggplot2::aes(x = Review, y = Study, fill = Included)) + ggplot2::geom_tile(colour = "white") +
      ggplot2::scale_fill_manual(values = c(`FALSE` = "white", `TRUE` = "#3182bd"),
        na.value = "grey80", name = "Included")
    if (length(matrices) > 1L) p <- p + ggplot2::facet_wrap(~Outcome, scales = "free")
  } else if (type == "jaccard") {
    d <- object$pairwise
    if (!nrow(d)) stop("At least two reviews are required.", call. = FALSE)
    reverse <- d; reverse$Review1 <- d$Review2; reverse$Review2 <- d$Review1
    diagonal <- dplyr::bind_rows(lapply(split(d, d$Outcome), function(g) {
      ids <- unique(c(g$Review1, g$Review2)); tibble::tibble(Outcome = g$Outcome[1], Review1 = ids, Review2 = ids, Jaccard = 1)
    }))
    d <- dplyr::bind_rows(d[, c("Outcome", "Review1", "Review2", "Jaccard")], reverse[, c("Outcome", "Review1", "Review2", "Jaccard")], diagonal)
    p <- ggplot2::ggplot(d, ggplot2::aes(x = Review1, y = Review2, fill = Jaccard)) + ggplot2::geom_tile(colour = "white") +
      ggplot2::scale_fill_gradient(low = "white", high = "#08519c", limits = c(0, 1), labels = scales::label_percent())
    if (length(unique(d$Outcome)) > 1L) p <- p + ggplot2::facet_wrap(~Outcome)
  } else if (type == "cca") {
    d <- object$pairwise
    if (!nrow(d)) stop("At least two reviews are required.", call. = FALSE)
    review_col <- object$mapping$review
    study_col <- object$mapping$study
    clean <- object$data
    counts <- dplyr::bind_rows(lapply(split(clean, clean$.group), function(g) {
      g <- g[!is.na(g$.included) & g$.included, , drop = FALSE]
      ids <- sort(unique(as.character(g[[review_col]])))
      study_frequency <- table(as.character(g[[study_col]]))
      single_ids <- names(study_frequency)[study_frequency == 1L]
      tibble::tibble(
        Outcome = g$.group[1], Review1 = ids, Review2 = ids,
        Single = vapply(ids, function(id) {
          studies <- unique(as.character(g[g[[review_col]] == id, study_col]))
          sum(studies %in% single_ids)
        }, integer(1)),
        Total = vapply(ids, function(id) {
          length(unique(as.character(g[g[[review_col]] == id, study_col])))
        }, integer(1))
      )
    }))
    # Outcome names are retained only as facet labels when multiple outcomes
    # are plotted. Overall CCA values belong in the returned table, not in an
    # automatically generated plot heading.
    d$Facet <- d$Outcome
    counts$Facet <- counts$Outcome
    review_levels <- sort(unique(as.character(clean[[review_col]])))
    d$Review1 <- factor(d$Review1, levels = review_levels)
    d$Review2 <- factor(d$Review2, levels = review_levels)
    counts$Review1 <- factor(counts$Review1, levels = review_levels)
    counts$Review2 <- factor(counts$Review2, levels = review_levels)
    p <- ggplot2::ggplot(d, ggplot2::aes(x = Review1, y = Review2)) +
      ggplot2::theme_classic(base_size = 16) +
      ggplot2::geom_tile(ggplot2::aes(fill = CCA.percent), colour = "grey") +
      ggplot2::geom_text(ggplot2::aes(label = sprintf("%.1f", CCA.percent),
        colour = CCA.percent > 60), fontface = "bold") +
      ggplot2::geom_tile(data = counts, ggplot2::aes(x = Review1, y = Review2),
        inherit.aes = FALSE, fill = "grey", colour = "grey") +
      ggplot2::geom_text(data = counts,
        ggplot2::aes(x = Review1, y = Review2,
          label = paste0(.data$Single, " / ", .data$Total, "*")),
        inherit.aes = FALSE, fontface = "bold") +
      ggplot2::scale_fill_gradient(low = "white", high = "#527e11",
        limits = c(0, 100), breaks = seq(0, 100, 20), name = "CCA (%)") +
      ggplot2::scale_colour_manual(values = c(`FALSE` = "black", `TRUE` = "white"),
        guide = "none") +
      ggplot2::scale_y_discrete(limits = review_levels, drop = FALSE) +
      ggplot2::coord_equal() +
      ggplot2::labs(x = NULL, y = NULL,
        caption = "* single / total number of primary studies included in the review\nCCA: Corrected Covered Area") +
      ggplot2::scale_x_discrete(limits = review_levels, drop = FALSE,
        position = "top") +
      ggplot2::theme(axis.text.x.top = ggplot2::element_text(
        angle = 90, vjust = 0.3, hjust = 0.05))
    if (length(unique(d$Outcome)) > 1L) {
      p <- p + ggplot2::facet_wrap(~Facet, scales = "free")
    }
  } else {
    d <- object$overall
    p <- ggplot2::ggplot(d, ggplot2::aes(x = stats::reorder(Outcome, CCA.percent), y = CCA.percent, fill = Interpretation)) +
      ggplot2::geom_col() + ggplot2::coord_flip() + ggplot2::labs(x = NULL, y = "Corrected covered area (%)", fill = "Overlap")
  }
  p <- p + ggplot2::labs(title = title)
  if (type != "cca") {
    p <- p + ggplot2::theme_minimal(base_size = 11) +
      ggplot2::theme(panel.grid = ggplot2::element_blank())
  }
  if (type == "citation_matrix") {
    p <- p + ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))
  }
  if (save_as == "viewer") return(p)
  if (is.null(filename)) filename <- file.path(tempdir(), paste0("study_overlap_", type, ".", save_as))
  ggplot2::ggsave(filename, p, width = width, height = height, dpi = 300); message("Overlap plot saved to: ", normalizePath(filename, mustWork = FALSE)); invisible(p)
}
