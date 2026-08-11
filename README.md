
<!-- README.md is generated from README.Rmd. Please edit that file. -->

# metapropul

<!-- badges: start -->

[![R-CMD-check](https://github.com/drrubesh/metapropul/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/drrubesh/metapropul/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/drrubesh/metapropul/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/drrubesh/metapropul/actions/workflows/pkgdown.yaml)
<!-- badges: end -->

`metapropul` is a practical toolkit for meta-analysis in systematic
reviews. It provides a consistent workflow for ratio measures,
continuous outcomes, single proportions, subgroup analysis,
meta-regression, influence diagnostics, publication-bias assessment,
risk-of-bias figures, and non-pooling umbrella reviews.

## Installation

Install the development version from GitHub:

``` r
# install.packages("pak")
pak::pak("drrubesh/metapropul")
```

## Graphical interface

Users who prefer a point-and-click workflow can launch the optional
Shiny interface. It supports CSV and Excel upload, bundled examples, all six core
analysis families, subgroup analysis, model controls, forest plots,
tables, diagnostics, downloads, and an equivalent reproducible R call. A
guided, numbered workflow includes controls to start over or safely close
the local application. Every analytical figure can be downloaded as PDF, PNG,
SVG, or TIFF, and every result table as Word, CSV, or PDF. Publication-bias
assessment can display one selected method or all four methods in a 2-by-2
panel.

The Risk of bias workspace can also combine the current meta-analysis with an
uploaded ROB assessment in one aligned forest-and-traffic-light figure. Study
labels are checked before plotting to prevent judgements being assigned to the
wrong estimates.

See [Preparing CSV and Excel data](articles/input-data-formats.html) for the
required columns and scales for every analysis family. The GUI displays the
same context-sensitive guidance and provides a CSV template for the selected
input format. Subgroup analysis is never preselected: the GUI starts at
**None**, even when a bundled or uploaded dataset contains a subgroup column.

``` r
install.packages(c("shiny", "bslib", "readxl")) # once, if needed
metapropul::metapropul_app()
```

Plot titles remain blank unless the user enters one.

## Quick example

``` r
library(metapropul)
data("dat_bcg", package = "metapropul")

dat_bcg$ncon <- dat_bcg$cpos + dat_bcg$cneg

fit <- meta_ratio(
  dat_bcg,
  event.e = "tpos", n.e = "npos",
  event.c = "cpos", n.c = "ncon",
  studylab = "author", subgroup = "alloc",
  measure = "OR", model = "random"
)
#> Warning: Duplicate study label(s) were made unique: Rosenthal et al, Comstock
#> et al. See 'label_audit' in the result.

summary(fit)
#>
#> Meta-analysis Summary
#> ----------------------
#> Number of studies: 13
#> Total observations: 357,347 (191,064 experimental, 166,283 control)
#> Total events: 2,575
#>
#> Pooled OR = 0.47 (95% CI: 0.32, 0.71)
#> Prediction interval: 0.13 – 1.79
#> p-value = 0.002
#> Q = 163.16 (df = 12), p < 0.001
#> I² = 92.6%
#> Tau² = 0.3378
#>
#> Subgroup results
#> ----------------
#> random: 0.37 (95% CI: 0.20, 0.70), Tau² = 0.4131, I² = 94.6%
#> alternate: 0.54 (95% CI: 0.01, 58.20), Tau² = 0.2421, I² = 88.7%
#> systematic: 0.65 (95% CI: 0.20, 2.12), Tau² = 0.4200, I² = 82.3%
#>
#> Test for subgroup differences (random): Q = 1.76, df = 2, p = 0.414
#>
#> Notes
#> -----
#>   - Pooled OR < 1 indicates lower odds in the experimental group.
#>   - I² quantifies the proportion of total observed variability attributable
#>   to between-study heterogeneity rather than sampling error.
#>   - However, I² increases with study precision and may approach 100% even
#>   when Tau² remains unchanged.
#>   - Therefore, I² should not be used alone to judge heterogeneity or decide
#>   whether studies should be pooled.
#>   - Tau² represents the variance of true effects across studies and is
#>   generally more informative than I² for judging the magnitude of
#>   heterogeneity.
#>   - High I² observed. Interpret cautiously because I² may be inflated in
#>   large or highly precise studies.
#>   - The prediction interval shows the range of effects expected in a new
#>   study and helps assess clinical relevance.
#>   - Confidence interval method for random-effects model: HK.
#>   - The subgroup-difference test assesses whether pooled effects differ
#>   between subgroup levels; a non-significant result does not prove the
#>   subgroups are equivalent.
#>   - Subgroup-specific prediction intervals are not shown in this summary.
#>   - Decisions to pool studies should be based on clinical relevance, not
#>   solely on statistical heterogeneity.
#>
#> For study-level results: object$table
```

Create publication-oriented outputs with the same fitted object:

``` r
forest_meta(fit)
table_meta(fit)
plot_baujat(fit)
publication_bias(fit, plot_method = "original")
```

## Analysis families

- `meta_ratio()` analyses odds ratios, risk ratios, and pre-computed
  hazard ratios.
- `meta_mean()` analyses mean differences and standardised mean
  differences.
- `meta_prop()` analyses single proportions using logit or Freeman–Tukey
  transformations.
- `meta_generic()` pools estimates supplied with standard errors,
  variances, or confidence intervals.
- `meta_cor()` pools correlations using Fisher’s z transformation.
- `meta_rate()` pools incidence rates from events and person-time.
- `meta_reg()` supports continuous and categorical moderators,
  interactions, Knapp–Hartung inference, predictions, and diagnostics.
- `umbrella_review()` organises reported review-level results without
  calculating a new pooled estimate across meta-analyses.

The package includes a getting-started vignette, worked case studies, and a
complete function reference. Run `browseVignettes("metapropul")` after
installation or use the Articles and Reference sections of the pkgdown site.
