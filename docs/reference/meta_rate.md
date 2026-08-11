# Meta-analysis of incidence rates

Pools event rates per unit of person-time on the log incidence-rate
scale.

## Usage

``` r
meta_rate(
  data,
  event,
  time,
  studylab = NULL,
  subgroup = NULL,
  model = c("random", "fixed"),
  tau_method = "REML",
  ci_method = "HK",
  prediction_interval = TRUE,
  irscale = 1,
  irunit = "person-years",
  incr = 0.5,
  missing_action = c("exclude", "error"),
  duplicate_action = c("warn", "error", "make_unique"),
  singleton_action = c("warn", "retain", "omit", "error")
)
```

## Arguments

- data:

  A data frame.

- event:

  Event-count column.

- time:

  Person-time column.

- studylab, subgroup:

  Optional study-label and subgroup columns.

- model, tau_method, ci_method, prediction_interval:

  Model controls.

- irscale:

  Scaling factor for displayed rates, such as 1000.

- irunit:

  Person-time unit label.

- incr:

  Continuity correction for zero-event studies.

- missing_action, duplicate_action, singleton_action:

  Audit policies.

## Value

An object of class `meta_rate`.

## CSV and Excel columns

Use one row per study with numeric event-count and person-time columns.
Events must be non-negative and person-time must be positive.
Study-label and subgroup columns are optional.
