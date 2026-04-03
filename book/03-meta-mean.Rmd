# Mean differences: MD and SMD {#meta-mean}

Use `meta_mean()` when studies report **continuous outcomes** — for example,
blood pressure, quality-of-life scores, or length of hospital stay.
It supports mean difference (MD) and standardised mean difference (SMD,
Cohen's *d* / Hedges' *g*).

## Function overview {.fn-box}

```r
meta_mean(
  data,
  mean.e   = NULL,   # mean in experimental group
  sd.e     = NULL,   # SD in experimental group
  n.e      = NULL,   # sample size in experimental group
  mean.c   = NULL,   # mean in control group
  sd.c     = NULL,   # SD in control group
  n.c      = NULL,   # sample size in control group
  effect   = NULL,   # pre-computed MD or SMD column
  lower    = NULL,   # lower CI column
  upper    = NULL,   # upper CI column
  ci_level = 0.95,
  studylab = NULL,
  subgroup = NULL,
  model    = "random",
  measure  = "MD",   # "MD" or "SMD"
  tau_method          = "REML",
  ci_method           = "HK",
  prediction_interval = TRUE,
  verbose             = FALSE
)
```

---

## Input path 1 — Raw group statistics

Provide means, SDs, and sample sizes for both arms:

```r
library(metapropul)
data(dat_normand1999, package = "metapropul")

result_md <- meta_mean(
  data     = dat_normand1999,
  mean.e   = "m1i",
  sd.e     = "sd1i",
  n.e      = "n1i",
  mean.c   = "m2i",
  sd.c     = "sd2i",
  n.c      = "n2i",
  studylab = "source",
  measure  = "MD"
)

summary(result_md)
#>
#> Meta-Analysis of Continuous Outcomes
#> ─────────────────────────────────────────────────────
#> Measure          : MD (Mean Difference)
#> Studies (k)      : 9
#> Model            : Random-effects (REML)
#> CI method        : Hartung-Knapp (HK)
#> Pooled MD        : -0.84  [95% CI: -1.51, -0.17]
#> Prediction interval: [-3.58, 1.90]
#> Heterogeneity:
#>   I² = 79.3%  [60.3%, 89.3%]
#>   τ² = 0.618
#> ─────────────────────────────────────────────────────
```

---

## Choosing MD vs. SMD

| Measure | When to use |
|---------|------------|
| `"MD"` | Studies use the **same scale** (e.g., all in mmHg) |
| `"SMD"` | Studies use **different scales** measuring the same construct |

```r
# Standardised Mean Difference
result_smd <- meta_mean(
  data     = dat_normand1999,
  mean.e   = "m1i",  sd.e = "sd1i",  n.e = "n1i",
  mean.c   = "m2i",  sd.c = "sd2i",  n.c = "n2i",
  studylab = "source",
  measure  = "SMD"
)
```

<div class="callout-tip">
<strong>Interpreting SMD</strong>
Cohen's d benchmarks: 0.2 = small, 0.5 = moderate, 0.8 = large. These are
rough guides — always interpret in the clinical context.
</div>

---

## Input path 2 — Pre-computed effect sizes

If your data already has computed MDs or SMDs:

```r
result_pre <- meta_mean(
  data     = my_data,
  effect   = "md",
  lower    = "lower_95",
  upper    = "upper_95",
  studylab = "study",
  measure  = "MD"
)
```

<div class="callout-note">
<strong>Note — Scale for pre-computed effects</strong>
Supply values on the natural scale (not log-transformed). MDs and SMDs
are symmetric around zero.
</div>

---

## Subgroup analysis

```r
result_by_setting <- meta_mean(
  data     = dat_normand1999,
  mean.e   = "m1i",  sd.e = "sd1i",  n.e = "n1i",
  mean.c   = "m2i",  sd.c = "sd2i",  n.c = "n2i",
  studylab = "source",
  subgroup = "setting"   # e.g. inpatient vs outpatient
)

forest_meta(result_by_setting)
```

---

## What's returned

`meta_mean()` returns a list of class `"meta_mean"` with the same slots as
`meta_ratio()`:

| Slot | Contents |
|------|---------|
| `$table` | Per-study estimates tibble |
| `$meta` | The underlying `meta::metacont` or `meta::metagen` object |
| `$influence` | Leave-one-out estimates |
| `$pooled` | Pooled MD/SMD, CI, τ², I², Q |
| `$subgroup` | Subgroup results (if applicable) |
| `$measure` | `"MD"` or `"SMD"` |

---

## Downstream functions

All downstream functions work identically for `meta_mean` objects:

```r
forest_meta(result_md)
publication_bias(result_md, plot_method = "original")
plot_heterogeneity(result_md, stat = "tau2")
forest_influence(result_md)
table_meta(result_md)
```
