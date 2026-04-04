#' Summary plot for risk of bias or study appraisal
#'
#' Creates a stacked summary plot showing the distribution of judgement
#' levels across domains.
#'
#' @param rob_data A data frame containing study labels and judgement
#'   columns.
#' @param studylab Character string giving the study label column name.
#' @param tool Character string specifying the ROB or appraisal tool.
#' @param domains Optional character vector of domain column names. If
#'   omitted, domains are taken from the selected template where
#'   available.
#' @param levels Optional character vector of allowed judgement levels
#'   when \code{tool = "Custom"}.
#' @param colours Optional named character vector of colours when
#'   \code{tool = "Custom"}.
#' @param has_overall Logical; used only when \code{tool = "Custom"}.
#' @param as_percent Logical; if \code{TRUE}, bars are shown as
#'   percentages. If \code{FALSE}, raw counts are shown.
#'
#' @return A \pkg{ggplot2} object.
#'
#' @examples
#' \donttest{
#' rob_df <- data.frame(
#'   study = c("Study 1", "Study 2"),
#'   d1 = c("Low", "High"),
#'   d2 = c("Some concerns", "Low"),
#'   overall = c("Low", "High")
#' )
#'
#' plot_rob_summary(
#'   rob_data = rob_df,
#'   studylab = "study",
#'   tool = "Custom",
#'   domains = c("d1", "d2", "overall"),
#'   levels = c("Low", "Some concerns", "High")
#' )
#' }
#'
#' @importFrom ggplot2 aes coord_flip geom_col ggplot labs
#' @importFrom ggplot2 scale_fill_manual scale_y_continuous theme_minimal
#' @export
plot_rob_summary <- function(rob_data,
                             studylab,
                             tool = "GENERIC",
                             domains = NULL,
                             levels = NULL,
                             colours = NULL,
                             has_overall = TRUE,
                             as_percent = TRUE) {
  template <- .get_rob_template(
    tool = tool,
    domains = domains,
    levels = levels,
    colours = colours,
    has_overall = has_overall
  )

  if (is.null(domains)) {
    domains <- template$domains
  }

  if (is.null(domains) || length(domains) == 0L) {
    stop(
      "'domains' must be provided for this tool.",
      call. = FALSE
    )
  }

  .validate_rob_data(
    rob_data = rob_data,
    studylab = studylab,
    domains = domains,
    template = template
  )

  plot_df <- .prepare_rob_long(
    rob_data = rob_data,
    studylab = studylab,
    domains = domains
  )

  plot_df$Judgement <- factor(
    plot_df$Judgement,
    levels = template$levels
  )

  sum_df <- plot_df |>
    dplyr::count(Domain, Judgement, name = "n") |>
    dplyr::group_by(Domain) |>
    dplyr::mutate(prop = n / sum(n)) |>
    dplyr::ungroup()

  if (isTRUE(as_percent)) {
    p <- ggplot2::ggplot(
      sum_df,
      ggplot2::aes(
        x = Domain,
        y = prop,
        fill = Judgement
      )
    ) +
      ggplot2::geom_col(width = 0.75) +
      ggplot2::coord_flip() +
      ggplot2::scale_fill_manual(
        values = template$colours,
        drop = FALSE
      ) +
      ggplot2::scale_y_continuous(
        labels = scales::percent
      ) +
      ggplot2::labs(
        x = NULL,
        y = "Percentage",
        fill = "Judgement"
      ) +
      ggplot2::theme_minimal(base_size = 11)
  } else {
    p <- ggplot2::ggplot(
      sum_df,
      ggplot2::aes(
        x = Domain,
        y = n,
        fill = Judgement
      )
    ) +
      ggplot2::geom_col(width = 0.75) +
      ggplot2::coord_flip() +
      ggplot2::scale_fill_manual(
        values = template$colours,
        drop = FALSE
      ) +
      ggplot2::labs(
        x = NULL,
        y = "Count",
        fill = "Judgement"
      ) +
      ggplot2::theme_minimal(base_size = 11)
  }

  p
}
