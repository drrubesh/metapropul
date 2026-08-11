# Real-time manual tests

These are interactive developer scripts in the style of the original
`gtstats`/`gtregression` manual tests. Open a script in RStudio and run it one
section at a time. Read the comments, inspect objects in the Environment and
Viewer, and deliberately compare alternative calls.

They are not unit tests and do not stop at `PASS` assertions. Generated files
are written to `manual-test-output/`, which can be deleted after inspection.

Run in order:

1. `01_core_models_and_regression.R`
2. `02_plots_tables_and_stress.R`
3. `03_rob_additional_and_umbrella.R`

During package development use `devtools::load_all()`. To test the installed
GitHub version instead, replace that call with:

```r
# devtools::install_github("drrubesh/propulmeta", force = TRUE)
# library(metapropul)
```
