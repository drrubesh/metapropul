# Meta-regression

Performs meta-regression on a fitted
[`meta_ratio()`](https://drrubesh.github.io/metapropul/reference/meta_ratio.md),
[`meta_mean()`](https://drrubesh.github.io/metapropul/reference/meta_mean.md),
or
[`meta_prop()`](https://drrubesh.github.io/metapropul/reference/meta_prop.md)
object using
[`metafor::rma()`](https://wviechtb.github.io/metafor/reference/rma.uni.html).

## Usage

``` r
meta_reg(
  meta_object,
  data,
  moderators,
  studylab,
  reference_levels = NULL,
  center = NULL,
  scale = NULL,
  test = c("z", "knha"),
  method = NULL,
  min_studies_per_parameter = 10
)
```

## Arguments

- meta_object:

  A fitted object from
  [`meta_ratio()`](https://drrubesh.github.io/metapropul/reference/meta_ratio.md),
  [`meta_mean()`](https://drrubesh.github.io/metapropul/reference/meta_mean.md),
  or
  [`meta_prop()`](https://drrubesh.github.io/metapropul/reference/meta_prop.md).

- data:

  The original dataset used to fit the meta-analysis model.

- moderators:

  A formula specifying the moderators (e.g. `~ age + region`).

- studylab:

  Character string naming the study label column in `data`. This is
  required so studies are matched safely by label.

- reference_levels:

  Optional named character vector or named list mapping categorical
  moderators to their desired reference levels, for example
  `c(region = "Europe")`.

- center:

  Optional character vector naming numeric moderators to mean-center
  before fitting.

- scale:

  Optional character vector naming numeric moderators to standardise to
  mean zero and unit standard deviation. A variable cannot be listed in
  both `center` and `scale`.

- test:

  Inference method passed to
  [`metafor::rma()`](https://wviechtb.github.io/metafor/reference/rma.uni.html):
  `"z"` (default) or `"knha"` for Knapp–Hartung adjustment.

- method:

  Between-study variance estimator passed to
  [`metafor::rma()`](https://wviechtb.github.io/metafor/reference/rma.uni.html).
  The default inherits the estimator requested by the source
  meta-analysis when it is supported by `metafor`.

- min_studies_per_parameter:

  Positive number used to warn when the number of included studies per
  fitted coefficient is small. Default 10.

## Value

An object of class `"meta_reg"` containing the fitted
[`metafor::rma`](https://wviechtb.github.io/metafor/reference/rma.uni.html)
model, coefficient table, heterogeneity summary, R-squared analog,
excluded study labels, measure metadata, and call.

## Details

Coefficients are reported on the model scale and, where appropriate,
moderator effects are additionally shown on a back-transformed scale.
For ratio and proportion models, the intercept is not back-transformed
by default because it is often not interpretable unless continuous
moderators are centered.

Study labels are matched rather than assumed to be in the same row
order. Studies with missing moderator values are excluded with a
warning. Ratio coefficients are fitted on the log scale and proportion
coefficients on the logit scale; non-intercept coefficients are
additionally back-transformed. The R-squared analog is the proportional
reduction in tau-squared relative to the original meta-analysis and is
truncated to the interval 0–100%.

## Examples

``` r
# \donttest{
data(dat_bcg, package = "metapropul")
result <- meta_prop(
  data = dat_bcg,
  event = "tpos",
  n = "npos",
  studylab = "author"
)
#> Warning: Duplicate study label(s) were made unique: Rosenthal et al, Comstock et al. See 'label_audit' in the result.
reg <- meta_reg(
  meta_object = result,
  data = dat_bcg,
  moderators = ~ ablat,
  studylab = "author"
)
summary(reg)
#> 
#> Meta-regression Summary
#> ------------------------
#> # A tibble: 1 × 8
#>   tau2_null  tau2 R2_analog   QE_pval    QM QM_pval k_included k_excluded
#>       <dbl> <dbl>     <dbl>     <dbl> <dbl>   <dbl>      <int>      <int>
#> 1      1.45  1.24      14.3 1.17e-203  3.05  0.0808         13          0
#> 
#> Coefficients (model scale):
#> ---------------------------
#>      Term    Estimate     CI.Lower    CI.Upper      p.value
#> 1 intrcpt -6.21184619 -7.821744797 -4.60194758 3.951372e-14
#> 2   ablat  0.03993842 -0.004897628  0.08477447 8.083372e-02
#> 
#> Moderator effects on odds-ratio scale:
#> --------------------------------
#>    Term Estimate  CI.Lower CI.Upper
#> 1 ablat 1.040747 0.9951143 1.088472
#> 
#> Notes
#> -----
#>   - Model-scale estimates are on the logit scale. Exponentiated moderator
#>   coefficients are odds ratios; use predict_meta_reg() for predicted
#>   proportions.
#>   - The intercept is not back-transformed because it is often not
#>   interpretable unless continuous moderators are centered.
#>   - In models with interactions or uncentered continuous moderators, some
#>   coefficient-based back-transformations may be difficult to interpret
#>   because they depend on reference values of other moderators.
#>   - R² analog = 14.3198620690409%: modest proportion of between-study
#>   variance explained.
#>   - QE tests residual heterogeneity after accounting for moderators.
#>   - QM tests whether moderators jointly explain heterogeneity.
#>   - Use object$meta to access the full rma() model.
# }
```
