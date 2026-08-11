# Internal helper: Auto-adjust plot size for meta-analysis forest plots

Internal helper: Auto-adjust plot size for meta-analysis forest plots

## Usage

``` r
.auto_plot_sizing(k, height = NULL, width = NULL, type = "ratio")
```

## Arguments

- k:

  Number of studies.

- height:

  Optional fixed height in inches. Overrides auto-sizing.

- width:

  Optional fixed width in inches. Overrides auto-sizing.

- type:

  Plot type: one of `"ratio"`, `"mean"`, `"prop"`, `"subgroup"`,
  `"influence"`, `"cumulative"`.

## Value

A list with `height`, `width`, `fontsize`, and `spacing`. The spacing
value compresses large viewer plots while exported devices still receive
enough physical height for every row.
