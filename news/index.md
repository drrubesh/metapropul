# Changelog

## metapropul 0.1.0

- Initial CRAN submission.
- Added unified fixed- and random-effects models for ratios, continuous
  outcomes, proportions, generic inverse-variance effects, correlations,
  and incidence rates.
- Added subgroup tests, meta-regression prediction and diagnostics,
  influence analyses, publication-bias assessments, and automatically
  sized figures.
- Added non-pooling umbrella-review reporting, evidence classification,
  reviewer-supplied GRADE assessments, and primary-study overlap
  diagnostics.
- Added publication-ready tables, case-study vignettes, manual
  validation scripts, and direct numerical comparisons with ‘meta’ and
  ‘metafor’.
- Added an optional Shiny graphical interface, launched with
  [`metapropul_app()`](https://drrubesh.github.io/metapropul/reference/metapropul_app.md),
  for data import, model configuration, diagnostics, reproducible code,
  and result export.
- Added CSV and Excel imports, a single horizontally scrollable
  workflow, a floating close control, multi-format figure export, and
  Word-table export.
- Added contextual downloads to every analytical figure and result table
  in the graphical interface. Publication-bias plots can now be viewed
  and exported individually or as a manuscript-ready four-method 2-by-2
  panel.
- Added
  [`forest_rob()`](https://drrubesh.github.io/metapropul/reference/forest_rob.md)
  and a matching GUI view to align forest-plot estimates with
  study-level, colour-coded risk-of-bias traffic lights in one figure.
- Added explicit CSV/Excel schemas, downloadable GUI templates, and a
  pkgdown data-preparation guide.
  [`meta_ratio()`](https://drrubesh.github.io/metapropul/reference/meta_ratio.md)
  now directly accepts log OR, log RR, or log HR estimates with their
  standard errors.
- Fixed the GUI so subgroup analysis always defaults to `None`,
  including for bundled datasets that contain a candidate subgroup
  column. Manual cases now test no-subgroup and explicitly requested
  subgroup paths separately.
- Added downloadable, worked CSV templates and inline schema guidance
  for meta-regression predictions, ROB assessments, umbrella-review
  results, review–study overlap/CCA, and within-review primary-study
  diagnostics.
