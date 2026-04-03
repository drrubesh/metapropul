# Summary tables {#tables}

metapropul produces publication-ready tables via the `gt` package — formatted
for direct use in manuscripts, supplementary materials, and reports.

## Table functions overview

| Function | What it produces |
|----------|-----------------|
| `table_meta(object)` | Main results table — per-study estimates + pooled row |
| `table_influence(object)` | Leave-one-out influence table |
| `table_cumulative_meta(object)` | Cumulative meta-analysis table |

All three functions share the same interface:

```r
table_*(
  object,              # meta_ratio, meta_mean, or meta_prop
  title   = NULL,      # auto-constructed if NULL
  save_as = "viewer",  # "viewer", "docx", "pdf"
  filename = NULL      # timestamped in tempdir() if NULL
)
```

---

## `table_meta()` — Main results table {.fn-box}

Produces a complete results table with:

- One row per study with per-study effect estimate and 95% CI
- A pooled summary row (emboldened)
- I² footnote explaining the statistic

```r
library(metapropul)

# ── Proportions ──
data(dat_bcg, package = "metapropul")
result_prop <- meta_prop(dat_bcg, event = "tpos", n = "npos", studylab = "author")
table_meta(result_prop)

# ── Ratios ──
data(Olkin95, package = "metapropul")
result_or <- meta_ratio(
  Olkin95,
  event.e = "event.e", n.e = "n.e",
  event.c = "event.c", n.c = "n.c",
  studylab = "author"
)
table_meta(result_or)

# ── Means ──
data(dat_normand1999, package = "metapropul")
result_md <- meta_mean(
  dat_normand1999,
  mean.e = "m1i", sd.e = "sd1i", n.e = "n1i",
  mean.c = "m2i", sd.c = "sd2i", n.c = "n2i",
  studylab = "source"
)
table_meta(result_md)
```

### Table structure

The column header adapts automatically to the effect measure:

| Object type | Estimate column header |
|-------------|----------------------|
| `meta_prop` | Proportion (%) |
| `meta_ratio` with OR | Odds Ratio [95% CI] |
| `meta_ratio` with RR | Risk Ratio [95% CI] |
| `meta_ratio` with HR | Hazard Ratio [95% CI] |
| `meta_mean` with MD | Mean Difference [95% CI] |
| `meta_mean` with SMD | SMD [95% CI] |

### Custom title

```r
table_meta(result_or, title = "Table 1. Pooled odds ratio — Olkin95 dataset")
```

### Saving to Word (most common for manuscripts)

```r
table_meta(
  result_or,
  title   = "Table 1. Pooled odds ratio",
  save_as = "docx",
  filename = "Table1_main_results.docx"
)
```

The saved path is printed to the console. Open the `.docx` file to see a
fully formatted `gt` table ready for insertion into your manuscript.

### Saving to PDF

```r
table_meta(result_or, save_as = "pdf", filename = "Table1.pdf")
```

---

## `table_influence()` — Leave-one-out table {.fn-box}

See Chapter \@ref(influence-analysis) for full details. Quick reference:

```r
table_influence(
  result_or,
  title                 = "Table S1. Leave-one-out influence analysis",
  include_heterogeneity = TRUE,    # adds I² and τ² columns
  save_as  = "docx",
  filename = "Table_S1_influence.docx"
)
```

---

## `table_cumulative_meta()` — Cumulative table {.fn-box}

See Chapter \@ref(influence-analysis) for full details. Quick reference:

```r
# Sort by year first
dat_sorted <- dat_bcg[order(dat_bcg$year), ]
result_ordered <- meta_prop(dat_sorted, event = "tpos", n = "npos", studylab = "author")

table_cumulative_meta(
  result_ordered,
  title   = "Table S2. Cumulative meta-analysis by year",
  save_as = "docx",
  filename = "Table_S2_cumulative.docx"
)
```

---

## Working with gt tables

The return value of all table functions is a `gt` table object. You can
apply any `gt` customisation before printing or saving:

```r
library(gt)

tbl <- table_meta(result_or)

# Add a source note
tbl |>
  tab_source_note("Data: Olkin et al. (1995)") |>
  tab_options(table.font.size = "small")
```

---

## Tips for manuscript submission

<div class="callout-tip">
<strong>Word documents</strong>
`save_as = "docx"` produces a `.docx` with the `gt` table rendered via
`gt::gtsave()`. The table is editable in Word — you can adjust column widths,
fonts, and borders after export.
</div>

<div class="callout-tip">
<strong>PRISMA-compliant footnotes</strong>
`table_meta()` automatically includes an I² footnote explaining what the
statistic measures. This satisfies common reviewer requests for statistical
transparency.
</div>

<div class="callout-note">
<strong>Large tables</strong>
For very large meta-analyses (k > 50), consider whether per-study rows are
needed in the main table. The pooled row + subgroup summaries are often
more informative for readers, with the full per-study table in supplementary
material.
</div>

---

## Recommended table layout for a systematic review

| Table | Function | Location |
|-------|----------|----------|
| Main results | `table_meta()` | Main text (Table 1 or 2) |
| Subgroup results | `table_meta()` on subgroup object | Main text or supplementary |
| Leave-one-out influence | `table_influence()` | Supplementary |
| Cumulative analysis | `table_cumulative_meta()` | Supplementary |
| Meta-regression coefficients | `summary(reg)` → manual table | Main text or supplementary |
