# Meta-analysis of means (MD or SMD)

Performs a meta-analysis of continuous outcomes using mean difference
(MD) or standardised mean difference (SMD). Accepts either raw
group-level statistics or pre-computed effect sizes with confidence
intervals.

## Usage

``` r
meta_mean(
  data,
  mean.e = NULL,
  sd.e = NULL,
  n.e = NULL,
  mean.c = NULL,
  sd.c = NULL,
  n.c = NULL,
  effect = NULL,
  lower = NULL,
  upper = NULL,
  ci_level = 0.95,
  studylab = NULL,
  subgroup = NULL,
  model = "random",
  measure = "MD",
  tau_method = "REML",
  ci_method = "HK",
  prediction_interval = TRUE,
  missing_action = c("exclude", "error"),
  duplicate_action = c("warn", "error", "make_unique"),
  singleton_action = c("warn", "retain", "omit", "error"),
  verbose = FALSE
)
```

## Arguments

- data:

  A data frame containing the meta-analysis data.

- mean.e:

  Column name for the mean in the experimental group.

- sd.e:

  Column name for the SD in the experimental group.

- n.e:

  Column name for the sample size in the experimental group.

- mean.c:

  Column name for the mean in the control group.

- sd.c:

  Column name for the SD in the control group.

- n.c:

  Column name for the sample size in the control group.

- effect:

  Column name for a pre-computed effect size (MD or SMD). Optional
  alternative to supplying raw group data.

- lower:

  Column name for the lower CI bound of `effect`.

- upper:

  Column name for the upper CI bound of `effect`.

- ci_level:

  Confidence level for pre-computed CIs. Default `0.95`.

- studylab:

  Column name for study labels (optional).

- subgroup:

  Optional single character string naming a completely observed subgroup
  variable with at least two levels.

- model:

  `"random"` (default) or `"fixed"`.

- measure:

  `"MD"` (default) or `"SMD"`.

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

- verbose:

  Logical. Print progress messages (default `FALSE`).

## Value

An object of class `"meta_mean"` containing the fitted meta object, a
tidy study table, optional subgroup summary, tidy and raw leave-one-out
influence results, and the requested model settings.

## Details

Raw arm-level inputs are fitted with
[`meta::metacont()`](https://rdrr.io/pkg/meta/man/metacont.html).
Pre-computed MD or SMD estimates are fitted with
[`meta::metagen()`](https://rdrr.io/pkg/meta/man/metagen.html); their
standard errors are reconstructed from `lower`, `upper`, and `ci_level`.
Subgroup estimates are extracted from that same fitted model, so the
confidence-interval and heterogeneity methods remain consistent with the
overall analysis.

## CSV and Excel columns

Use one row per independent comparison. Raw data require numeric columns
for treatment mean, SD, and sample size and control mean, SD, and sample
size. Pre-computed data require numeric `effect`, `lower`, and `upper`
columns on the MD or SMD scale. To pool a continuous effect supplied
with a standard error or variance, use
[`meta_generic()`](https://drrubesh.github.io/metapropul/reference/meta_generic.md)
with `backtransform = "identity"`. Column headers may differ because
each is mapped by its argument.

## Examples

``` r
# \donttest{
data(dat_normand1999, package = "metapropul")
result <- meta_mean(
  data     = dat_normand1999,
  mean.e   = "m1i", sd.e = "sd1i", n.e = "n1i",
  mean.c   = "m2i", sd.c = "sd2i", n.c = "n2i",
  studylab = "source"
)
summary(result)
#> 
#> Meta-analysis Summary
#> ----------------------
#> Number of studies: 9
#> Total observations: 1,158 (548 experimental, 610 control)
#> 
#> Pooled MD = -15.11 (95% CI: -36.32, 6.11)
#> Prediction interval: -78.87 – 48.66
#> p-value = 0.139
#> Q = 238.92 (df = 8), p < 0.001
#> I² = 96.7%
#> Tau² = 684.6462
#> 
#> Notes
#> -----
#>   - Continuous outcomes pooled as MD.
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
