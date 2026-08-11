# Leave-one-out heterogeneity plot

Plots I\\^2\\ or Tau\\^2\\ from a leave-one-out meta-analysis to show
how much each study contributes to between-study heterogeneity.

## Usage

``` r
plot_heterogeneity(
  object,
  stat = c("I2", "tau2"),
  title = NULL,
  save_as = c("viewer", "pdf", "png", "tiff"),
  filename = NULL,
  width = 10,
  height = NULL,
  ...
)
```

## Arguments

- object:

  A `meta_prop`, `meta_ratio`, or `meta_mean` object.

- stat:

  `"I2"` (default) or `"tau2"`.

- title:

  Optional character string for the plot title. No title is drawn when
  `NULL` (the default).

- save_as:

  One of `"viewer"` (default), `"pdf"`, `"png"`, or `"tiff"`.

- filename:

  Optional file name for saving.

- width, height:

  Export dimensions in inches. Default width is 10; height is chosen
  automatically if `NULL`.

- ...:

  Additional arguments passed to
  [`graphics::plot()`](https://rdrr.io/r/graphics/plot.default.html).

## Value

Invisibly returns `TRUE`.

## Details

**Interpreting I\\^2\\:** I\\^2\\ is the proportion of total observed
variability attributable to between-study heterogeneity – not a test for
it, and not a fixed-threshold measure of its magnitude. A high I\\^2\\
does not automatically mean heterogeneity is clinically important; use
Tau\\^2\\ and the prediction interval for that judgement.

## Examples

``` r
# \donttest{
data(dat_bcg, package = "metapropul")
result <- meta_prop(
  data = dat_bcg,
  event = "tpos",
  n = "npos",
  studylab = "author"
)
#> Warning: Duplicate study label(s) were made unique: Rosenthal et al, Comstock et al. See 'label_audit' in the result.
plot_heterogeneity(result)

#> Heterogeneity plot displayed in Viewer. Use save_as = 'pdf', 'png', or 'tiff' to export.
plot_heterogeneity(result, stat = "tau2")

#> Heterogeneity plot displayed in Viewer. Use save_as = 'pdf', 'png', or 'tiff' to export.
# }
```
