# Ratio outcomes: OR, RR, HR {#meta-ratio}

Use `meta_ratio()` when your studies report **binary event counts** — for
example, disease events in treated vs. control arms — or pre-computed
odds ratios, risk ratios, or hazard ratios.

## Function overview {.fn-box}

```r
meta_ratio(
  data,
  event.e  = NULL,   # events in experimental arm
  n.e      = NULL,   # total in experimental arm
  event.c  = NULL,   # events in control arm
  n.c      = NULL,   # total in control arm
  effect   = NULL,   # OR/RR/HR column (pre-computed)
  lower    = NULL,   # lower CI column
  upper    = NULL,   # upper CI column
  ci_level = 0.95,
  studylab = NULL,   # study label column
  subgroup = NULL,   # subgroup column
  model    = "random",       # "random" or "fixed"
  measure  = "OR",           # "OR", "RR", or "HR"
  tau_method          = "REML",
  ci_method           = "HK",
  prediction_interval = TRUE,
  verbose             = FALSE
)
```

---

## Input path 1 — Raw event counts

This is the most common path. Provide four columns: events and totals for
each arm.

```r
library(metapropul)
data(Olkin95, package = "metapropul")

result_or <- meta_ratio(
  data     = Olkin95,
  event.e  = "event.e",
  n.e      = "n.e",
  event.c  = "event.c",
  n.c      = "n.c",
  studylab = "author",
  measure  = "OR"          # default — Odds Ratio
)
```

### Inspect the result

```r
summary(result_or)
#>
#> Meta-Analysis of Ratio Outcomes
#> ─────────────────────────────────────────────────────
#> Measure          : OR
#> Studies (k)      : 70
#> Model            : Random-effects (REML)
#> CI method        : Hartung-Knapp (HK)
#> Pooled OR        : 0.74  [95% CI: 0.67, 0.82]
#> Prediction interval: [0.36, 1.53]
#> Heterogeneity:
#>   I² = 54.5%  [39.8%, 65.8%]
#>   τ² = 0.069  (τ = 0.263)
#>   Q = 152.4 (df = 69, p < 0.001)
#> ─────────────────────────────────────────────────────
```

### Access the results table

```r
head(result_or$table)
#> # A tibble: 70 × 9
#>   study              k   OR lower upper weight  i2   tau2 subgroup
#>   <chr>          <dbl> <dbl> <dbl> <dbl>  <dbl> <dbl> <dbl> <chr>
#> 1 Auckland 1972 1972     1  0.60  0.42  0.86   1.48    NA    NA NA
```

---

## Input path 2 — Pre-computed effect sizes

Use this when your meta-analysis software (e.g., RevMan) has already
computed log ORs or log RRs:

```r
result_pre <- meta_ratio(
  data     = my_data,
  effect   = "log_or",     # log-scale effect size column
  lower    = "lower_log",  # lower CI on log scale
  upper    = "upper_log",
  studylab = "study",
  measure  = "OR"
)
```

<div class="callout-note">
<strong>Note — Scale for pre-computed effects</strong>
Supply log-scale values (ln OR, ln RR, ln HR). metapropul will
back-transform to the ratio scale for all output.
</div>

---

## Choosing the effect measure

| `measure` | Use when |
|-----------|----------|
| `"OR"` | Case-control studies; rare events; logistic regression |
| `"RR"` | Cohort studies; randomised trials; common events |
| `"HR"` | Time-to-event (survival) outcomes |

```r
# Risk Ratio
result_rr <- meta_ratio(
  data = Olkin95, event.e = "event.e", n.e = "n.e",
  event.c = "event.c", n.c = "n.c",
  studylab = "author", measure = "RR"
)

# Hazard Ratio (pre-computed)
result_hr <- meta_ratio(
  data = survival_data,
  effect = "log_hr", lower = "lci_log", upper = "uci_log",
  studylab = "study", measure = "HR"
)
```

---

## Subgroup analysis

Pass a column name to `subgroup`. metapropul will fit and report
within-subgroup pooled estimates and a test for subgroup differences.

```r
result_sub <- meta_ratio(
  data     = Olkin95,
  event.e  = "event.e",  n.e = "n.e",
  event.c  = "event.c",  n.c = "n.c",
  studylab = "author",
  subgroup = "decade"     # a column in Olkin95 grouping by decade
)

summary(result_sub)
# ... shows pooled estimates per subgroup + Q-between test
```

<div class="callout-tip">
<strong>Tip — Subgroup forest plots</strong>
When `subgroup` is set, `forest_meta(result_sub)` automatically draws
a panelled forest plot with subgroup headers and a pooled diamond per group.
</div>

---

## Model and method options

### Random vs. fixed effects

```r
# Fixed-effect model
result_fixed <- meta_ratio(..., model = "fixed")

# Random-effects (default, REML + Hartung-Knapp CI)
result_random <- meta_ratio(..., model = "random")
```

### τ² estimators

| `tau_method` | When to use |
|-------------|------------|
| `"REML"` (default) | Best overall; unbiased for most settings |
| `"DL"` | DerSimonian-Laird; traditional |
| `"PM"` | Paule-Mandel; recommended for small k |
| `"ML"` | Maximum likelihood |

### CI methods

| `ci_method` | Notes |
|-------------|-------|
| `"HK"` (default) | Hartung-Knapp; conservative; preferred for small k |
| `"classic"` | Wald-type; may be anti-conservative |

---

## Prediction intervals

By default (`prediction_interval = TRUE`), metapropul computes the 95%
prediction interval — the range within which the *true effect* in a new,
hypothetical study would fall with 95% probability. This is often more
informative than I² alone.

```r
summary(result_or)
# Pooled OR  : 0.74  [0.67, 0.82]
# Pred. int. : [0.36, 1.53]   <-- spans null: effect may not hold everywhere
```

<div class="callout-important">
<strong>Interpret prediction intervals carefully</strong>
A prediction interval that crosses the null (OR = 1) suggests that in some
settings the intervention may not be effective, even if the pooled OR is
statistically significant.
</div>

---

## What's returned

`meta_ratio()` returns a list of class `"meta_ratio"` with these key slots:

| Slot | Contents |
|------|---------|
| `$table` | Per-study estimates tibble |
| `$meta` | The underlying `meta::metabin` or `meta::metagen` object |
| `$influence` | Leave-one-out estimates |
| `$pooled` | Pooled estimate, CI, τ², I², Q |
| `$subgroup` | Subgroup results (if applicable) |
| `$measure` | Effect measure label ("OR", "RR", "HR") |

---

## Next steps

```r
# Forest plot
forest_meta(result_or)

# Publication bias
publication_bias(result_or, plot_method = c("original", "contour"))

# Heterogeneity visualisation
plot_heterogeneity(result_or)

# Influence analysis
forest_influence(result_or)

# Summary table
table_meta(result_or)
```
