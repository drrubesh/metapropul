test_that("meta_mean: raw group data path returns correct class and structure", {
  r <- .fix_mean

  expect_s3_class(r, "meta_mean")
  expect_named(
    r,
    c(
      "meta", "table", "meta.subgroup.summary", "influence.analysis",
      "model", "measure", "tau_method", "ci_method", "subgroup"
    )
  )
  expect_s3_class(r$meta, "metacont")
  expect_true(is.data.frame(r$table))
  expect_equal(nrow(r$table), 9L)
  expect_true(all(
    c("Study", "Estimate", "lower", "upper", "weight", "subgroup") %in% names(r$table)
  ))
  expect_equal(r$measure, "MD")
  expect_false(r$subgroup)
})

test_that("meta_mean: raw estimates are finite", {
  r <- .fix_mean
  expect_true(all(is.finite(r$table$Estimate)))
  expect_true(all(is.finite(r$table$lower)))
  expect_true(all(is.finite(r$table$upper)))
})

test_that("meta_mean: SMD measure stored correctly", {
  expect_equal(.fix_mean_smd$measure, "SMD")
})

test_that("meta_mean: fixed model path works", {
  r <- .fix_mean_fixed
  expect_equal(r$model, "fixed")
  expect_s3_class(r$meta, "meta")
})

test_that("meta_mean: weights sum to approximately 100", {
  expect_equal(sum(.fix_mean$table$weight), 100, tolerance = 0.01)
})

test_that("meta_mean: pre-computed effect-size path uses metagen", {
  r <- .fix_mean_precomp

  expect_s3_class(r, "meta_mean")
  expect_s3_class(r$meta, "metagen")
  expect_equal(nrow(r$table), 9L)
  expect_true(all(
    c("Study", "Estimate", "lower", "upper", "weight", "subgroup") %in% names(r$table)
  ))
})

test_that("meta_mean: subgroup summary is populated", {
  r <- .fix_mean_subgroup

  expect_true(r$subgroup)
  expect_false(is.null(r$meta.subgroup.summary))
  expect_true(is.data.frame(r$meta.subgroup.summary))
  expect_true(nrow(r$meta.subgroup.summary) >= 1L)
  expect_true(all(
    c("Subgroup", "Estimate", "lower", "upper", "Tau2", "I2") %in%
      names(r$meta.subgroup.summary)
  ))
})

test_that("meta_mean: prediction interval stored when enabled", {
  expect_false(is.null(.fix_mean$meta$lower.predict))
})

test_that("meta_mean: prediction_interval = FALSE suppresses prediction interval", {
  r <- meta_mean(
    data = dat_normand1999,
    mean.e = "m1i", sd.e = "sd1i", n.e = "n1i",
    mean.c = "m2i", sd.c = "sd2i", n.c = "n2i",
    studylab = "source",
    prediction_interval = FALSE
  )

  expect_true(is.null(r$meta$lower.predict) || is.na(r$meta$lower.predict))
})

test_that("meta_mean: influence analysis is a metainf object", {
  expect_s3_class(.fix_mean$influence.analysis, "metainf")
})

test_that("meta_mean: errors when no input path is given", {
  expect_error(
    meta_mean(data = dat_normand1999, studylab = "source"),
    "raw group data"
  )
})

test_that("meta_mean: errors when effect is given without confidence interval bounds", {
  expect_error(
    meta_mean(data = dat_normand1999, effect = "md"),
    "lower.*upper"
  )
})

test_that("meta_mean: errors when studylab column is missing", {
  expect_error(
    meta_mean(
      data = dat_normand1999,
      mean.e = "m1i", sd.e = "sd1i", n.e = "n1i",
      mean.c = "m2i", sd.c = "sd2i", n.c = "n2i",
      studylab = "not_a_column"
    ),
    "not found"
  )
})

test_that("meta_mean: auto study labels created when studylab is NULL", {
  r <- meta_mean(
    data = dat_normand1999,
    mean.e = "m1i", sd.e = "sd1i", n.e = "n1i",
    mean.c = "m2i", sd.c = "sd2i", n.c = "n2i"
  )

  expect_true(all(grepl("^Study_", r$table$Study)))
})

test_that("meta_mean: verbose = TRUE produces startup message", {
  expect_message(
    meta_mean(
      dat_normand1999,
      mean.e = "m1i", sd.e = "sd1i", n.e = "n1i",
      mean.c = "m2i", sd.c = "sd2i", n.c = "n2i",
      verbose = TRUE
    ),
    "Starting"
  )
})

test_that("print.meta_mean calls summary without error", {
  expect_output(print(.fix_mean), "Meta-analysis Summary")
})

test_that("summary.meta_mean: MD path prints pooled MD", {
  out <- capture_output(summary(.fix_mean))
  expect_match(out, "Pooled MD")
})

test_that("summary.meta_mean: SMD path prints pooled SMD", {
  out <- capture_output(summary(.fix_mean_smd))
  expect_match(out, "Pooled SMD")
})

test_that("summary.meta_mean: subgroup path prints subgroup results", {
  expect_output(summary(.fix_mean_subgroup), "Subgroup")
})

test_that("summary.meta_mean: Q statistic is printed", {
  out <- capture_output(summary(.fix_mean))
  expect_match(out, "Q = ")
})

test_that("summary.meta_mean: I2 note uses correct statistical language", {
  out <- capture_output(summary(.fix_mean))
  expect_match(out, "proportion of total observed variability")
})

test_that("summary.meta_mean: prediction interval is printed when available", {
  out <- capture_output(summary(.fix_mean))
  expect_match(out, "Prediction interval")
})
