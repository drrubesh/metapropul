#' Launch the metapropul graphical interface
#'
#' Starts an interactive Shiny application for importing study-level data,
#' configuring a meta-analysis, reviewing the pooled results, and exporting
#' tables and forest plots. The graphical interface calls the same exported
#' analysis and reporting functions used in an R script; it does not implement
#' a separate statistical engine.
#'
#' The app supports analyses of proportions, ratios, continuous outcomes,
#' generic inverse-variance effects, correlations, and incidence rates. Bundled
#' example datasets are available from the data panel, and users can upload a
#' CSV or Excel workbook for their own analysis.
#'
#' @param launch.browser Passed to [shiny::runApp()]. By default, the RStudio
#'   Viewer is used when available; otherwise the system browser opens. Use
#'   `FALSE` when embedding or testing the app.
#' @param host Host address on which to serve the application.
#' @param port Optional TCP port. When `NULL`, Shiny chooses an available port.
#' @param ... Additional arguments passed to [shiny::runApp()].
#'
#' @return Called for its side effect. The return value from
#'   [shiny::runApp()] is returned invisibly when the application stops.
#'
#' @details
#' `shiny` and `bslib` are optional dependencies because they are required only
#' for the graphical interface. The optional `readxl` package enables Excel
#' imports. Install them with
#' `install.packages(c("shiny", "bslib", "readxl"))` if needed.
#'
#' @examples
#' \dontrun{
#' metapropul_app()
#' }
#'
#' @export
metapropul_app <- function(launch.browser = getOption("viewer", TRUE),
                           host = getOption("shiny.host", "127.0.0.1"),
                           port = getOption("shiny.port"),
                           ...) {
  for (package in c("shiny", "bslib")) {
    if (!requireNamespace(package, quietly = TRUE)) {
      stop(
        "The '", package, "' package is required for the graphical interface. ",
        "Install it with install.packages('", package, "').",
        call. = FALSE
      )
    }
  }

  app_dir <- system.file("shiny", "metapropul", package = "metapropul")
  if (!nzchar(app_dir)) {
    # Supports devtools::load_all() before the package has been installed.
    candidate <- file.path("inst", "shiny", "metapropul")
    if (file.exists(file.path(candidate, "app.R"))) {
      app_dir <- normalizePath(candidate)
    } else {
      stop("Could not locate the metapropul graphical interface.", call. = FALSE)
    }
  }

  shiny::runApp(
    appDir = app_dir,
    launch.browser = launch.browser,
    host = host,
    port = port,
    ...
  )
}
