# Classify statistical credibility in an umbrella review

Applies an Ioannidis-style quantitative evidence classification to each
reported meta-analysis separately. This is not GRADE, AMSTAR 2, or
ROBIS.

## Usage

``` r
classify_umbrella(
  object,
  diagnostics = NULL,
  strong_p = 1e-06,
  highly_suggestive_p = 1e-06,
  suggestive_p = 0.001,
  nominal_p = 0.05,
  min_participants = 1000,
  max_i2 = 50
)
```

## Arguments

- object:

  An `umbrella_review` object.

- diagnostics:

  Optional data frame or `umbrella_primary_diagnostics` containing
  outcome/review-level largest-study and bias diagnostics.

- strong_p, highly_suggestive_p, suggestive_p, nominal_p:

  Thresholds for evidence Classes I–IV.

- min_participants:

  Minimum participant/case count for Classes I–III.

- max_i2:

  Maximum I-squared for Class I.

## Value

Review results with criterion flags and `EvidenceClass`.
