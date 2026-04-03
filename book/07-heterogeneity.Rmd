# Heterogeneity {#heterogeneity}

Between-study heterogeneity is one of the central challenges in meta-analysis.
metapropul provides two dedicated visualisation functions — `plot_heterogeneity()`
and `plot_baujat()` — alongside the heterogeneity statistics already embedded
in `summary()` output.

## Understanding heterogeneity statistics

metapropul reports three complementary heterogeneity measures:

| Statistic | What it measures | Reported in |
|-----------|-----------------|-------------|
| **I²** | Proportion of total variability due to between-study differences (%) | `summary()`, `plot_heterogeneity()` |
| **τ²** | Absolute between-study variance (on the model scale) | `summary()`, `plot_heterogeneity()` |
| **Q** | Cochran's chi-squared test for heterogeneity | `summary()` |
| **Prediction interval** | Range where 95% of true effects likely fall | `summary()`, `forest_meta()` |

<div class="callout-important">
<strong>Interpreting I²</strong>
I² is the **proportion** of total observed variability attributable to
between-study heterogeneity — not a test for it, and not a fixed-threshold
measure of clinical importance. The common benchmarks (25% = low,
50% = moderate, 75% = high) were intended as rough guides, not decision
thresholds. Always interpret I² alongside τ² and the prediction interval.
</div>

---

## `plot_heterogeneity()` — Leave-one-out heterogeneity plot {.fn-box}

This function performs a leave-one-out analysis and plots how I² or τ²
changes when each study is removed. Studies whose removal substantially reduces
heterogeneity are likely driving it.

```r
plot_heterogeneity(
  object,
  stat    = "I2",       # "I2" or "tau2"
  title   = NULL,
  save_as = "viewer",   # "viewer", "pdf", "png", "tiff"
  filename = NULL,
  width = 10,
  height = NULL,        # auto-calculated from k
  ...
)
```

### Basic examples

```r
library(metapropul)
data(dat_bcg, package = "metapropul")

result <- meta_prop(dat_bcg, event = "tpos", n = "npos", studylab = "author")

# Plot I² leave-one-out
plot_heterogeneity(result)

# Plot τ² leave-one-out
plot_heterogeneity(result, stat = "tau2")
```

### Interpreting the plot

The x-axis lists each study (rotated labels). The y-axis shows I² (%) or τ²
when that study is **omitted**. 

- A point **lower than the overall** suggests that study increases heterogeneity
- Steep drops for a single study indicate it is a key heterogeneity driver
- Roughly flat lines suggest heterogeneity is distributed across all studies

```r
# Annotated example with title and PDF export
plot_heterogeneity(
  result,
  stat    = "I2",
  title   = "BCG vaccine — leave-one-out I² analysis",
  save_as = "pdf",
  filename = "fig_heterogeneity.pdf",
  width = 10
)
```

### Auto-sizing

Plot height is calculated automatically from the number of studies (k).
For large meta-analyses (k > 50), study labels are spaced every 5 studies
to prevent overlap. Override with `height =`:

```r
plot_heterogeneity(result, height = 8, width = 12)
```

---

## `plot_baujat()` — Contribution and influence {.fn-box}

The Baujat plot is a scatter plot that helps identify influential studies
with a single visualisation:

- **x-axis** — Each study's contribution to overall heterogeneity (Q statistic)
- **y-axis** — Each study's influence on the pooled estimate (squared change when omitted)

Studies in the upper-right quadrant are both influential *and* heterogeneous —
these warrant sensitivity analysis.

```r
plot_baujat(
  object,
  title           = NULL,
  save_as         = "viewer",
  filename        = NULL,
  width           = 10,
  height          = 8,
  label_threshold = 1.0,   # label studies > mean + 1 SD on either axis
  ...
)
```

### Basic example

```r
data(Olkin95, package = "metapropul")

result_or <- meta_ratio(
  Olkin95,
  event.e = "event.e", n.e = "n.e",
  event.c = "event.c", n.c = "n.c",
  studylab = "author"
)

plot_baujat(result_or)
```

Studies are automatically labelled when they exceed `mean + 1 SD` on either
axis. Adjust the threshold to show more or fewer labels:

```r
# Label only the most extreme studies
plot_baujat(result_or, label_threshold = 2.0)

# Label more studies
plot_baujat(result_or, label_threshold = 0.5)
```

### Return value

`plot_baujat()` invisibly returns a data frame with three columns:

```r
baujat_data <- plot_baujat(result_or)
head(baujat_data)
#> # A tibble: 6 × 3
#>   studlab           het_contribution   influence
#>   <chr>                        <dbl>       <dbl>
#> 1 Auckland 1972 1972          0.234     0.00031
#> ...
```

This is useful for programmatic identification of outlier studies.

---

## Heterogeneity in `summary()` output

Both I² with confidence intervals and τ² are reported directly by `summary()`:

```r
summary(result)
#>
#> Heterogeneity:
#>   I² = 84.8%  [75.9%, 90.5%]   ← with 95% CI
#>   τ² = 1.33   (τ = 1.15)
#>   Q = 77.5 (df = 12, p < 0.001)
#>
#> Prediction interval: [0.5%, 20.0%]
```

The **prediction interval** is the single most important quantity for
understanding whether the pooled effect is consistent across settings.
When it is wide and spans the null, the treatment effect likely varies
substantially across populations.

---

## Complete heterogeneity workflow

```r
# Fit model
result <- meta_ratio(
  Olkin95,
  event.e = "event.e", n.e = "n.e",
  event.c = "event.c", n.c = "n.c",
  studylab = "author"
)

# 1. Check summary statistics
summary(result)

# 2. Identify which studies drive heterogeneity (leave-one-out I²)
plot_heterogeneity(result, save_as = "pdf", filename = "fig_het_I2.pdf")
plot_heterogeneity(result, stat = "tau2", save_as = "pdf", filename = "fig_het_tau2.pdf")

# 3. Scatter view of contribution vs. influence
plot_baujat(result, save_as = "pdf", filename = "fig_baujat.pdf")

# 4. Investigate the top drivers with a subgroup or sensitivity analysis
result_sub <- meta_ratio(
  Olkin95,
  event.e = "event.e", n.e = "n.e",
  event.c = "event.c", n.c = "n.c",
  studylab = "author",
  subgroup = "decade"
)
summary(result_sub)
forest_meta(result_sub)
```
