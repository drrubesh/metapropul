umbrella_dat <- data.frame(
  outcome = rep(c("Cardiovascular", "Mortality"), each = 3),
  review = paste0("Review ", 1:6),
  effect = c(0.78, 0.82, 0.80, 1.12, 1.08, 1.15),
  lower = c(0.70, 0.73, 0.72, 1.02, 0.99, 1.04),
  upper = c(0.87, 0.92, 0.89, 1.23, 1.18, 1.27),
  studies = c(14, 11, 16, 8, 12, 10),
  participants = c(3000, 2500, 4000, 1800, 2200, 2100),
  i2 = c(20, 45, 30, 55, 40, 25),
  p = c(1e-7, 2e-5, 4e-8, 0.01, 0.08, 0.004),
  pred_low = c(.71, .69, .73, .98, .94, 1.01),
  pred_high = c(.88, .98, .88, 1.28, 1.24, 1.30),
  year = c(2022, 2024, 2023, 2020, 2025, 2023),
  quality = c("High", "Moderate", "High", "Low", "High", "Moderate"),
  rob = c("Low", "Some concerns", "Low", "High", "Low", "Some concerns")
)

make_umbrella <- function() umbrella_review(
  umbrella_dat, "outcome", "review", "effect", "lower", "upper",
  studies = "studies", participants = "participants", i2 = "i2",
  p_value = "p", pred_lower = "pred_low", pred_upper = "pred_high",
  year = "year", quality = "quality", risk_of_bias = "rob"
)

test_that("umbrella_review preserves every reported result without pooling", {
  object <- make_umbrella()
  expect_s3_class(object, "umbrella_review")
  expect_equal(nrow(object$results), nrow(umbrella_dat))
  expect_equal(object$results$Estimate, umbrella_dat$effect)
  expect_false("models" %in% names(object))
  expect_false(any(grepl("pooled", names(object), ignore.case = TRUE)))
  expect_output(print(object), "Systematic reviews/meta-analyses: 6")
})

test_that("umbrella_review validates extracted fields", {
  bad <- umbrella_dat; bad$lower[1] <- 0
  expect_error(umbrella_review(bad, "outcome", "review", "effect", "lower", "upper"),
    "ratio estimates must be positive")
  expect_error(umbrella_review(umbrella_dat, "missing", "review", "effect", "lower", "upper"),
    "not found")
})

test_that("Ioannidis classification and GRADE remain distinct", {
  object <- make_umbrella()
  classification <- classify_umbrella(object)
  expect_true("EvidenceClass" %in% names(classification))
  expect_false("GRADE" %in% names(classification))
  grade <- grade_umbrella(object, starting_certainty = "high",
    risk_of_bias = c("not_serious", "serious", "not_serious", "very_serious",
      "not_serious", "serious"))
  expect_true("GRADE" %in% names(grade))
  expect_false("EvidenceClass" %in% names(grade))
  expect_equal(as.character(grade$GRADE[1]), "high")
  expect_equal(as.character(grade$GRADE[4]), "low")
})

test_that("review quality assessment stores AMSTAR or ROBIS judgements", {
  object <- make_umbrella()
  quality <- assess_review_quality(object, "AMSTAR2", overall = "quality")
  expect_s3_class(quality, "umbrella_review_quality")
  expect_equal(quality$Overall, umbrella_dat$quality)
  expect_error(assess_review_quality(object, "AMSTAR2", overall = 1:2),
    "scalar, length n")
})

test_that("umbrella table and plot show review rows without pooled diamond", {
  object <- make_umbrella(); classification <- classify_umbrella(object)
  grade <- grade_umbrella(object, "high")
  expect_s3_class(suppressMessages(table_umbrella(object, classification, grade)), "gt_tbl")
  plot <- plot_umbrella(object, classification)
  expect_s3_class(plot, "ggplot")
  expect_equal(nrow(plot$data), nrow(umbrella_dat))
  path <- tempfile(fileext = ".png")
  expect_message(plot_umbrella(object, classification, save_as = "png", filename = path), "saved to")
  expect_true(file.exists(path))
})

