# Influence forest plot

Draws a leave-one-out influence forest plot from a `meta_ratio`,
`meta_mean`, or `meta_prop` object.

## Usage

``` r
forest_influence(
  object,
  title = NULL,
  layout = "meta",
  prediction = FALSE,
  save_as = c("viewer", "pdf", "png", "tiff"),
  filename = NULL,
  width = NULL,
  height = NULL,
  ...
)
```

## Arguments

- object:

  A `meta_ratio`, `meta_mean`, or `meta_prop` object.

- title:

  Optional character string printed above the plot. No title is drawn
  when `NULL` (the default).

- layout:

  Layout style. One of `"meta"` (default), `"JAMA"`, `"BMJ"`, or
  `"meta"`.

- prediction:

  Logical; if `TRUE`, show prediction intervals. Default is `FALSE`.

- save_as:

  One of `"viewer"` (default), `"pdf"`, `"png"`, or `"tiff"`.

- filename:

  Optional file path. If `NULL` and `save_as != "viewer"`, a timestamped
  file is created in
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html).

- width:

  Optional plot width in inches (overrides auto-sizing).

- height:

  Optional plot height in inches (overrides auto-sizing).

- ...:

  Additional arguments passed to
  [`meta::forest()`](https://wviechtb.github.io/metafor/reference/forest.html).

## Value

Invisibly returns `TRUE`.

## Examples

``` r
# \donttest{
data(dat_bcg, package = "metapropul")
result <- meta_prop(
  data = dat_bcg, event = "tpos", n = "npos",
  studylab = "author"
)
#> Warning: Duplicate study label(s) were made unique: Rosenthal et al, Comstock et al. See 'label_audit' in the result.
forest_influence(result)

#> Influence plot displayed in Plots pane. Use save_as = 'pdf', 'png', or 'tiff' for publication-quality export.
forest_influence(result, title = "BCG vaccine -- leave-one-out analysis")

#> Influence plot displayed in Plots pane. Use save_as = 'pdf', 'png', or 'tiff' for publication-quality export.
# }
```
