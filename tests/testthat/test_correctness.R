test_that(".format_i2 handles proportion-scale input", {
  expect_equal(metapropul:::.format_i2(0.234), 23.4)
})

test_that(".format_i2 handles percentage-scale input", {
  expect_equal(metapropul:::.format_i2(23.4), 23.4)
})

test_that(".format_i2 handles NA", {
  expect_true(is.na(metapropul:::.format_i2(NA_real_)))
})

test_that(".format_i2 is vector-safe", {
  expect_equal(
    metapropul:::.format_i2(c(0.10, 10, NA_real_)),
    c(10.0, 10.0, NA_real_)
  )
})

test_that(".backtransform_prop works for PLOGIT", {
  expect_equal(metapropul:::.backtransform_prop(0, "PLOGIT"), 0.5)
})

test_that(".backtransform_prop works for PFT", {
  expect_equal(metapropul:::.backtransform_prop(0, "PFT"), 0)
})

test_that(".backtransform_prop errors for unsupported summary measure", {
  expect_error(
    metapropul:::.backtransform_prop(0.5, "BAD"),
    "Unsupported summary measure"
  )
})

test_that(".fmt_pval formats p-values correctly", {
  expect_equal(metapropul:::.fmt_pval(NA_real_), "NA")
  expect_equal(metapropul:::.fmt_pval(0.2), "= 0.200")
  expect_equal(metapropul:::.fmt_pval(0.0005), "< 0.001")
})

test_that(".pooled_vals returns random-effects slots", {
  x <- metapropul:::.pooled_vals(.fix_ratio_events$meta, "random")

  expect_true(all(c("est", "lo", "hi") %in% names(x)))
  expect_equal(x$est, .fix_ratio_events$meta$TE.random)
  expect_equal(x$lo, .fix_ratio_events$meta$lower.random)
  expect_equal(x$hi, .fix_ratio_events$meta$upper.random)
})

test_that(".pooled_vals returns fixed/common-effect slots", {
  x <- metapropul:::.pooled_vals(.fix_ratio_events$meta, "fixed")

  expect_true(all(c("est", "lo", "hi") %in% names(x)))
  expect_equal(x$est, .fix_ratio_events$meta$TE.common)
  expect_equal(x$lo, .fix_ratio_events$meta$lower.common)
  expect_equal(x$hi, .fix_ratio_events$meta$upper.common)
})

test_that("meta_prop pooled summaries are on percentage scale", {
  s <- .fix_prop$meta.summary

  expect_true(is.numeric(s$Estimate))
  expect_true(is.numeric(s$lower))
  expect_true(is.numeric(s$upper))
  expect_true(s$Estimate >= 0 && s$Estimate <= 100)
  expect_true(s$lower >= 0 && s$lower <= 100)
  expect_true(s$upper >= 0 && s$upper <= 100)
})

test_that("meta_prop subgroup summaries are on percentage scale", {
  s <- .fix_prop_subgroup$meta.subgroup.summary

  expect_true(all(s$Estimate >= 0 & s$Estimate <= 100))
  expect_true(all(s$lower >= 0 & s$lower <= 100))
  expect_true(all(s$upper >= 0 & s$upper <= 100))
})

test_that("meta_prop summary method distinguishes PLOGIT and PFT", {
  out_logit <- capture_output(summary(.fix_prop))
  out_pft <- capture_output(summary(.fix_prop_pft))

  expect_match(out_logit, "logit")
  expect_match(out_pft, "Freeman-Tukey|PFT")
})

test_that("table_meta works for PFT proportion models", {
  gt <- table_meta(.fix_prop_pft)
  expect_s3_class(gt, "gt_tbl")
})

test_that("table_influence works for PFT proportion models", {
  gt <- table_influence(.fix_prop_pft)
  expect_s3_class(gt, "gt_tbl")
})

test_that("table_cumulative_meta works for PFT proportion models", {
  gt <- table_cumulative_meta(.fix_prop_pft)
  expect_s3_class(gt, "gt_tbl")
})

test_that("publication_bias rejects PFT proportion models", {
  expect_error(
    publication_bias(.fix_prop_pft),
    "only when sm = 'PLOGIT'"
  )
})

test_that("meta_reg rejects PFT proportion models", {
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

test_that("meta_reg stores sm for proportion models", {
  expect_equal(.fix_reg_prop$sm, "PLOGIT")
})

test_that("meta_reg does not store transformation for mean models", {
  expect_true(is.null(.fix_reg_mean$sm))
})

test_that("heterogeneity formatting helper is used consistently in summaries", {
  out_ratio <- capture_output(summary(.fix_ratio_events))
  out_mean <- capture_output(summary(.fix_mean))
  out_prop <- capture_output(summary(.fix_prop))

  expect_match(out_ratio, "I² = ")
  expect_match(out_mean, "I² = ")
  expect_match(out_prop, "I² = ")
})

test_that("table_meta pooled row exists for each model family", {
  gt_ratio <- table_meta(.fix_ratio_events)
  gt_mean <- table_meta(.fix_mean)
  gt_prop <- table_meta(.fix_prop)

  expect_true("Pooled" %in% gt_ratio$`_data`$Study)
  expect_true("Pooled" %in% gt_mean$`_data`$Study)
  expect_true("Pooled" %in% gt_prop$`_data`$Study)
})

test_that("table_influence can suppress heterogeneity columns", {
  gt <- table_influence(.fix_prop, include_heterogeneity = FALSE)
  labels <- gt$`_boxhead`$label

  expect_false(any(grepl("^I²", labels)))
  expect_false(any(grepl("^Tau²", labels)))
})

test_that("table_cumulative_meta can suppress heterogeneity columns", {
  gt <- table_cumulative_meta(.fix_prop, include_heterogeneity = FALSE)
  labels <- gt$`_boxhead`$label

  expect_false(any(grepl("^I²", labels)))
  expect_false(any(grepl("^Tau²", labels)))
})


test_that("meta_ratio, meta_mean, and meta_prop all return study-level tables", {
  expect_true(is.data.frame(.fix_ratio_events$table))
  expect_true(is.data.frame(.fix_mean$table))
  expect_true(is.data.frame(.fix_prop$table))

  expect_true(nrow(.fix_ratio_events$table) > 0)
  expect_true(nrow(.fix_mean$table) > 0)
  expect_true(nrow(.fix_prop$table) > 0)
})

test_that("influence objects exist for all core model families", {
  expect_s3_class(.fix_ratio_events$influence.meta, "metainf")
  expect_s3_class(.fix_mean$influence.meta, "metainf")
  expect_s3_class(.fix_prop$influence.meta, "metainf")
})

test_that("summary methods return object invisibly", {
  expect_identical(summary(.fix_ratio_events), .fix_ratio_events)
  expect_identical(summary(.fix_mean), .fix_mean)
  expect_identical(summary(.fix_prop), .fix_prop)
})
