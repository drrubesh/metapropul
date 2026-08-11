test_that("meta_ratio: event-count path returns correct class and structure", {
  r <- .fix_ratio_events

  expect_s3_class(r, "meta_ratio")
  expect_named(
    r,
    c(
      "meta", "table", "meta.subgroup.summary", "influence.analysis",
      "influence.meta", "subgroup_test", "analysis_data", "excluded_data",
      "exclusion_log", "label_audit", "settings",
      "model", "measure", "tau_method", "ci_method", "subgroup"
    )
  )
  expect_s3_class(r$meta, "metabin")
  expect_true(is.data.frame(r$table))
  expect_equal(nrow(r$table), 13L)
  expect_true(all(
    c("Study", "Estimate", "lower", "upper", "weight", "subgroup") %in% names(r$table)
  ))
  expect_null(r$meta.subgroup.summary)
  expect_false(r$subgroup)
  expect_equal(r$model, "random")
  expect_equal(r$measure, "OR")
})

test_that("meta_ratio: OR estimates are back-transformed and positive", {
  r <- .fix_ratio_events
  expect_true(all(is.finite(r$table$Estimate)))
  expect_true(all(is.finite(r$table$lower)))
  expect_true(all(is.finite(r$table$upper)))
  expect_true(all(r$table$Estimate > 0))
  expect_true(all(r$table$lower > 0))
  expect_true(all(r$table$upper > 0))
})

test_that("meta_ratio: weights sum to approximately 100", {
  expect_equal(sum(.fix_ratio_events$table$weight), 100, tolerance = 0.01)
})

test_that("meta_ratio: fixed-effects model stored correctly", {
  r <- .fix_ratio_fixed
  expect_equal(r$model, "fixed")
  expect_s3_class(r$meta, "meta")
})

test_that("meta_ratio: RR measure stored correctly", {
  expect_equal(.fix_ratio_rr$measure, "RR")
})

test_that("meta_ratio: HR is accepted with pre-computed effect sizes", {
  r <- meta_ratio(
    data = bcg_clean,
    effect = "or_est",
    lower = "or_lo",
    upper = "or_hi",
    studylab = "author",
    measure = "HR"
  )

  expect_s3_class(r, "meta_ratio")
  expect_equal(r$measure, "HR")
})

test_that("meta_ratio: HR errors when raw event counts are supplied", {
  expect_error(
    meta_ratio(
      data = transform(dat_bcg, ncon = cpos + cneg),
      event.e = "tpos", n.e = "npos",
      event.c = "cpos", n.c = "ncon",
      studylab = "author",
      measure = "HR"
    ),
    "requires pre-computed effect sizes"
  )
})

test_that("meta_ratio: pre-computed effect path works", {
  r <- .fix_ratio_precomp

  expect_s3_class(r, "meta_ratio")
  expect_s3_class(r$meta, "metagen")
  expect_true(nrow(r$table) >= 1L)
  expect_true(nrow(r$table) <= 13L)
  expect_true(all(
    c("Study", "Estimate", "lower", "upper", "weight", "subgroup") %in% names(r$table)
  ))
})

test_that("meta_ratio accepts log-ratio estimates with standard errors", {
  dat <- data.frame(
    study = paste("Study", 1:4),
    log_or = log(c(0.70, 0.85, 1.10, 1.25)),
    se = c(0.18, 0.15, 0.20, 0.17)
  )
  fit <- meta_ratio(dat, effect = "log_or", se = "se",
    effect_scale = "log", studylab = "study", measure = "OR")
  expect_s3_class(fit, "meta_ratio")
  expect_equal(fit$meta$TE, dat$log_or)
  expect_equal(fit$meta$seTE, dat$se)
  expect_identical(fit$settings$uncertainty, "se")
  expect_error(meta_ratio(dat, effect = "log_or", se = "se"),
    "effect_scale")
})

test_that("meta_ratio: ci_level changes SE calculation", {
  r90 <- meta_ratio(
    data = bcg_clean,
    effect = "or_est", lower = "or_lo", upper = "or_hi",
    studylab = "author",
    ci_level = 0.90
  )

  expect_s3_class(r90, "meta_ratio")
  expect_false(identical(r90$meta$tau2, .fix_ratio_precomp$meta$tau2))
})

test_that("meta_ratio: subgroup analysis populates summary table", {
  r <- .fix_ratio_subgroup

  expect_true(r$subgroup)
  expect_false(is.null(r$meta.subgroup.summary))
  expect_true(is.data.frame(r$meta.subgroup.summary))
  expect_true(nrow(r$meta.subgroup.summary) >= 2L)
  expect_true(all(
    c("Subgroup", "Estimate", "lower", "upper", "Tau2", "I2") %in%
      names(r$meta.subgroup.summary)
  ))
})

test_that("meta_ratio: large k path works", {
  r <- .fix_ratio_large

  expect_s3_class(r, "meta_ratio")
  expect_equal(nrow(r$table), 70L)
})

test_that("meta_ratio: prediction interval stored on meta object when enabled", {
  expect_false(is.null(.fix_ratio_events$meta$lower.predict))
})

