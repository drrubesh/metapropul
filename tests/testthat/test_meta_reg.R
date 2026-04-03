test_that("meta_reg: returns correct class and structure", {
  r <- .fix_reg_prop

  expect_s3_class(r, "meta_reg")
  expect_named(
    r,
    c(
      "model", "meta", "table", "meta.summary", "r2_analog",
      "measure", "sm", "excluded_studies", "call"
    )
  )
  expect_equal(r$model, "meta-regression")
  expect_equal(r$measure, "Proportion")
  expect_equal(r$sm, "PLOGIT")
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
})

test_that("meta_reg: ratio back-transformed estimates are positive", {
  tbl <- .fix_reg_ratio$table

  expect_true(tbl$Estimate_bt[1] > 0)
  expect_true(tbl$CI.Lower_bt[1] > 0)
  expect_true(tbl$CI.Upper_bt[1] > 0)
  expect_equal(attr(tbl, "bt_label"), "OR (back-transformed)")
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

test_that("meta_reg: multiple moderators accepted", {
  r <- meta_reg(
    meta_object = .fix_prop,
    data = dat_bcg,
    moderators = ~ ablat + year,
    studylab = "author"
  )

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
    "meta_prop.*meta_ratio.*meta_mean"
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
  expect_match(out, "Back-transformed")
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
  expect_match(out, "logit scale|back-transformed to percentages")
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
