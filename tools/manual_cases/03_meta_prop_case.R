# Single-group proportion case study using bundled BCG data.
# Run: Rscript tools/manual_cases/03_meta_prop_case.R [output-directory]
source("tools/manual_cases/_helpers.R")
out <- manual_output_dir("proportion-case")
data("dat_bcg", package = "metapropul")

case_begin("Tuberculosis risk among vaccinated trial arms",
  "What proportion of vaccinated participants developed tuberculosis, and does that proportion vary by trial allocation method?",
  "The treatment arms of `dat_bcg`; this single-proportion analysis must not be interpreted as vaccine effectiveness without the control arms.", out)
case_section("1. Clarify the estimand")
case_text("This analysis pools risks in vaccinated arms only. It demonstrates `meta_prop()` and is intentionally distinct from the comparative effect estimated in the BCG ratio case.")
manual_check(all(dat_bcg$tpos >= 0 & dat_bcg$tpos <= dat_bcg$npos), "valid proportion inputs")

case_section("2. Primary random-effects logit model")
logit <- meta_prop(dat_bcg, "tpos", "npos", studylab = "author",
  sm = "PLOGIT", model = "random",
  duplicate_action = "make_unique")
case_value("Pooled vaccinated-arm proportion", pooled_text(logit))
case_value("I-squared", i2_text(logit))
case_text("The displayed estimate is a percentage. High heterogeneity is expected because baseline tuberculosis risk differs across settings.")

case_section("3. Freeman-Tukey sensitivity analysis")
case_text("Freeman-Tukey is retained for compatibility and tested here only as a sensitivity analysis. Its sample-size-dependent back-transformation should not replace the logit model as the primary result.")
pft <- suppressWarnings(meta_prop(dat_bcg, "tpos", "npos", studylab = "author",
  sm = "PFT", model = "fixed",
  duplicate_action = "make_unique"))
manual_check(inherits(logit$meta, "meta") && inherits(pft$meta, "meta"),
  "PLOGIT random and PFT fixed models")
case_section("4. Subgroups and diagnostics")
case_text("The primary analysis deliberately has no subgroup. Allocation method is selected explicitly here, as it must be in the GUI.")
manual_check(is.null(logit$meta.subgroup.summary), "no subgroup unless explicitly requested")
subgroup_logit <- meta_prop(dat_bcg, "tpos", "npos", studylab = "author",
  subgroup = "alloc", sm = "PLOGIT", model = "random",
  duplicate_action = "make_unique")
manual_check(all(is.finite(subgroup_logit$meta.subgroup.summary$Estimate)),
  "back-transformed subgroup proportions")
case_value("Between-subgroup p-value", fmt_num(subgroup_logit$subgroup_test$p.value, 4))
save_gt_html(table_meta(logit), file.path(out, "main-results.html"))
save_gt_html(table_influence(logit), file.path(out, "influence-results.html"))
save_gt_html(table_cumulative_meta(logit), file.path(out, "cumulative-results.html"))
forest_meta(logit, save_as = "pdf", filename = file.path(out, "forest-logit.pdf"))
forest_meta(subgroup_logit, save_as = "pdf", filename = file.path(out, "forest-subgroup.pdf"))
forest_meta(pft, save_as = "pdf", filename = file.path(out, "forest-pft.pdf"))
forest_influence(logit, save_as = "pdf", filename = file.path(out, "forest-influence.pdf"))
forest_cumulative(logit, save_as = "pdf", filename = file.path(out, "forest-cumulative.pdf"))
plot_heterogeneity(logit, save_as = "pdf", filename = file.path(out, "heterogeneity.pdf"))
plot_baujat(logit, save_as = "pdf", filename = file.path(out, "baujat.pdf"))
publication_bias(logit, plot_method = "original", save_as = "pdf",
  filename = file.path(out, "publication-bias.pdf"))
check_artifacts(out, c("forest-logit.pdf", "forest-subgroup.pdf", "forest-pft.pdf", "forest-influence.pdf",
  "forest-cumulative.pdf", "heterogeneity.pdf", "baujat.pdf", "publication-bias.pdf"))
case_finish(c("main-results.html", "forest-logit.pdf", "forest-subgroup.pdf", "forest-pft.pdf",
  "forest-influence.pdf", "forest-cumulative.pdf", "heterogeneity.pdf",
  "baujat.pdf", "publication-bias.pdf"))
message("Proportion case completed: ", out)