test_that("meta_ratio: prediction_interval = FALSE suppresses prediction interval", {
  r <- meta_ratio(
    data = transform(dat_bcg, ncon = cpos + cneg),
    event.e = "tpos", n.e = "npos",
    event.c = "cpos", n.c = "ncon",
    studylab = "author",
    prediction_interval = FALSE
  )

  expect_true(is.null(r$meta$lower.predict) || is.na(r$meta$lower.predict))
})

test_that("meta_ratio: influence outputs include raw and tidy forms", {
  expect_s3_class(.fix_ratio_events$influence.meta, "metainf")
  expect_s3_class(.fix_ratio_events$influence.analysis, "data.frame")
})

test_that("meta_ratio: verbose = TRUE produces startup message", {
  expect_message(
    meta_ratio(
      transform(dat_bcg, ncon = cpos + cneg),
      event.e = "tpos", n.e = "npos",
      event.c = "cpos", n.c = "ncon",
      studylab = "author",
      verbose = TRUE
    ),
    "Starting"
  )
})

test_that("meta_ratio: warns when pre-computed values contain invalid zeros", {
  bad <- bcg_clean
  bad$or_est[1] <- 0
  bad$or_lo[1] <- 0

  expect_warning(
    meta_ratio(
      data = bad,
      effect = "or_est",
      lower = "or_lo",
      upper = "or_hi",
      studylab = "author"
    ),
    "excluded"
  )
})

test_that("meta_ratio: errors when event counts are given without totals", {
  expect_error(
    meta_ratio(dat_bcg, event.e = "tpos", event.c = "cpos"),
    "n.e.*n.c"
  )
})

test_that("meta_ratio: errors when effect is given without confidence interval", {
  expect_error(
    meta_ratio(dat_bcg, effect = "or_est"),
    "lower.*upper"
  )
})

test_that("meta_ratio: errors when neither raw counts nor effect sizes are supplied", {
  expect_error(
    meta_ratio(dat_bcg, studylab = "author"),
    "event counts.*effect sizes"
  )
})

test_that("meta_ratio rejects ambiguous inputs and records continuity settings", {
  binary <- transform(dat_bcg, ncon = cpos + cneg)
  both <- transform(binary, est = 1, lo = 0.8, hi = 1.2)
  expect_error(
    meta_ratio(both, "tpos", "npos", "cpos", "ncon",
      effect = "est", lower = "lo", upper = "hi"),
    "not both"
  )
  fit <- suppressWarnings(meta_ratio(binary, "tpos", "npos", "cpos", "ncon",
    incr = 0.25, method_incr = "all", allstudies = TRUE))
  expect_equal(fit$settings$continuity_correction, 0.25)
  expect_equal(fit$settings$method_incr, "all")
  expect_true(fit$settings$allstudies)
})

test_that("meta_ratio: auto study labels created when studylab is NULL", {
  r <- meta_ratio(
    data = transform(dat_bcg, ncon = cpos + cneg),
    event.e = "tpos", n.e = "npos",
    event.c = "cpos", n.c = "ncon"
  )

  expect_true(all(grepl("^Study_", r$table$Study)))
})

test_that("meta_ratio: ci_method classic is accepted", {
  r <- meta_ratio(
    data = transform(dat_bcg, ncon = cpos + cneg),
    event.e = "tpos", n.e = "npos",
    event.c = "cpos", n.c = "ncon",
    ci_method = "classic"
  )

  expect_equal(r$ci_method, "classic")
})

test_that("meta_ratio: tau_method DL is accepted", {
  r <- meta_ratio(
    transform(dat_bcg, ncon = cpos + cneg),
    event.e = "tpos", n.e = "npos",
    event.c = "cpos", n.c = "ncon",
    tau_method = "DL"
  )

  expect_equal(r$tau_method, "DL")
})

test_that("print.meta_ratio calls summary without error", {
  expect_output(print(.fix_ratio_events), "Meta-analysis Summary")
})

test_that("summary.meta_ratio: OR path prints pooled OR", {
  expect_output(summary(.fix_ratio_events), "Pooled OR")
})

test_that("summary.meta_ratio: RR path prints pooled RR", {
  expect_output(summary(.fix_ratio_rr), "Pooled RR")
})

test_that("summary.meta_ratio: fixed model path mentions common-effect model", {
  expect_output(summary(.fix_ratio_fixed), "Common-effect")
})

test_that("summary.meta_ratio: subgroup path prints subgroup results", {
  expect_output(summary(.fix_ratio_subgroup), "Subgroup")
})

test_that("summary.meta_ratio: I2 note uses correct statistical language", {
  out <- capture_output(summary(.fix_ratio_events))
  expect_match(out, "proportion of total observed variability")
})

test_that("summary.meta_ratio: Q statistic is printed", {
  out <- capture_output(summary(.fix_ratio_events))
  expect_match(out, "Q = ")
})

test_that("summary.meta_ratio: prediction interval is printed when available", {
  out <- capture_output(summary(.fix_ratio_events))
  expect_match(out, "Prediction interval")
})

test_that("meta_ratio: errors when studylab column is missing", {
  expect_error(
    meta_ratio(
      data = transform(dat_bcg, ncon = cpos + cneg),
      event.e = "tpos", n.e = "npos",
      event.c = "cpos", n.c = "ncon",
      studylab = "not_a_column"
    ),
    "not found"
  )
})
