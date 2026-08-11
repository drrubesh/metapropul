# Plot meta-regression results and diagnostics

Draws a moderator relationship with confidence and prediction bands, or
a residual, fitted-value, or influence diagnostic plot.

## Usage

``` r
plot_meta_reg(
  object,
  type = c("bubble", "residual", "fitted", "influence"),
  moderator = NULL,
  level = 0.95,
  prediction = TRUE,
  points = 100L,
  title = NULL,
  save_as = c("viewer", "pdf", "png", "tiff"),
  filename = NULL,
  width = 9,
  height = 7
)
```

## Arguments

- object:

  A `meta_reg` object.

- type:

  Plot type: `"bubble"`, `"residual"`, `"fitted"`, or `"influence"`.

- moderator:

  Moderator name for a bubble plot. If omitted, the sole moderator in a
  univariable model is used.

- level:

  Confidence level for bubble-plot intervals.

- prediction:

  Logical; show the prediction band on bubble plots.

- points:

  Number of grid points for a continuous moderator.

- title:

  Optional plot title.

- save_as:

  One of `"viewer"`, `"pdf"`, `"png"`, or `"tiff"`.

- filename:

  Optional output path.

- width, height:

  Output dimensions in inches.

## Value

A ggplot2 object, invisibly when saved.
