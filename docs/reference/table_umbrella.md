# Create a review-by-review umbrella table

Create a review-by-review umbrella table

## Usage

``` r
table_umbrella(
  object,
  classification = NULL,
  grade = NULL,
  title = NULL,
  save_as = c("viewer", "docx", "pdf"),
  filename = NULL
)
```

## Arguments

- object:

  An `umbrella_review` object.

- classification:

  Optional output from
  [`classify_umbrella()`](https://drrubesh.github.io/metapropul/reference/classify_umbrella.md).

- grade:

  Optional output from
  [`grade_umbrella()`](https://drrubesh.github.io/metapropul/reference/grade_umbrella.md).

- title:

  Optional title.

- save_as:

  `"viewer"`, `"docx"`, or `"pdf"`.

- filename:

  Optional output path.

## Value

A `gt` table, invisibly when saved.
