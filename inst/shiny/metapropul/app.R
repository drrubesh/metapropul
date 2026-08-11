suppressPackageStartupMessages({
  library(shiny)
  library(bslib)
})

`%||%` <- function(x, y) if (is.null(x) || !length(x)) y else x
mp_fun <- function(name) getExportedValue("metapropul", name)

sample_specs <- list(
  "BCG vaccine — proportion" = list(
    dataset = "dat_bcg", type = "Proportion", event = "tpos", n = "npos",
    study = "author", subgroup = "alloc"
  ),
  "BCG vaccine — odds ratio" = list(
    dataset = "dat_bcg", type = "Ratio", event_e = "tpos", n_e = "npos",
    event_c = "cpos", n_c = "cneg", study = "author", subgroup = "alloc"
  ),
  "Normand 1999 — mean difference" = list(
    dataset = "dat_normand1999", type = "Continuous",
    mean_e = "m1i", sd_e = "sd1i", n_e = "n1i",
    mean_c = "m2i", sd_c = "sd2i", n_c = "n2i", study = "study"
  )
)

load_package_data <- function(name) {
  env <- new.env(parent = emptyenv())
  utils::data(list = name, package = "metapropul", envir = env)
  as.data.frame(env[[name]], stringsAsFactors = FALSE)
}

column_input <- function(id, label, choices, selected = NULL, optional = FALSE) {
  values <- if (optional) c("None" = "", choices) else choices
  selectInput(id, label, choices = values, selected = selected %||% values[[1]], width = "100%")
}

figure_header <- function(title, id) {
  card_header(div(class = "mp-card-header-row",
    span(title),
    div(class = "mp-inline-export",
      selectInput(paste0(id, "_format"), NULL,
        c("PDF" = "pdf", "PNG" = "png", "SVG" = "svg", "TIFF" = "tiff"),
        width = "92px"),
      downloadButton(paste0("download_", id), "Download", class = "btn-sm")
    )
  ))
}

table_header <- function(title, id) {
  card_header(div(class = "mp-card-header-row",
    span(title),
    div(class = "mp-inline-export",
      selectInput(paste0(id, "_format"), NULL,
        c("Word" = "docx", "CSV" = "csv", "PDF" = "pdf"), width = "92px"),
      downloadButton(paste0("download_", id), "Download", class = "btn-sm")
    )
  ))
}

analysis_fields <- function(type, columns, defaults) {
  study <- column_input("study", "Study label", columns, defaults$study, TRUE)
  # Subgroup analysis must always be an explicit user choice. In particular,
  # bundled examples must not silently opt the user into subgroup pooling.
  subgroup <- column_input("subgroup", "Subgroup (optional; default: None)",
    columns, selected = NULL, optional = TRUE)
  fields <- switch(type,
    "Proportion" = tagList(
      column_input("event", "Events", columns, defaults$event),
      column_input("n", "Total sample", columns, defaults$n), study, subgroup,
      selectInput("prop_sm", "Transformation", c("Logit (recommended)" = "PLOGIT", "Freeman–Tukey" = "PFT"))
    ),
    "Ratio" = tagList(
      radioButtons("ratio_input", "Input format", c(
        "2 × 2 counts" = "raw", "Ratio and 95% CI" = "effect",
        "Log ratio and SE" = "log_se"), inline = TRUE),
      conditionalPanel("input.ratio_input == 'raw'",
        column_input("event_e", "Treatment events", columns, defaults$event_e),
        column_input("n_e", "Treatment total", columns, defaults$n_e),
        column_input("event_c", "Control events", columns, defaults$event_c),
        column_input("n_c", "Control total", columns, defaults$n_c)
      ),
      conditionalPanel("input.ratio_input == 'effect'",
        column_input("effect", "Effect estimate", columns, defaults$effect),
        column_input("lower", "Lower 95% CI", columns, defaults$lower),
        column_input("upper", "Upper 95% CI", columns, defaults$upper)
      ),
      conditionalPanel("input.ratio_input == 'log_se'",
        column_input("effect", "Log effect estimate", columns, defaults$effect),
        column_input("se", "Standard error of log effect", columns, defaults$se)
      ),
      study, subgroup,
      selectInput("ratio_measure", "Effect measure", c("Odds ratio" = "OR", "Risk ratio" = "RR", "Hazard ratio" = "HR"))
    ),
    "Continuous" = tagList(
      radioButtons("mean_input", "Input format", c("Group summaries" = "raw", "Effect and confidence interval" = "effect"), inline = TRUE),
      conditionalPanel("input.mean_input == 'raw'",
        column_input("mean_e", "Treatment mean", columns, defaults$mean_e),
        column_input("sd_e", "Treatment SD", columns, defaults$sd_e),
        column_input("n_e", "Treatment total", columns, defaults$n_e),
        column_input("mean_c", "Control mean", columns, defaults$mean_c),
        column_input("sd_c", "Control SD", columns, defaults$sd_c),
        column_input("n_c", "Control total", columns, defaults$n_c)
      ),
      conditionalPanel("input.mean_input == 'effect'",
        column_input("effect", "Effect estimate", columns, defaults$effect),
        column_input("lower", "Lower 95% CI", columns, defaults$lower),
        column_input("upper", "Upper 95% CI", columns, defaults$upper)
      ),
      study, subgroup,
      selectInput("mean_measure", "Effect measure", c("Mean difference" = "MD", "Standardised mean difference" = "SMD"))
    ),
    "Generic effect" = tagList(
      column_input("effect", "Effect estimate", columns, defaults$effect),
      selectInput("uncertainty_type", "Uncertainty", c("Standard error" = "se", "Variance" = "variance", "95% confidence interval" = "ci")),
      conditionalPanel("input.uncertainty_type == 'se'", column_input("se", "Standard error", columns, defaults$se)),
      conditionalPanel("input.uncertainty_type == 'variance'", column_input("variance", "Variance", columns, defaults$variance)),
      conditionalPanel("input.uncertainty_type == 'ci'",
        column_input("lower", "Lower 95% CI", columns, defaults$lower),
        column_input("upper", "Upper 95% CI", columns, defaults$upper)
      ),
      study, subgroup,
      textInput("generic_measure", "Effect label", "Generic effect"),
      selectInput("backtransform", "Display scale", c("Identity" = "identity", "Exponentiate" = "exp"))
    ),
    "Correlation" = tagList(
      column_input("cor", "Correlation", columns, defaults$cor),
      column_input("n", "Sample size", columns, defaults$n), study, subgroup
    ),
    "Incidence rate" = tagList(
      column_input("event", "Events", columns, defaults$event),
      column_input("time", "Person-time", columns, defaults$time), study, subgroup,
      numericInput("irscale", "Display rate per", 1000, min = .0001),
      textInput("irunit", "Person-time unit", "person-years")
    )
  )
  fields
}

