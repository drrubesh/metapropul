# Continuous-outcome case study using bundled Normand data.
# Run: Rscript tools/manual_cases/02_meta_mean_case.R [output-directory]
source("tools/manual_cases/_helpers.R")
out <- manual_output_dir("mean-case")
data("dat_normand1999", package = "metapropul")
dat_normand1999$period <- ifelse(seq_len(nrow(dat_normand1999)) <= 4, "Earlier", "Later")

case_begin("Continuous outcomes in controlled trials",
  "What is the pooled mean difference between treatment and control, how stable is it to modelling choices, and did the evidence pattern differ between earlier and later studies?",
  "`dat_normand1999`: nine studies with arm-level sample sizes, means, and standard deviations.", out)
case_section("1. Data and estimand")
case_text("Mean difference is appropriate when every study uses a common outcome scale. Standardised mean difference is fitted only as a sensitivity analysis because it changes the estimand to standard-deviation units.")
manual_check(all(dat_normand1999$n1i > 0 & dat_normand1999$n2i > 0 & dat_normand1999$sd1i > 0 & dat_normand1999$sd2i > 0), "valid continuous inputs")
case_value("Studies", nrow(dat_normand1999))

case_section("2. Primary random-effects mean difference")
random_md <- meta_mean(dat_normand1999, "m1i", "sd1i", "n1i", "m2i", "sd2i", "n2i",
  studylab = "source", measure = "MD", model = "random",
  duplicate_action = "make_unique")
case_value("Random-effects mean difference", pooled_text(random_md))
case_value("I-squared", i2_text(random_md))
case_text("The sign must be interpreted using the direction of the original outcome. A negative difference is beneficial only when lower scores are clinically preferable.")

case_section("3. Standardised fixed-effect sensitivity model")
fixed_smd <- meta_mean(dat_normand1999, "m1i", "sd1i", "n1i", "m2i", "sd2i", "n2i",
  studylab = "source", measure = "SMD", model = "fixed",
  duplicate_action = "make_unique")
case_value("Fixed-effect SMD", pooled_text(fixed_smd))
manual_check(inherits(random_md$meta, "meta") && inherits(fixed_smd$meta, "meta"),
  "random MD and fixed SMD models")
case_section("4. Subgroups, influence, and evidence accumulation")
case_text("The primary analysis deliberately has no subgroup. The earlier/later split is now added explicitly as a structural demonstration, not a prespecified clinical hypothesis.")
manual_check(is.null(random_md$meta.subgroup.summary), "no subgroup unless explicitly requested")
subgroup_md <- meta_mean(dat_normand1999, "m1i", "sd1i", "n1i", "m2i", "sd2i", "n2i",
  studylab = "source", subgroup = "period", measure = "MD", model = "random",
  duplicate_action = "make_unique")
manual_check(nrow(subgroup_md$meta.subgroup.summary) == 2L, "continuous subgroup results")
case_value("Between-subgroup p-value", fmt_num(subgroup_md$subgroup_test$p.value, 4))
save_gt_html(table_meta(random_md), file.path(out, "main-results.html"))
save_gt_html(table_influence(random_md), file.path(out, "influence-results.html"))
save_gt_html(table_cumulative_meta(random_md), file.path(out, "cumulative-results.html"))
forest_meta(random_md, save_as = "pdf", filename = file.path(out, "forest.pdf"))
forest_meta(subgroup_md, save_as = "pdf", filename = file.path(out, "forest-subgroup.pdf"))
forest_influence(random_md, save_as = "pdf", filename = file.path(out, "forest-influence.pdf"))
forest_cumulative(random_md, save_as = "pdf", filename = file.path(out, "forest-cumulative.pdf"))
plot_heterogeneity(random_md, save_as = "pdf", filename = file.path(out, "heterogeneity.pdf"))
plot_baujat(random_md, save_as = "pdf", filename = file.path(out, "baujat.pdf"))
# With only nine studies, formal funnel-asymmetry testing is intentionally not
# requested; doi_plot() provides the package's small-k visual assessment.
doi_plot(random_md, save_as = "pdf", filename = file.path(out, "doi.pdf"))
check_artifacts(out, c("forest.pdf", "forest-subgroup.pdf", "forest-influence.pdf", "forest-cumulative.pdf",
  "heterogeneity.pdf", "baujat.pdf", "doi.pdf"))
case_finish(c("main-results.html", "forest.pdf", "forest-subgroup.pdf", "forest-influence.pdf",
  "forest-cumulative.pdf", "heterogeneity.pdf", "baujat.pdf", "doi.pdf"))
message("Mean case completed: ", out)
