## LET'S TEST METAPROPUL IN REAL TIME
## Script 3: ROB, generic effects, rates, correlations and umbrella reviews

devtools::load_all()
library(dplyr)

output_dir <- file.path(getwd(), "manual-test-output")
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

###############################################################################
## 1. RISK-OF-BIAS VALIDATION AND FIGURES
###############################################################################

data("caffeine", package = "metapropul")
names(caffeine)
head(caffeine)

rob_domains <- c("D1", "D2", "D3", "D4", "D5", "rob")
rob_levels <- unique(unlist(caffeine[rob_domains], use.names = FALSE))
rob_levels <- rob_levels[!is.na(rob_levels)]

rob_check <- validate_rob(
  caffeine, studylab = "study", tool = "Custom",
  domains = rob_domains, levels = rob_levels
)
rob_check
names(rob_check)
rob_check$frequencies

rob_traffic <- plot_rob(
  caffeine, "study", tool = "Custom",
  domains = rob_domains, levels = rob_levels
)
rob_traffic

rob_summary <- plot_rob_summary(
  caffeine, "study", tool = "Custom",
  domains = rob_domains, levels = rob_levels
)
rob_summary

ggplot2::ggsave(file.path(output_dir, "rob-traffic-light.pdf"),
  rob_traffic, width = 10, height = 7)
ggplot2::ggsave(file.path(output_dir, "rob-summary.pdf"),
  rob_summary, width = 9, height = 6)

###############################################################################
## 2. GENERIC INVERSE-VARIANCE META-ANALYSIS
###############################################################################

data("Pagliaro1992", package = "metapropul")
## Some upstream teaching datasets carry an old `pairwise` subclass. Convert
## to a plain data frame before using modern dplyr verbs.
Pagliaro1992 <- as.data.frame(unclass(Pagliaro1992))
names(Pagliaro1992)
head(Pagliaro1992)

generic_or <- meta_generic(
  Pagliaro1992, effect = "logOR", se = "selogOR",
  studylab = "id", measure = "Odds ratio", backtransform = "exp",
  model = "random", duplicate_action = "make_unique"
)
summary(generic_or)
generic_or
names(generic_or)
head(generic_or$table)
generic_or$settings

## Reconstruct variances to exercise the alternative input route.
Pagliaro1992$variance <- Pagliaro1992$selogOR^2
generic_variance <- meta_generic(
  Pagliaro1992, effect = "logOR", variance = "variance",
  studylab = "id", measure = "Odds ratio", backtransform = "exp",
  duplicate_action = "make_unique"
)
summary(generic_variance)

## Reconstruct confidence intervals to exercise the third uncertainty route.
Pagliaro1992 <- Pagliaro1992 |>
  mutate(lower_log = logOR - 1.96 * selogOR,
         upper_log = logOR + 1.96 * selogOR)
generic_ci <- meta_generic(
  Pagliaro1992, effect = "logOR", lower = "lower_log", upper = "upper_log",
  studylab = "id", measure = "Odds ratio", backtransform = "exp",
  duplicate_action = "make_unique"
)
summary(generic_ci)

table_meta(generic_or)
forest_meta(generic_or)
forest_meta(generic_or, save_as = "pdf",
  filename = file.path(output_dir, "generic-odds-ratio.pdf"))

###############################################################################
## 3. INCIDENCE-RATE META-ANALYSIS
###############################################################################

data("lungcancer", package = "metapropul")
names(lungcancer)
head(lungcancer)

smoking_rate <- meta_rate(
  lungcancer, event = "d.smokers", time = "py.smokers",
  studylab = "study", irscale = 100000, irunit = "person-years",
  model = "random"
)
summary(smoking_rate)
smoking_rate
head(smoking_rate$table)
smoking_rate$settings

## Compare fixed-effect output without confusing a rate with a rate ratio.
smoking_rate_fixed <- meta_rate(
  lungcancer, "d.smokers", "py.smokers", studylab = "study",
  irscale = 100000, irunit = "person-years", model = "fixed"
)
summary(smoking_rate_fixed)

