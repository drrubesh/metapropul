# Cumulative forest plot

Produces a cumulative forest plot from a `meta_ratio`, `meta_mean`, or
`meta_prop` object. Each row shows the pooled estimate after
sequentially adding one more study in the order supplied.

## Usage

``` r
forest_cumulative(
  object,
  title = NULL,
  layout = "RevMan5",
  prediction = FALSE,
  overall = TRUE,
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

  Forest plot layout passed to
  [`meta::forest()`](https://wviechtb.github.io/metafor/reference/forest.html).
  One of `"RevMan5"` (default), `"JAMA"`, `"BMJ"`, or `"meta"`.

- prediction:

  Logical; show a prediction interval (default `FALSE`).

- overall:

  Logical; show the overall cumulative estimate (default `TRUE`).

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

## Details

**Study ordering:** Sort your data by publication year before fitting to
show when evidence first became conclusive:


    dat <- dat[order(dat$year), ]
    result <- meta_ratio(data = dat, ...)
    forest_cumulative(result)

## Examples

``` r
# \donttest{
data(dat_bcg, package = "metapropul")
dat_bcg <- dat_bcg[order(dat_bcg$year), ]
result <- meta_prop(
  data = dat_bcg, event = "tpos", n = "npos",
  studylab = "author"
)
#> Warning: Duplicate study label(s) were made unique: Rosenthal et al, Comstock et al. See 'label_audit' in the result.
forest_cumulative(result)

#> Forest plot displayed in Viewer. Use save_as = 'pdf' or 'png' for publication-quality export.
forest_cumulative(result, title = "BCG vaccine -- cumulative evidence")

#> Forest plot displayed in Viewer. Use save_as = 'pdf' or 'png' for publication-quality export.
# }
```