ui <- page_navbar(
  title = "metapropul",
  theme = bs_theme(version = 5, bootswatch = "flatly", primary = "#1f6f8b"),
  header = tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "metapropul.css")),
  nav_panel(
    "Analyse",
    div(class = "container-fluid",
      div(class = "mp-hero",
        h2("Meta-analysis workspace"),
        p("Import study-level data, specify the analysis, and inspect publication-ready outputs generated by metapropul.")
      ),
      layout_sidebar(
        sidebar = sidebar(
          width = 350,
          h5("1. Data"),
          radioButtons("data_source", NULL, c("Example data" = "example", "Upload file" = "upload"), inline = TRUE),
          conditionalPanel("input.data_source == 'example'", selectInput("sample", "Example", names(sample_specs))),
          conditionalPanel("input.data_source == 'upload'",
            fileInput("upload", "CSV or Excel file", accept = c(".csv", ".xls", ".xlsx", "text/csv")),
            checkboxInput("header", "First row contains column names", TRUE),
            selectInput("separator", "CSV separator", c("Comma" = ",", "Semicolon" = ";", "Tab" = "\t")),
            helpText("CSV settings are ignored for Excel workbooks; the first worksheet is imported.")
          ),
          hr(),
          h5("2. Analysis"),
          selectInput("analysis_type", "Outcome type", c("Proportion", "Ratio", "Continuous", "Generic effect", "Correlation", "Incidence rate")),
          uiOutput("analysis_fields"),
          hr(),
          h5("3. Model"),
          selectInput("model", "Pooling model", c("Random effects" = "random", "Fixed effect" = "fixed")),
          conditionalPanel("input.model == 'random'",
            selectInput("tau_method", "Between-study variance", c("REML", "Paule–Mandel" = "PM", "DerSimonian–Laird" = "DL", "ML", "Sidik–Jonkman" = "SJ")),
            selectInput("ci_method", "Random-effects inference", c("Knapp–Hartung" = "HK", "Classic" = "classic", "Kenward–Roger" = "KR"))
          ),
          checkboxInput("prediction", "Show prediction interval", TRUE),
          div(class = "d-grid gap-2",
            actionButton("run", "Run analysis", class = "btn-primary w-100", icon = icon("play")),
            actionButton("start_over", "Start over", icon = icon("rotate-left"),
              class = "btn-outline-secondary w-100")
          )
        ),
        navset_card_underline(
          id = "workflow_tabs",
          nav_panel("1 Data", card(
            card_header("Check your data"),
            p(class = "mp-note", "Confirm that the selected columns contain the expected study-level values before running the analysis."),
            uiOutput("input_guide"),
            downloadButton("download_input_template", "Download CSV template", class = "btn-outline-primary btn-sm"),
            hr(), tableOutput("data_preview"), card_footer(textOutput("data_status"))
          )),
          nav_panel("2 Results",
            uiOutput("analysis_status"),
            layout_columns(
              card(card_header("Model summary"), verbatimTextOutput("summary", placeholder = TRUE)),
              card(card_header("Audit trail"), verbatimTextOutput("audit", placeholder = TRUE)),
              col_widths = c(8, 4)
            )
          ),
          nav_panel("3 Forest plot",
            card(
              card_header("Forest plot"),
              textInput("plot_title", "Optional plot title", placeholder = "No title by default"),
              layout_columns(
                selectInput("plot_format", "Download format", c(
                  "PDF" = "pdf", "PNG" = "png", "SVG" = "svg", "TIFF" = "tiff"
                )),
                div(class = "mp-download-action",
                  downloadButton("download_plot", "Download forest plot", class = "btn-primary")),
                col_widths = c(4, 4)
              ),
              plotOutput("forest", height = "auto")
            )
          ),
          nav_panel("4 Table",
            card(card_header("Meta-analysis table"),
              layout_columns(
                selectInput("table_format", "Download format", c(
                  "Word document" = "docx", "CSV data" = "csv", "PDF" = "pdf"
                )),
                div(class = "mp-download-action",
                  downloadButton("download_table", "Download table", class = "btn-primary")),
                col_widths = c(4, 4)
              ),
              htmlOutput("meta_table")
            )
          ),
          nav_panel("5 Subgroups",
            card(
              table_header("Subgroup meta-analysis", "subgroups"),
              p(class = "mp-note", "Available when a subgroup column was selected before fitting. Estimates and the formal test for subgroup differences are reported without re-fitting the model."),
              uiOutput("subgroup_message"),
              htmlOutput("subgroup_table")
            )
          ),
          nav_panel("6 Influence",
            p(class = "mp-note", "Leave-one-out analysis repeats the meta-analysis after omitting one study at a time. Use it to assess robustness, not as an automatic study-exclusion rule."),
            card(figure_header("Leave-one-out forest plot", "influence"), plotOutput("influence", height = "auto")),
            card(table_header("Leave-one-out estimates", "influence_table"), htmlOutput("influence_table"))
          ),
          nav_panel("7 Cumulative",
            p(class = "mp-note", "Studies are added in their current row order. Sort the uploaded data by year before fitting when a chronological cumulative analysis is intended."),
            card(figure_header("Cumulative forest plot", "cumulative"), plotOutput("cumulative", height = "auto")),
            card(table_header("Cumulative estimates", "cumulative_table"), htmlOutput("cumulative_table"))
          ),
          nav_panel("8 Heterogeneity",
            p(class = "mp-note", "Diagnostics become available after a successful analysis. Publication-bias tests are interpreted cautiously when fewer than 10 studies are available."),
            layout_columns(
              card(figure_header("Heterogeneity", "heterogeneity"), plotOutput("heterogeneity", height = 430)),
              card(figure_header("Baujat contribution plot", "baujat"), plotOutput("baujat", height = 430)),
              col_widths = c(6, 6)
            )
          ),
          nav_panel("9 Publication bias",
            p(class = "mp-note", "Funnel asymmetry methods are exploratory and are generally underpowered with fewer than 10 studies."),
            layout_columns(
              radioButtons("bias_display", "Display", c("One method" = "single", "All four (2 × 2)" = "all"), inline = TRUE),
              conditionalPanel("input.bias_display == 'single'", selectInput("bias_plot_method", "Funnel plot", c(
                "Original" = "original", "Contour enhanced" = "contour",
                "Trim and fill" = "trimfill", "Limit meta-analysis" = "limitmeta"
              ))),
              actionButton("run_bias", "Run publication-bias assessment", class = "btn-primary align-self-end"),
              col_widths = c(3, 5, 4)
            ),
            uiOutput("bias_status"),
            card(table_header("Assessment availability", "bias_table"), htmlOutput("bias_table")),
            layout_columns(
              card(figure_header("Funnel plot assessment", "bias_plot"), plotOutput("bias_plot", height = "auto")),
              card(figure_header("DOI plot (small meta-analyses)", "doi"), plotOutput("doi", height = 650)),
              col_widths = c(7, 5)
            )
          ),
          nav_panel("10 Meta-regression",
            p(class = "mp-note", "Specify moderators using R formula syntax, for example: ablat + alloc or ablat * alloc. A study-label column is required for safe matching."),
            layout_columns(
              textInput("moderators", "Moderators", placeholder = "ablat + alloc"),
              selectInput("reg_test", "Inference", c("Wald z" = "z", "Knapp–Hartung" = "knha")),
              numericInput("min_studies_parameter", "Minimum studies per parameter", 10, min = 2, step = 1),
              col_widths = c(6, 3, 3)
            ),
            layout_columns(
              uiOutput("reg_preprocess"),
              actionButton("run_reg", "Run meta-regression", class = "btn-primary align-self-end"),
              col_widths = c(8, 4)
            ),
            uiOutput("reg_status"),
            card(table_header("Coefficients and joint moderator test", "reg_table"), htmlOutput("reg_table")),
            card(
              table_header("Predictions at selected moderator values", "reg_predictions"),
              p(class = "mp-note", "Upload a CSV or Excel file containing one row per desired moderator combination and the same moderator column names used in the model."),
              fileInput("reg_predict_upload", "Prediction-values file", accept = c(".csv", ".xls", ".xlsx")),
              downloadButton("download_reg_prediction_template", "Download moderator template", class = "btn-outline-primary btn-sm"),
              tableOutput("reg_predictions")
            ),
            layout_columns(
              card(figure_header("Moderator/bubble plot", "reg_bubble"), plotOutput("reg_bubble", height = 430)),
              card(figure_header("Residual diagnostics", "reg_residual"), plotOutput("reg_residual", height = 430)),
              col_widths = c(6, 6)
            ),
            card(table_header("Influence and collinearity diagnostics", "reg_diagnostics"), verbatimTextOutput("reg_diagnostics"))
          ),
          nav_panel("11 R code", card(
            card_header("Equivalent reproducible R call"),
            p(class = "mp-note", "Copy this call into an R script to reproduce the selected analysis outside the app."),
            verbatimTextOutput("code", placeholder = TRUE)
          ))
        )
      )
    )
  ),
  nav_panel(
    "Risk of bias",
    div(class = "container-fluid py-4",
      div(class = "mp-hero", h2("Risk-of-bias figures"),
        p("Upload study-level judgements and create validated traffic-light and summary plots.")),
      layout_sidebar(
        sidebar = sidebar(
          width = 350,
          fileInput("rob_upload", "Risk-of-bias file", accept = c(".csv", ".xls", ".xlsx")),
          helpText("Expected layout: one row per study, one study-label column, and one column per ROB domain. Labels must match the primary meta-analysis for the combined forest + ROB figure."),
          selectInput("rob_tool", "Appraisal tool", c(
            "Generic" = "GENERIC", "RoB 2" = "ROB2", "ROBINS-I" = "ROBINS-I",
            "QUADAS-2" = "QUADAS2", "QUIPS" = "QUIPS", "ROBIS" = "ROBIS",
            "AMSTAR 2" = "AMSTAR2", "Newcastle–Ottawa Scale" = "NOS"
          )),
          downloadButton("download_rob_template", "Download ROB template", class = "btn-outline-primary btn-sm w-100"),
          uiOutput("rob_mapping"),
          actionButton("run_rob", "Validate and plot", class = "btn-primary w-100")
        ),
        navset_card_underline(
          nav_panel("Data", card(card_header("Uploaded judgements"), tableOutput("rob_preview"))),
          nav_panel("Traffic light", uiOutput("rob_status"), card(figure_header("Traffic-light plot", "rob_traffic"), plotOutput("rob_traffic", height = 600))),
          nav_panel("Forest + ROB", uiOutput("forest_rob_status"), card(figure_header("Forest plot with risk-of-bias traffic lights", "forest_rob"), plotOutput("forest_rob", height = "auto"))),
          nav_panel("Summary", card(figure_header("Risk-of-bias summary", "rob_summary"), plotOutput("rob_summary", height = 500))),
          nav_panel("Validation", card(table_header("Validation frequencies", "rob_validation"), verbatimTextOutput("rob_validation")))
        )
      )
    )
  ),
  nav_panel(
    "Umbrella review",
    div(class = "container-fluid py-4",
      div(class = "mp-hero", h2("Non-pooling umbrella-review workspace"),
        p("Preserve each published meta-analysis estimate, assess credibility, and examine primary-study overlap without calculating a revised pooled estimate.")),
      navset_card_underline(
        nav_panel("Review results",
          layout_sidebar(
            sidebar = sidebar(
              width = 360,
              fileInput("umbrella_upload", "Review-results file", accept = c(".csv", ".xls", ".xlsx")),
              helpText("Required: outcome, review, effect, lower and upper. One row is one reported meta-analysis result; reviews are not pooled together."),
              downloadButton("download_umbrella_template", "Download review-results template", class = "btn-outline-primary btn-sm w-100"),
              uiOutput("umbrella_mapping"),
              selectInput("umbrella_scale", "Effect scale", c("Ratio (OR, RR, HR)" = "ratio", "Identity (MD, SMD)" = "identity")),
              selectInput("quality_tool", "Review-quality tool", c("AMSTAR 2" = "AMSTAR2", "ROBIS" = "ROBIS")),
              selectInput("grade_start", "GRADE starting certainty", c("High" = "high", "Moderate" = "moderate", "Low" = "low", "Very low" = "very_low")),
              selectInput("grade_rob", "GRADE risk of bias", c("Not serious" = "not_serious", "Serious" = "serious", "Very serious" = "very_serious")),
              selectInput("grade_inconsistency", "GRADE inconsistency", c("Not serious" = "not_serious", "Serious" = "serious", "Very serious" = "very_serious")),
              actionButton("run_umbrella", "Build umbrella review", class = "btn-primary w-100")
            ),
            div(
              uiOutput("umbrella_status"),
              card(table_header("Reported meta-analysis results", "umbrella_table"), htmlOutput("umbrella_table")),
              card(table_header("Review quality and GRADE audit", "umbrella_appraisal"), verbatimTextOutput("umbrella_appraisal")),
              card(figure_header("Umbrella plot", "umbrella_plot"), plotOutput("umbrella_plot", height = 650))
            )
          )
        ),
        nav_panel("Study overlap / CCA",
          layout_sidebar(
            sidebar = sidebar(
              width = 360,
              fileInput("overlap_upload", "Review–study membership file", accept = c(".csv", ".xls", ".xlsx")),
              helpText("Long format: one row per review–primary-study membership. Outcome and TRUE/FALSE inclusion columns are optional."),
              downloadButton("download_overlap_template", "Download overlap template", class = "btn-outline-primary btn-sm w-100"),
              uiOutput("overlap_mapping"),
              selectInput("overlap_plot_type", "Display", c(
                "CCA matrix" = "cca", "CCA summary" = "cca_summary",
                "Citation matrix" = "citation_matrix", "Jaccard matrix" = "jaccard"
              )),
              selectInput("sensitivity_strategies", "Review-selection sensitivity", c(
                "Most comprehensive" = "most_comprehensive",
                "Largest participant count" = "largest_participant_count",
                "Highest quality" = "highest_quality",
                "Lowest overlap" = "lowest_overlap"
              ), multiple = TRUE, selected = c("most_comprehensive", "lowest_overlap")),
              actionButton("run_overlap", "Calculate overlap", class = "btn-primary w-100")
            ),
            div(
              uiOutput("overlap_status"),
              card(table_header("Overlap statistics", "overlap_summary"), verbatimTextOutput("overlap_summary")),
              card(table_header("Review-selection sensitivity", "overlap_sensitivity"), tableOutput("overlap_sensitivity")),
              card(figure_header("Overlap plot", "overlap_plot"), plotOutput("overlap_plot", height = 700))
            )
          )
        ),
        nav_panel("Primary-study diagnostics",
          layout_sidebar(
            sidebar = sidebar(
              width = 360,
              fileInput("primary_upload", "Primary-study estimates file", accept = c(".csv", ".xls", ".xlsx")),
              helpText("Required: outcome, source review, primary study, effect, lower and upper. Each source review needs at least two unique primary studies."),
              downloadButton("download_primary_template", "Download diagnostics template", class = "btn-outline-primary btn-sm w-100"),
              uiOutput("primary_mapping"),
              selectInput("primary_scale", "Effect scale", c("Ratio" = "ratio", "Identity" = "identity")),
              actionButton("run_primary", "Run within-review diagnostics", class = "btn-primary w-100")
            ),
            div(
              p(class = "mp-note", "Diagnostics are reconstructed separately within each source review. Primary studies from different reviews are never pooled together."),
              uiOutput("primary_status"),
              card(table_header("Largest-study, small-study and excess-significance diagnostics", "primary_table"), tableOutput("primary_table"))
            )
          )
        )
      )
    )
  ),
  nav_panel(
    "About",
    div(class = "container py-4",
      card(card_header("About this interface"),
        p("This application is a graphical front end to metapropul. Analyses use the package's exported functions, so results are reproducible in an ordinary R script."),
        tags$ul(
          tags$li("No data are sent outside the running R session."),
          tags$li("Plot titles are optional and blank by default."),
          tags$li("Subgroup variables are passed directly to the validated package workflow."),
          tags$li("Use the generated code as the starting point for a scripted analysis.")
        )
      )
    )
  ),
  nav_item(actionButton("close_app", "Close app", icon = icon("power-off"),
    class = "btn-danger mp-close-floating"))
)

