# Meta-analysis of ratio measures

Conducts a meta-analysis of ratio effect measures using either raw
event-count data or pre-computed study-level effect estimates with
confidence intervals, or log-ratio estimates with standard errors.

## Usage

``` r
meta_ratio(
  data,
  event.e = NULL,
  n.e = NULL,
  event.c = NULL,
  n.c = NULL,
  effect = NULL,
  lower = NULL,
  upper = NULL,
  se = NULL,
  effect_scale = c("ratio", "log"),
  ci_level = 0.95,
  studylab = NULL,
  subgroup = NULL,
  model = "random",
  measure = "OR",
  tau_method = "REML",
  ci_method = "HK",
  prediction_interval = TRUE,
  incr = 0.5,
  method_incr = c("only0", "if0all", "all", "user"),
  allstudies = FALSE,
  missing_action = c("exclude", "error"),
  duplicate_action = c("warn", "error", "make_unique"),
  singleton_action = c("warn", "retain", "omit", "error"),
  verbose = FALSE
)
```

## Arguments

- data:

  A data frame containing the meta-analysis dataset.

- event.e:

  Character string giving the column name for the number of events in
  the experimental or exposed group.

- n.e:

  Character string giving the column name for the total number of
  participants in the experimental or exposed group.

- event.c:

  Character string giving the column name for the number of events in
  the control or unexposed group.

- n.c:

  Character string giving the column name for the total number of
  participants in the control or unexposed group.

- effect:

  Character string giving the column name for the pre-computed study
  effect estimate. Supported measures are OR, RR, and HR, depending on
  `measure`.

- lower:

  Character string giving the column name for the lower confidence
  interval bound of the pre-computed effect estimate.

- upper:

  Character string giving the column name for the upper confidence
  interval bound of the pre-computed effect estimate.

- se:

  Optional character string giving the standard-error column for a
  pre-computed log ratio. When supplied, set `effect_scale = "log"` and
  do not supply `lower` or `upper`.

- effect_scale:

  Scale of pre-computed `effect`, `lower`, and `upper`: `"ratio"`
  (default) for OR/RR/HR values, or `"log"` for log OR/log RR/log HR
  values. Standard-error input is supported only on the log scale.

- ci_level:

  Numeric scalar giving the confidence level used for pre-computed
  effect sizes, typically `0.95`. This is used to derive the standard
  error from `lower` and `upper`.

- studylab:

  Optional character string giving the column name for study labels. If
  omitted, labels are auto-generated as `"Study_1"`, `"Study_2"`, and so
  on.

- subgroup:

  Optional single character string giving a completely observed subgroup
  column. At least two observed levels are required. Singleton levels
  are retained with a warning.

- model:

  Character string specifying the meta-analytic model: `"random"` for
  random-effects or `"fixed"` for fixed-effect analysis.

- measure:

  Character string specifying the effect measure: `"OR"` for odds ratio,
  `"RR"` for risk ratio, or `"HR"` for hazard ratio.

- tau_method:

  Character string specifying the method used to estimate between-study
  variance tau-squared in random-effects models. Options are `"REML"`
  (restricted maximum likelihood), `"PM"` (Paule-Mandel), `"DL"`
  (DerSimonian-Laird), `"ML"` (maximum likelihood), `"HS"`
  (Hunter-Schmidt), `"SJ"` (Sidik-Jonkman), `"HE"` (Hedges), and `"EB"`
  (empirical Bayes).

- ci_method:

  Character string specifying the method used for random-effects
  confidence intervals. Options are `"HK"` (Hartung-Knapp), `"classic"`,
  and `"KR"`.

- prediction_interval:

  Logical; if `TRUE`, a prediction interval is computed for the pooled
  random-effects estimate where applicable.

- incr:

  Continuity correction added to zero cells for raw binary data.

- method_incr:

  When to apply `incr`: `"only0"`, `"if0all"`, `"all"`, or `"user"`,
  corresponding to
  [`meta::metabin()`](https://rdrr.io/pkg/meta/man/metabin.html)'s
  `method.incr`.

- allstudies:

  Logical; apply the continuity correction to all studies.

- missing_action:

  How incomplete analysis rows are handled: `"exclude"` records and
  removes them, while `"error"` stops before fitting.

- duplicate_action:

  How duplicate study labels are handled: `"warn"` (default) makes them
  unique and records the change, `"error"` stops, and `"make_unique"`
  records the change without warning.

- singleton_action:

  Handling of subgroup levels containing one study: `"warn"`,
  `"retain"`, `"omit"`, or `"error"`.

- verbose:

  Logical; if `TRUE`, progress messages are printed during model
  fitting.

## Value

An object of class `"meta_ratio"` containing:

- `meta`: the fitted meta object

- `table`: a tidy study-level summary table

- `meta.subgroup.summary`: subgroup pooled estimates, if subgroup
  analysis was requested

- `influence.analysis`: leave-one-out influence analysis

- model settings such as `model`, `measure`, `tau_method`, and
  `ci_method`

## Details

Two input formats are supported:

- Raw 2 x 2 data using `event.e`, `n.e`, `event.c`, and `n.c`

- Pre-computed effect sizes using `effect`, `lower`, and `upper`

- Log OR, log RR, or log HR estimates using `effect` and `se`, with
  `effect_scale = "log"`

The function supports odds ratios (OR), risk ratios (RR), and hazard
ratios (HR). Hazard ratios require pre-computed effect sizes and cannot
be derived from raw event-count data.

If raw event-count data are supplied, the function fits the model using
[`meta::metabin()`](https://rdrr.io/pkg/meta/man/metabin.html). If
pre-computed effect sizes are supplied on the ratio scale, the function
log-transforms the estimates and derives standard errors from the
reported confidence intervals. Log-scale confidence limits or a
log-scale standard error may instead be supplied directly. All
pre-computed paths are fitted with
[`meta::metagen()`](https://rdrr.io/pkg/meta/man/metagen.html).

When pre-computed effect sizes are used, studies with non-finite
log-transformed values are excluded with a warning. This commonly occurs
when odds ratios, risk ratios, or confidence intervals are not finite,
for example because of zero cells or invalid bounds.

Results from the raw-data and pre-computed effect-size paths may differ
if zero-cell corrections were applied in the original study calculations
or if raw event counts are analysed with continuity corrections
internally by meta.

## CSV and Excel columns

Use one row per independent study comparison. For OR or RR from counts,
provide numeric columns corresponding to `event.e`, `n.e`, `event.c`,
and `n.c`. For a reported OR, RR, or HR, provide `effect`, `lower`, and
`upper` on the ratio scale. Alternatively provide a log effect and its
standard error using `effect`, `se`, and `effect_scale = "log"`.
Study-label and subgroup columns may contain text. Column headers do not
need to use these exact names because arguments map the user's headers
explicitly.

## Examples

``` r
data(dat_bcg, package = "metapropul")

result <- meta_ratio(
  data = dat_bcg,
  event.e = "tpos",
  n.e = "npos",
  event.c = "cpos",
  n.c = "cneg",
  studylab = "author"
)
#> Warning: Duplicate study label(s) were made unique: Rosenthal et al, Comstock et al. See 'label_audit' in the result.
```
