utils::globalVariables(c(
  # table column names
  "Study", "Estimate", "lower", "upper", "Step", "Study Added",
  "Estimate [95% CI]", "Proportion", "Proportion [95% CI]",
  "Mean (SD)", "Weight (%)", "Mean Difference [95% CI]",
  "Odds Ratio [95% CI]",
  # back-transform columns in meta_reg table
  "Estimate_bt", "CI.Lower_bt", "CI.Upper_bt",
  # meta-regression plot and diagnostic columns
  "x", "y", "weight", "estimate", "conf.low", "conf.high",
  "pred.low", "pred.high", "fitted", "standardized_residual",
  "cooks_distance", "influential",
  # umbrella-review table and plot columns
  "Outcome", "Reviews", "Prediction interval", "p-value", "I2 (%)",
  "EvidenceClass",
  "Review1", "Review2", "Jaccard", "Review", "Included",
  "LargestReview", "LargestStudyP", "SmallStudyP",
  "ExcessSignificanceP",
  "PrimaryStudies", "LargestStudy",
  "Label", "CCA.percent", "Interpretation",
  # misc
  ".final", ".data", "Domain", "Judgement", "n", "prop"
))
