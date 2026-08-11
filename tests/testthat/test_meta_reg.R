test_that("meta_reg: returns correct class and structure", {
  r <- .fix_reg_prop

  expect_s3_class(r, "meta_reg")
  expect_named(
    r,
    c(
      "model", "meta", "table", "meta.summary", "r2_analog",
      "measure", "sm", "source_settings", "excluded_studies", "moderators",
      "moderator_variables", "model_data", "preprocessing", "test",
      "method", "analysis_type", "n_parameters", "studies_per_parameter", "call"
    )
  )
  expect_equal(r$model, "meta-regression")
  expect_equal(r$measure, "Proportion")
  expect_equal(r$sm, "PLOGIT")
})

test_that("meta_reg: supports centering and Knapp-Hartung inference", {
  r <- meta_reg(
    .fix_prop, dat_bcg, ~ablat, "author",
    center = "ablat", test = "knha"
  )
  expect_equal(r$test, "knha")
  expect_equal(mean(r$model_data$ablat), 0, tolerance = 1e-12)
  expect_equal(r$analysis_type, "univariable")
})

test_that("meta_reg inherits or accepts the tau-squared method", {
  expect_equal(.fix_reg_prop$method, .fix_prop$tau_method)
  fit <- meta_reg(.fix_prop, dat_bcg, ~ablat, "author", method = "ML")
  expect_equal(fit$method, "ML")
  expect_equal(fit$meta$method, "ML")
})

test_that("meta_reg: controls categorical reference levels", {
  r <- suppressWarnings(meta_reg(
    .fix_prop, dat_bcg, ~alloc, "author",
    reference_levels = c(alloc = "systematic")
  ))
  expect_equal(levels(r$model_data$alloc)[1], "systematic")
})

test_that("meta_reg: interactions and multivariable models are supported", {
  r <- suppressWarnings(meta_reg(
    .fix_prop, dat_bcg, ~ablat * year, "author",
    min_studies_per_parameter = 2
  ))
  expect_equal(r$analysis_type, "multivariable")
  expect_true(any(grepl(":", r$table$Term)))
})

test_that("predict_meta_reg returns confidence and prediction intervals", {
  pred <- predict_meta_reg(
    .fix_reg_prop,
    data.frame(ablat = c(20, 40, 60))
  )
  expect_equal(nrow(pred), 3L)
  expect_true(all(c("estimate", "conf.low", "conf.high", "pred.low", "pred.high") %in%
    names(pred)))
  expect_true(all(pred$estimate >= 0 & pred$estimate <= 100))
})

test_that("diagnose_meta_reg returns study and collinearity diagnostics", {
  diagnostics <- diagnose_meta_reg(.fix_reg_prop)
  expect_s3_class(diagnostics, "meta_reg_diagnostics")
  expect_equal(nrow(diagnostics$studies), .fix_reg_prop$meta$k)
  expect_true(all(c("standardized_residual", "cooks_distance", "influential") %in%
    names(diagnostics$studies)))
  expect_true(all(c("leverage", "dffits", "covariance_ratio", "max_abs_dfbeta") %in%
    names(diagnostics$studies)))
  expect_true(is.data.frame(diagnostics$condition))
  expect_equal(diagnostics$collinearity$VIF, 1)
})

test_that("table_meta_reg returns a gt table", {
  expect_s3_class(table_meta_reg(.fix_reg_prop), "gt_tbl")
})

test_that("plot_meta_reg supports fitted and influence diagnostics", {
  expect_s3_class(plot_meta_reg(.fix_reg_prop, type = "fitted"), "ggplot")
  expect_s3_class(plot_meta_reg(.fix_reg_prop, type = "influence"), "ggplot")
})

test_that("plot_meta_reg bubble includes interval layers", {
  p <- plot_meta_reg(.fix_reg_prop, type = "bubble")
  expect_s3_class(p, "ggplot")
  expect_gte(length(p$layers), 4L)
})

test_that("plot_meta_reg supports adjusted multivariable bubbles", {
  fit <- suppressWarnings(meta_reg(.fix_prop, dat_bcg, ~ablat + year,
    "author", min_studies_per_parameter = 2))
  p <- plot_meta_reg(fit, type = "bubble", moderator = "ablat")
  expect_s3_class(p, "ggplot")
  expect_gte(length(p$layers), 4L)
})

test_that("meta_reg: tidy table has correct columns", {
  tbl <- .fix_reg_prop$table

  expect_true(all(
    c(
      "Term", "Estimate", "CI.Lower", "CI.Upper", "p.value",
      "Estimate_bt", "CI.Lower_bt", "CI.Upper_bt"
    ) %in% names(tbl)
  ))
})

test_that("meta_reg: proportion back-transformed estimates are numeric", {
  tbl <- .fix_reg_prop$table

  expect_true(is.numeric(tbl$Estimate_bt))
  expect_true(is.numeric(tbl$CI.Lower_bt))
  expect_true(is.numeric(tbl$CI.Upper_bt))
  expect_equal(attr(tbl, "bt_label"), "odds-ratio scale")
})

test_that("meta_reg: ratio back-transformed estimates are positive", {
  tbl <- .fix_reg_ratio$table

  expect_true(all(tbl$Estimate_bt[tbl$backtransformable] > 0))
  expect_true(all(tbl$CI.Lower_bt[tbl$backtransformable] > 0))
  expect_true(all(tbl$CI.Upper_bt[tbl$backtransformable] > 0))
  expect_equal(attr(tbl, "bt_label"), "OR scale")
})

