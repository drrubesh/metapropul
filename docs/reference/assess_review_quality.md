# Store AMSTAR 2 or ROBIS review-quality assessments

Store AMSTAR 2 or ROBIS review-quality assessments

## Usage

``` r
assess_review_quality(
  object,
  tool = c("AMSTAR2", "ROBIS"),
  overall,
  domains = NULL,
  validate = TRUE
)
```

## Arguments

- object:

  An `umbrella_review` object.

- tool:

  `"AMSTAR2"` or `"ROBIS"`.

- overall:

  Scalar, vector, or source-data column with overall judgements.

- domains:

  Optional data frame of domain-level judgements with one row per
  result.

- validate:

  Logical; validate overall judgements against the selected tool's
  conventional categories.

## Value

A quality-assessment table of class `umbrella_review_quality`.
