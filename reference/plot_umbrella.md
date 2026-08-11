# Plot reported meta-analysis results in an umbrella review

Plot reported meta-analysis results in an umbrella review

## Usage

``` r
plot_umbrella(
  object,
  classification = NULL,
  title = NULL,
  save_as = c("viewer", "pdf", "png", "tiff"),
  filename = NULL,
  width = 9,
  height = 7
)
```

## Arguments

- object:

  An `umbrella_review` object.

- classification:

  Optional output from
  [`classify_umbrella()`](https://drrubesh.github.io/metapropul/reference/classify_umbrella.md)
  for colours.

- title:

  Optional title.

- save_as:

  `"viewer"`, `"pdf"`, `"png"`, or `"tiff"`.

- filename:

  Optional output path.

- width, height:

  Output dimensions in inches.

## Value

A `ggplot2` object with one interval per reported meta-analysis and no
pooled diamond.
