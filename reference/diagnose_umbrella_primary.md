# Diagnose primary-study evidence within each source meta-analysis

Reconstructs diagnostics separately for every outcome–review
combination. It never merges primary studies from different reviews into
a new estimate.

## Usage

``` r
diagnose_umbrella_primary(
  data,
  outcome,
  review,
  study,
  effect,
  lower,
  upper,
  participants = NULL,
  effect_scale = c("ratio", "identity"),
  ci_level = 0.95,
  method = "REML",
  alpha = 0.05,
  expected_effect = c("largest", "reported"),
  reported_effect = NULL,
  min_egger = 10L,
  duplicate_action = c("error", "precision", "first"),
  tolerance = sqrt(.Machine$double.eps)
)
```

## Arguments

- data:

  Long-format primary-study estimates.

- outcome, review, study:

  Columns identifying outcome, source review, and study.

- effect, lower, upper:

  Estimate and confidence-limit columns.

- participants:

  Optional participant-count column used to identify the largest study.

- effect_scale:

  `"ratio"` or `"identity"`.

- ci_level:

  Confidence level of supplied intervals.

- method:

  Tau-squared estimator passed to
  [`metafor::rma()`](https://wviechtb.github.io/metafor/reference/rma.uni.html).

- alpha:

  Significance threshold.

- expected_effect:

  `"largest"` or `"reported"`. For `"reported"`, supply
  `reported_effect` as a column containing the source meta-analysis
  estimate.

- reported_effect:

  Optional reported pooled-effect column.

- min_egger:

  Minimum primary studies for Egger testing.

- duplicate_action:

  Handling of conflicting duplicate rows within the same review:
  `"error"`, `"precision"`, or `"first"`.

- tolerance:

  Numerical equivalence tolerance.

## Value

An `umbrella_primary_diagnostics` object. Its summary has one row per
source review result and can be passed to
[`classify_umbrella()`](https://drrubesh.github.io/metapropul/reference/classify_umbrella.md).

## CSV and Excel columns

Use one row per primary-study estimate within a source review. Outcome,
review, study, effect, lower limit, and upper limit are required;
participants are optional. Every outcome–review group must contain at
least two unique primary studies. Studies from different reviews are
never combined into a new pooled estimate.
