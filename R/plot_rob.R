#' Traffic-light plot for risk of bias or study appraisal
#'
#' Creates a study-by-domain traffic-light plot for risk-of-bias or
#' critical appraisal judgements.
#'
#' @param rob_data A data frame containing study labels and judgement
#'   columns.
#' @param studylab Character string giving the study label column name.
#' @param tool Character string specifying the ROB or appraisal tool.
#'   Supported values include \code{"ROB2"}, \code{"ROBINS-I"},
#'   \code{"QUADAS2"}, \code{"QUIPS"}, \code{"ROBIS"},
#'   \code{"AMSTAR2"}, \code{"NOS"}, \code{"GENERIC"}, and
#'   \code{"Custom"}.
#' @param domains Optional character vector of domain column names. If
#'   omitted, domains are taken from the selected template where
#'   available.
#' @param levels Optional character vector of allowed judgement levels
#'   when \code{tool = "Custom"}.
#' @param colours Optional named character vector of colours when
#'   \code{tool = "Custom"}. If omitted, common judgements such as low, some
#'   concerns, and high receive semantic green, amber, and red colours;
#'   unrecognised levels receive a distinct qualitative palette.
#' @param has_overall Logical; used only when \code{tool = "Custom"} to
#'   indicate whether an overall judgement is expected.
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
#' plot_rob(
#'   rob_data = rob_df,
#'   studylab = "study",
#'   tool = "Custom",
#'   domains = c("d1", "d2", "overall"),
#'   levels = c("Low", "Some concerns", "High")
#' )
#' }
#'
#' @importFrom ggplot2 aes coord_equal element_blank element_text
#' @importFrom ggplot2 geom_tile ggplot labs scale_fill_manual theme
#' @importFrom ggplot2 theme_minimal
#' @export
plot_rob <- function(rob_data,
                     studylab,
                     tool = "GENERIC",
                     domains = NULL,
                     levels = NULL,
                     colours = NULL,
                     has_overall = TRUE) {
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

  plot_df$Domain <- factor(plot_df$Domain, levels = domains)
  plot_df$Study <- factor(
    plot_df$Study,
    levels = rev(unique(as.character(rob_data[[studylab]])))
  )

  ggplot2::ggplot(
    plot_df,
    ggplot2::aes(
      x = Domain,
      y = Study,
      fill = Judgement
    )
  ) +
    ggplot2::geom_tile(
      colour = "white",
      linewidth = 0.6
    ) +
    ggplot2::scale_fill_manual(
      values = template$colours,
      drop = FALSE
    ) +
    ggplot2::coord_equal() +
    ggplot2::labs(
      x = NULL,
      y = NULL,
      fill = "Judgement"
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      panel.grid = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_text(
        angle = 45,
        hjust = 1,
        vjust = 1
      ),
      axis.text.y = ggplot2::element_text(size = 10)
    )
}
