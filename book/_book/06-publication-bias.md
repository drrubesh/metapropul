# Publication bias {#publication-bias}

Publication bias occurs when studies with significant or favourable results
are more likely to be published, distorting the pooled estimate. metapropul
provides a comprehensive set of tests and plots — all accessed through two
functions: `publication_bias()` for large meta-analyses (k ≥ 10) and
`doi_plot()` for smaller ones.

## When to use each function

| Function | Use when | Key outputs |
|----------|----------|-------------|
| `publication_bias()` | k ≥ 10 studies | Egger's test, Begg's test, trim-and-fill, funnel plots, limit meta-analysis |
| `doi_plot()` | k < 10 studies | DOI plot + LFK index |

<div class="callout-important">
<strong>Statistical power warning</strong>
Egger's and Begg's tests have low power when k < 10 studies. metapropul
will print a message and return invisibly if this threshold is not met.
Use `doi_plot()` instead.
</div>

---

## `publication_bias()` {.fn-box}

```r
publication_bias(
  object,
  plot_method = NULL,   # NULL, "original", "trimfill", "contour", "limitmeta"
  title  = NULL,
  save_as = "viewer",   # "viewer", "pdf", "png", "tiff"
  filename = NULL,
  width = 10,
  height = 8
)
```

### Tests only (no plot)

By default (`plot_method = NULL`), `publication_bias()` runs all tests and
prints results to the console — no plot is generated:

```r
library(metapropul)
data(Olkin95, package = "metapropul")

result <- meta_ratio(
  Olkin95, event.e = "event.e", n.e = "n.e",
  event.c = "event.c", n.c = "n.c",
  studylab = "author"
)

bias_results <- publication_bias(result)
#> Egger's test: z = 2.41, p = 0.0162, intercept = 0.847 -- suggests possible bias or small-study effects
#> Begg's test (rank correlation): z = 1.89, p = 0.0590 -- borderline; interpret cautiously
#> Trim-and-fill: 8 studies imputed -- adjusted OR = 0.69 [0.62; 0.77]
#> Interpretation: Meaningful asymmetry suggested; review the original estimate carefully.
```

The returned object is a list with slots `$egger`, `$begg`, `$trimfill`,
and `$limitmeta` (when applicable).

```r
# Access individual test results programmatically
bias_results$egger$p.value
bias_results$trimfill$TE.random   # log-scale pooled estimate after imputation
```

---

### Funnel plots

Pass a character vector to `plot_method` to produce one or more funnel plots.
Multiple plots are automatically arranged in a grid.

```r
# Single funnel plot
publication_bias(result, plot_method = "original")

# Two plots side-by-side
publication_bias(result, plot_method = c("original", "trimfill"))

# All four plots in a 2×2 grid
publication_bias(
  result,
  plot_method = c("original", "trimfill", "contour", "limitmeta"),
  title = "Olkin95 — Publication Bias Assessment"
)
```

### Plot method reference

| `plot_method` | What it shows |
|--------------|--------------|
| `"original"` | Standard funnel plot (SE vs. effect size) |
| `"trimfill"` | Trim-and-fill funnel — imputed studies shown as open circles |
| `"contour"` | Contour-enhanced funnel — shaded regions show p-value zones (p > 0.10 in white, 0.05–0.10 in light grey, < 0.05 in dark grey) |
| `"limitmeta"` | Limit meta-analysis funnel — adjusts for small-study effects |

<div class="callout-tip">
<strong>Tip — Contour-enhanced funnel plots</strong>
The contour-enhanced funnel plot is useful for distinguishing publication
bias from genuine heterogeneity. If missing studies cluster in non-significant
regions (white/light grey), publication bias is more likely than if they
cluster in significant regions.
</div>

---

### Saving plots

```r
publication_bias(
  result,
  plot_method = c("original", "contour"),
  save_as  = "pdf",
  filename = "fig_pub_bias.pdf",
  width    = 12,
  height   = 6
)
```

---

## Interpreting test results

### Egger's test

Egger's linear regression test checks for funnel plot asymmetry by regressing
standardised effect sizes on their precision. A significant intercept (p < 0.05)
suggests asymmetry.

| p-value | Interpretation |
|---------|----------------|
| < 0.05 | Suggests possible bias or small-study effects |
| 0.05–0.10 | Borderline — interpret cautiously |
| > 0.10 | No evidence of asymmetry detected |

<div class="callout-note">
<strong>Note — Proportions (PLOGIT)</strong>
For `meta_prop()` objects, Egger's test runs on the **logit-transformed** scale.
metapropul prints a reminder of this automatically. The PFT transformation
is not supported for publication bias testing.
</div>

### Begg's test

Begg's rank correlation test checks whether effect size estimates are
correlated with their variances (Kendall's τ). Less powerful than Egger's
test but non-parametric.

### Trim-and-fill

Trim-and-fill imputes missing studies to make the funnel plot symmetric, then
recomputes the pooled estimate. Key output: number of imputed studies (k₀)
and the adjusted pooled estimate.

| Imputed studies (k₀) | Interpretation |
|---------------------|----------------|
| 0 | No asymmetry detected |
| 1–3 | Minimal asymmetry |
| > 3 | Meaningful asymmetry — re-examine original estimate |

### Limit meta-analysis

Limit meta-analysis (Rücker et al.) provides an effect size estimate that is
adjusted for small-study effects. This is more robust than trim-and-fill when
the direction of bias is unknown.

---

## `doi_plot()` — for small meta-analyses {.fn-box}

```r
doi_plot(
  object,
  title   = NULL,
  save_as = "viewer",   # "viewer", "pdf", "png", "tiff"
  filename = NULL,
  width = 7,
  height = 7,
  ...   # passed to metasens::doiplot()
)
```

The DOI plot mirrors the standard funnel plot but plots each study as a point
on a normalised scale. The **LFK index** quantifies asymmetry:

| LFK index | Interpretation |
|-----------|----------------|
| ≤ ±1 | No asymmetry |
| ±1 to ±2 | Minor asymmetry |
| > ±2 | Major asymmetry |

```r
# Use a small subset (k < 10)
data(dat_bcg, package = "metapropul")
small <- dat_bcg[1:9, ]
result_small <- meta_prop(small, event = "tpos", n = "npos", studylab = "author")
doi_plot(result_small)
doi_plot(result_small, title = "BCG vaccine (9 studies) — DOI plot", save_as = "pdf")
```

<div class="callout-note">
<strong>Note</strong>
`doi_plot()` can be called on larger meta-analyses too — metapropul prints
a note that `publication_bias()` is preferred for k ≥ 10, but proceeds
with the plot.
</div>

---

## Complete publication bias workflow

```r
# Step 1: Fit your model
result <- meta_ratio(
  Olkin95,
  event.e = "event.e", n.e = "n.e",
  event.c = "event.c", n.c = "n.c",
  studylab = "author"
)

# Step 2: Run all tests (check k first)
if (result$meta$k >= 10) {
  bias <- publication_bias(result)
} else {
  doi_plot(result)
}

# Step 3: Visualise (pick the plots that match your needs)
publication_bias(
  result,
  plot_method = c("original", "trimfill", "contour", "limitmeta"),
  title   = "Publication Bias — Full Assessment",
  save_as = "pdf",
  filename = "Supplementary_Fig_S1.pdf",
  width   = 14,
  height  = 7
)
```