test_that("study overlap provides CCA, citation matrix, and all plot types", {
  membership <- data.frame(review = rep(c("A", "B", "C"), each = 3),
    study = c("1", "2", "3", "2", "3", "4", "3", "4", "5"),
    outcome = "Cardiovascular")
  overlap <- study_overlap(membership, "review", "study", "outcome")
  expect_equal(overlap$overall$CCA, 0.4)
  expect_equal(overlap$overall$Interpretation, "Very high")
  expect_equal(dim(overlap$matrix), c(5L, 3L))
  expect_true(is.list(overlap$matrices))
  expect_equal(names(overlap$matrices), "Cardiovascular")
  expect_equal(nrow(overlap$pairwise), 3L)
  expect_equal(overlap$pairwise$CCA, overlap$pairwise$Jaccard)
  expect_equal(overlap$pairwise$Occurrences, rep(6L, 3L))
  expect_equal(overlap$pairwise$StructuralMissing, rep(0L, 3L))
  expect_equal(overlap$pairwise$CCA.percent, 100 * overlap$pairwise$CCA)
  expect_s3_class(plot_study_overlap(overlap, "citation_matrix"), "ggplot")
  expect_s3_class(plot_study_overlap(overlap, "jaccard"), "ggplot")
  cca_plot <- plot_study_overlap(overlap, "cca")
  expect_s3_class(cca_plot, "ggplot")
  expect_equal(length(cca_plot$layers), 4L)
  expect_null(cca_plot$labels$title)
  expect_null(cca_plot$labels$subtitle)
  titled_cca <- plot_study_overlap(overlap, "cca", title = "Requested title")
  expect_equal(titled_cca$labels$title, "Requested title")
  expect_s3_class(plot_study_overlap(overlap, "cca_summary"), "ggplot")
})

test_that("CCA agrees with the corrected formula under structural missingness", {
  citation <- expand.grid(
    study = as.character(1:5), review = c("A", "B", "C"),
    stringsAsFactors = FALSE
  )
  values <- data.frame(
    study = as.character(1:5),
    A = c(1, 1, 1, 0, NA),
    B = c(0, 1, 1, 1, 0),
    C = c(0, 0, 1, 1, 1)
  )
  citation$included <- mapply(function(study, review) {
    values[values$study == study, review]
  }, citation$study, citation$review)

  overlap <- study_overlap(citation, "review", "study", included = "included")
  # ccaR reference: (N - r) / (r*c - r - structural missingness)
  expect_equal(overlap$overall$CCA, (9 - 5) / (5 * 3 - 5 - 1))
  expect_equal(overlap$overall$CCA.percent, 44.444444, tolerance = 1e-5)
  expect_equal(overlap$overall$StructuralMissing, 1L)
  expect_equal(overlap$pairwise$CCA, c(.5, .25, .5))
  expect_equal(overlap$pairwise$StructuralMissing, c(0L, 1L, 0L))
  expect_true(anyNA(overlap$matrix))
  expect_s3_class(plot_study_overlap(overlap, "citation_matrix"), "ggplot")
  expect_s3_class(plot_study_overlap(overlap, "cca"), "ggplot")
})

test_that("overlap sensitivity compares selection strategies without pooling", {
  object <- make_umbrella()
  membership <- data.frame(
    review = c(rep("Review 1", 3), rep("Review 2", 3), rep("Review 3", 3),
      rep("Review 4", 2), rep("Review 5", 2), rep("Review 6", 2)),
    study = c("a", "b", "c", "a", "b", "c", "d", "e", "f",
      "g", "h", "i", "j", "k", "l"),
    outcome = c(rep("Cardiovascular", 9), rep("Mortality", 6))
  )
  overlap <- study_overlap(membership, "review", "study", "outcome")
  sensitivity <- sensitivity_umbrella_overlap(object, overlap,
    strategies = c("highest_quality", "most_recent", "most_comprehensive", "lowest_overlap"))
  expect_s3_class(sensitivity, "umbrella_selection_sensitivity")
  expect_equal(nrow(sensitivity), 8L)
  expect_true(all(table(sensitivity$Outcome, sensitivity$Strategy) == 1L))
  expect_false(any(grepl("pooled", names(sensitivity), ignore.case = TRUE)))
  expect_equal(sensitivity$Review[sensitivity$Outcome == "Cardiovascular" &
    sensitivity$Strategy == "most_recent"], "Review 2")
})

test_that("primary diagnostics operate within source reviews", {
  set.seed(42)
  primary <- do.call(rbind, lapply(c("Review 1", "Review 2"), function(review) {
    k <- 12L; se <- seq(.08, .19, length.out = k); truth <- log(.8)
    yi <- truth + stats::rnorm(k, sd = se / 2)
    data.frame(outcome = "Cardiovascular", review = review,
      study = paste0(review, "-S", seq_len(k)), effect = exp(yi),
      lower = exp(yi - 1.96 * se), upper = exp(yi + 1.96 * se),
      participants = seq(500, 1600, length.out = k))
  }))
  duplicate <- primary[1, ]; primary <- rbind(primary, duplicate)
  diagnostics <- diagnose_umbrella_primary(primary, "outcome", "review", "study",
    "effect", "lower", "upper", participants = "participants")
  expect_s3_class(diagnostics, "umbrella_primary_diagnostics")
  expect_equal(nrow(diagnostics$summary), 2L)
  expect_equal(diagnostics$summary$PrimaryStudies, c(12L, 12L))
  expect_equal(nrow(diagnostics$duplicate_audit), 1L)
  object <- make_umbrella()
  classified <- classify_umbrella(object, diagnostics)
  expect_equal(nrow(classified), nrow(object$results))
})

test_that("umbrella_meta has been removed", {
  expect_false(exists("umbrella_meta", envir = asNamespace("metapropul"), inherits = FALSE))
})
