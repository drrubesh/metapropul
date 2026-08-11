# Meta-regression case study using latitude and allocation from bundled BCG data.
# Run: Rscript tools/manual_cases/04_meta_regression_case.R [output-directory]
source("tools/manual_cases/_helpers.R")
out <- manual_output_dir("meta-regression-case")
data("dat_bcg", package = "metapropul")

case_begin("Explaining variation with meta-regression",
  "Is vaccinated-arm tuberculosis risk associated with study latitude, and is that association modified by allocation method?",
  "`dat_bcg`, using absolute latitude as a continuous moderator and allocation method as a categorical moderator.", out)
case_section("1. Fit the source meta-analysis")
case_text("Meta-regression is fitted to study effects and uncertainty, not participant-level observations. With only 13 studies, multivariable findings are exploratory.")
base <- meta_prop(dat_bcg, "tpos", "npos", studylab = "author",
  duplicate_action = "make_unique")

case_section("2. Univariable Knapp-Hartung model")
case_text("Latitude is centred so the intercept represents a study at mean latitude. Knapp-Hartung inference is requested because uncertainty can otherwise be understated in small meta-analyses.")
uni <- suppressWarnings(meta_reg(base, dat_bcg, ~ ablat, "author",
  center = "ablat", test = "knha", min_studies_per_parameter = 3))

case_section("3. Exploratory interaction model")
case_text("The multivariable model includes latitude, allocation, and their interaction. Random allocation is the reference category and latitude is scaled. A low studies-per-parameter ratio limits inference.")
multi <- suppressWarnings(meta_reg(base, dat_bcg, ~ ablat * alloc, "author",
  reference_levels = c(alloc = "random"), scale = "ablat",
  min_studies_per_parameter = 2))
pred <- predict_meta_reg(uni, data.frame(ablat = c(10, 30, 50)), scale = "response")
diag <- diagnose_meta_reg(multi)
case_section("4. Predictions and diagnostics")
case_text("Predictions at 10, 30, and 50 degrees translate the model back to proportions. They are descriptive model outputs, not causal effects. Inspect leverage, Cook's distance, residuals, fitted values, and collinearity.")
case_value("Prediction rows", nrow(pred))
case_value("Studies assessed for influence", nrow(diag$studies))
manual_check(nrow(pred) == 3L && all(is.finite(pred$estimate)), "selected-value predictions")
manual_check(nrow(diag$studies) == multi$meta$k, "regression influence diagnostics")
manual_check(grepl("multivariable", multi$analysis_type), "multivariable reporting")
save_gt_html(table_meta_reg(multi), file.path(out, "meta-regression-results.html"))
utils::write.csv(pred, file.path(out, "predictions.csv"), row.names = FALSE)
for (type in c("bubble", "residual", "fitted", "influence")) {
  plot_meta_reg(uni, type = type, moderator = if (type == "bubble") "ablat" else NULL,
    save_as = "pdf", filename = file.path(out, paste0(type, ".pdf")))
}
bubble_plot(uni, moderator = "ablat", save_as = "pdf",
  filename = file.path(out, "bubble-wrapper.pdf"))
check_artifacts(out, c("bubble.pdf", "residual.pdf", "fitted.pdf", "influence.pdf",
  "bubble-wrapper.pdf"))
case_finish(c("meta-regression-results.html", "predictions.csv", "bubble.pdf",
  "residual.pdf", "fitted.pdf", "influence.pdf", "bubble-wrapper.pdf"))
message("Meta-regression case completed: ", out)
