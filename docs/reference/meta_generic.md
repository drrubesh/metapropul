# Generic inverse-variance meta-analysis

Pools study effects already expressed on their analysis scale. Supply a
standard error, variance, or confidence interval. For log ratio effects
set `backtransform = "exp"`; the input effect and uncertainty must then
be on the log scale.

## Usage

``` r
meta_generic(
  data,
  effect,
  se = NULL,
  variance = NULL,
  lower = NULL,
  upper = NULL,
  ci_level = 0.95,
  studylab = NULL,
  subgroup = NULL,
  model = c("random", "fixed"),
  measure = "Generic effect",
  backtransform = c("identity", "exp"),
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

- effect:

  Effect column on the analysis scale.

- se, variance:

  Optional standard-error or variance column.

- lower, upper:

  Optional confidence limits used to reconstruct the SE.

- ci_level:

  Confidence level of supplied limits.

- studylab, subgroup:

  Optional study-label and subgroup columns.

- model:

  `"random"` or `"fixed"`.

- measure:

  Descriptive effect-measure label.

- backtransform:

  `"identity"` or `"exp"`.

- tau_method, ci_method, prediction_interval:

  Model controls.

- missing_action, duplicate_action, singleton_action:

  Audit policies.

## Value

An object of class `meta_generic`.

## CSV and Excel columns

Use one row per study and provide an effect column plus exactly one
uncertainty representation: standard error, variance, or both confidence
limits. For log OR, log RR, or log HR with a standard error, supply the
log effect and set `backtransform = "exp"`. Study-label and subgroup
columns are optional and may contain text.
