# Launch the metapropul graphical interface

Starts an interactive Shiny application for importing study-level data,
configuring a meta-analysis, reviewing the pooled results, and exporting
tables and forest plots. The graphical interface calls the same exported
analysis and reporting functions used in an R script; it does not
implement a separate statistical engine.

## Usage

``` r
metapropul_app(
  launch.browser = getOption("viewer", TRUE),
  host = getOption("shiny.host", "127.0.0.1"),
  port = getOption("shiny.port"),
  ...
)
```

## Arguments

- launch.browser:

  Passed to
  [`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html). By
  default, the RStudio Viewer is used when available; otherwise the
  system browser opens. Use `FALSE` when embedding or testing the app.

- host:

  Host address on which to serve the application.

- port:

  Optional TCP port. When `NULL`, Shiny chooses an available port.

- ...:

  Additional arguments passed to
  [`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html).

## Value

Called for its side effect. The return value from
[`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html) is
returned invisibly when the application stops.

## Details

The app supports analyses of proportions, ratios, continuous outcomes,
generic inverse-variance effects, correlations, and incidence rates.
Bundled example datasets are available from the data panel, and users
can upload a CSV or Excel workbook for their own analysis.

`shiny` and `bslib` are optional dependencies because they are required
only for the graphical interface. The optional `readxl` package enables
Excel imports. Install them with
`install.packages(c("shiny", "bslib", "readxl"))` if needed.

## Examples

``` r
if (FALSE) { # \dontrun{
metapropul_app()
} # }
```
