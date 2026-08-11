# Package index

## Graphical interface

Launch the optional point-and-click meta-analysis workspace.

- [`metapropul_app()`](https://drrubesh.github.io/metapropul/reference/metapropul_app.md)
  : Launch the metapropul graphical interface

## Core meta-analysis models

Fit binary, continuous, and single-proportion meta-analyses.

- [`meta_ratio()`](https://drrubesh.github.io/metapropul/reference/meta_ratio.md)
  : Meta-analysis of ratio measures
- [`meta_mean()`](https://drrubesh.github.io/metapropul/reference/meta_mean.md)
  : Meta-analysis of means (MD or SMD)
- [`meta_prop()`](https://drrubesh.github.io/metapropul/reference/meta_prop.md)
  : Meta-analysis of proportions
- [`meta_generic()`](https://drrubesh.github.io/metapropul/reference/meta_generic.md)
  : Generic inverse-variance meta-analysis
- [`meta_cor()`](https://drrubesh.github.io/metapropul/reference/meta_cor.md)
  : Meta-analysis of correlations
- [`meta_rate()`](https://drrubesh.github.io/metapropul/reference/meta_rate.md)
  : Meta-analysis of incidence rates

## Forest plots and diagnostics

Inspect primary, cumulative, influence, and heterogeneity results.

- [`forest_meta()`](https://drrubesh.github.io/metapropul/reference/forest_meta.md)
  : Forest plot for meta-analysis results
- [`forest_rob()`](https://drrubesh.github.io/metapropul/reference/forest_rob.md)
  : Combined forest plot and risk-of-bias traffic lights
- [`forest_influence()`](https://drrubesh.github.io/metapropul/reference/forest_influence.md)
  : Influence forest plot
- [`forest_cumulative()`](https://drrubesh.github.io/metapropul/reference/forest_cumulative.md)
  : Cumulative forest plot
- [`plot_heterogeneity()`](https://drrubesh.github.io/metapropul/reference/plot_heterogeneity.md)
  : Leave-one-out heterogeneity plot
- [`plot_baujat()`](https://drrubesh.github.io/metapropul/reference/plot_baujat.md)
  : Baujat plot

## Publication bias

Assess funnel asymmetry and small-study effects.

- [`publication_bias()`](https://drrubesh.github.io/metapropul/reference/publication_bias.md)
  : Publication bias assessment
- [`table_publication_bias()`](https://drrubesh.github.io/metapropul/reference/table_publication_bias.md)
  : Tabulate publication-bias method availability
- [`doi_plot()`](https://drrubesh.github.io/metapropul/reference/doi_plot.md)
  : DOI plot for publication bias (small meta-analyses)

## Meta-regression

Fit, predict, diagnose, tabulate, and plot moderator models.

- [`meta_reg()`](https://drrubesh.github.io/metapropul/reference/meta_reg.md)
  : Meta-regression
- [`predict_meta_reg()`](https://drrubesh.github.io/metapropul/reference/predict_meta_reg.md)
  : Predict from a meta-regression model
- [`diagnose_meta_reg()`](https://drrubesh.github.io/metapropul/reference/diagnose_meta_reg.md)
  : Diagnose a meta-regression model
- [`table_meta_reg()`](https://drrubesh.github.io/metapropul/reference/table_meta_reg.md)
  : Tabulate meta-regression results
- [`plot_meta_reg()`](https://drrubesh.github.io/metapropul/reference/plot_meta_reg.md)
  : Plot meta-regression results and diagnostics
- [`bubble_plot()`](https://drrubesh.github.io/metapropul/reference/bubble_plot.md)
  : Bubble plot for meta-regression

## Results tables

Create publication-ready meta-analysis tables.

- [`table_meta()`](https://drrubesh.github.io/metapropul/reference/table_meta.md)
  : Summary table for meta-analysis results
- [`table_influence()`](https://drrubesh.github.io/metapropul/reference/table_influence.md)
  : Leave-one-out influence table
- [`table_cumulative_meta()`](https://drrubesh.github.io/metapropul/reference/table_cumulative_meta.md)
  : Cumulative meta-analysis table
- [`table_subgroups()`](https://drrubesh.github.io/metapropul/reference/table_subgroups.md)
  : Tabulate subgroup meta-analysis results

## Risk-of-bias plots

Create traffic-light and summary appraisal figures.

- [`plot_rob()`](https://drrubesh.github.io/metapropul/reference/plot_rob.md)
  : Traffic-light plot for risk of bias or study appraisal
- [`plot_rob_summary()`](https://drrubesh.github.io/metapropul/reference/plot_rob_summary.md)
  : Summary plot for risk of bias or study appraisal
- [`validate_rob()`](https://drrubesh.github.io/metapropul/reference/validate_rob.md)
  : Validate risk-of-bias data

## Umbrella reviews

Preserve reported review estimates and assess credibility, quality, and
overlap without pooling reviews.

- [`umbrella_review()`](https://drrubesh.github.io/metapropul/reference/umbrella_review.md)
  : Construct an umbrella-review evidence object
- [`classify_umbrella()`](https://drrubesh.github.io/metapropul/reference/classify_umbrella.md)
  : Classify statistical credibility in an umbrella review
- [`grade_umbrella()`](https://drrubesh.github.io/metapropul/reference/grade_umbrella.md)
  : Record structured GRADE judgements
- [`assess_review_quality()`](https://drrubesh.github.io/metapropul/reference/assess_review_quality.md)
  : Store AMSTAR 2 or ROBIS review-quality assessments
- [`diagnose_umbrella_primary()`](https://drrubesh.github.io/metapropul/reference/diagnose_umbrella_primary.md)
  : Diagnose primary-study evidence within each source meta-analysis
- [`study_overlap()`](https://drrubesh.github.io/metapropul/reference/study_overlap.md)
  : Quantify primary-study overlap across reviews
- [`sensitivity_umbrella_overlap()`](https://drrubesh.github.io/metapropul/reference/sensitivity_umbrella_overlap.md)
  : Compare prespecified review-selection strategies
- [`table_umbrella()`](https://drrubesh.github.io/metapropul/reference/table_umbrella.md)
  : Create a review-by-review umbrella table
- [`plot_umbrella()`](https://drrubesh.github.io/metapropul/reference/plot_umbrella.md)
  : Plot reported meta-analysis results in an umbrella review
- [`plot_study_overlap()`](https://drrubesh.github.io/metapropul/reference/plot_study_overlap.md)
  : Plot citation matrices, pairwise overlap, or CCA

## Example datasets

Bundled datasets for examples, teaching, and manual validation.

- [`dat_bcg`](https://drrubesh.github.io/metapropul/reference/dat_bcg.md)
  : Example Dataset: dat_bcg
- [`dat_normand1999`](https://drrubesh.github.io/metapropul/reference/dat_normand1999.md)
  : Normand 1999 Meta-analysis Dataset (Continuous Outcomes)
- [`Fleiss1993bin`](https://drrubesh.github.io/metapropul/reference/Fleiss1993bin.md)
  : Fleiss1993bin: Aspirin After Myocardial Infarction Dataset (Binary
  Outcomes)
- [`Olkin95`](https://drrubesh.github.io/metapropul/reference/Olkin95.md)
  : Example dataset: Olkin95
- [`caffeine`](https://drrubesh.github.io/metapropul/reference/caffeine.md)
  : Caffeine and Endurance Performance Dataset
- [`cisapride`](https://drrubesh.github.io/metapropul/reference/cisapride.md)
  : Cisapride and Reflux Esophagitis Dataset
- [`lungcancer`](https://drrubesh.github.io/metapropul/reference/lungcancer.md)
  : Lung Cancer and Smoking Cohort Study Dataset
- [`amlodipine`](https://drrubesh.github.io/metapropul/reference/amlodipine.md)
  : Amlodipine Clinical Trial Dataset
- [`Pagliaro1992`](https://drrubesh.github.io/metapropul/reference/Pagliaro1992.md)
  : Portal Vein Thrombosis After Splenectomy Dataset
