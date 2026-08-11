# Tabulate meta-regression results

Creates a publication-ready coefficient table with confidence intervals,
p-values, model metadata, and optional back-transformed moderator
effects.

## Usage

``` r
table_meta_reg(
  object,
  backtransform = TRUE,
  title = NULL,
  save_as = c("viewer", "docx", "pdf"),
  filename = NULL
)
```

## Arguments

- object:

  A `meta_reg` object.

- backtransform:

  Logical; include back-transformed effects when defined.

- title:

  Optional table title.

- save_as:

  One of `"viewer"`, `"docx"`, or `"pdf"`.

- filename:

  Optional output path when saving.

## Value

A gt table, invisibly when saved.
