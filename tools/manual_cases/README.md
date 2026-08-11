# Manual case studies

> These are batch artifact checks. For the interactive, run-line-by-line
> developer scripts modelled on the `gtstats`/`gtregression` workflow, use
> [`tools/realtime_tests/`](../realtime_tests/README.md).

These scripts are executable, analyst-led case studies. They are deliberately
different from `testthat` tests: each script begins with a research question,
explains the estimand and model choice, reports key numerical findings, creates
publication outputs, and ends with a human visual-review checklist.
The core cases first fit a model without subgroups, verify that no subgroup
result was created, and only then request a subgroup explicitly. The ratio case
also exercises ordinary ratios with confidence limits and log ratios with
standard errors.

Run every case from the package root:

```sh
Rscript tools/manual_cases/00_run_all.R path/to/output-directory
```

Each output folder contains a `CASE-STUDY.md` narrative plus the relevant HTML
tables, CSV data, and PDF figures. A successful `PASS` confirms a software
invariant or artifact; it does not replace scientific interpretation.

## Case map

1. `01_meta_ratio_case.R`: BCG comparative effects, fixed/random models,
   subgroups, influence, cumulative analysis, heterogeneity, Baujat and
   publication-bias outputs.
2. `02_meta_mean_case.R`: continuous outcomes, MD/SMD estimands, subgroup,
   cumulative, influence, heterogeneity, Baujat and DOI outputs.
3. `03_meta_prop_case.R`: single proportions, logit primary analysis,
   Freeman–Tukey sensitivity analysis, subgroup and diagnostic outputs.
4. `04_meta_regression_case.R`: centring, scaling, reference levels,
   interaction terms, predictions, diagnostics and all regression plots.
5. `05_risk_of_bias_case.R`: validation, traffic-light and summary appraisal
   plots without numerical scoring.
6. `06_additional_models_case.R`: generic inverse variance, incidence rates,
   correlations, tables and forest plots.
7. `manual_umbrella_builtin.R`: non-pooling umbrella synthesis, primary-study
   diagnostics, evidence classification, GRADE recording, AMSTAR 2, CCA,
   Jaccard overlap and review-selection sensitivity analysis.

The datasets are bundled with `metapropul`, except for the clearly labelled
simulated correlations in case 6. The umbrella reviews in case 7 are constructed
teaching records and must not be presented as published reviews.
