# Summary plot for risk of bias or study appraisal

Creates a stacked summary plot showing the distribution of judgement
levels across domains.

## Usage

``` r
plot_rob_summary(
  rob_data,
  studylab,
  tool = "GENERIC",
  domains = NULL,
  levels = NULL,
  colours = NULL,
  has_overall = TRUE,
  as_percent = TRUE
)
```

## Arguments

- rob_data:

  A data frame containing study labels and judgement columns.

- studylab:

  Character string giving the study label column name.

- tool:

  Character string specifying the ROB or appraisal tool.

- domains:

  Optional character vector of domain column names. If omitted, domains
  are taken from the selected template where available.

- levels:

  Optional character vector of allowed judgement levels when
  `tool = "Custom"`.

- colours:

  Optional named character vector of colours when `tool = "Custom"`. If
  omitted, common judgements such as low, some concerns, and high
  receive semantic green, amber, and red colours; unrecognised levels
  receive a distinct qualitative palette.

- has_overall:

  Logical; used only when `tool = "Custom"`.

- as_percent:

  Logical; if `TRUE`, bars are shown as percentages. If `FALSE`, raw
  counts are shown.

## Value

A ggplot2 object.

## Examples

``` r
# \donttest{
rob_df <- data.frame(
  study = c("Study 1", "Study 2"),
  d1 = c("Low", "High"),
  d2 = c("Some concerns", "Low"),
  overall = c("Low", "High")
)

plot_rob_summary(
  rob_data = rob_df,
  studylab = "study",
  tool = "Custom",
  domains = c("d1", "d2", "overall"),
  levels = c("Low", "Some concerns", "High")
)

# }
```
