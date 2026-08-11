# Manual umbrella-review audit using a dataset bundled with metapropul.
#
# Run from the package root with:
#   Rscript tools/manual_umbrella_builtin.R
#   Rscript tools/manual_umbrella_builtin.R path/to/retained-output
#
# The three review records below are deliberately overlapping analyses of
# dat_bcg. They are teaching/audit examples, not published systematic reviews.
# Each reported meta-analysis remains separate throughout the workflow.

options(warn = 1)
source("tools/manual_cases/_helpers.R")
data("dat_bcg", package = "metapropul")
output_dir <- manual_output_dir("umbrella-builtin-audit")
check <- manual_check

case_begin("Umbrella review without pooling meta-analyses",
  "How can overlapping reviews of the same outcome be mapped, appraised, classified, and compared without calculating a new pooled estimate across reviews?",
  "Three deliberately overlapping eligibility windows constructed from bundled `dat_bcg` trials. They are teaching reviews, not published systematic reviews.", output_dir)
case_section("1. Construct separate source reviews")
case_text("Each eligibility window is analysed independently. The resulting review-level estimates remain separate throughout the umbrella workflow; this case explicitly tests that no umbrella-level pooled model is created.")

# Treat three overlapping eligibility windows as three source reviews. This
# provides known citation overlap while using only package-bundled study data.
review_rows <- list(
  "BCG all trials" = seq_len(nrow(dat_bcg)),
  "BCG through 1974" = which(dat_bcg$year <= 1974),
  "BCG from 1953" = which(dat_bcg$year >= 1953)
)

fit_review <- function(rows) {
  d <- dat_bcg[rows, , drop = FALSE]
  d$ncon <- d$cpos + d$cneg
  meta_ratio(
    d, event.e = "tpos", n.e = "npos", event.c = "cpos", n.c = "ncon",
    studylab = "author", measure = "OR", model = "random",
    tau_method = "REML", ci_method = "HK", prediction_interval = TRUE,
    duplicate_action = "make_unique"
  )
}

fits <- lapply(review_rows, fit_review)

# Extract the three source meta-analysis results. These rows are passed to
# umbrella_review(); they are never pooled with one another.
quality <- c("High", "Moderate", "Low")
risk_of_bias <- c("Low", "Some concerns", "High")
review_year <- c(2026L, 2024L, 2022L)
review_data <- do.call(rbind, lapply(seq_along(fits), function(i) {
  model <- fits[[i]]$meta
  rows <- review_rows[[i]]
  data.frame(
    outcome = "Tuberculosis incidence",
    review = names(fits)[i],
    effect = exp(model$TE.random),
    lower = exp(model$lower.random),
    upper = exp(model$upper.random),
    studies = model$k,
    participants = sum(dat_bcg$npos[rows] + dat_bcg$cpos[rows] + dat_bcg$cneg[rows]),
    i2 = 100 * model$I2,
    p_value = model$pval.random,
    pred_lower = exp(model$lower.predict),
    pred_upper = exp(model$upper.predict),
    year = review_year[i],
    quality = quality[i],
    risk_of_bias = risk_of_bias[i],
    stringsAsFactors = FALSE
  )
}))

umbrella <- umbrella_review(
  review_data, "outcome", "review", "effect", "lower", "upper",
  studies = "studies", participants = "participants", i2 = "i2",
  p_value = "p_value", pred_lower = "pred_lower",
  pred_upper = "pred_upper", year = "year", quality = "quality",
  risk_of_bias = "risk_of_bias", effect_scale = "ratio"
)
case_value("Source reviews", nrow(umbrella$results))
check(nrow(umbrella$results) == length(review_rows),
  "reported meta-analysis rows are preserved")
check(!"models" %in% names(umbrella), "umbrella object contains no pooled model")

case_section("2. Diagnose evidence within each review")
case_text("Primary-study diagnostics are calculated inside each source review. They inform credibility classification but are never used to merge the source reviews.")
# Create long primary-study data independently within every source review.
# The same trial may occur in several reviews; that is intentional overlap.
make_primary <- function(review, rows) {
  d <- dat_bcg[rows, , drop = FALSE]
  a <- d$tpos
  b <- d$npos - d$tpos
  c <- d$cpos
  d0 <- d$cneg
  log_or <- log((a * d0) / (b * c))
  se <- sqrt(1 / a + 1 / b + 1 / c + 1 / d0)
  data.frame(
    outcome = "Tuberculosis incidence", review = review,
    study = paste0(d$author, " (", d$year, ")"), effect = exp(log_or),
    lower = exp(log_or - stats::qnorm(0.975) * se),
    upper = exp(log_or + stats::qnorm(0.975) * se),
    participants = d$npos + d$cpos + d$cneg,
    stringsAsFactors = FALSE
  )
}
primary_data <- do.call(rbind, Map(make_primary, names(review_rows), review_rows))

