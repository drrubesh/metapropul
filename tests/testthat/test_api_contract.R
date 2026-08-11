test_that("the release API exposes the intended public functions", {
  expected <- c(
    "assess_review_quality", "bubble_plot", "classify_umbrella",
    "diagnose_meta_reg", "diagnose_umbrella_primary", "doi_plot",
    "forest_cumulative", "forest_influence", "forest_meta", "forest_rob",
    "grade_umbrella", "meta_cor", "meta_generic", "meta_mean",
    "meta_prop", "meta_rate", "meta_ratio", "meta_reg", "plot_baujat",
    "plot_heterogeneity", "plot_meta_reg", "plot_rob",
    "plot_rob_summary", "plot_study_overlap", "plot_umbrella",
    "predict_meta_reg", "publication_bias", "sensitivity_umbrella_overlap",
    "metapropul_app",
    "study_overlap", "table_cumulative_meta", "table_influence",
    "table_meta", "table_meta_reg", "table_publication_bias",
    "table_subgroups", "table_umbrella", "umbrella_review", "validate_rob"
  )

  expect_setequal(getNamespaceExports("metapropul"), expected)
})

test_that("core model functions retain a consistent analysis contract", {
  core <- list(meta_ratio, meta_mean, meta_prop, meta_generic, meta_cor, meta_rate)
  common <- c(
    "data", "studylab", "subgroup", "model", "tau_method", "ci_method",
    "prediction_interval", "missing_action", "duplicate_action",
    "singleton_action"
  )

  for (fun in core) {
    expect_true(all(common %in% names(formals(fun))))
    expect_identical(formals(fun)$tau_method, "REML")
    expect_identical(formals(fun)$ci_method, "HK")
    expect_identical(formals(fun)$prediction_interval, TRUE)
  }
})

test_that("plot exporters share the file-output contract", {
  exporters <- list(
    forest_cumulative, forest_influence, plot_baujat, plot_heterogeneity,
    plot_meta_reg, plot_study_overlap, plot_umbrella, publication_bias
  )

  for (fun in exporters) {
    expect_true(all(c("save_as", "filename", "width", "height") %in%
      names(formals(fun))))
  }
})
