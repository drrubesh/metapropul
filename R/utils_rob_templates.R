#' @keywords internal
.rob_templates <- list(
  ROB2 = list(
    tool = "ROB2",
    domains = c(
      "Randomization process",
      "Deviations from intended interventions",
      "Missing outcome data",
      "Measurement of the outcome",
      "Selection of the reported result",
      "Overall"
    ),
    levels = c("Low", "Some concerns", "High"),
    colours = c(
      "Low" = "#02C100",
      "Some concerns" = "#E2DF07",
      "High" = "#BF0000"
    ),
    has_overall = TRUE
  ),
  ROBINS_I = list(
    tool = "ROBINS-I",
    domains = c(
      "Confounding",
      "Selection of participants",
      "Classification of interventions",
      "Deviations from intended interventions",
      "Missing data",
      "Measurement of outcomes",
      "Selection of reported result",
      "Overall"
    ),
    levels = c(
      "Low",
      "Moderate",
      "Serious",
      "Critical",
      "No information"
    ),
    colours = c(
      "Low" = "#02C100",
      "Moderate" = "#E2DF07",
      "Serious" = "#E67E22",
      "Critical" = "#BF0000",
      "No information" = "#BDBDBD"
    ),
    has_overall = TRUE
  ),
  QUADAS2 = list(
    tool = "QUADAS-2",
    domains = c(
      "Patient selection",
      "Index test",
      "Reference standard",
      "Flow and timing",
      "Applicability: patient selection",
      "Applicability: index test",
      "Applicability: reference standard"
    ),
    levels = c("Low", "High", "Unclear"),
    colours = c(
      "Low" = "#02C100",
      "High" = "#BF0000",
      "Unclear" = "#BDBDBD"
    ),
    has_overall = FALSE
  ),
  QUIPS = list(
    tool = "QUIPS",
    domains = c(
      "Study participation",
      "Study attrition",
      "Prognostic factor measurement",
      "Outcome measurement",
      "Study confounding",
      "Statistical analysis and reporting",
      "Overall"
    ),
    levels = c("Low", "Moderate", "High"),
    colours = c(
      "Low" = "#02C100",
      "Moderate" = "#E2DF07",
      "High" = "#BF0000"
    ),
    has_overall = TRUE
  ),
  ROBIS = list(
    tool = "ROBIS",
    domains = c(
      "Study eligibility criteria",
      "Identification and selection of studies",
      "Data collection and study appraisal",
      "Synthesis and findings",
      "Overall"
    ),
    levels = c("Low", "High", "Unclear"),
    colours = c(
      "Low" = "#02C100",
      "High" = "#BF0000",
      "Unclear" = "#BDBDBD"
    ),
    has_overall = TRUE
  ),
  AMSTAR2 = list(
    tool = "AMSTAR-2",
    domains = NULL,
    levels = c("High", "Moderate", "Low", "Critically low"),
    colours = c(
      "High" = "#02C100",
      "Moderate" = "#E2DF07",
      "Low" = "#E67E22",
      "Critically low" = "#BF0000"
    ),
    has_overall = TRUE
  ),
  NOS = list(
    tool = "NOS",
    domains = NULL,
    levels = c("Good", "Fair", "Poor"),
    colours = c(
      "Good" = "#02C100",
      "Fair" = "#E2DF07",
      "Poor" = "#BF0000"
    ),
    has_overall = TRUE
  ),
  GENERIC = list(
    tool = "Generic",
    domains = NULL,
    levels = c("Low", "Some concerns", "High"),
    colours = c(
      "Low" = "#02C100",
      "Some concerns" = "#E2DF07",
      "High" = "#BF0000"
    ),
    has_overall = TRUE
  )
)

#' @keywords internal
.get_rob_template <- function(tool = "GENERIC",
                              domains = NULL,
                              levels = NULL,
                              colours = NULL,
                              has_overall = TRUE) {
  tool_key <- toupper(gsub("-", "_", tool))

  if (identical(tool_key, "CUSTOM")) {
    if (is.null(domains) || length(domains) == 0L) {
      stop(
        "'domains' must be provided when tool = 'Custom'.",
        call. = FALSE
      )
    }

    if (is.null(levels) || length(levels) == 0L) {
      stop(
        "'levels' must be provided when tool = 'Custom'.",
        call. = FALSE
      )
    }

    if (is.null(colours)) {
      colours <- stats::setNames(
        rep("#BDBDBD", length(levels)),
        levels
      )
    }

    return(list(
      tool = "Custom",
      domains = domains,
      levels = levels,
      colours = colours,
      has_overall = has_overall
    ))
  }

  if (!tool_key %in% names(.rob_templates)) {
    stop(
      sprintf("Unsupported ROB tool: '%s'.", tool),
      call. = FALSE
    )
  }

  .rob_templates[[tool_key]]
}

#' @keywords internal
.validate_rob_data <- function(rob_data,
                               studylab,
                               domains,
                               template) {
  if (!inherits(rob_data, "data.frame")) {
    stop("'rob_data' must be a data frame.", call. = FALSE)
  }

  if (!studylab %in% names(rob_data)) {
    stop(
      sprintf("Column '%s' not found in rob_data.", studylab),
      call. = FALSE
    )
  }

  missing_domains <- domains[!domains %in% names(rob_data)]
  if (length(missing_domains) > 0L) {
    stop(
      sprintf(
        "ROB domain column(s) not found: %s",
        paste(missing_domains, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  vals <- unique(unlist(rob_data[, domains, drop = FALSE]))
  vals <- vals[!is.na(vals)]

  bad_vals <- setdiff(as.character(vals), template$levels)
  if (length(bad_vals) > 0L) {
    stop(
      sprintf(
        "Invalid ROB level(s): %s",
        paste(bad_vals, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  invisible(TRUE)
}

#' @keywords internal
.prepare_rob_long <- function(rob_data,
                              studylab,
                              domains) {
  out <- tidyr::pivot_longer(
    rob_data,
    cols = dplyr::all_of(domains),
    names_to = "Domain",
    values_to = "Judgement"
  )

  names(out)[names(out) == studylab] <- "Study"
  out
}
