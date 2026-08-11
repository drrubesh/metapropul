# Construct an umbrella-review evidence object

Organises results reported by systematic reviews and meta-analyses
without pooling them. Each input row remains a separate research
synthesis.

## Usage

``` r
umbrella_review(
  data,
  outcome,
  review,
  effect,
  lower,
  upper,
  studies = NULL,
  participants = NULL,
  i2 = NULL,
  p_value = NULL,
  pred_lower = NULL,
  pred_upper = NULL,
  year = NULL,
  quality = NULL,
  risk_of_bias = NULL,
  certainty = NULL,
  measure = NULL,
  effect_scale = c("ratio", "identity"),
  duplicate_action = c("warn", "error", "allow")
)
```

## Arguments

- data:

  A data frame with one row per reported meta-analysis result.

- outcome, review:

  Column names identifying the outcome and review.

- effect, lower, upper:

  Columns containing the reported estimate and CI.

- studies, participants, i2, p_value, pred_lower, pred_upper, year:

  Optional columns containing reported review characteristics and
  statistics.

- quality, risk_of_bias, certainty:

  Optional columns containing AMSTAR 2, ROBIS, or GRADE results supplied
  by reviewers.

- measure:

  Optional column identifying the reported effect measure, such as
  `"OR"`, `"RR"`, or `"MD"`.

- effect_scale:

  `"ratio"` or `"identity"`.

- duplicate_action:

  Handling of repeated outcome–review records: `"warn"`, `"error"`, or
  `"allow"`.

## Value

An `umbrella_review` object containing standardised review-level results
and metadata. No new pooled estimate is calculated.
