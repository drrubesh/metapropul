# Manual end-to-end audit for metapropul.
# Run from the package root with: Rscript tools/manual_audit.R

options(warn = 1)

required <- c("devtools", "meta", "metafor", "metasens", "gt")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) {
  stop("Install required packages before running: ", paste(missing, collapse = ", "))
}

devtools::load_all(quiet = TRUE)
output_dir <- file.path(tempdir(), "metapropul-manual-audit")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

check <- function(ok, label) {
  if (!isTRUE(ok)) stop("FAILED: ", label, call. = FALSE)
  message("PASS: ", label)
}

data("dat_bcg", package = "metapropul")
data("dat_normand1999", package = "metapropul")
dat_bcg$ncon <- dat_bcg$cpos + dat_bcg$cneg

# Core model families, with subgroups.
ratio <- meta_ratio(
  dat_bcg, "tpos", "npos", "cpos", "ncon",
  studylab = "author", subgroup = "alloc", measure = "OR"
)
prop <- meta_prop(
  dat_bcg, "tpos", "npos", studylab = "author", subgroup = "alloc"
)
dat_normand1999$subgroup <- rep(c("A", "B"), length.out = nrow(dat_normand1999))
mean <- meta_mean(
  dat_normand1999,
  "m1i", "sd1i", "n1i", "m2i", "sd2i", "n2i",
  studylab = "source", subgroup = "subgroup"
)

for (object in list(ratio, prop, mean)) {
  check(inherits(object$meta, "meta"), paste(class(object)[1], "model fitted"))
  check(nrow(object$table) == object$meta$k, paste(class(object)[1], "study table"))
  check(nrow(object$meta.subgroup.summary) >= 2L,
    paste(class(object)[1], "subgroup summary")
  )
  check(all(is.finite(object$meta.subgroup.summary$Estimate)),
    paste(class(object)[1], "finite subgroup estimates")
  )
}

# Meta-regression and diagnostics.
reg <- meta_reg(prop, dat_bcg, ~ ablat, "author")
check(inherits(reg$meta, "rma"), "meta-regression")
check(inherits(table_meta(prop), "gt_tbl"), "main results table")
check(inherits(table_influence(prop), "gt_tbl"), "influence table")
check(inherits(table_cumulative_meta(prop), "gt_tbl"), "cumulative table")

# Large-k forest plot: 200 studies, four subgroups. PDF is used because a
# screen pane cannot display 200 readable rows at ordinary zoom.
set.seed(20260809)
large <- data.frame(
  study = sprintf("Study %03d", seq_len(200)),
  event = stats::rbinom(200, 200, 0.12),
  total = rep(200L, 200),
  subgroup = rep(c("A", "B", "C", "D"), each = 50)
)
large_fit <- meta_prop(
  large, "event", "total", studylab = "study", subgroup = "subgroup"
)
large_pdf <- file.path(output_dir, "forest-200-studies.pdf")
forest_meta(large_fit, save_as = "pdf", filename = large_pdf)
check(file.exists(large_pdf) && file.info(large_pdf)$size > 0,
  "200-study subgroup forest plot"
)

# Remaining figure functions. Each writes a concrete artifact for inspection.
forest_influence(prop, save_as = "pdf",
  filename = file.path(output_dir, "forest-influence.pdf")
)
forest_cumulative(prop, save_as = "pdf",
  filename = file.path(output_dir, "forest-cumulative.pdf")
)
plot_heterogeneity(prop, save_as = "pdf",
  filename = file.path(output_dir, "heterogeneity.pdf")
)
plot_baujat(prop, save_as = "pdf", filename = file.path(output_dir, "baujat.pdf"))
publication_bias(prop, plot_method = "original", save_as = "pdf",
  filename = file.path(output_dir, "publication-bias.pdf")
)
doi_plot(mean, save_as = "pdf", filename = file.path(output_dir, "doi.pdf"))
bubble_plot(reg, moderator = "ablat", save_as = "pdf",
  filename = file.path(output_dir, "bubble.pdf")
)

rob <- data.frame(
  study = c("Study 1", "Study 2", "Study 3"),
  d1 = c("Low", "Some concerns", "High"),
  d2 = c("Low", "Low", "Some concerns"),
  overall = c("Low", "Some concerns", "High")
)
rob_plot <- plot_rob(
  rob, "study", tool = "Custom",
  domains = c("d1", "d2", "overall"),
  levels = c("Low", "Some concerns", "High")
)
rob_summary <- plot_rob_summary(
  rob, "study", tool = "Custom",
  domains = c("d1", "d2", "overall"),
  levels = c("Low", "Some concerns", "High")
)
check(inherits(rob_plot, "ggplot"), "risk-of-bias traffic-light plot")
check(inherits(rob_summary, "ggplot"), "risk-of-bias summary plot")

