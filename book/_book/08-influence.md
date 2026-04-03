# Influence analysis {#influence-analysis}

Influence analysis asks: *what happens to the pooled estimate when I remove
each study one at a time?* A study is **influential** if its removal
substantially changes the pooled estimate or its significance.

metapropul computes leave-one-out estimates automatically when you call
`meta_ratio()`, `meta_mean()`, or `meta_prop()` — no extra step needed.
Three dedicated functions help you visualise and tabulate these results.

## Functions at a glance

| Function | Output |
|----------|--------|
| `forest_influence(object)` | Leave-one-out forest plot |
| `table_influence(object)` | Publication-ready gt table |
| `table_cumulative_meta(object)` | Cumulative meta-analysis table |
| `forest_cumulative(object)` | Cumulative meta-analysis forest plot |

---

## `forest_influence()` — Leave-one-out forest plot {.fn-box}

```r
forest_influence(
  object,
  title   = NULL,
  layout  = "RevMan5",   # "RevMan5", "JAMA", "BMJ", "meta"
  save_as = "viewer",    # "viewer", "pdf", "png", "tiff"
  filename = NULL,
  width = NULL,          # auto-sized
  height = NULL,         # auto-sized
  ...
)
```

Each row shows the pooled estimate **with that study excluded**. The overall
pooled estimate (from all studies) is shown at the bottom for reference.

```r
library(metapropul)
data(dat_bcg, package = "metapropul")

result <- meta_prop(dat_bcg, event = "tpos", n = "npos", studylab = "author")

# Display in Viewer
forest_influence(result)

# Save to PDF
forest_influence(
  result,
  title   = "BCG vaccine — leave-one-out influence analysis",
  save_as = "pdf",
  filename = "fig_influence_forest.pdf"
)
```

### Reading the plot

- Rows close to the overall estimate → the excluded study has little influence
- Rows that shift markedly → influential study; consider reporting results with
  and without that study
- Narrowing confidence intervals when a study is excluded → it contributes
  disproportionate variance

### Layout options

The `layout` argument accepts the same values as `forest_meta()`:
`"RevMan5"` (default), `"JAMA"`, `"BMJ"`, `"meta"`.

---

## `table_influence()` — Leave-one-out table {.fn-box}

Produces a `gt`-formatted table of all leave-one-out pooled estimates,
optionally including I² and τ² columns.

```r
table_influence(
  object,
  title                 = NULL,
  include_heterogeneity = TRUE,   # add I² and τ² columns
  save_as  = "viewer",             # "viewer", "docx", "pdf"
  filename = NULL
)
```

```r
# View in RStudio Viewer
table_influence(result)

# Save to Word
table_influence(
  result,
  title   = "Leave-one-out influence analysis — BCG vaccine",
  save_as = "docx",
  filename = "Table_S1_influence.docx"
)

# Without heterogeneity columns (compact)
table_influence(result, include_heterogeneity = FALSE)
```

### Table structure

| Column | Contents |
|--------|---------|
| Study | Study label (omitted study) |
| Estimate [95% CI] | Pooled estimate with that study removed |
| I² (% variability) | Between-study heterogeneity with footnote |
| Tau² | Between-study variance |

Effect sizes are **back-transformed** automatically:
- Ratios → OR/RR/HR on the natural scale
- Proportions → percentage (%)
- Means → raw MD or SMD

---

## Cumulative meta-analysis

Cumulative meta-analysis adds studies one at a time and shows how the pooled
estimate evolves. It is most informative when studies are sorted by year —
showing whether the evidence has converged over time.

### Preparing ordered data

```r
# Sort by year before fitting
data(dat_bcg, package = "metapropul")
dat_ordered <- dat_bcg[order(dat_bcg$year), ]

result_ordered <- meta_prop(
  dat_ordered,
  event = "tpos", n = "npos",
  studylab = "author"
)
```

<div class="callout-tip">
<strong>Sort first, fit second</strong>
metapropul uses the row order in your data frame for cumulative analysis.
Always sort by year (or whatever ordering makes scientific sense) **before**
calling `meta_prop()`, `meta_ratio()`, or `meta_mean()`.
</div>

### `forest_cumulative()` — Cumulative forest plot {.fn-box}

```r
forest_cumulative(
  object,
  title   = NULL,
  layout  = "RevMan5",
  save_as = "viewer",
  filename = NULL,
  width  = NULL,
  height = NULL,
  ...
)
```

```r
forest_cumulative(result_ordered)

# Save to PDF
forest_cumulative(
  result_ordered,
  title   = "BCG vaccine — cumulative meta-analysis by year",
  save_as = "pdf",
  filename = "fig_cumulative.pdf"
)
```

### `table_cumulative_meta()` — Cumulative table {.fn-box}

```r
table_cumulative_meta(
  object,
  title                 = NULL,
  include_heterogeneity = TRUE,
  save_as  = "viewer",
  filename = NULL
)
```

```r
table_cumulative_meta(result_ordered)

table_cumulative_meta(
  result_ordered,
  title   = "Cumulative meta-analysis — BCG vaccine by year",
  save_as = "docx",
  filename = "Table_S2_cumulative.docx"
)
```

Each row shows the pooled estimate after adding studies sequentially.
I² and τ² are included by default to track how heterogeneity evolves.

---

## Interpreting cumulative plots

| Pattern | Interpretation |
|---------|---------------|
| Estimate stabilises early | Evidence converged; later studies add precision |
| Estimate still shifting | Further studies needed; early evidence was misleading |
| CI narrows monotonically | Increasing precision — expected |
| CI widens at a particular study | That study is an outlier — check for inconsistency |

---

## Complete influence workflow

```r
data(Olkin95, package = "metapropul")

# 1. Fit with natural ordering (by year for cumulative)
dat_sorted <- Olkin95[order(Olkin95$year), ]
result <- meta_ratio(
  dat_sorted,
  event.e = "event.e", n.e = "n.e",
  event.c = "event.c", n.c = "n.c",
  studylab = "author"
)

# 2. Leave-one-out forest plot
forest_influence(result, save_as = "pdf", filename = "fig_influence.pdf")

# 3. Leave-one-out table (supplementary material)
table_influence(result, save_as = "docx", filename = "Table_S1.docx")

# 4. Cumulative forest plot
forest_cumulative(result, save_as = "pdf", filename = "fig_cumulative.pdf")

# 5. Cumulative table
table_cumulative_meta(result, save_as = "docx", filename = "Table_S2.docx")
```
