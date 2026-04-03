# Proportions {#meta-prop}

Use `meta_prop()` for **single-arm studies** reporting a proportion — for
example, prevalence, incidence rate, diagnostic accuracy, or adverse event rate.

## Function overview {.fn-box}

```r
meta_prop(
  data,
  event,               # events column
  n,                   # total column
  studylab = NULL,
  subgroup = NULL,
  model    = "random",
  sm       = "PLOGIT", # "PLOGIT" or "PFT"
  tau_method          = "REML",
  ci_method           = "HK",
  prediction_interval = TRUE,
  verbose             = FALSE
)
```

---

## Basic usage

```r
library(metapropul)
data(dat_bcg, package = "metapropul")

# Proportion TB-positive in vaccinated arm
result_prop <- meta_prop(
  data     = dat_bcg,
  event    = "tpos",
  n        = "npos",
  studylab = "author"
)

summary(result_prop)
#>
#> Meta-Analysis of Proportions
#> ─────────────────────────────────────────────────────
#> Transformation   : Logit (PLOGIT) → back-transformed %
#> Studies (k)      : 13
#> Model            : Random-effects (REML)
#> CI method        : Hartung-Knapp (HK)
#> Pooled proportion: 3.4%  [95% CI: 2.0%, 5.7%]
#> Prediction interval: [0.5%, 20.0%]
#> Heterogeneity:
#>   I² = 84.8%  [75.9%, 90.5%]
#>   τ² = 1.33
#> ─────────────────────────────────────────────────────
```

<div class="callout-note">
<strong>Output scale</strong>
All proportions are displayed as **percentages** (back-transformed from the
logit or Freeman-Tukey scale). The pooled estimate of "3.4%" means 3.4 events
per 100 persons.
</div>

---

## Choosing the transformation

metapropul offers two transformations, controlled by the `sm` argument.

| `sm` | Full name | When to use |
|------|-----------|------------|
| `"PLOGIT"` (default) | Logit transformation | Proportions 0.1–0.9; most common |
| `"PFT"` | Freeman-Tukey double arcsine | Proportions near 0 or 1, or when studies have zero events |

```r
# Near-zero proportions — use PFT
result_pft <- meta_prop(
  data     = dat_bcg,
  event    = "tpos",
  n        = "npos",
  studylab = "author",
  sm       = "PFT"
)
```

<div class="callout-tip">
<strong>Which to choose?</strong>
When in doubt, use `"PLOGIT"`. Switch to `"PFT"` if proportions are consistently
below 0.10 or above 0.90, or if any study has zero events in the denominator.
Note that PFT back-transformation is approximate; report both if they diverge.
</div>

---

## Subgroup analysis

```r
result_sub <- meta_prop(
  data     = dat_bcg,
  event    = "tpos",
  n        = "npos",
  studylab = "author",
  subgroup = "region"   # e.g. geographic region
)

summary(result_sub)
forest_meta(result_sub)
```

---

## Zero-event studies

metapropul passes data directly to `meta::metaprop()`, which applies a
continuity correction by default when zero-event cells are encountered.
You do not need to manually add 0.5 to events.

```r
# Studies with 0 events are handled automatically
result_sparse <- meta_prop(
  data     = my_sparse_data,
  event    = "events",
  n        = "total",
  sm       = "PFT"       # PFT is more robust for sparse data
)
```

---

## What's returned

`meta_prop()` returns a list of class `"meta_prop"`:

| Slot | Contents |
|------|---------|
| `$table` | Per-study proportions (%) |
| `$meta` | Underlying `meta::metaprop` object |
| `$influence` | Leave-one-out estimates |
| `$pooled` | Pooled proportion, CI, τ², I² |
| `$subgroup` | Subgroup results (if applicable) |
| `$sm` | Transformation used (`"PLOGIT"` or `"PFT"`) |

---

## Downstream functions

```r
# Forest plot
forest_meta(result_prop)

# Publication bias (Egger's test + funnel plots)
publication_bias(result_prop, plot_method = c("original", "trimfill"))

# Heterogeneity plot
plot_heterogeneity(result_prop)

# Leave-one-out influence forest
forest_influence(result_prop)

# Cumulative meta-analysis
forest_cumulative(result_prop)

# Summary table
table_meta(result_prop)
```
