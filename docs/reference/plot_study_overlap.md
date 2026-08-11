# Plot citation matrices, pairwise overlap, or CCA

Plot citation matrices, pairwise overlap, or CCA

## Usage

``` r
plot_study_overlap(
  object,
  type = c("citation_matrix", "jaccard", "cca", "cca_summary"),
  title = NULL,
  save_as = c("viewer", "pdf", "png", "tiff"),
  filename = NULL,
  width = 9,
  height = 7
)
```

## Arguments

- object:

  An `umbrella_overlap` object.

- type:

  Plot type: `"citation_matrix"`, `"jaccard"`, `"cca"`, or
  `"cca_summary"`. `"cca"` draws a triangular pairwise CCA heatmap in
  the style established by the `ccaR` package; diagonal cells show the
  number of studies unique to that review and its total number of
  included studies. `"cca_summary"` draws outcome-level overall CCA
  bars.

- title:

  Optional title.

- save_as:

  `"viewer"`, `"pdf"`, `"png"`, or `"tiff"`.

- filename:

  Optional output path.

- width, height:

  Output dimensions in inches.

## Value

A `ggplot2` object, invisibly when saved.
