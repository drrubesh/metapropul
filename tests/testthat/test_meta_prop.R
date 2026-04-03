test_that("meta_prop: returns correct class and structure", {
  r <- .fix_prop

  expect_s3_class(r, "meta_prop")
  expect_named(
    r,
    c(
      "meta", "table", "meta.summary", "meta.subgroup.summary",
      "influence.analysis", "influence.meta", "model",
      "measure", "sm", "tau_method", "ci_method", "subgroup"
    )
  )
  expect_s3_class(r$meta, "metaprop")
  expect_true(is.data.frame(r$table))
  expect_equal(nrow(r$table), 13L)
  expect_equal(r$measure, "Proportion")
  expect_equal(r$sm, "PLOGIT")
  expect_false(r$subgroup)
})

test_that("meta_prop: proportions are percentages on 0-100 scale", {
  r <- .fix_prop

  expect_true(all(is.finite(r$table$Proportion)))
  expect_true(all(is.finite(r$table$lower)))
  expect_true(all(is.finite(r$table$upper)))
  expect_true(all(r$table$Proportion >= 0 & r$table$Proportion <= 100))
  expect_true(all(r$table$lower >= 0 & r$table$lower <= 100))
  expect_true(all(r$table$upper >= 0 & r$table$upper <= 100))
})

test_that("meta_prop: weights sum to approximately 100", {
  expect_equal(sum(.fix_prop$table$weight), 100, tolerance = 0.01)
})

test_that("meta_prop: fixed model path works", {
  expect_equal(.fix_prop_fixed$model, "fixed")
  expect_s3_class(.fix_prop_fixed$meta, "meta")
})

test_that("meta_prop: PFT transformation is accepted", {
  expect_equal(.fix_prop_pft$sm, "PFT")
  expect_s3_class(.fix_prop_pft, "meta_prop")
})

test_that("meta_prop: meta.summary contains expected fields and prediction interval", {
  s <- .fix_prop$meta.summary

  expect_true(all(
    c("Estimate", "lower", "upper", "pred.lower", "pred.upper", "I2", "Tau2") %in%
      names(s)
  ))
  expect_false(is.na(s$pred.lower))
  expect_false(is.na(s$pred.upper))
})

test_that("meta_prop: prediction_interval = FALSE gives NA prediction bounds", {
  s <- .fix_prop_no_pi$meta.summary

  expect_true(is.na(s$pred.lower))
  expect_true(is.na(s$pred.upper))
})

test_that("meta_prop: subgroup summary extracted from fitted model", {
  r <- .fix_prop_subgroup

  expect_true(r$subgroup)
  expect_false(is.null(r$meta.subgroup.summary))
  expect_true(is.data.frame(r$meta.subgroup.summary))
  expect_true("Subgroup" %in% names(r$meta.subgroup.summary))
  expect_equal(
    sort(r$meta.subgroup.summary$Subgroup),
    sort(unique(dat_bcg$alloc))
  )
})

test_that("meta_prop: subgroup estimates are percentages", {
  s <- .fix_prop_subgroup$meta.subgroup.summary

  expect_true(all(s$Estimate >= 0 & s$Estimate <= 100))
  expect_true(all(s$lower >= 0 & s$lower <= 100))
  expect_true(all(s$upper >= 0 & s$upper <= 100))
})

test_that("meta_prop: influence.analysis is a tidy data frame", {
  inf <- .fix_prop$influence.analysis

  expect_true(is.data.frame(inf))
  expect_true(all(c("Study", "Proportion", "lower", "upper") %in% names(inf)))
})

test_that("meta_prop: influence.meta is a metainf object", {
  expect_s3_class(.fix_prop$influence.meta, "metainf")
})

test_that("meta_prop: auto study labels created when studylab is NULL", {
  r <- meta_prop(data = dat_bcg, event = "tpos", n = "npos")

  expect_true(all(grepl("^Study_", r$table$Study)))
})

test_that("meta_prop: errors when studylab column is missing", {
  expect_error(
    meta_prop(data = dat_bcg, event = "tpos", n = "npos", studylab = "not_a_column"),
    "not found"
  )
})

test_that("meta_prop: verbose = TRUE produces startup message", {
  expect_message(
    meta_prop(dat_bcg, event = "tpos", n = "npos", verbose = TRUE),
    "Starting"
  )
})

test_that("print.meta_prop calls summary without error", {
  expect_output(print(.fix_prop), "Meta-analysis Summary")
})

test_that("summary.meta_prop: pooled proportion is printed", {
  out <- capture_output(summary(.fix_prop))
  expect_match(out, "Pooled proportion")
})

test_that("summary.meta_prop: prediction interval is printed when available", {
  out <- capture_output(summary(.fix_prop))
  expect_match(out, "Prediction interval")
})

test_that("summary.meta_prop: subgroup path prints subgroup results", {
  expect_output(summary(.fix_prop_subgroup), "Subgroup")
})

test_that("summary.meta_prop: Q statistic is printed", {
  out <- capture_output(summary(.fix_prop))
  expect_match(out, "Q = ")
})

test_that("summary.meta_prop: I2 note uses correct statistical language", {
  out <- capture_output(summary(.fix_prop))
  expect_match(out, "proportion of total observed variability")
})

test_that("summary.meta_prop: PLOGIT note is present for PLOGIT models", {
  out <- capture_output(summary(.fix_prop))
  expect_match(out, "logit")
})

test_that("summary.meta_prop: PFT note is present for PFT models", {
  out <- capture_output(summary(.fix_prop_pft))
  expect_match(out, "Freeman-Tukey|PFT")
})

test_that("summary.meta_prop: fixed model note is printed", {
  out <- capture_output(summary(.fix_prop_fixed))
  expect_match(out, "Common-effect")
})