test_that("meta_reg: mean models have no back-transformed values", {
  tbl <- .fix_reg_mean$table

  expect_true(is.na(attr(tbl, "bt_label")))
  expect_true(all(is.na(tbl$Estimate_bt)))
  expect_true(all(is.na(tbl$CI.Lower_bt)))
  expect_true(all(is.na(tbl$CI.Upper_bt)))
})

test_that("meta_reg: meta.summary has expected columns", {
  ms <- .fix_reg_prop$meta.summary

  expect_true(all(
    c("tau2_null", "tau2", "R2_analog", "QE_pval", "QM", "k_included", "k_excluded") %in%
      names(ms)
  ))
})

test_that("meta_reg: r2_analog is numeric or NA", {
  expect_true(is.numeric(.fix_reg_prop$r2_analog) || is.na(.fix_reg_prop$r2_analog))
})

test_that("meta_reg: meta slot is rma object", {
  expect_s3_class(.fix_reg_prop$meta, "rma")
})

test_that("meta_reg: excluded_studies element exists", {
  expect_true("excluded_studies" %in% names(.fix_reg_prop))
})

test_that("meta_reg: multiple moderators accepted with stability warning", {
  expect_warning(r <- meta_reg(
    meta_object = .fix_prop,
    data = dat_bcg,
    moderators = ~ ablat + year,
    studylab = "author"
  ), "studies per coefficient")

  expect_s3_class(r, "meta_reg")
  expect_true(nrow(r$table) >= 3L)
})

test_that("meta_reg: studylab is required", {
  expect_error(
    meta_reg(
      meta_object = .fix_prop,
      data = dat_bcg,
      moderators = ~ablat
    ),
    "Provide 'studylab'"
  )
})

test_that("meta_reg: errors when studylab column is missing", {
  expect_error(
    meta_reg(
      meta_object = .fix_prop,
      data = dat_bcg,
      moderators = ~ablat,
      studylab = "not_a_column"
    ),
    "not found in data"
  )
})

test_that("meta_reg: errors when meta_object is wrong class", {
  expect_error(
    meta_reg(
      meta_object = list(),
      data = dat_bcg,
      moderators = ~ablat,
      studylab = "author"
    ),
    "supported metapropul"
  )
})

test_that("meta_reg: errors when moderators are missing", {
  expect_error(
    meta_reg(
      meta_object = .fix_prop,
      data = dat_bcg,
      studylab = "author"
    ),
    "moderators formula"
  )
})

test_that("meta_reg: errors when moderators is not a formula", {
  expect_error(
    meta_reg(
      meta_object = .fix_prop,
      data = dat_bcg,
      moderators = "ablat",
      studylab = "author"
    ),
    "must be a formula"
  )
})

test_that("meta_reg: errors when moderator column is missing", {
  expect_error(
    meta_reg(
      meta_object = .fix_prop,
      data = dat_bcg,
      moderators = ~not_a_variable,
      studylab = "author"
    ),
    "Moderator column"
  )
})

test_that("meta_reg: errors when study labels do not match", {
  bad <- dat_bcg
  bad$author <- paste0("X_", bad$author)

  expect_error(
    meta_reg(
      meta_object = .fix_prop,
      data = bad,
      moderators = ~ablat,
      studylab = "author"
    ),
    "not found in data"
  )
})

test_that("meta_reg: errors when meta_prop uses PFT", {
  expect_error(
    meta_reg(
      meta_object = .fix_prop_pft,
      data = dat_bcg,
      moderators = ~ablat,
      studylab = "author"
    ),
    "only when sm = 'PLOGIT'"
  )
})

test_that("meta_reg: warns when studies are excluded for missing moderator values", {
  bad <- dat_bcg
  bad$ablat[1:2] <- NA

  expect_warning(
    meta_reg(
      meta_object = .fix_prop,
      data = bad,
      moderators = ~ablat,
      studylab = "author"
    ),
    "excluded"
  )
})

test_that("print.meta_reg calls summary", {
  expect_output(print(.fix_reg_prop), "Meta-regression Summary")
})

test_that("summary.meta_reg: back-transformed table printed for proportions", {
  out <- capture_output(summary(.fix_reg_prop))
  expect_match(out, "Moderator effects on odds-ratio scale")
})

test_that("summary.meta_reg: scale note printed for OR", {
  out <- capture_output(summary(.fix_reg_ratio))
  expect_match(out, "log odds ratios")
})

test_that("summary.meta_reg: scale note printed for mean difference", {
  out <- capture_output(summary(.fix_reg_mean))
  expect_match(out, "mean difference scale")
})

test_that("summary.meta_reg: scale note printed for PLOGIT proportions", {
  out <- capture_output(summary(.fix_reg_prop))
  expect_match(out, "logit scale|odds ratios|predicted proportions")
})

test_that("summary.meta_reg: R2 analog note printed", {
  out <- capture_output(summary(.fix_reg_prop))
  expect_match(out, "analog = ")
})

test_that("summary.meta_reg: works when R2 analog is near zero or modest", {
  r <- meta_reg(
    meta_object = .fix_prop,
    data = dat_bcg,
    moderators = ~year,
    studylab = "author"
  )

  out <- capture_output(summary(r))
  expect_match(out, "analog = ")
  expect_output(print(r), "Meta-regression Summary")
})