table_meta(smoking_rate)
forest_meta(smoking_rate)
forest_meta(smoking_rate, save_as = "pdf",
  filename = file.path(output_dir, "smoking-incidence-rate.pdf"))

###############################################################################
## 4. CORRELATION META-ANALYSIS
###############################################################################

## This dataset is simulated for function testing and is not clinical evidence.
correlation_data <- data.frame(
  study = paste("Correlation study", 1:10),
  r = c(0.12, 0.28, 0.05, -0.04, 0.31, 0.18, 0.22, 0.09, 0.41, 0.15),
  n = c(84, 120, 95, 78, 160, 110, 140, 90, 175, 105),
  setting = rep(c("Community", "Clinical"), 5)
)
correlation_data

cor_random <- meta_cor(
  correlation_data, cor = "r", n = "n", studylab = "study",
  model = "random"
)
summary(cor_random)
cor_random
head(cor_random$table)

cor_subgroup <- meta_cor(
  correlation_data, "r", "n", studylab = "study",
  subgroup = "setting", model = "random"
)
summary(cor_subgroup)
cor_subgroup$meta.subgroup.summary
cor_subgroup$subgroup_test

table_meta(cor_random)
forest_meta(cor_random)
forest_meta(cor_random, save_as = "pdf",
  filename = file.path(output_dir, "correlation-meta-analysis.pdf"))

###############################################################################
## 5. BUILD A NON-POOLING UMBRELLA-REVIEW EXAMPLE
###############################################################################

data("dat_bcg", package = "metapropul")
dat_bcg$n_control <- dat_bcg$cpos + dat_bcg$cneg

## Create three overlapping source reviews for teaching. Each is fitted and
## reported separately. We do NOT combine their pooled estimates.
review_rows <- list(
  "All eligible trials" = seq_len(nrow(dat_bcg)),
  "Trials through 1974" = which(dat_bcg$year <= 1974),
  "Trials from 1953" = which(dat_bcg$year >= 1953)
)

fit_source_review <- function(rows) {
  meta_ratio(
    dat_bcg[rows, ], "tpos", "npos", "cpos", "n_control",
    studylab = "author", measure = "OR", model = "random",
    duplicate_action = "make_unique"
  )
}
source_fits <- lapply(review_rows, fit_source_review)
lapply(source_fits, summary)

review_results <- bind_rows(lapply(seq_along(source_fits), function(i) {
  fit <- source_fits[[i]]$meta
  rows <- review_rows[[i]]
  data.frame(
    outcome = "Tuberculosis",
    review = names(source_fits)[i],
    effect = exp(fit$TE.random), lower = exp(fit$lower.random),
    upper = exp(fit$upper.random), studies = fit$k,
    participants = sum(dat_bcg$npos[rows] + dat_bcg$n_control[rows]),
    i2 = 100 * fit$I2, p_value = fit$pval.random,
    pred_lower = exp(fit$lower.predict), pred_upper = exp(fit$upper.predict),
    year = c(2026, 2024, 2022)[i],
    quality = c("High", "Moderate", "Low")[i],
    risk_of_bias = c("Low", "Some concerns", "High")[i]
  )
}))
review_results

umbrella <- umbrella_review(
  review_results, outcome = "outcome", review = "review",
  effect = "effect", lower = "lower", upper = "upper",
  studies = "studies", participants = "participants", i2 = "i2",
  p_value = "p_value", pred_lower = "pred_lower",
  pred_upper = "pred_upper", year = "year", quality = "quality",
  risk_of_bias = "risk_of_bias", effect_scale = "ratio"
)
umbrella
names(umbrella)
umbrella$results

## Confirm by inspection: there is no umbrella pooled model.
"models" %in% names(umbrella)

###############################################################################
## 6. PRIMARY-STUDY DIAGNOSTICS WITHIN EACH SOURCE REVIEW
###############################################################################

