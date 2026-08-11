# Run every manual package case study in a fresh R process.
# Run: Rscript tools/manual_cases/00_run_all.R [output-root]
args <- commandArgs(trailingOnly = TRUE)
if (length(args) > 1L) stop("Supply at most one output root.")
root <- if (length(args)) args[[1]] else file.path(tempdir(), "metapropul-manual-cases")
dir.create(root, recursive = TRUE, showWarnings = FALSE)
scripts <- c("01_meta_ratio_case.R", "02_meta_mean_case.R", "03_meta_prop_case.R",
  "04_meta_regression_case.R", "05_risk_of_bias_case.R",
  "06_additional_models_case.R")
rscript <- file.path(R.home("bin"), "Rscript")
for (script in scripts) {
  label <- sub("\\.R$", "", script)
  message("\nRUNNING: ", label)
  status <- system2(rscript,
    c(file.path("tools/manual_cases", script), file.path(root, label)))
  if (!identical(status, 0L)) stop("Manual case failed: ", label, call. = FALSE)
}
message("\nRUNNING: umbrella review")
status <- system2(rscript, c("tools/manual_umbrella_builtin.R", file.path(root, "07_umbrella_case")))
if (!identical(status, 0L)) stop("Manual umbrella case failed.", call. = FALSE)
message("\nAll manual cases passed. Inspect: ", normalizePath(root))