server <- function(input, output, session) {
  defaults <- reactiveVal(sample_specs[[1]])

  read_uploaded_file <- function(file, header = TRUE, separator = ",") {
    req(file)
    extension <- tolower(tools::file_ext(file$name %||% ""))
    if (extension %in% c("xls", "xlsx")) {
      if (!requireNamespace("readxl", quietly = TRUE)) {
        stop("Install the 'readxl' package to import Excel workbooks.", call. = FALSE)
      }
      return(as.data.frame(
        readxl::read_excel(file$datapath, sheet = 1, col_names = isTRUE(header)),
        stringsAsFactors = FALSE, check.names = FALSE
      ))
    }
    if (!extension %in% c("csv", "txt", "tsv")) {
      stop("Upload a .csv, .xls, or .xlsx file.", call. = FALSE)
    }
    utils::read.table(file$datapath, header = isTRUE(header), sep = separator,
      quote = "\"", comment.char = "", check.names = FALSE,
      stringsAsFactors = FALSE)
  }

  open_plot_device <- function(file, format, width, height) {
    if (format == "pdf") {
      grDevices::pdf(file, width = width, height = height)
    } else if (format == "svg") {
      grDevices::svg(file, width = width, height = height)
    } else if (format == "png") {
      grDevices::png(file, width = width, height = height, units = "in", res = 300)
    } else {
      args <- list(filename = file, width = width, height = height,
        units = "in", res = 300)
      if (Sys.info()[["sysname"]] != "Darwin") args$compression <- "lzw"
      do.call(grDevices::tiff, args)
    }
  }

  register_plot_download <- function(id, draw, width = 9, height = 7) {
    output[[paste0("download_", id)]] <- downloadHandler(
      filename = function() paste0("metapropul-", gsub("_", "-", id), "-",
        Sys.Date(), ".", input[[paste0(id, "_format")]] %||% "pdf"),
      content = function(file) {
        format <- input[[paste0(id, "_format")]] %||% "pdf"
        resolved_height <- if (is.function(height)) height() else height
        open_plot_device(file, format, width, resolved_height)
        on.exit(grDevices::dev.off(), add = TRUE)
        value <- draw()
        if (inherits(value, c("gg", "ggplot"))) print(value)
      }
    )
  }

  register_table_download <- function(id, value) {
    output[[paste0("download_", id)]] <- downloadHandler(
      filename = function() paste0("metapropul-", gsub("_", "-", id), "-",
        Sys.Date(), ".", input[[paste0(id, "_format")]] %||% "docx"),
      content = function(file) {
        format <- input[[paste0(id, "_format")]] %||% "docx"
        object <- value()
        if (format == "csv") {
          data <- if (inherits(object, "gt_tbl")) object[["_data"]] else object
          utils::write.csv(as.data.frame(data), file, row.names = FALSE, na = "")
        } else {
          table <- if (inherits(object, "gt_tbl")) object else gt::gt(object)
          gt::gtsave(table, filename = file)
        }
      }
    )
  }

  observeEvent(input$start_over, {
    showModal(modalDialog(
      title = "Start a new analysis?",
      "This clears the current selections and results, then reloads the example workflow.",
      footer = tagList(
        modalButton("Cancel"),
        actionButton("confirm_reset", "Start over", class = "btn-primary")
      ),
      easyClose = TRUE
    ))
  })

  observeEvent(input$confirm_reset, {
    removeModal()
    session$reload()
  })

  observeEvent(input$close_app, {
    shiny::stopApp(invisible(NULL))
  })

  input_data <- reactive({
    if (identical(input$data_source, "upload")) {
      req(input$upload)
      tryCatch(
        read_uploaded_file(input$upload, header = input$header,
          separator = input$separator),
        error = function(e) stop("Could not read the uploaded file: ",
          conditionMessage(e), call. = FALSE)
      )
    } else {
      spec <- sample_specs[[input$sample %||% names(sample_specs)[1]]]
      load_package_data(spec$dataset)
    }
  })

  observeEvent(input$sample, {
    spec <- sample_specs[[input$sample]]
    defaults(spec)
    updateSelectInput(session, "analysis_type", selected = spec$type)
  }, ignoreInit = FALSE)

  observeEvent(input$data_source, {
    if (identical(input$data_source, "upload")) defaults(list())
  })

  output$analysis_fields <- renderUI({
    dat <- input_data()
    analysis_fields(input$analysis_type, names(dat), defaults())
  })

  output$data_preview <- renderTable({
    head(input_data(), 12)
  }, striped = TRUE, hover = TRUE, spacing = "s", width = "100%")

  output$data_status <- renderText({
    dat <- input_data()
    paste(nrow(dat), "rows and", ncol(dat), "columns. Preview shows the first 12 rows.")
  })

  input_schema <- reactive({
    type <- input$analysis_type %||% "Proportion"
    optional_cols <- c("study", "subgroup")
    required <- switch(type,
      "Proportion" = c("event", "n"),
      "Ratio" = switch(input$ratio_input %||% "raw",
        raw = c("event_e", "n_e", "event_c", "n_c"),
        effect = c("effect", "lower", "upper"),
        log_se = c("log_effect", "se")),
      "Continuous" = if (identical(input$mean_input, "effect"))
        c("effect", "lower", "upper") else
        c("mean_e", "sd_e", "n_e", "mean_c", "sd_c", "n_c"),
      "Generic effect" = switch(input$uncertainty_type %||% "se",
        se = c("effect", "se"), variance = c("effect", "variance"),
        ci = c("effect", "lower", "upper")),
      "Correlation" = c("cor", "n"),
      "Incidence rate" = c("event", "person_time")
    )
    note <- switch(type,
      "Proportion" = "event must be between 0 and n; n must be positive.",
      "Ratio" = switch(input$ratio_input %||% "raw",
        raw = "Use treatment and control event counts. OR and RR can be calculated; HR cannot.",
        effect = "Enter OR, RR, or HR and its confidence limits on the ratio scale; every value must be positive.",
        log_se = "Enter log(OR), log(RR), or log(HR) and its standard error—not the ratio itself."),
      "Continuous" = if (identical(input$mean_input, "effect"))
        "Enter an MD or SMD and confidence limits on the same scale." else
        "SDs and sample sizes must be positive; use one row per independent study comparison.",
      "Generic effect" = "Effects must be on the analysis scale. Choose Exponentiate when supplying log-ratio effects.",
      "Correlation" = "Correlations must be strictly between -1 and 1 and sample sizes must exceed 3.",
      "Incidence rate" = "Events must be non-negative and person-time must be positive."
    )
    list(required = required, optional = optional_cols, note = note)
  })

  output$input_guide <- renderUI({
    schema <- input_schema()
    div(class = "alert alert-info",
      tags$strong("Expected spreadsheet columns"),
      tags$p(paste("Required:", paste(schema$required, collapse = ", "))),
      tags$p(paste("Optional:", paste(schema$optional, collapse = ", "))),
      tags$p(schema$note),
      tags$small("Column names may differ: upload the file, then map each header using the controls on the left. Keep one study/comparison per row."))
  })

  output$download_input_template <- downloadHandler(
    filename = function() paste0("metapropul-", tolower(gsub(" ", "-", input$analysis_type)), "-template.csv"),
    content = function(file) {
      schema <- input_schema()
      headers <- c(schema$optional, schema$required)
      example_values <- list(
        study = c("Study 1", "Study 2"), subgroup = c("Group A", "Group B"),
        event = c(10, 15), event_e = c(10, 15), event_c = c(18, 20),
        n = c(100, 120), n_e = c(100, 120), n_c = c(100, 125),
        effect = c(0.80, 1.20), log_effect = c(-0.223, 0.182),
        lower = c(0.60, 0.90), upper = c(1.07, 1.60), se = c(0.10, 0.12),
        variance = c(0.01, 0.0144), mean_e = c(12.1, 10.8),
        sd_e = c(3.2, 2.9), mean_c = c(14.0, 12.2), sd_c = c(3.5, 3.1),
        cor = c(0.25, 0.40), person_time = c(1250, 1780)
      )
      values <- stats::setNames(lapply(headers, function(header) {
        example_values[[header]] %||% c(1, 2)
      }), headers)
      utils::write.csv(as.data.frame(values, check.names = FALSE), file, row.names = FALSE)
    }
  )

  output$download_reg_prediction_template <- downloadHandler(
    filename = function() "metapropul-meta-regression-predictions.csv",
    content = function(file) {
      object <- reg_fit()
      variables <- object$moderator_variables
      template <- lapply(object$model_data[variables], function(x) {
        values <- unique(x[!is.na(x)])
        if (!length(values)) return(c(NA, NA))
        rep(values, length.out = 2L)
      })
      utils::write.csv(as.data.frame(template, check.names = FALSE), file,
        row.names = FALSE, na = "")
    }
  )

  rob_template <- reactive({
    definitions <- list(
      ROB2 = list(domains = c("Randomization process", "Deviations from intended interventions",
        "Missing outcome data", "Measurement of the outcome", "Selection of the reported result", "Overall"),
        values = c("Low", "Some concerns")),
      `ROBINS-I` = list(domains = c("Confounding", "Selection of participants",
        "Classification of interventions", "Deviations from intended interventions",
        "Missing data", "Measurement of outcomes", "Selection of reported result", "Overall"),
        values = c("Low", "Moderate")),
      QUADAS2 = list(domains = c("Patient selection", "Index test", "Reference standard",
        "Flow and timing", "Applicability: patient selection", "Applicability: index test",
        "Applicability: reference standard"), values = c("Low", "Unclear")),
      QUIPS = list(domains = c("Study participation", "Study attrition",
        "Prognostic factor measurement", "Outcome measurement", "Study confounding",
        "Statistical analysis and reporting", "Overall"), values = c("Low", "Moderate")),
      ROBIS = list(domains = c("Study eligibility criteria", "Identification and selection of studies",
        "Data collection and study appraisal", "Synthesis and findings", "Overall"),
        values = c("Low", "Unclear")),
      AMSTAR2 = list(domains = c("Domain 1", "Domain 2", "Overall"),
        values = c("High", "Moderate")),
      NOS = list(domains = c("Selection", "Comparability", "Outcome", "Overall"),
        values = c("Good", "Fair")),
      GENERIC = list(domains = c("Domain 1", "Domain 2", "Overall"),
        values = c("Low", "Some concerns"))
    )
    definition <- definitions[[input$rob_tool %||% "GENERIC"]]
    values <- c(list(study = c("Study 1", "Study 2")),
      stats::setNames(lapply(definition$domains,
        function(x) definition$values), definition$domains))
    as.data.frame(values, check.names = FALSE)
  })

  output$download_rob_template <- downloadHandler(
    filename = function() paste0("metapropul-rob-",
      tolower(gsub("[^A-Za-z0-9]+", "-", input$rob_tool %||% "generic")), ".csv"),
    content = function(file) utils::write.csv(rob_template(), file,
      row.names = FALSE, na = "")
  )

  output$download_umbrella_template <- downloadHandler(
    filename = function() "metapropul-umbrella-review-results.csv",
    content = function(file) utils::write.csv(data.frame(
      outcome = c("Mortality", "Mortality"), review = c("Review A", "Review B"),
      effect = c(0.80, 0.92), lower = c(0.68, 0.78), upper = c(0.94, 1.08),
      measure = c("RR", "RR"), studies = c(12, 8), participants = c(5400, 3200),
      i2 = c(42, 58), p_value = c(0.004, 0.23), year = c(2024, 2022),
      quality = c("High", "Moderate"), certainty = c("Moderate", "Low"),
      check.names = FALSE), file, row.names = FALSE, na = "")
  )

  output$download_overlap_template <- downloadHandler(
    filename = function() "metapropul-review-study-overlap.csv",
    content = function(file) utils::write.csv(data.frame(
      review = c("Review A", "Review A", "Review B", "Review B"),
      primary_study = c("Study 1", "Study 2", "Study 1", "Study 3"),
      outcome = rep("Mortality", 4), included = c(TRUE, TRUE, TRUE, TRUE)),
      file, row.names = FALSE, na = "")
  )

  output$download_primary_template <- downloadHandler(
    filename = function() "metapropul-primary-study-diagnostics.csv",
    content = function(file) utils::write.csv(data.frame(
      outcome = rep("Mortality", 4), review = rep("Review A", 4),
      primary_study = paste("Study", 1:4), effect = c(0.75, 0.90, 0.82, 1.05),
      lower = c(0.58, 0.70, 0.64, 0.80), upper = c(0.97, 1.16, 1.05, 1.38),
      participants = c(900, 650, 720, 480)), file, row.names = FALSE, na = "")
  )

  optional <- function(value) if (is.null(value) || !nzchar(value)) NULL else value

  analysis_call <- reactive({
    req(input$analysis_type)
    common <- list(
      data = input_data(), studylab = optional(input$study), subgroup = optional(input$subgroup),
      model = input$model, tau_method = input$tau_method %||% "REML",
      ci_method = input$ci_method %||% "HK", prediction_interval = isTRUE(input$prediction)
    )
    switch(input$analysis_type,
      "Proportion" = list(fun = "meta_prop", args = c(common, list(event = input$event, n = input$n, sm = input$prop_sm))),
      "Ratio" = {
        specific <- switch(input$ratio_input,
          effect = list(effect = input$effect, lower = input$lower,
            upper = input$upper, effect_scale = "ratio"),
          log_se = list(effect = input$effect, se = input$se,
            effect_scale = "log"),
          list(event.e = input$event_e, n.e = input$n_e,
            event.c = input$event_c, n.c = input$n_c))
        list(fun = "meta_ratio", args = c(common, specific, list(measure = input$ratio_measure)))
      },
      "Continuous" = {
        specific <- if (identical(input$mean_input, "effect"))
          list(effect = input$effect, lower = input$lower, upper = input$upper) else
          list(mean.e = input$mean_e, sd.e = input$sd_e, n.e = input$n_e,
            mean.c = input$mean_c, sd.c = input$sd_c, n.c = input$n_c)
        list(fun = "meta_mean", args = c(common, specific, list(measure = input$mean_measure)))
      },
      "Generic effect" = {
        uncertainty <- switch(input$uncertainty_type,
          se = list(se = input$se), variance = list(variance = input$variance),
          ci = list(lower = input$lower, upper = input$upper))
        list(fun = "meta_generic", args = c(common, list(effect = input$effect), uncertainty,
          list(measure = input$generic_measure, backtransform = input$backtransform)))
      },
      "Correlation" = list(fun = "meta_cor", args = c(common, list(cor = input$cor, n = input$n))),
      "Incidence rate" = list(fun = "meta_rate", args = c(common,
        list(event = input$event, time = input$time, irscale = input$irscale, irunit = input$irunit)))
    )
  })

  fit_state <- eventReactive(input$run, {
    call <- analysis_call()
    warnings <- character()
    value <- withCallingHandlers(
      tryCatch(do.call(mp_fun(call$fun), call$args), error = function(e) e),
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    )
    list(value = value, warnings = unique(warnings), call = call)
  }, ignoreInit = TRUE)

  observeEvent(input$run, {
    state <- fit_state()
    if (inherits(state$value, "error")) {
      showNotification(
        paste("Analysis could not be completed:", conditionMessage(state$value)),
        type = "error", duration = 8
      )
    } else {
      showNotification(
        paste("Analysis complete:", state$value$meta$k, "studies included."),
        type = "message", duration = 5
      )
      bslib::nav_select("workflow_tabs", "2 Results", session = session)
    }
  }, ignoreInit = TRUE)

  fit <- reactive({
    state <- fit_state()
    error_message <- if (inherits(state$value, "error")) conditionMessage(state$value) else ""
    validate(need(!inherits(state$value, "error"), error_message))
    state$value
  })

  output$analysis_status <- renderUI({
    state <- fit_state()
    if (inherits(state$value, "error")) div(class = "mp-error", strong("Analysis failed: "), conditionMessage(state$value))
    else div(class = "mp-status", strong("Analysis complete. "), paste(state$value$meta$k, "studies were included."))
  })

  output$summary <- renderPrint(summary(fit()))

  output$audit <- renderPrint({
    state <- fit_state()
    cat("Analysis:", state$call$fun, "\n")
    cat("Rows supplied:", nrow(input_data()), "\n")
    cat("Studies fitted:", state$value$meta$k, "\n")
    if (length(state$warnings)) cat("\nWarnings:\n-", paste(state$warnings, collapse = "\n- "), "\n")
    if (!is.null(state$value$excluded)) {
      cat("Excluded:", length(state$value$excluded), "\n")
    }
  })

  plot_height <- reactive({
    req(fit())
    max(520, min(4200, 250 + 30 * (fit()$meta$k %||% 10)))
  })
  output$forest <- renderPlot({
    mp_fun("forest_meta")(fit(), title = optional(input$plot_title))
  }, height = function() plot_height(), res = 110)
  outputOptions(output, "forest", suspendWhenHidden = FALSE)

  output$meta_table <- renderUI({
    tbl <- mp_fun("table_meta")(fit(), title = NULL)
    HTML(gt::as_raw_html(tbl))
  })

  output$subgroup_message <- renderUI({
    req(fit())
    if (is.null(fit()$meta.subgroup.summary) || !nrow(fit()$meta.subgroup.summary)) {
      div(class = "mp-empty", icon("circle-info"), " No subgroup analysis is present. Select a subgroup column and run the primary analysis again.")
    }
  })

  output$subgroup_table <- renderUI({
    req(fit())
    validate(need(inherits(fit(), c("meta_ratio", "meta_mean", "meta_prop")),
      "Subgroup tables are currently available for ratio, continuous, and proportion models."))
    validate(need(!is.null(fit()$meta.subgroup.summary) && nrow(fit()$meta.subgroup.summary),
      "No subgroup analysis is present in this model."))
    HTML(gt::as_raw_html(mp_fun("table_subgroups")(fit(), title = NULL)))
  })

  output$influence_table <- renderUI({
    HTML(gt::as_raw_html(mp_fun("table_influence")(fit(), title = NULL)))
  })

  output$cumulative <- renderPlot({
    mp_fun("forest_cumulative")(fit(), title = NULL)
  }, height = function() plot_height(), res = 105)

  output$cumulative_table <- renderUI({
    HTML(gt::as_raw_html(mp_fun("table_cumulative_meta")(fit(), title = NULL)))
  })

  output$heterogeneity <- renderPlot({
    mp_fun("plot_heterogeneity")(fit(), title = NULL)
  }, res = 105)

  output$baujat <- renderPlot({
    mp_fun("plot_baujat")(fit(), title = NULL)
  }, res = 105)

  output$influence <- renderPlot({
    mp_fun("forest_influence")(fit(), title = NULL)
  }, height = function() plot_height(), res = 105)

  bias_state <- eventReactive(input$run_bias, {
    req(fit())
    tryCatch(mp_fun("publication_bias")(fit(), plot_method = NULL, title = NULL),
      error = function(e) e)
  }, ignoreInit = TRUE)

  bias_methods <- reactive({
    if (identical(input$bias_display, "all")) {
      c("original", "contour", "trimfill", "limitmeta")
    } else {
      input$bias_plot_method %||% "original"
    }
  })

  output$bias_status <- renderUI({
    result <- bias_state()
    if (inherits(result, "error")) {
      div(class = "mp-error", conditionMessage(result))
    } else {
      div(class = "mp-status", "Publication-bias assessment completed. Interpret asymmetry alongside clinical and methodological differences between studies.")
    }
  })

  output$bias_table <- renderUI({
    result <- bias_state()
    message <- if (inherits(result, "error")) conditionMessage(result) else ""
    validate(need(!inherits(result, "error"), message))
    HTML(gt::as_raw_html(mp_fun("table_publication_bias")(result, title = NULL)))
  })

  output$bias_plot <- renderPlot({
    req(bias_state())
    validate(need(!inherits(bias_state(), "error"), "Publication-bias assessment was not available."))
    mp_fun("publication_bias")(
      fit(), plot_method = bias_methods(), title = NULL
    )
  }, height = function() if (identical(input$bias_display, "all")) 900 else 650,
  res = 105)

  output$doi <- renderPlot({
    req(bias_state())
    validate(need(!inherits(bias_state(), "error"), "Publication-bias assessment was not available."))
    validate(need(inherits(fit(), c("meta_ratio", "meta_mean", "meta_prop")),
      "DOI plots support ratio, continuous, and proportion models."))
    validate(need(fit()$meta$k < 10,
      "DOI plots are intended for fewer than 10 studies; use the funnel assessment for this model."))
    mp_fun("doi_plot")(fit(), title = NULL)
  }, res = 105)

  output$reg_preprocess <- renderUI({
    dat <- input_data()
    numeric_columns <- names(dat)[vapply(dat, is.numeric, logical(1))]
    tagList(
      selectInput("reg_center", "Centre continuous moderators (optional)",
        choices = numeric_columns, multiple = TRUE),
      selectInput("reg_scale", "Standardise continuous moderators (optional)",
        choices = numeric_columns, multiple = TRUE)
    )
  })

  reg_state <- eventReactive(input$run_reg, {
    req(fit(), input$moderators)
    if (!nzchar(trimws(input$moderators))) {
      return(simpleError("Enter at least one moderator."))
    }
    if (is.null(input$study) || !nzchar(input$study)) {
      return(simpleError("Select a study-label column before fitting meta-regression."))
    }
    formula <- tryCatch(stats::as.formula(paste("~", input$moderators)),
      error = function(e) e)
    if (inherits(formula, "error")) return(formula)
    tryCatch(mp_fun("meta_reg")(
      meta_object = fit(), data = input_data(), moderators = formula,
      studylab = input$study,
      center = if (length(input$reg_center)) input$reg_center else NULL,
      scale = if (length(input$reg_scale)) input$reg_scale else NULL,
      test = input$reg_test,
      min_studies_per_parameter = input$min_studies_parameter
    ), error = function(e) e)
  }, ignoreInit = TRUE)

  reg_fit <- reactive({
    result <- reg_state()
    error_message <- if (inherits(result, "error")) conditionMessage(result) else ""
    validate(need(!inherits(result, "error"), error_message))
    result
  })

  output$reg_status <- renderUI({
    result <- reg_state()
    if (inherits(result, "error")) {
      div(class = "mp-error", strong("Meta-regression failed: "), conditionMessage(result))
    } else {
      div(class = "mp-status", strong("Meta-regression complete. "),
        paste(result$meta$k, "studies and", length(result$moderator_variables), "moderator variables analysed."))
    }
  })

  output$reg_table <- renderUI({
    HTML(gt::as_raw_html(mp_fun("table_meta_reg")(reg_fit(), title = NULL)))
  })

  output$reg_bubble <- renderPlot({
    object <- reg_fit()
    numeric_mods <- object$moderator_variables[
      vapply(object$model_data[object$moderator_variables], is.numeric, logical(1))
    ]
    validate(need(length(numeric_mods), "A bubble plot requires at least one continuous moderator."))
    print(mp_fun("plot_meta_reg")(object, type = "bubble", moderator = numeric_mods[1], title = NULL))
  }, res = 105)

  output$reg_residual <- renderPlot({
    print(mp_fun("plot_meta_reg")(reg_fit(), type = "residual", title = NULL))
  }, res = 105)

  output$reg_diagnostics <- renderPrint({
    diagnostics <- mp_fun("diagnose_meta_reg")(reg_fit())
    cat("Collinearity\n")
    print(diagnostics$collinearity)
    cat("\nPotentially influential studies\n")
    print(diagnostics$studies[diagnostics$studies$influential, , drop = FALSE])
  })

  output$reg_predictions <- renderTable({
    req(reg_fit(), input$reg_predict_upload)
    newdata <- read_uploaded_file(input$reg_predict_upload)
    mp_fun("predict_meta_reg")(reg_fit(), newdata = newdata)
  }, digits = 4, striped = TRUE, hover = TRUE)

  rob_data <- reactive(read_uploaded_file(input$rob_upload))
  output$rob_mapping <- renderUI({
    columns <- names(rob_data())
    tagList(
      column_input("rob_study", "Study label", columns),
      selectInput("rob_domains", "Judgement domains", choices = columns,
        selected = columns[-1], multiple = TRUE)
    )
  })
  output$rob_preview <- renderTable(head(rob_data(), 12), striped = TRUE, spacing = "s")

  rob_state <- eventReactive(input$run_rob, {
    req(input$rob_study, input$rob_domains)
    tryCatch(mp_fun("validate_rob")(
      rob_data(), studylab = input$rob_study, tool = input$rob_tool,
      domains = input$rob_domains
    ), error = function(e) e)
  }, ignoreInit = TRUE)

  output$rob_status <- renderUI({
    result <- rob_state()
    if (inherits(result, "error")) div(class = "mp-error", conditionMessage(result))
    else div(class = "mp-status", "Judgements validated successfully.")
  })
  output$rob_traffic <- renderPlot({
    result <- rob_state()
    validate(need(!inherits(result, "error"), "Correct the validation problem before plotting."))
    print(mp_fun("plot_rob")(rob_data(), input$rob_study, tool = input$rob_tool,
      domains = input$rob_domains))
  }, res = 110)
  output$rob_summary <- renderPlot({
    result <- rob_state()
    validate(need(!inherits(result, "error"), "Correct the validation problem before plotting."))
    print(mp_fun("plot_rob_summary")(rob_data(), input$rob_study,
      tool = input$rob_tool, domains = input$rob_domains))
  }, res = 110)
  output$forest_rob_status <- renderUI({
    req(rob_state())
    if (inherits(rob_state(), "error")) {
      div(class = "mp-error", conditionMessage(rob_state()))
    } else if (is.null(fit_state())) {
      div(class = "mp-empty", "Run the primary meta-analysis before combining it with ROB judgements.")
    } else {
      div(class = "mp-status", "Studies are matched by label; unmatched studies are reported before plotting.")
    }
  })
  output$forest_rob <- renderPlot({
    result <- rob_state()
    validate(need(!inherits(result, "error"), "Correct the ROB validation problem before plotting."))
    mp_fun("forest_rob")(fit(), rob_data(), input$rob_study,
      tool = input$rob_tool, domains = input$rob_domains, title = NULL)
  }, height = function() plot_height(), res = 110)
  output$rob_validation <- renderPrint({
    result <- rob_state()
    message <- if (inherits(result, "error")) conditionMessage(result) else ""
    validate(need(!inherits(result, "error"), message))
    cat("Tool:", result$template$tool, "\nDomains:", paste(result$domains, collapse = ", "), "\n\n")
    print(result$frequencies)
  })

  umbrella_data <- reactive(read_uploaded_file(input$umbrella_upload))
  output$umbrella_mapping <- renderUI({
    columns <- names(umbrella_data())
    tagList(
      column_input("u_outcome", "Outcome", columns),
      column_input("u_review", "Review", columns),
      column_input("u_effect", "Reported effect", columns),
      column_input("u_lower", "Lower 95% CI", columns),
      column_input("u_upper", "Upper 95% CI", columns),
      column_input("u_measure", "Effect measure (optional)", columns, optional = TRUE),
      column_input("u_studies", "Number of studies (optional)", columns, optional = TRUE),
      column_input("u_participants", "Participants (optional)", columns, optional = TRUE),
      column_input("u_i2", "I-squared (optional)", columns, optional = TRUE),
      column_input("u_p", "p-value (optional)", columns, optional = TRUE),
      column_input("u_quality", "Review quality (optional)", columns, optional = TRUE),
      column_input("u_certainty", "GRADE certainty (optional)", columns, optional = TRUE)
    )
  })

  umbrella_state <- eventReactive(input$run_umbrella, {
    tryCatch(mp_fun("umbrella_review")(
      umbrella_data(), outcome = input$u_outcome, review = input$u_review,
      effect = input$u_effect, lower = input$u_lower, upper = input$u_upper,
      measure = optional(input$u_measure), studies = optional(input$u_studies),
      participants = optional(input$u_participants), i2 = optional(input$u_i2),
      p_value = optional(input$u_p), quality = optional(input$u_quality),
      certainty = optional(input$u_certainty), effect_scale = input$umbrella_scale
    ), error = function(e) e)
  }, ignoreInit = TRUE)

  umbrella_fit <- reactive({
    result <- umbrella_state()
    message <- if (inherits(result, "error")) conditionMessage(result) else ""
    validate(need(!inherits(result, "error"), message))
    result
  })
  output$umbrella_status <- renderUI({
    result <- umbrella_state()
    if (inherits(result, "error")) div(class = "mp-error", conditionMessage(result))
    else div(class = "mp-status", paste(
      result$summary$reviews, "reviews and", result$summary$outcomes,
      "outcomes organised. No new pooled estimate was calculated."
    ))
  })
  output$umbrella_table <- renderUI({
    classification <- tryCatch(mp_fun("classify_umbrella")(umbrella_fit()),
      error = function(e) NULL)
    grade <- tryCatch(mp_fun("grade_umbrella")(
      umbrella_fit(), starting_certainty = input$grade_start,
      risk_of_bias = input$grade_rob,
      inconsistency = input$grade_inconsistency
    ), error = function(e) NULL)
    HTML(gt::as_raw_html(mp_fun("table_umbrella")(
      umbrella_fit(), classification = classification, grade = grade, title = NULL
    )))
  })
  output$umbrella_plot <- renderPlot({
    classification <- tryCatch(mp_fun("classify_umbrella")(umbrella_fit()),
      error = function(e) NULL)
    print(mp_fun("plot_umbrella")(umbrella_fit(), classification = classification,
      title = NULL))
  }, res = 110)

  output$umbrella_appraisal <- renderPrint({
    object <- umbrella_fit()
    grade <- mp_fun("grade_umbrella")(
      object, starting_certainty = input$grade_start,
      risk_of_bias = input$grade_rob,
      inconsistency = input$grade_inconsistency
    )
    cat("GRADE judgements (reviewer supplied)\n")
    print(grade[, c("Outcome", "Review", "StartingCertainty", "RiskOfBias",
      "Inconsistency", "GRADE")])
    if (!is.null(input$u_quality) && nzchar(input$u_quality)) {
      cat("\n", input$quality_tool, "review-quality assessment\n", sep = "")
      quality <- mp_fun("assess_review_quality")(
        object, tool = input$quality_tool, overall = input$u_quality
      )
      print(quality)
    } else {
      cat("\nMap a review-quality column to add AMSTAR 2 or ROBIS appraisal.")
    }
  })

  overlap_data <- reactive(read_uploaded_file(input$overlap_upload))
  output$overlap_mapping <- renderUI({
    columns <- names(overlap_data())
    tagList(
      column_input("o_review", "Review", columns),
      column_input("o_study", "Primary study", columns),
      column_input("o_outcome", "Outcome (optional)", columns, optional = TRUE),
      column_input("o_included", "Included indicator (optional)", columns, optional = TRUE)
    )
  })
  overlap_state <- eventReactive(input$run_overlap, {
    tryCatch(mp_fun("study_overlap")(
      overlap_data(), review = input$o_review, study = input$o_study,
      outcome = optional(input$o_outcome), included = optional(input$o_included)
    ), error = function(e) e)
  }, ignoreInit = TRUE)
  overlap_fit <- reactive({
    result <- overlap_state()
    message <- if (inherits(result, "error")) conditionMessage(result) else ""
    validate(need(!inherits(result, "error"), message))
    result
  })
  output$overlap_status <- renderUI({
    result <- overlap_state()
    if (inherits(result, "error")) div(class = "mp-error", conditionMessage(result))
    else div(class = "mp-status", "Primary-study overlap calculated using the ccaR-compatible CCA definition.")
  })
  output$overlap_summary <- renderPrint({
    object <- overlap_fit()
    cat("Overall corrected covered area\n")
    print(object$cca)
    cat("\nPairwise overlap\n")
    print(object$pairwise)
  })
  output$overlap_plot <- renderPlot({
    print(mp_fun("plot_study_overlap")(
      overlap_fit(), type = input$overlap_plot_type, title = NULL
    ))
  }, res = 110)

  output$overlap_sensitivity <- renderTable({
    req(umbrella_fit(), overlap_fit(), input$sensitivity_strategies)
    mp_fun("sensitivity_umbrella_overlap")(
      umbrella_fit(), overlap = overlap_fit(),
      strategies = input$sensitivity_strategies,
      missing_action = "exclude"
    )
  }, digits = 4, striped = TRUE, hover = TRUE)

  primary_data <- reactive(read_uploaded_file(input$primary_upload))
  output$primary_mapping <- renderUI({
    columns <- names(primary_data())
    tagList(
      column_input("p_outcome", "Outcome", columns),
      column_input("p_review", "Source review", columns),
      column_input("p_study", "Primary study", columns),
      column_input("p_effect", "Study effect", columns),
      column_input("p_lower", "Lower 95% CI", columns),
      column_input("p_upper", "Upper 95% CI", columns),
      column_input("p_participants", "Participants (optional)", columns, optional = TRUE)
    )
  })
  primary_state <- eventReactive(input$run_primary, {
    tryCatch(mp_fun("diagnose_umbrella_primary")(
      primary_data(), outcome = input$p_outcome, review = input$p_review,
      study = input$p_study, effect = input$p_effect,
      lower = input$p_lower, upper = input$p_upper,
      participants = optional(input$p_participants),
      effect_scale = input$primary_scale
    ), error = function(e) e)
  }, ignoreInit = TRUE)
  output$primary_status <- renderUI({
    result <- primary_state()
    if (inherits(result, "error")) div(class = "mp-error", conditionMessage(result))
    else div(class = "mp-status", paste(nrow(result$summary),
      "source meta-analyses diagnosed independently."))
  })
  output$primary_table <- renderTable({
    result <- primary_state()
    message <- if (inherits(result, "error")) conditionMessage(result) else ""
    validate(need(!inherits(result, "error"), message))
    result$summary
  }, digits = 4, striped = TRUE, hover = TRUE)

  code_text <- reactive({
    call <- analysis_call()
    args <- call$args
    args$data <- quote(my_data)
    paste(deparse(as.call(c(list(as.name(call$fun)), args)), width.cutoff = 88), collapse = "\n")
  })
  output$code <- renderText(code_text())

  register_plot_download("influence",
    function() mp_fun("forest_influence")(fit(), title = NULL),
    width = 11, height = function() max(7, plot_height() / 110))
  register_plot_download("cumulative",
    function() mp_fun("forest_cumulative")(fit(), title = NULL),
    width = 11, height = function() max(7, plot_height() / 110))
  register_plot_download("heterogeneity",
    function() mp_fun("plot_heterogeneity")(fit(), title = NULL))
  register_plot_download("baujat",
    function() mp_fun("plot_baujat")(fit(), title = NULL))
  register_plot_download("bias_plot",
    function() mp_fun("publication_bias")(fit(), plot_method = bias_methods(), title = NULL),
    width = 12, height = function() if (length(bias_methods()) > 1L) 10 else 8)
  register_plot_download("doi",
    function() mp_fun("doi_plot")(fit(), title = NULL), width = 8, height = 8)
  register_plot_download("reg_bubble", function() {
    object <- reg_fit()
    numeric_mods <- object$moderator_variables[
      vapply(object$model_data[object$moderator_variables], is.numeric, logical(1))
    ]
    validate(need(length(numeric_mods), "A continuous moderator is required."))
    mp_fun("plot_meta_reg")(object, type = "bubble", moderator = numeric_mods[1], title = NULL)
  })
  register_plot_download("reg_residual",
    function() mp_fun("plot_meta_reg")(reg_fit(), type = "residual", title = NULL))
  register_plot_download("rob_traffic",
    function() mp_fun("plot_rob")(rob_data(), input$rob_study,
      tool = input$rob_tool, domains = input$rob_domains), width = 11, height = 8)
  register_plot_download("forest_rob",
    function() mp_fun("forest_rob")(fit(), rob_data(), input$rob_study,
      tool = input$rob_tool, domains = input$rob_domains, title = NULL),
    width = 14, height = function() max(8, plot_height() / 110))
  register_plot_download("rob_summary",
    function() mp_fun("plot_rob_summary")(rob_data(), input$rob_study,
      tool = input$rob_tool, domains = input$rob_domains))
  register_plot_download("umbrella_plot", function() {
    classification <- tryCatch(mp_fun("classify_umbrella")(umbrella_fit()),
      error = function(e) NULL)
    mp_fun("plot_umbrella")(umbrella_fit(), classification = classification,
      title = NULL)
  }, width = 10, height = 8)
  register_plot_download("overlap_plot",
    function() mp_fun("plot_study_overlap")(overlap_fit(),
      type = input$overlap_plot_type, title = NULL), width = 10, height = 8)

  register_table_download("subgroups",
    function() mp_fun("table_subgroups")(fit(), title = NULL))
  register_table_download("influence_table",
    function() mp_fun("table_influence")(fit(), title = NULL))
  register_table_download("cumulative_table",
    function() mp_fun("table_cumulative_meta")(fit(), title = NULL))
  register_table_download("bias_table",
    function() mp_fun("table_publication_bias")(bias_state(), title = NULL))
  register_table_download("reg_table",
    function() mp_fun("table_meta_reg")(reg_fit(), title = NULL))
  register_table_download("reg_predictions", function() {
    req(reg_fit(), input$reg_predict_upload)
    mp_fun("predict_meta_reg")(reg_fit(),
      newdata = read_uploaded_file(input$reg_predict_upload))
  })
  register_table_download("reg_diagnostics",
    function() mp_fun("diagnose_meta_reg")(reg_fit())$studies)
  register_table_download("rob_validation",
    function() rob_state()$frequencies)
  register_table_download("umbrella_table", function() {
    classification <- tryCatch(mp_fun("classify_umbrella")(umbrella_fit()),
      error = function(e) NULL)
    grade <- tryCatch(mp_fun("grade_umbrella")(
      umbrella_fit(), starting_certainty = input$grade_start,
      risk_of_bias = input$grade_rob,
      inconsistency = input$grade_inconsistency
    ), error = function(e) NULL)
    mp_fun("table_umbrella")(umbrella_fit(), classification = classification,
      grade = grade, title = NULL)
  })
  register_table_download("umbrella_appraisal", function() {
    mp_fun("grade_umbrella")(
      umbrella_fit(), starting_certainty = input$grade_start,
      risk_of_bias = input$grade_rob,
      inconsistency = input$grade_inconsistency
    )
  })
  register_table_download("overlap_summary",
    function() overlap_fit()$pairwise)
  register_table_download("overlap_sensitivity", function() {
    mp_fun("sensitivity_umbrella_overlap")(
      umbrella_fit(), overlap = overlap_fit(),
      strategies = input$sensitivity_strategies, missing_action = "exclude"
    )
  })
  register_table_download("primary_table",
    function() primary_state()$summary)

  output$download_plot <- downloadHandler(
    filename = function() paste0("metapropul-forest-", Sys.Date(), ".",
      input$plot_format %||% "pdf"),
    content = function(file) {
      format <- input$plot_format %||% "pdf"
      width <- 11
      height <- max(7, plot_height() / 110)
      if (format == "pdf") {
        grDevices::pdf(file, width = width, height = height)
      } else if (format == "svg") {
        grDevices::svg(file, width = width, height = height)
      } else if (format == "png") {
        grDevices::png(file, width = width, height = height,
          units = "in", res = 300)
      } else {
        tiff_args <- list(filename = file, width = width, height = height,
          units = "in", res = 300)
        if (Sys.info()[["sysname"]] != "Darwin") tiff_args$compression <- "lzw"
        do.call(grDevices::tiff, tiff_args)
      }
      on.exit(grDevices::dev.off(), add = TRUE)
      mp_fun("forest_meta")(fit(), title = optional(input$plot_title))
    }
  )

  output$download_table <- downloadHandler(
    filename = function() paste0("metapropul-results-", Sys.Date(), ".",
      input$table_format %||% "docx"),
    content = function(file) {
      object <- fit()
      format <- input$table_format %||% "docx"
      if (format == "csv") {
        utils::write.csv(object$table, file, row.names = FALSE, na = "")
      } else {
        mp_fun("table_meta")(object, save_as = format, filename = file)
      }
    }
  )
}

shinyApp(ui, server)
