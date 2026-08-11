generic_data <- data.frame(
  study = paste("Study", 1:6), effect = c(-0.2, 0.1, 0.3, -0.1, 0.2, 0.05),
  se = c(0.12, 0.15, 0.11, 0.18, 0.14, 0.13),
  region = rep(c("A", "B"), each = 3), year = 2010:2015
)

cor_data <- data.frame(
  study = paste("Correlation", 1:6),
  r = c(0.12, 0.25, -0.05, 0.31, 0.18, 0.08),
  n = c(80, 120, 95, 150, 110, 90)
)

rate_data <- data.frame(
  study = paste("Cohort", 1:6), events = c(4, 0, 12, 7, 18, 3),
  person_years = c(800, 650, 1200, 900, 1500, 700)
)

test_that("meta_generic agrees with direct metagen", {
  fit <- meta_generic(generic_data, "effect", se = "se", studylab = "study",
    ci_method = "classic")
  ref <- meta::metagen(generic_data$effect, generic_data$se,
    studlab = generic_data$study, method.tau = "REML",
    method.random.ci = "classic", common = FALSE, random = TRUE,
    prediction = TRUE, sm = "Generic effect")
  expect_s3_class(fit, "meta_generic")
  expect_equal(fit$meta$TE.random, ref$TE.random, tolerance = 1e-12)
  expect_equal(fit$meta$tau2, ref$tau2, tolerance = 1e-12)
  expect_true(is.data.frame(fit$analysis_data))
})

test_that("meta_generic supports CI input, exp transformation, and subgroups", {
  d <- transform(generic_data,
    log_effect = log(exp(effect)), lower = effect - 1.96 * se,
    upper = effect + 1.96 * se)
  fit <- meta_generic(d, "log_effect", lower = "lower", upper = "upper",
    studylab = "study", subgroup = "region", backtransform = "exp",
    ci_method = "classic")
  expect_true(all(fit$table$Estimate > 0))
  expect_equal(nrow(fit$meta.subgroup.summary), 2L)
  expect_true(is.data.frame(fit$subgroup_test))
})

test_that("meta_cor agrees with direct Fisher-z meta-analysis", {
  fit <- meta_cor(cor_data, "r", "n", "study", ci_method = "classic")
  ref <- meta::metacor(cor_data$r, cor_data$n, studlab = cor_data$study,
    sm = "ZCOR", method.tau = "REML", method.random.ci = "classic",
    common = FALSE, random = TRUE, prediction = TRUE)
  expect_s3_class(fit, "meta_cor")
  expect_equal(fit$meta$TE.random, ref$TE.random, tolerance = 1e-12)
  expect_true(all(fit$table$Estimate > -1 & fit$table$Estimate < 1))
})

test_that("meta_rate agrees with direct incidence-rate meta-analysis", {
  fit <- meta_rate(rate_data, "events", "person_years", "study",
    irscale = 1000, ci_method = "classic")
  ref <- meta::metarate(rate_data$events, rate_data$person_years,
    studlab = rate_data$study, sm = "IRLN", method = "Inverse", incr = 0.5,
    irscale = 1000, irunit = "person-years", method.tau = "REML",
    method.random.ci = "classic", common = FALSE, random = TRUE,
    prediction = TRUE)
  expect_s3_class(fit, "meta_rate")
  expect_equal(fit$meta$TE.random, ref$TE.random, tolerance = 1e-12)
  expect_true(all(fit$table$Estimate >= 0))
})

test_that("additional models integrate with tables, forests, and regression", {
  generic <- meta_generic(generic_data, "effect", se = "se", studylab = "study",
    ci_method = "classic")
  expect_s3_class(table_meta(generic), "gt_tbl")
  path <- tempfile(fileext = ".pdf")
  expect_message(forest_meta(generic, save_as = "pdf", filename = path), "saved")
  expect_true(file.exists(path))
  reg <- suppressWarnings(meta_reg(generic, generic_data, ~year, "study",
    min_studies_per_parameter = 2))
  expect_s3_class(reg, "meta_reg")
})

test_that("additional models validate scientific boundaries", {
  expect_error(meta_generic(generic_data, "effect", se = "se",
    variance = "se"), "exactly one")
  bad_cor <- transform(cor_data, r = 1)
  expect_error(meta_cor(bad_cor, "r", "n"), "strictly")
  bad_rate <- transform(rate_data, person_years = 0)
  expect_error(meta_rate(bad_rate, "events", "person_years"), "positive")
})
