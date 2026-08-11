## LET'S TEST METAPROPUL IN REAL TIME
## Script 2: forest plots, diagnostics, tables and automatic sizing
## Run script 1 first. If its objects are absent, this line recreates them.

if (!exists("ratio_or", inherits = FALSE)) {
  source("tools/realtime_tests/01_core_models_and_regression.R")
}

output_dir <- file.path(getwd(), "manual-test-output")
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

###############################################################################
## 1. FOREST PLOTS IN THE VIEWER
###############################################################################

## Start with ten studies so labels and columns are easy to inspect.
olkin_10 <- dplyr::slice(Olkin95, 1:10)
ratio_10 <- meta_ratio(
  olkin_10, "event.e", "n.e", "event.c", "n.c",
  studylab = "author", measure = "OR",
  duplicate_action = "make_unique"
)

forest_meta(ratio_10)
forest_meta(ratio_10, layout = "JAMA")
forest_meta(ratio_10, layout = "BMJ")

## Compare outcome families. Check null lines and axis labels carefully.
forest_meta(ratio_or)
forest_meta(mean_md)
forest_meta(prop_logit)
forest_meta(ratio_subgroup)
forest_meta(mean_subgroup)
forest_meta(prop_subgroup)

## Check RevMan-style output and right-hand columns.
forest_meta(prop_logit, layout = "RevMan5")

###############################################################################
## 2. FOREST EXPORTS
###############################################################################

forest_meta(ratio_10, save_as = "pdf",
  filename = file.path(output_dir, "ratio-10.pdf"))
forest_meta(ratio_or, save_as = "pdf",
  filename = file.path(output_dir, "ratio-70-auto.pdf"))
forest_meta(prop_subgroup, save_as = "png",
  filename = file.path(output_dir, "proportion-subgroup.png"))
forest_meta(mean_md, save_as = "tiff",
  filename = file.path(output_dir, "mean-random.tiff"))

## User-defined width and height should override automatic sizing.
forest_meta(ratio_or, width = 11, height = 28, save_as = "pdf",
  filename = file.path(output_dir, "ratio-70-custom-size.pdf"))

###############################################################################
## 3. INFLUENCE, HETEROGENEITY, BAUJAT AND CUMULATIVE PLOTS
###############################################################################

forest_influence(ratio_or)
forest_influence(mean_md)
forest_influence(prop_logit)

forest_influence(ratio_or, save_as = "pdf",
  filename = file.path(output_dir, "ratio-influence.pdf"))
forest_influence(mean_md, save_as = "pdf",
  filename = file.path(output_dir, "mean-influence.pdf"))

plot_heterogeneity(ratio_or)
plot_heterogeneity(mean_md)
plot_heterogeneity(prop_logit)
plot_heterogeneity(ratio_or, stat = "tau2")

plot_baujat(ratio_or)
plot_baujat(ratio_or, label_threshold = 2)
plot_baujat(mean_md)
plot_baujat(prop_logit)

forest_cumulative(ratio_or)
forest_cumulative(mean_md)
forest_cumulative(prop_logit)
forest_cumulative(ratio_or, save_as = "pdf",
  filename = file.path(output_dir, "ratio-cumulative.pdf"))

###############################################################################
## 4. PUBLICATION-BIAS AND DOI WORKFLOWS
###############################################################################

## Seventy studies: formal tests and all funnel variants are available.
bias_ratio <- publication_bias(ratio_or)
names(bias_ratio)
bias_ratio$status
table_publication_bias(bias_ratio)

publication_bias(ratio_or,
  plot_method = c("original", "contour", "limitmeta", "trimfill"))
publication_bias(ratio_or,
  plot_method = c("original", "trimfill"))
publication_bias(ratio_or, plot_method = "original")
publication_bias(ratio_or,
  plot_method = c("original", "contour", "limitmeta", "trimfill"),
  save_as = "pdf", filename = file.path(output_dir, "ratio-funnels.pdf"))

## Nine studies: expect a caution for formal funnel-asymmetry tests.
bias_mean <- publication_bias(mean_md, plot_method = "original")
bias_mean$status
table_publication_bias(bias_mean)

## DOI is intended for small meta-analyses.
doi_plot(mean_md)
doi_plot(mean_md, save_as = "pdf",
  filename = file.path(output_dir, "mean-doi.pdf"))

## These larger analyses should explain that DOI is not the intended method.
doi_plot(prop_logit)
doi_plot(ratio_or)

###############################################################################
## 5. META-REGRESSION PLOTS
###############################################################################

