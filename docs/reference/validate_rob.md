# Validate risk-of-bias data

Checks study labels, domain columns, and judgement levels against a
supported risk-of-bias template without creating a plot.

## Usage

``` r
validate_rob(
  rob_data,
  studylab,
  tool = "GENERIC",
  domains = NULL,
  levels = NULL,
  colours = NULL,
  has_overall = TRUE
)
```

## Arguments

- rob_data:

  A data frame containing study labels and judgements.

- studylab:

  Study-label column.

- tool:

  Risk-of-bias or appraisal tool; see
  [`plot_rob()`](https://drrubesh.github.io/metapropul/reference/plot_rob.md).

- domains:

  Optional domain columns.

- levels:

  Optional allowed levels for a custom tool.

- colours:

  Optional custom colours.

- has_overall:

  Whether a custom tool has an overall judgement.

## Value

A list containing the resolved template, validated domains, and a
frequency table of judgements.
