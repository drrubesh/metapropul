# Generic, correlation, and incidence-rate meta-analysis case study.
# Run: Rscript tools/manual_cases/06_additional_models_case.R [output-directory]
source("tools/manual_cases/_helpers.R")
out <- manual_output_dir("additional-models-case")

case_begin("Three alternative meta-analytic data structures",
  "How should an analyst choose between generic inverse variance, incidence-rate, and correlation meta-analysis when raw two-arm data are unavailable?",
  "Bundled `Pagliaro1992` and `lungcancer` data, plus an explicitly simulated correlation teaching dataset.", out)
case_section("1. Published effects with standard errors")
case_text("When a study already reports a log effect and its standard error, `meta_generic()` avoids reconstructing fictitious arm-level data. Exponentiation returns odds ratios for interpretation.")

# Generic inverse-variance analysis using the bundled Pagliaro1992 log odds
# ratios and their standard errors.
data("Pagliaro1992", package = "metapropul")
generic <- meta_generic(Pagliaro1992, effect = "logOR", se = "selogOR",
  studylab = "id", measure = "Odds ratio", backtransform = "exp",
  duplicate_action = "make_unique")
manual_check(inherits(generic, "meta_generic"), "generic inverse-variance model")
case_value("Generic pooled odds ratio", pooled_text(generic))

# Incidence rates using the bundled lung-cancer person-time dataset.
case_section("2. Events observed over person-time")
case_text("Incidence-rate meta-analysis retains the amount of observation time. Results are scaled to 100,000 person-years; they are rates, not risks or rate ratios.")
data("lungcancer", package = "metapropul")
rates <- meta_rate(lungcancer, event = "d.smokers", time = "py.smokers",
  studylab = "study", irscale = 100000, irunit = "person-years")
manual_check(inherits(rates, "meta_rate"), "incidence-rate model")
case_value("Pooled incidence rate per 100,000 person-years", pooled_text(rates))

# Correlation datasets require r and n. This compact teaching dataset is kept
# inside the manual script so package data are not presented as real evidence.
case_section("3. Correlations and Fisher's z")
case_text("Correlations are transformed to Fisher's z for analysis and returned to the correlation scale. The following values are simulated and must never be presented as clinical evidence.")
correlations <- data.frame(
  study = paste("Correlation study", 1:8),
  r = c(0.12, 0.28, 0.05, -0.04, 0.31, 0.18, 0.22, 0.09),
  n = c(84, 120, 95, 78, 160, 110, 140, 90)
)
cor_fit <- meta_cor(correlations, cor = "r", n = "n", studylab = "study")
manual_check(inherits(cor_fit, "meta_cor"), "Fisher-z correlation model")
case_value("Pooled correlation", pooled_text(cor_fit))

case_section("4. Compare the three reporting paths")
case_text("Each fitted object should produce the same table/forest workflow while retaining its correct scientific scale and labels.")

save_gt_html(table_meta(generic), file.path(out, "generic-results.html"))
save_gt_html(table_meta(rates), file.path(out, "rate-results.html"))
save_gt_html(table_meta(cor_fit), file.path(out, "correlation-results.html"))
forest_meta(generic, save_as = "pdf", filename = file.path(out, "generic-forest.pdf"))
forest_meta(rates, save_as = "pdf", filename = file.path(out, "rate-forest.pdf"))
forest_meta(cor_fit, save_as = "pdf", filename = file.path(out, "correlation-forest.pdf"))
check_artifacts(out, c("generic-results.html", "rate-results.html",
  "correlation-results.html", "generic-forest.pdf", "rate-forest.pdf",
  "correlation-forest.pdf"))
case_finish(c("generic-results.html", "generic-forest.pdf", "rate-results.html",
  "rate-forest.pdf", "correlation-results.html", "correlation-forest.pdf"))
message("Additional-model case completed: ", out)