plot_meta_reg(reg_ratio_year, type = "bubble", moderator = "year")
plot_meta_reg(reg_ratio_year, type = "residual")
plot_meta_reg(reg_ratio_year, type = "fitted")
plot_meta_reg(reg_ratio_year, type = "influence")

plot_meta_reg(reg_ratio_year, type = "bubble", moderator = "year",
  save_as = "pdf", filename = file.path(output_dir, "regression-bubble.pdf"))

## bubble_plot() is the compatibility wrapper around plot_meta_reg().
bubble_plot(reg_ratio_year, moderator = "year")
bubble_plot(reg_prop_region, moderator = "region", plot_all_levels = TRUE)
bubble_plot(reg_prop_region, moderator = "region", plot_all_levels = FALSE)

###############################################################################
## 6. TABLES IN VIEWER AND EXPORTED FILES
###############################################################################

table_meta(ratio_or)
table_meta(mean_md)
table_meta(prop_logit)
table_subgroups(ratio_subgroup)
table_influence(ratio_or)
table_cumulative_meta(ratio_or)
table_meta_reg(reg_ratio_multi)

table_meta(ratio_or, save_as = "docx",
  filename = file.path(output_dir, "ratio-table.docx"))
table_influence(ratio_or, save_as = "docx",
  filename = file.path(output_dir, "ratio-influence-table.docx"))
table_cumulative_meta(ratio_or, save_as = "docx",
  filename = file.path(output_dir, "ratio-cumulative-table.docx"))

###############################################################################
## 7. AUTOMATIC SIZING: 1, 2, 10, 50, 100 AND 200 STUDIES
###############################################################################

set.seed(123)
make_prop_data <- function(k) {
  data.frame(
    Study = paste("Study", seq_len(k)),
    event = stats::rbinom(k, size = 1000, prob = 0.05),
    total = rep(1000, k)
  )
}

## A meta-analysis needs at least two studies. Confirm the one-study guardrail.
one_study <- make_prop_data(1)
try(meta_prop(one_study, "event", "total", studylab = "Study"))

study_sizes <- c(2, 10, 50, 100, 200)
stress_models <- lapply(study_sizes, function(k) {
  d <- make_prop_data(k)
  meta_prop(d, "event", "total", studylab = "Study", model = "random")
})
names(stress_models) <- paste0("k", study_sizes)

## Inspect the small plots in Viewer.
forest_meta(stress_models$k2)
forest_meta(stress_models$k10)

## Export every size using automatic dimensions.
for (k in study_sizes) {
  forest_meta(stress_models[[paste0("k", k)]], save_as = "pdf",
    filename = file.path(output_dir, paste0("forest-proportion-k", k, ".pdf")))
}

## The 200-study export should retain every row, header and pooled section.
forest_meta(stress_models$k200, save_as = "pdf",
  filename = file.path(output_dir, "forest-proportion-200-auto.pdf"))
forest_influence(stress_models$k200, save_as = "pdf",
  filename = file.path(output_dir, "influence-proportion-200-auto.pdf"))

## Compare an explicit custom size. This is deliberately user-controlled.
forest_meta(stress_models$k200, width = 10, height = 55, save_as = "pdf",
  filename = file.path(output_dir, "forest-proportion-200-custom.pdf"))

## Viewer behaviour for 200 studies should give a useful export message and
## must not silently omit studies.
forest_meta(stress_models$k200)

###############################################################################
## 8. EDGE-CASE DATA
###############################################################################

edge_data <- data.frame(
  Study = c("Duplicate", "Duplicate", "Zero events", "All events", "Missing"),
  event = c(1, 2, 0, 100, NA),
  total = c(100, 100, 100, 100, 100),
  group = c("A", "A", "B", "C", "C")
)

## Duplicate labels are retained and made unique; the missing row is logged.
edge_fit <- meta_prop(edge_data, "event", "total", studylab = "Study",
  subgroup = "group", duplicate_action = "make_unique",
  singleton_action = "retain", missing_action = "exclude")
edge_fit$label_audit
edge_fit$exclusion_log
edge_fit$meta.subgroup.summary
edge_fit$subgroup_test
forest_meta(edge_fit)

## Explicit policies should fail loudly when requested.
try(meta_prop(edge_data, "event", "total", studylab = "Study",
  duplicate_action = "error"))
try(meta_prop(edge_data, "event", "total", studylab = "Study",
  missing_action = "error"))

## Inspect every generated file manually.
list.files(output_dir, full.names = TRUE)
