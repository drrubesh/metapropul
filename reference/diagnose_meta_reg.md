# Diagnose a meta-regression model

Produces coefficient-level collinearity measures and study-level
residual and influence diagnostics without drawing a plot.

## Usage

``` r
diagnose_meta_reg(object, vif_threshold = 5, cook_threshold = NULL)
```

## Arguments

- object:

  A `meta_reg` object.

- vif_threshold:

  Numeric threshold used to flag coefficient-level VIFs.

- cook_threshold:

  Optional Cook's-distance threshold. By default `4 / k` is used.

## Value

An object of class `"meta_reg_diagnostics"` containing study influence
measures, coefficient-level collinearity measures, condition indices,
and the raw metafor influence object.
