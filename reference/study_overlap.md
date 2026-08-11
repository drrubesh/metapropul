# Quantify primary-study overlap across reviews

Calculates the corrected covered area (CCA), pairwise overlap, and
citation matrix from long-format review–primary-study membership data.

## Usage

``` r
study_overlap(data, review, study, outcome = NULL, included = NULL)
```

## Arguments

- data:

  A data frame with one row per review–study membership.

- review, study:

  Columns identifying reviews and primary studies.

- outcome:

  Optional outcome column for outcome-specific CCA.

- included:

  Optional column containing inclusion indicators. Use `TRUE`/`1` for an
  included primary study, `FALSE`/`0` when the study was eligible but
  not included, and `NA` for structural missingness (for example, when a
  study was not eligible for a review). When omitted, every row is
  treated as an included review–study membership.

## Value

An `umbrella_overlap` object with CCA summaries, pairwise measures, and
a logical citation matrix.

## CSV and Excel columns

Use long format with one row per review–primary-study membership. Review
and study identifiers are required. Outcome and an inclusion indicator
are optional; inclusion values may only be `TRUE`/`FALSE`, `1`/`0`, or
`NA`.
