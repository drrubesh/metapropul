# Meta-regression {#meta-regression}

Meta-regression extends meta-analysis by modelling the relationship between
effect sizes and one or more **moderator** (covariate) variables. It answers
the question: *does the treatment effect vary systematically with study-level
characteristics?*

metapropul provides `meta_reg()` for fitting models and `bubble_plot()` for
visualising continuous moderators.

<div class="callout-important">
<strong>Power and interpretation</strong>
Meta-regression is underpowered with fewer than ~10 studies per moderator
level. Results should be considered exploratory and hypothesis-generating
rather than confirmatory. Always adjust for multiple testing when examining
many potential moderators.
</div>

---

## `meta_reg()` {.fn-box}

```r
meta_reg(
  meta_object,     # a meta_ratio, meta_mean, or meta_prop object
  data,            # the original data frame used to fit the model
  moderators,      # a formula, e.g. ~ ablat or ~ ablat + alloc
  studylab         # the study label column name (required for matching)
)
```

`meta_reg()` uses `metafor::rma()` internally with REML estimation.
It returns a `"meta_reg"` object with the full model, coefficient table,
and model diagnostics.

---

## Fitting a meta-regression

### Continuous moderator

```r
library(metapropul)
data(dat_bcg, package = "metapropul")

# Step 1: Fit base model
result <- meta_prop(
  dat_bcg,
  event = "tpos", n = "npos",
  studylab = "author"
)

# Step 2: Fit meta-regression with latitude as moderator
reg <- meta_reg(
  meta_object = result,
  data        = dat_bcg,
  moderators  = ~ ablat,
  studylab    = "author"
)
```

### Multiple moderators

```r
reg_multi <- meta_reg(
  meta_object = result,
  data        = dat_bcg,
  moderators  = ~ ablat + year,
  studylab    = "author"
)
```

### Categorical moderator

```r
# Allocation method as a categorical moderator
reg_cat <- meta_reg(
  meta_object = result,
  data        = dat_bcg,
  moderators  = ~ alloc,
  studylab    = "author"
)
```

---

## Interpreting the output

```r
summary(reg)
#>
#> Meta-Regression Results
#> ─────────────────────────────────────────────────────
#> Outcome type : Proportion (logit scale)
#> Studies      : 13
#> Moderator(s) : ablat
#>
#> Coefficients:
#>            Estimate  95% CI Lower  95% CI Upper   p-value
#> intrcpt     -2.841       -4.120        -1.562     < 0.001
#> ablat       -0.029       -0.056        -0.002      0.035
#>
#> Model diagnostics:
#>   τ² (null model)  : 1.326
#>   τ² (fitted model): 0.617
#>   R² analog        : 53.5%   ← variance explained by moderator
#>   Q_E (residual)   : p = 0.003   ← residual heterogeneity after adjustment
#>   Q_M (moderator)  : p = 0.035   ← test for moderator significance
#> ─────────────────────────────────────────────────────
```

### Key output components

| Component | Meaning |
|-----------|---------|
| **Coefficients** | Regression slopes on the model scale (log for ratios, logit for proportions, raw for means) |
| **τ² (null)** | Between-study variance without moderators |
| **τ² (fitted)** | Residual between-study variance after accounting for moderators |
| **R² analog** | Proportion of between-study variance explained by the moderator(s) |
| **Q_E p-value** | Test for residual heterogeneity — significant means moderators don't fully explain variance |
| **Q_M p-value** | Test for overall moderator significance |

### Accessing results programmatically

```r
# Coefficient table (tibble)
reg$table
#> # A tibble: 2 × 8
#>   Term    Estimate CI.Lower CI.Upper p.value Estimate_bt CI.Lower_bt CI.Upper_bt
#>   <chr>      <dbl>    <dbl>    <dbl>   <dbl>       <dbl>       <dbl>       <dbl>
#> 1 intrcpt   -2.841   -4.120   -1.562  <0.001        5.6%        1.6%       17.3%
#> 2 ablat     -0.029   -0.056   -0.002   0.035        ...

# Model diagnostics (tibble)
reg$meta.summary

# The underlying metafor rma() object
reg$meta
```

The `Estimate_bt` column gives **back-transformed** coefficients:
- Ratios → OR/RR/HR
- Proportions → percentage (%)
- Means → raw scale (no transformation needed)

---

## `bubble_plot()` — Visualise a moderator {.fn-box}

```r
bubble_plot(
  meta_reg_object,
  moderator       = NULL,    # required if model has multiple predictors
  title           = NULL,
  plot_all_levels = TRUE,    # for categorical: one panel per level
  max_levels      = 6,
  save_as         = "viewer",
  filename        = NULL,
  width  = 10,
  height = 8,
  ...    # passed to metafor::regplot()
)
```

Bubble size is proportional to each study's weight. The regression line
shows the fitted moderator relationship. The **y-axis is on the model scale**
(log for ratios, logit for proportions, raw for means) — this is expected.

```r
# Simple bubble plot (auto-detects the single moderator)
bubble_plot(reg)

# Named moderator (required for multi-predictor models)
bubble_plot(
  reg_multi,
  moderator = "ablat",
  title     = "BCG vaccine — proportion TB positive vs. latitude"
)

# Export
bubble_plot(reg, save_as = "pdf", filename = "fig_bubble.pdf")
```

### Categorical moderators

For categorical moderators, `bubble_plot()` produces one panel per dummy
variable (up to `max_levels`):

```r
bubble_plot(reg_cat, moderator = "alloc", plot_all_levels = TRUE)
```

---

## Common errors and solutions

| Error message | Cause | Fix |
|---------------|-------|-----|
| `"Provide 'studylab' to match studies safely"` | `studylab` not supplied | Add `studylab = "author"` |
| `"Mismatch: N study label(s) not found"` | Study labels differ between `meta_object` and `data` | Check `names(data)` and match exactly |
| `"Not enough complete studies"` | Too many missing moderator values | Impute or filter data before fitting |
| `"meta_reg() supports meta_prop only when sm = 'PLOGIT'"` | PFT transformation used | Re-fit with `sm = "PLOGIT"` |
| `"Specify the 'moderator' argument"` | Multiple predictors but no moderator specified in `bubble_plot()` | Add `moderator = "varname"` |

---

## Full meta-regression workflow

```r
library(metapropul)
data(dat_bcg, package = "metapropul")

# 1. Fit base model
result <- meta_prop(
  dat_bcg, event = "tpos", n = "npos", studylab = "author"
)

# 2. Fit regression
reg <- meta_reg(
  meta_object = result,
  data        = dat_bcg,
  moderators  = ~ ablat,
  studylab    = "author"
)

# 3. Inspect results
summary(reg)

# 4. Visualise
bubble_plot(
  reg,
  title   = "Proportion TB positive vs. absolute latitude",
  save_as = "pdf",
  filename = "fig3_bubble.pdf"
)
```
