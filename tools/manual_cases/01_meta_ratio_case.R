# BCG vaccine case study: ratio meta-analysis and shared reporting functions.
# Run: Rscript tools/manual_cases/01_meta_ratio_case.R [output-directory]
source("tools/manual_cases/_helpers.R")
out <- manual_output_dir("ratio-case")
data("dat_bcg", package = "metapropul")
dat_bcg$ncon <- dat_bcg$cpos + dat_bcg$cneg

case_begin(
  "BCG vaccination and tuberculosis: a ratio meta-analysis",
  "Across controlled trials, is BCG vaccination associated with lower odds of tuberculosis, and does the allocation method explain variation between studies?",
  "`dat_bcg`: 13 BCG vaccine trials with treatment/control event counts, study latitude, year, and allocation method.",
  out
)
case_section("1. Inspect and prepare the trial data")
case_text("The control total is reconstructed as cases plus non-cases. Before fitting, verify that every event count lies between zero and its arm total. Repeated author citations are retained and made unique for display.")
manual_check(all(dat_bcg$tpos >= 0 & dat_bcg$tpos <= dat_bcg$npos) &&
  all(dat_bcg$cpos >= 0 & dat_bcg$cpos <= dat_bcg$ncon), "valid event denominators")
case_value("Studies", nrow(dat_bcg))
case_value("Allocation groups", paste(sort(unique(dat_bcg$alloc)), collapse = ", "))

case_section("2. Primary random-effects odds-ratio model")
case_text("Clinical and methodological diversity make a random-effects model the primary analysis. REML estimates between-study variance and Knapp-Hartung inference is used for the pooled interval.")
random_or <- meta_ratio(dat_bcg, "tpos", "npos", "cpos", "ncon",
  studylab = "author", measure = "OR", model = "random",
  duplicate_action = "make_unique")
case_value("Random-effects odds ratio", pooled_text(random_or))
case_value("I-squared", i2_text(random_or))
case_text("An odds ratio below 1 favours vaccination. Interpret the magnitude together with heterogeneity and the prediction interval rather than treating the pooled estimate alone as definitive.")

case_section("3. Fixed-effect risk-ratio sensitivity analysis")
case_text("A fixed-effect risk ratio answers a deliberately different sensitivity question: what common effect is estimated if all studies share one underlying effect?")
fixed_rr <- meta_ratio(dat_bcg, "tpos", "npos", "cpos", "ncon",
  studylab = "author", measure = "RR", model = "fixed",
  duplicate_action = "make_unique")
case_value("Fixed-effect risk ratio", pooled_text(fixed_rr))
manual_check(inherits(random_or$meta, "meta") && inherits(fixed_rr$meta, "meta"),
  "random OR and fixed RR models")

case_section("4. Subgroup analysis by allocation method")
case_text("The primary model above deliberately omits subgroup analysis, matching the GUI's None default. Allocation method is now selected explicitly. The formal between-subgroup test—not overlap of separate confidence intervals—is the relevant comparison.")
manual_check(is.null(random_or$meta.subgroup.summary), "no subgroup unless explicitly requested")
subgroup_or <- meta_ratio(dat_bcg, "tpos", "npos", "cpos", "ncon",
  studylab = "author", subgroup = "alloc", measure = "OR", model = "random",
  duplicate_action = "make_unique")
manual_check(nrow(subgroup_or$meta.subgroup.summary) == length(unique(dat_bcg$alloc)),
  "subgroup results")
case_value("Subgroup rows", nrow(subgroup_or$meta.subgroup.summary))
case_value("Between-subgroup p-value", fmt_num(subgroup_or$subgroup_test$p.value, 4))

case_section("5. Reported log odds ratios with standard errors")
log_input <- data.frame(study = random_or$meta$studlab,
  log_or = random_or$meta$TE, se = random_or$meta$seTE)
log_or <- meta_ratio(log_input, effect = "log_or", se = "se",
  effect_scale = "log", studylab = "study", measure = "OR")
manual_check(all.equal(log_or$meta$TE, log_input$log_or) == TRUE,
  "log-ratio and SE input")

case_section("6. Reporting, influence, cumulative evidence, and small-study effects")
case_text("The following outputs test the complete reporting path. Influence and Baujat plots identify studies requiring investigation; they do not justify automatic exclusion. Cumulative analysis checks how the estimate developed as evidence accrued.")
save_gt_html(table_meta(random_or), file.path(out, "main-results.html"))
save_gt_html(table_influence(random_or), file.path(out, "influence-results.html"))
save_gt_html(table_cumulative_meta(random_or), file.path(out, "cumulative-results.html"))
forest_meta(random_or, save_as = "pdf", filename = file.path(out, "forest.pdf"))
forest_meta(subgroup_or, save_as = "pdf", filename = file.path(out, "forest-subgroup.pdf"))
forest_influence(random_or, save_as = "pdf", filename = file.path(out, "forest-influence.pdf"))
forest_cumulative(random_or, save_as = "pdf", filename = file.path(out, "forest-cumulative.pdf"))
plot_heterogeneity(random_or, save_as = "pdf", filename = file.path(out, "heterogeneity.pdf"))
plot_baujat(random_or, save_as = "pdf", filename = file.path(out, "baujat.pdf"))
publication_bias(random_or, plot_method = "original", save_as = "pdf",
  filename = file.path(out, "publication-bias.pdf"))
check_artifacts(out, c("forest.pdf", "forest-subgroup.pdf", "forest-influence.pdf", "forest-cumulative.pdf",
  "heterogeneity.pdf", "baujat.pdf", "publication-bias.pdf"))
case_finish(c("main-results.html", "forest.pdf", "forest-subgroup.pdf", "forest-influence.pdf",
  "forest-cumulative.pdf", "heterogeneity.pdf", "baujat.pdf",
  "publication-bias.pdf"))
message("Ratio case completed: ", out)
