utils::globalVariables(c(
  # table column names
  "Study", "Estimate", "lower", "upper", "Step", "Study Added",
  "Estimate [95% CI]", "Proportion", "Proportion [95% CI]",
  "Mean (SD)", "Weight (%)", "Mean Difference [95% CI]",
  "Odds Ratio [95% CI]",
  # back-transform columns in meta_reg table
  "Estimate_bt", "CI.Lower_bt", "CI.Upper_bt",
  # misc
  ".final", ".data"
))
