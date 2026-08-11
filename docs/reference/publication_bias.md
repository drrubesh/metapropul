# Publication bias assessment

Performs Egger's and Begg's tests, computes trim-and-fill, and
optionally displays one or more publication bias plots arranged in a
grid automatically.

## Usage

``` r
publication_bias(
  object,
  plot_method = NULL,
  title = NULL,
  save_as = c("viewer", "pdf", "png", "tiff"),
  filename = NULL,
  width = 10,
  height = 8
)
```

## Arguments

- object:

  A meta-analysis object from
  [`meta_ratio()`](https://drrubesh.github.io/metapropul/reference/meta_ratio.md),
  [`meta_mean()`](https://drrubesh.github.io/metapropul/reference/meta_mean.md),
  or
  [`meta_prop()`](https://drrubesh.github.io/metapropul/reference/meta_prop.md).

- plot_method:

  Character vector of plot methods. Any combination of `"original"`,
  `"trimfill"`, `"contour"`, `"limitmeta"`. If `NULL` (default), no plot
  is produced.

- title:

  Optional character string used as the overall plot title (printed via
  [`mtext()`](https://rdrr.io/r/graphics/mtext.html) above the grid). If
  `NULL` (default), each panel uses its own label. Set to `""` to
  suppress.

- save_as:

  `"viewer"` (default), `"pdf"`, `"png"`, or `"tiff"`.

- filename:

  Optional filename for export.

- width, height:

  Export dimensions in inches (default 10 x 8).

## Value

Invisibly returns a list with Begg's test, Egger's test, trim-and-fill,
and limit meta-analysis results where available.

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
publication_bias(result)
#> Egger's test: z = -0.07, p = 0.9431, intercept = -0.369 -- no evidence of asymmetry detected
#> Note: Egger's test was run on the logit-transformed scale for proportion data.
#> Begg's test (rank correlation): z = 1.95, p = 0.0509 -- borderline; interpret cautiously
#> Trim-and-fill: 2 studies imputed -- adjusted proportion = 0.94% [0.46%; 1.90%]
#> Interpretation: Minimal asymmetry; a small number of studies were imputed.
#> Note: For proportion outcomes, publication bias tests were run on the logit-transformed scale.
publication_bias(
  result,
  plot_method = c("original", "trimfill"),
  title = "BCG vaccine -- publication bias"
)
#> Egger's test: z = -0.07, p = 0.9431, intercept = -0.369 -- no evidence of asymmetry detected
#> Note: Egger's test was run on the logit-transformed scale for proportion data.
#> Begg's test (rank correlation): z = 1.95, p = 0.0509 -- borderline; interpret cautiously
#> Trim-and-fill: 2 studies imputed -- adjusted proportion = 0.94% [0.46%; 1.90%]
#> Interpretation: Minimal asymmetry; a small number of studies were imputed.
#> Note: For proportion outcomes, publication bias tests were run on the logit-transformed scale.

#> Publication bias plot displayed in Viewer. Use save_as = 'pdf', 'png', or 'tiff' to export.
# }
```
