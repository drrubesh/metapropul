# Risk-of-bias case study using the bundled caffeine appraisal fields.
# Run: Rscript tools/manual_cases/05_risk_of_bias_case.R [output-directory]
source("tools/manual_cases/_helpers.R")
out <- manual_output_dir("risk-of-bias-case")
data("caffeine", package = "metapropul")
domains <- c("D1", "D2", "D3", "D4", "D5", "rob")
levels <- unique(unlist(caffeine[domains], use.names = FALSE))
levels <- levels[!is.na(levels)]

case_begin("Risk-of-bias appraisal as part of evidence interpretation",
  "Can study-level domain judgements be validated and communicated clearly without collapsing them into an unsupported numerical score?",
  "`caffeine`: eight studies with five domain judgements and an overall risk-of-bias field.", out)
case_section("1. Validate the appraisal structure")
case_text("The script treats judgements as categorical assessments. The traffic-light plot preserves study-level detail; the summary plot describes the distribution across studies.")
validated <- validate_rob(caffeine, "study", tool = "Custom", domains = domains,
  levels = levels)
manual_check(inherits(validated, "rob_validation") && isTRUE(validated$valid),
  "risk-of-bias data validation")
case_value("Studies", nrow(caffeine))
case_value("Appraisal fields", paste(domains, collapse = ", "))

case_section("2. Create complementary risk-of-bias figures")
case_text("Use the traffic-light figure to find which domain drives concern in each study. Use the summary only for an overview; it must not be interpreted as a pooled risk-of-bias estimate.")
traffic <- plot_rob(caffeine, "study", tool = "Custom", domains = domains,
  levels = levels)
summary_plot <- plot_rob_summary(caffeine, "study", tool = "Custom",
  domains = domains, levels = levels)
manual_check(inherits(traffic, "ggplot") && inherits(summary_plot, "ggplot"),
  "risk-of-bias figures")
ggplot2::ggsave(file.path(out, "traffic-light.pdf"), traffic, width = 10, height = 7)
ggplot2::ggsave(file.path(out, "summary.pdf"), summary_plot, width = 9, height = 6)
check_artifacts(out, c("traffic-light.pdf", "summary.pdf"))
case_finish(c("traffic-light.pdf", "summary.pdf"))
message("Risk-of-bias case completed: ", out)
