# Predict from a meta-regression model

Computes fitted meta-regression effects, confidence intervals, and
prediction intervals at user-supplied moderator values. The centering,
scaling, and categorical reference-level decisions recorded by
[`meta_reg()`](https://drrubesh.github.io/metapropul/reference/meta_reg.md)
are applied automatically.

## Usage

``` r
predict_meta_reg(
  object,
  newdata,
  level = 0.95,
  scale = c("auto", "response", "model"),
  ...
)
```

## Arguments

- object:

  A `meta_reg` object.

- newdata:

  Data frame containing every moderator used by the fitted model.
  Interactions are constructed from the original formula.

- level:

  Confidence level between 0 and 1.

- scale:

  Output scale: `"response"` back-transforms ratio and PLOGIT proportion
  models, `"model"` retains the linear-predictor scale, and `"auto"`
  selects the response scale when available.

- ...:

  Reserved for future methods.

## Value

A tibble containing the supplied moderator values and columns
`estimate`, `conf.low`, `conf.high`, `pred.low`, `pred.high`, and
`scale`.
