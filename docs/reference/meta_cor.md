# Meta-analysis of correlations

Pools correlations using Fisher's z transformation and returns estimates
on the correlation scale.

## Usage

``` r
meta_cor(
  data,
  cor,
  n,
  studylab = NULL,
  subgroup = NULL,
  model = c("random", "fixed"),
  tau_method = "REML",
  ci_method = "HK",
  prediction_interval = TRUE,
  missing_action = c("exclude", "error"),
  duplicate_action = c("warn", "error", "make_unique"),
  singleton_action = c("warn", "retain", "omit", "error")
)
```

## Arguments

- data:

  A data frame.

- cor:

  Correlation column with values strictly between -1 and 1.

- n:

  Sample-size column; values must exceed 3.

- studylab, subgroup:

  Optional study-label and subgroup columns.

- model, tau_method, ci_method, prediction_interval:

  Model controls.

- missing_action, duplicate_action, singleton_action:

  Audit policies.

## Value

An object of class `meta_cor`.

## CSV and Excel columns

Use one row per study with numeric correlation and sample-size columns.
Correlations must lie strictly between -1 and 1 and sample sizes must
exceed 3. Study-label and subgroup columns are optional.