make_primary_rows <- function(review, rows) {
  d <- dat_bcg[rows, ]
  a <- d$tpos
  b <- d$npos - d$tpos
  c <- d$cpos
  d0 <- d$cneg
  log_or <- log((a * d0) / (b * c))
  se <- sqrt(1 / a + 1 / b + 1 / c + 1 / d0)
  data.frame(
    outcome = "Tuberculosis", review = review,
    study = paste0(d$author, " (", d$year, ")"),
    effect = exp(log_or), lower = exp(log_or - 1.96 * se),
    upper = exp(log_or + 1.96 * se),
    participants = d$npos + d$n_control
  )
}
primary_data <- bind_rows(Map(make_primary_rows, names(review_rows), review_rows))
head(primary_data)

umbrella_diagnostics <- diagnose_umbrella_primary(
  primary_data, "outcome", "review", "study", "effect", "lower", "upper",
  participants = "participants", effect_scale = "ratio"
)
umbrella_diagnostics$summary

classification <- classify_umbrella(umbrella, umbrella_diagnostics)
classification

###############################################################################
## 7. GRADE AND REVIEW-QUALITY RECORDING
###############################################################################

## These are reviewer decisions, not automated GRADE calculations.
grade <- grade_umbrella(
  umbrella,
  starting_certainty = "high",
  risk_of_bias = c("not_serious", "serious", "very_serious"),
  inconsistency = c("serious", "serious", "serious"),
  indirectness = "not_serious",
  imprecision = "not_serious",
  publication_bias = "not_serious",
  rationale = c(
    "All trials; residual heterogeneity considered serious.",
    "Restricted eligibility and some risk-of-bias concerns.",
    "Older review with high risk-of-bias concern."
  ),
  assessor = "Manual tester",
  assessment_date = Sys.Date()
)
grade

amstar2 <- assess_review_quality(
  umbrella, tool = "AMSTAR2", overall = "quality"
)
amstar2

table_umbrella(umbrella, classification, grade)
plot_umbrella(umbrella, classification)
plot_umbrella(umbrella, classification, save_as = "pdf",
  filename = file.path(output_dir, "umbrella-reported-results.pdf"))

###############################################################################
## 8. STUDY OVERLAP, CCA, JACCARD AND CITATION MATRIX
###############################################################################

membership <- primary_data[c("outcome", "review", "study")]
overlap <- study_overlap(membership, review = "review", study = "study",
  outcome = "outcome")
names(overlap)
overlap$overall
overlap$pairwise
overlap$citation_matrix

plot_study_overlap(overlap, type = "citation_matrix")
plot_study_overlap(overlap, type = "jaccard")
plot_study_overlap(overlap, type = "cca")
plot_study_overlap(overlap, type = "cca_summary")

plot_study_overlap(overlap, type = "citation_matrix", save_as = "pdf",
  filename = file.path(output_dir, "overlap-citation-matrix.pdf"))
plot_study_overlap(overlap, type = "jaccard", save_as = "pdf",
  filename = file.path(output_dir, "overlap-jaccard.pdf"))
plot_study_overlap(overlap, type = "cca", save_as = "pdf",
  filename = file.path(output_dir, "overlap-cca.pdf"))

###############################################################################
## 9. OVERLAP-AWARE REVIEW-SELECTION SENSITIVITY
###############################################################################

selection <- sensitivity_umbrella_overlap(
  umbrella, overlap,
  strategies = c(
    "highest_quality", "lowest_risk_of_bias", "most_recent",
    "most_comprehensive", "largest_participant_count", "lowest_overlap",
    "user_selected"
  ),
  user_selected = c(Tuberculosis = "Trials through 1974")
)
selection

## Check the column names: selection compares source reviews and does not pool.
names(selection)
any(grepl("pooled", names(selection), ignore.case = TRUE))

## Inspect all generated files.
list.files(output_dir, full.names = TRUE)