# Umbrella-review workflow: preserve reported review results, classify
# statistical credibility, record GRADE judgements, assess overlap, and compare
# review-selection strategies. No meta-analysis results are pooled together.
umbrella_data <- data.frame(
  outcome = rep(c("Outcome A", "Outcome B"), each = 3),
  review = paste0("Review ", seq_len(6)),
  effect = c(0.78, 0.82, 0.80, 1.12, 1.08, 1.15),
  lower = c(0.70, 0.73, 0.72, 1.02, 0.99, 1.04),
  upper = c(0.87, 0.92, 0.89, 1.23, 1.18, 1.27),
  participants = c(3000, 2500, 4000, 1800, 2200, 2100),
  studies = c(14, 11, 16, 8, 12, 10),
  i2 = c(20, 45, 30, 55, 40, 25),
  p = c(1e-7, 2e-5, 4e-8, 0.01, 0.08, 0.004),
  pred_lower = c(.71, .69, .73, .98, .94, 1.01),
  pred_upper = c(.88, .98, .88, 1.28, 1.24, 1.30),
  year = c(2022, 2024, 2023, 2020, 2025, 2023),
  quality = c("High", "Moderate", "High", "Low", "High", "Moderate"),
  rob = c("Low", "Some concerns", "Low", "High", "Low", "Some concerns")
)
umbrella <- umbrella_review(
  umbrella_data, "outcome", "review", "effect", "lower", "upper",
  studies = "studies", participants = "participants", i2 = "i2",
  p_value = "p", pred_lower = "pred_lower", pred_upper = "pred_upper",
  year = "year", quality = "quality", risk_of_bias = "rob"
)
umbrella_classes <- classify_umbrella(umbrella)
umbrella_grades <- grade_umbrella(umbrella, starting_certainty = "high")
check(nrow(umbrella$results) == 6L, "umbrella review preserves reported results")
check(all(!is.na(umbrella_classes$EvidenceClass)), "umbrella credibility classification")
check(all(!is.na(umbrella_grades$GRADE)), "structured GRADE recording")
plot_umbrella(
  umbrella, umbrella_classes, save_as = "pdf",
  filename = file.path(output_dir, "umbrella-evidence-map.pdf")
)

membership <- data.frame(
  review = c(rep("Review 1", 3), rep("Review 2", 3), rep("Review 3", 3),
    rep("Review 4", 2), rep("Review 5", 2), rep("Review 6", 2)),
  study = c("a", "b", "c", "a", "b", "c", "d", "e", "f",
    "g", "h", "i", "j", "k", "l"),
  outcome = c(rep("Outcome A", 9), rep("Outcome B", 6))
)
overlap <- study_overlap(membership, "review", "study", "outcome")
overlap_sensitivity <- sensitivity_umbrella_overlap(
  umbrella, overlap,
  strategies = c("highest_quality", "most_recent", "most_comprehensive", "lowest_overlap")
)
check(nrow(overlap_sensitivity) == 8L,
  "overlap-aware review-selection sensitivity analysis")
plot_study_overlap(
  overlap, save_as = "pdf",
  filename = file.path(output_dir, "review-overlap.pdf")
)

# Primary-study diagnostics for umbrella credibility grading. Duplicate study
# P01 is intentionally duplicated within its source review and counted once.
set.seed(20260810)
primary_se <- seq(0.08, 0.19, length.out = 12)
primary_yi <- log(0.8) + stats::rnorm(12, sd = primary_se / 2)
primary_data <- data.frame(
  outcome = "Outcome A", study = paste0("P", sprintf("%02d", seq_len(12))),
  review = "Review 1", effect = exp(primary_yi),
  lower = exp(primary_yi - 1.96 * primary_se),
  upper = exp(primary_yi + 1.96 * primary_se),
  participants = seq(500, 1600, length.out = 12)
)
primary_data <- rbind(primary_data, primary_data[1, ])
primary_diagnostics <- diagnose_umbrella_primary(
  primary_data, "outcome", "review", "study", "effect", "lower", "upper",
  participants = "participants"
)
check(primary_diagnostics$summary$PrimaryStudies == 12L &&
    primary_diagnostics$summary$Review == "Review 1",
  "within-review primary-study diagnostics")

message("Manual audit completed. Inspect outputs in: ", output_dir)
