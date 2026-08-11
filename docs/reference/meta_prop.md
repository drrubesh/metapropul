# Meta-analysis of proportions

Performs a meta-analysis of proportions using logit (`"PLOGIT"`) or
Freeman-Tukey double arcsine (`"PFT"`) transformation via
[`meta::metaprop()`](https://rdrr.io/pkg/meta/man/metaprop.html).
Results are expressed as percentages on the back-transformed scale.
Prediction intervals, subgroup analysis, and leave-one-out influence
analysis are included by default.

## Usage

``` r
meta_prop(
  data,
  event,
  n,
  studylab = NULL,
  subgroup = NULL,
  model = "random",
  sm = "PLOGIT",
  tau_method = "REML",
  ci_method = "HK",
  prediction_interval = TRUE,
  missing_action = c("exclude", "error"),
  duplicate_action = c("warn", "error", "make_unique"),
  singleton_action = c("warn", "retain", "omit", "error"),
  pool_method = c("inverse", "glmm"),
  verbose = FALSE
)
```

## Arguments

- data:

  A data frame with proportion data.

- event:

  Column name for event counts.

- n:

  Column name for total counts.

- studylab:

  Column name for study labels (optional).

- subgroup:

  Optional single character string naming a completely observed subgroup
  variable. At least two levels are required. Levels with only one study
  are allowed with a warning because their within-subgroup heterogeneity
  is not estimable.

- model:

  `"random"` (default) or `"fixed"`.

- sm:

  Summary measure: `"PLOGIT"` (logit, default) or `"PFT"` (Freeman-Tukey
  double arcsine – preferred when proportions are near 0 or 1). Note
  that `"PFT"` results are back-transformed using `meta`'s built-in
  method; displayed values are always on the proportion percentage
  scale.

- tau_method:

  Tau\\^2\\ estimator. Default `"REML"`.

- ci_method:

  CI method for the pooled estimate. `"HK"` (default), `"classic"`, or
  `"KR"`.

- prediction_interval:

  Logical. Compute a prediction interval (default `TRUE`).

- missing_action:

  How incomplete analysis rows are handled: `"exclude"` records and
  removes them, while `"error"` stops before fitting.

- duplicate_action:

  How duplicate study labels are handled: `"warn"` makes them unique and
  records the change, `"error"` stops, and `"make_unique"` records the
  change without warning.

- singleton_action:

  Handling of subgroup levels containing one study: `"warn"`,
  `"retain"`, `"omit"`, or `"error"`.

- pool_method:

  `"inverse"` for inverse-variance pooling or `"glmm"` for a
  random-intercept logistic GLMM. GLMM is available only with
  `sm = "PLOGIT"` and `model = "random"`.

- verbose:

  Logical. Print progress messages (default `FALSE`).

## Value

An object of class `"meta_prop"`, a list containing:

- meta:

  The fitted meta object on its analysis scale.

- table:

  Study estimates, confidence limits, weights, and subgroup assignments
  on the percentage scale.

- meta.summary:

  The pooled estimate, confidence interval, prediction interval,
  I-squared, and tau-squared.

- meta.subgroup.summary:

  One pooled row per subgroup, or `NULL`.

- influence.analysis:

  A tidy leave-one-out results table.

- influence.meta:

  The underlying `metainf` object.

- model,measure,sm,tau_method,ci_method,subgroup:

  Analysis settings.

## Details

The model is fitted by
[`meta::metaprop()`](https://rdrr.io/pkg/meta/man/metaprop.html) using
inverse-variance weighting. PLOGIT results are back-transformed with the
inverse logit. PFT results use the approximate inverse Freeman–Tukey
double-arcsine transform; values returned by this package are
percentages. For subgroup analyses, the overall model and subgroup
models are taken from the same fitted object, and the reported
subgroup-difference test is available through
[`summary()`](https://rdrr.io/r/base/summary.html).

## CSV and Excel columns

Use one row per study. The event and total-sample columns must be
numeric, with `0 <= event <= n` and `n > 0`. A study-label column and a
completely observed subgroup column are optional. Column headers need
not literally be `event`, `n`, `studylab`, or `subgroup`; pass the
actual header names to the corresponding arguments.

## Examples

``` r
# \donttest{
data(dat_bcg, package = "metapropul")
result <- meta_prop(
  data     = dat_bcg,
  event    = "tpos",
  n        = "npos",
  studylab = "author"
)
#> Warning: Duplicate study label(s) were made unique: Rosenthal et al, Comstock et al. See 'label_audit' in the result.
summary(result)
#> 
#> Meta-analysis Summary
#> ----------------------
#> Number of studies: 13
#> 
#> Pooled proportion = 0.7% (95% CI: 0.4%, 1.6%)
#> Prediction interval: 0.0% – 10.3%
#> Q = 1552.67 (df = 12), p < 0.001
#> I² = 99.2%
#> Tau² = 1.4477
#> 
#> Notes
#> -----
#>   - Proportions pooled using logit transformation and back-transformed to
#>   percentages.
#>   - p-value omitted for pooled proportions; focus on the confidence interval
#>   and prediction interval.
#>   - I² quantifies the proportion of total observed variability attributable
#>   to between-study heterogeneity rather than sampling error.
#>   - However, I² increases with study precision and may approach 100% even
#>   when Tau² remains unchanged.
#>   - Therefore, I² should not be used alone to judge heterogeneity or decide
#>   whether studies should be pooled.
#>   - Tau² represents the variance of true effects across studies and is
#>   generally more informative than I² for judging the magnitude of
#>   heterogeneity.
#>   - The prediction interval shows the range of effects expected in a new
#>   study and helps assess clinical relevance.
#>   - Confidence interval method for random-effects model: HK.
#>   - Decisions to pool studies should be based on clinical relevance, not
#>   solely on statistical heterogeneity.
#> 
#> For study-level results: object$table
# }
```
