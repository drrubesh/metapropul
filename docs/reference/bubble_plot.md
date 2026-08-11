# Bubble plot for meta-regression

Displays a bubble plot for a `meta_reg` object using
[`metafor::regplot()`](https://wviechtb.github.io/metafor/reference/regplot.html).
Bubble size is proportional to study weight. For categorical moderators,
one panel is produced per level with automatic grid layout (up to 6
levels).

## Usage

``` r
bubble_plot(
  meta_reg_object,
  moderator = NULL,
  title = NULL,
  plot_all_levels = TRUE,
  max_levels = 6L,
  save_as = c("viewer", "pdf", "png", "tiff"),
  filename = NULL,
  width = 10,
  height = 8,
  ...
)
```

## Arguments

- meta_reg_object:

  A `meta_reg` object from
  [`meta_reg()`](https://drrubesh.github.io/metapropul/reference/meta_reg.md).

- moderator:

  Character. Moderator variable to plot. Required when the model has
  multiple predictors. If `NULL` and only one predictor exists, that
  predictor is used automatically.

- title:

  Optional character string printed above the plot (or grid). No title
  is drawn when `NULL` (the default).

- plot_all_levels:

  Logical. For categorical moderators, produce a panel per dummy
  variable (default `TRUE`).

- max_levels:

  Integer. Maximum categorical levels to plot (default 6).

- save_as:

  One of `"viewer"` (default), `"pdf"`, `"png"`, or `"tiff"`.

- filename:

  Optional file path. If `NULL` and `save_as != "viewer"`, a timestamped
  file is created in
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html).

- width, height:

  Export dimensions per panel in inches (default 10\\x\\8).

- ...:

  Additional arguments passed to
  [`metafor::regplot()`](https://wviechtb.github.io/metafor/reference/regplot.html).

## Value

Invisibly returns `TRUE`.

## Details

**y-axis note:** Values are on the model scale (log for ratio measures,
logit for proportions, raw for means).

## Examples

``` r
# \donttest{
data(dat_bcg, package = "metapropul")
result <- meta_prop(
  data = dat_bcg, event = "tpos", n = "npos",
  studylab = "author"
)
#> Warning: Duplicate study label(s) were made unique: Rosenthal et al, Comstock et al. See 'label_audit' in the result.
reg <- meta_reg(result,
  data = dat_bcg, moderators = ~ablat,
  studylab = "author"
)
bubble_plot(reg)

#> Bubble plot displayed in Viewer. Use save_as = 'pdf', 'png', or 'tiff' to export.
bubble_plot(reg, title = "BCG vaccine -- latitude moderator")

#> Bubble plot displayed in Viewer. Use save_as = 'pdf', 'png', or 'tiff' to export.
# }
```
