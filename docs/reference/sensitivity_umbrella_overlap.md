# Compare prespecified review-selection strategies

Selects one reported review result per outcome under different
strategies. It does not pool review estimates.

## Usage

``` r
sensitivity_umbrella_overlap(
  object,
  overlap = NULL,
  strategies = c("highest_quality", "most_recent", "most_comprehensive",
    "lowest_overlap"),
  user_selected = NULL,
  tie_break = c("most_recent", "largest", "first", "error"),
  missing_action = c("warn", "exclude", "error")
)
```

## Arguments

- object:

  An `umbrella_review` object.

- overlap:

  Optional `umbrella_overlap` object, required for `"lowest_overlap"`.

- strategies:

  Any of `"highest_quality"`, `"lowest_risk_of_bias"`, `"most_recent"`,
  `"most_comprehensive"`, `"largest_participant_count"`,
  `"lowest_overlap"`, or `"user_selected"`.

- user_selected:

  Named character vector mapping outcomes to reviews.

- tie_break:

  How tied strategies are resolved: `"most_recent"`, `"largest"`,
  `"first"`, or `"error"`.

- missing_action:

  Handling when a strategy has no usable ranking data: `"warn"`,
  `"exclude"`, or `"error"`.

## Value

An `umbrella_selection_sensitivity` table with one selected reported
result per outcome and strategy; no synthesis is performed.
