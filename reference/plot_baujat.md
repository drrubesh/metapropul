# Baujat plot

Displays each study's contribution to overall heterogeneity (x-axis)
versus its influence on the pooled estimate (y-axis). Studies exceeding
a threshold on either axis are labelled automatically to reduce
overplotting.

## Usage

``` r
plot_baujat(
  object,
  title = NULL,
  save_as = c("viewer", "pdf", "png", "tiff"),
  filename = NULL,
  width = 10,
  height = 8,
  label_threshold = 1,
  ...
)
```

## Arguments

- object:

  A `meta_prop`, `meta_ratio`, or `meta_mean` object.

- title:

  Optional character string for the plot title. If `NULL` (default),
  `"Baujat Plot"` is used. Set to `""` to suppress.

- save_as:

  One of `"viewer"` (default), `"pdf"`, `"png"`, or `"tiff"`.

- filename:

  Optional file name for export.

- width:

  Width in inches (default 10).

- height:

  Height in inches (default 8).

- label_threshold:

  Numeric. A study is labelled if its x or y value exceeds
  `mean + label_threshold * sd` on that axis. Default `1.0`; increase
  for fewer labels.

- ...:

  Currently unused; reserved for future arguments.

## Value

Invisibly returns a data frame with columns `studlab`,
`het_contribution`, and `influence`.

## Examples

``` r
# \donttest{
data(dat_bcg, package = "metapropul")
result <- meta_prop(
  data = dat_bcg, event = "tpos", n = "npos",
  studylab = "author"
)
#> Warning: Duplicate study label(s) were made unique: Rosenthal et al, Comstock et al. See 'label_audit' in the result.
plot_baujat(result)

#> Baujat plot displayed in Viewer. Use save_as = 'pdf', 'png', or 'tiff' to export.
plot_baujat(result, title = "BCG vaccine \u2014 Baujat plot")

#> Baujat plot displayed in Viewer. Use save_as = 'pdf', 'png', or 'tiff' to export.
# }
```