diagnostics <- diagnose_umbrella_primary(
  primary_data, "outcome", "review", "study", "effect", "lower", "upper",
  participants = "participants", effect_scale = "ratio"
)
check(nrow(diagnostics$summary) == length(review_rows),
  "primary-study diagnostics remain within source reviews")

classification <- classify_umbrella(umbrella, diagnostics)
grade <- grade_umbrella(
  umbrella, starting_certainty = "high",
  risk_of_bias = c("not_serious", "serious", "very_serious"),
  inconsistency = c("serious", "serious", "serious"),
  indirectness = "not_serious", imprecision = "not_serious",
  publication_bias = "not_serious"
)
quality_assessment <- assess_review_quality(umbrella, "AMSTAR2", "quality")
check(all(!is.na(classification$EvidenceClass)), "credibility classification")
check(all(!is.na(grade$GRADE)), "reviewer-supplied GRADE decisions")
check(nrow(quality_assessment) == length(review_rows), "AMSTAR 2 recording")

case_section("3. Quantify primary-study overlap")
case_text("The citation matrix records review-by-study membership. Corrected covered area summarises overall redundancy, while pairwise Jaccard values show which review pairs share studies. High overlap affects interpretation and review selection; it is not resolved by pooling reviews.")

membership <- primary_data[c("outcome", "review", "study")]
overlap <- study_overlap(membership, "review", "study", "outcome")
check(is.finite(overlap$overall$CCA), "corrected covered area")
check(nrow(overlap$pairwise) == choose(length(review_rows), 2L),
  "pairwise overlap statistics")
case_value("Corrected covered area", paste0(fmt_num(overlap$overall$CCA.percent, 1), "% (",
  overlap$overall$Interpretation, ")"))

case_section("4. Review-selection sensitivity analysis")
case_text("Selection strategies identify one review per outcome under transparent rules such as quality, recency, comprehensiveness, or overlap. The output compares decisions and does not create revised effect estimates.")
selection <- sensitivity_umbrella_overlap(
  umbrella, overlap,
  strategies = c(
    "highest_quality", "lowest_risk_of_bias", "most_recent",
    "most_comprehensive", "largest_participant_count", "lowest_overlap",
    "user_selected"
  ),
  user_selected = c("Tuberculosis incidence" = "BCG through 1974")
)
check(nrow(selection) == 7L, "all review-selection sensitivity strategies")
check(!any(grepl("pooled", names(selection), ignore.case = TRUE)),
  "selection sensitivity does not pool reviews")

# Save inspectable tables and every umbrella figure type.
invisible(utils::capture.output(
  evidence_table <- suppressMessages(table_umbrella(
    umbrella, classification, grade, title = "BCG umbrella-review audit"
  ))
))
gt::gtsave(evidence_table, file.path(output_dir, "umbrella-evidence-table.html"))
utils::write.csv(review_data, file.path(output_dir, "reported-review-results.csv"),
  row.names = FALSE)
utils::write.csv(diagnostics$summary,
  file.path(output_dir, "primary-study-diagnostics.csv"), row.names = FALSE)
utils::write.csv(overlap$overall, file.path(output_dir, "overlap-cca.csv"),
  row.names = FALSE)
utils::write.csv(overlap$pairwise,
  file.path(output_dir, "overlap-pairwise.csv"), row.names = FALSE)
utils::write.csv(selection,
  file.path(output_dir, "review-selection-sensitivity.csv"), row.names = FALSE)

plot_umbrella(
  umbrella, classification, title = "Reported BCG meta-analyses (not pooled)",
  save_as = "pdf", filename = file.path(output_dir, "umbrella-plot.pdf")
)
for (type in c("citation_matrix", "jaccard", "cca")) {
  plot_study_overlap(
    overlap, type = type, save_as = "pdf",
    filename = file.path(output_dir, paste0("overlap-", type, ".pdf"))
  )
}

expected_files <- c(
  "umbrella-evidence-table.html", "reported-review-results.csv",
  "primary-study-diagnostics.csv", "overlap-cca.csv",
  "overlap-pairwise.csv", "review-selection-sensitivity.csv",
  "umbrella-plot.pdf", "overlap-citation_matrix.pdf",
  "overlap-jaccard.pdf", "overlap-cca.pdf"
)
paths <- file.path(output_dir, expected_files)
check(all(file.exists(paths) & file.info(paths)$size > 0),
  "all manual-review artifacts were created")

case_finish(expected_files)

message("Manual umbrella audit completed.")
message("Inspect outputs in: ", normalizePath(output_dir))
