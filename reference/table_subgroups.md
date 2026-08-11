# Tabulate subgroup meta-analysis results

Returns full-precision subgroup estimates and the test for subgroup
differences, or formats them as a `gt` table.

## Usage

``` r
table_subgroups(object, output = c("gt", "data"), digits = 3L, title = NULL)
```

## Arguments

- object:

  A `meta_ratio`, `meta_mean`, or `meta_prop` object fitted with a
  subgroup variable.

- output:

  `"gt"` or `"data"`.

- digits:

  Display precision for `output = "gt"`.

- title:

  Optional table title.

## Value

A `gt` table or a list containing subgroup estimates and the
subgroup-difference test.
