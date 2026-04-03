# Forest plots {#forest-plots}

metapropul produces publication-ready forest plots with a single function:
`forest_meta()`. Layout, sizing, and column labels are auto-configured from
the analysis object — you only add what you want to change.

## Core functions

| Function | Purpose |
|----------|---------|
| `forest_meta(x)` | Standard forest plot (studies + pooled diamond) |
| `forest_influence(x)` | Leave-one-out influence forest plot |
| `forest_cumulative(x)` | Cumulative meta-analysis forest plot |

---

## `forest_meta()` {.fn-box}

```r
forest_meta(x, ...)
```

`x` can be a `meta_ratio`, `meta_mean`, or `meta_prop` object.
The `...` are passed to layout-specific helpers.

### Minimal example

```r
library(metapropul)
data(dat_bcg, package = "metapropul")

result <- meta_prop(dat_bcg, event = "tpos", n = "npos", studylab = "author")
forest_meta(result)
```

This single line produces a complete forest plot with:

- Study labels and per-study estimates
- 95% confidence intervals
- Weights (random-effects)
- Prediction interval diamond
- Heterogeneity statistics (I², τ², Q)
- Auto-scaled plot height

### Common customisations

```r
forest_meta(
  result,
  layout    = "jama",      # "RevMan5", "JAMA", "bmj", "IVhet", "bare"
  sortby    = "TE",        # sort studies by effect size
  save_as   = "pdf",
  filename  = "fig1_forest.pdf",
  width     = 12,
  height    = 10
)
```

### Layout options

| Layout | Description |
|--------|-------------|
| `"RevMan5"` (default) | Cochrane Review Manager 5 style |
| `"JAMA"` | JAMA journal style with "Source" label |
| `"bmj"` | BMJ style |
| `"IVhet"` | IVhet model display |
| `"bare"` | Minimal, no decorations |

<div class="callout-tip">
<strong>Tip — JAMA layout</strong>
The JAMA layout hardcodes "Source" as the study label header. This is a known
behaviour of the underlying `meta` package. Use `"RevMan5"` if you need
custom column headers.
</div>

---

## Subgroup forest plots

When your analysis includes a subgroup variable, `forest_meta()` automatically
draws a panelled plot:

```r
result_sub <- meta_ratio(
  data     = Olkin95,
  event.e  = "event.e",  n.e = "n.e",
  event.c  = "event.c",  n.c = "n.c",
  studylab = "author",
  subgroup = "decade"
)

forest_meta(result_sub)
# → Draws subgroup headers, per-group diamonds, and a test-for-subgroup-differences line
```

---

## Auto-sizing

metapropul automatically calculates plot height from the number of studies (k):

- k ≤ 10: compact height
- 10 < k ≤ 30: medium height
- k > 30: expanded height with scroll-friendly PDF

You can override with `height =`:

```r
forest_meta(result, height = 14, width = 11)
```

---

## `forest_influence()` {.fn-box}

Leave-one-out influence forest plot — shows how the pooled estimate shifts
when each study is omitted.

```r
forest_influence(x, ...)
```

```r
result <- meta_ratio(
  Olkin95, event.e = "event.e", n.e = "n.e",
  event.c = "event.c", n.c = "n.c",
  studylab = "author"
)

forest_influence(result)
```

Each row shows the pooled estimate with that study excluded. Studies whose
removal substantially moves the pooled estimate are influential and merit
sensitivity analysis.

```r
# Save to PDF for manuscript
forest_influence(result, save_as = "pdf", filename = "fig_influence.pdf")
```

---

## `forest_cumulative()` {.fn-box}

Cumulative meta-analysis — adds studies one at a time (ordered by year or
effect size) and shows how the pooled estimate evolved over time.

```r
forest_cumulative(x, ...)
```

```r
result <- meta_prop(dat_bcg, event = "tpos", n = "npos", studylab = "author")
forest_cumulative(result)
```

<div class="callout-tip">
<strong>Interpreting cumulative plots</strong>
A narrowing confidence interval converging on a stable estimate suggests the
literature has reached consensus. A drifting estimate across time may indicate
publication bias or evolving study populations.
</div>

---

## Saving plots

All three functions accept the same export arguments:

```r
forest_meta(
  result,
  save_as  = "tiff",         # "viewer", "pdf", "png", "tiff"
  filename = "forest.tiff",
  width    = 12,
  height   = 9
)
```

The saved path is printed to the console.

<div class="callout-note">
<strong>On plot devices</strong>
metapropul uses `on.exit()` to safely close plot devices even if an error
occurs, so your R session won't become stuck in an open device state.
</div>

---

## Common issues

| Symptom | Solution |
|---------|---------|
| Plot clipped in Viewer | Use `save_as = "pdf"` for large k |
| Text too small | Increase `width` and `height` |
| Subgroup headers misaligned | Ensure all studies have a non-NA subgroup value |
| `"2 22"` artefact in header | Known for k > 30 with `metabin`; metapropul patches this automatically |
