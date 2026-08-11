test_that("core models agree with direct meta calls", {
  direct_ratio <- meta::metabin(
    event.e = dat_bcg$tpos, n.e = dat_bcg$npos,
    event.c = dat_bcg$cpos, n.c = dat_bcg$cpos + dat_bcg$cneg,
    studlab = dat_bcg$author, sm = "OR", method.tau = "REML",
    method.random.ci = "HK", common = FALSE, random = TRUE,
    prediction = TRUE
  )
  expect_equal(.fix_ratio_events$meta$TE.random, direct_ratio$TE.random,
    tolerance = 1e-12)
  expect_equal(.fix_ratio_events$meta$tau2, direct_ratio$tau2,
    tolerance = 1e-12)

  direct_mean <- meta::metacont(
    n.e = dat_normand1999$n1i, mean.e = dat_normand1999$m1i,
    sd.e = dat_normand1999$sd1i, n.c = dat_normand1999$n2i,
    mean.c = dat_normand1999$m2i, sd.c = dat_normand1999$sd2i,
    studlab = dat_normand1999$source, sm = "MD", method.tau = "REML",
    method.random.ci = "HK", common = FALSE, random = TRUE,
    prediction = TRUE
  )
  expect_equal(.fix_mean$meta$TE.random, direct_mean$TE.random,
    tolerance = 1e-12)

  direct_prop <- meta::metaprop(
    event = dat_bcg$tpos, n = dat_bcg$npos, studlab = dat_bcg$author,
    sm = "PLOGIT", method = "Inverse", method.tau = "REML",
    method.random.ci = "HK", common = FALSE, random = TRUE,
    incr = 0.5, prediction = TRUE, backtransf = TRUE
  )
  expect_equal(.fix_prop$meta$TE.random, direct_prop$TE.random,
    tolerance = 1e-12)
})

test_that("fixed and random subgroup estimates agree with meta", {
  for (model in c("fixed", "random")) {
    got <- meta_prop(dat_bcg, "tpos", "npos", "author", "alloc",
      model = model)
    ref <- meta::metaprop(
      event = dat_bcg$tpos, n = dat_bcg$npos, studlab = dat_bcg$author,
      subgroup = dat_bcg$alloc, sm = "PLOGIT", method = "Inverse",
      method.tau = "REML", method.random.ci = "HK",
      common = model == "fixed", random = model == "random",
      incr = 0.5, prediction = TRUE, backtransf = TRUE
    )
    slot <- if (model == "fixed") "TE.common.w" else "TE.random.w"
    expect_equal(got$meta[[slot]], ref[[slot]], tolerance = 1e-12)
    expect_equal(nrow(got$meta.subgroup.summary),
      length(unique(dat_bcg$alloc)))
  }
})

test_that("meta-regression coefficients agree with direct metafor fit", {
  got <- meta_reg(.fix_prop, dat_bcg, ~ ablat, "author",
    min_studies_per_parameter = 5)
  ref <- metafor::rma(
    yi = .fix_prop$meta$TE, sei = .fix_prop$meta$seTE,
    mods = ~ dat_bcg$ablat, method = "REML", test = "z"
  )
  expect_equal(as.numeric(stats::coef(got$meta)),
    as.numeric(stats::coef(ref)), tolerance = 1e-10)
})

test_that("study-count matrix and edge values behave deliberately", {
  make_dat <- function(k) data.frame(
    event = rep(c(0, 1, 50, 100), length.out = k),
    n = rep(100, k),
    study = paste0("S", seq_len(k))
  )
  expect_error(meta_prop(make_dat(1), "event", "n"), "at least 2")
  for (k in c(2, 10, 50, 100, 200)) {
    fit <- suppressWarnings(meta_prop(make_dat(k), "event", "n", "study",
      ci_method = "classic", prediction_interval = FALSE))
    expect_s3_class(fit, "meta_prop")
    expect_equal(fit$meta$k, k)
    expect_equal(nrow(fit$table), k)
  }
})

test_that("missing values, duplicate labels, zeros, and singleton subgroups are covered", {
  dat <- data.frame(event = c(0, 2, NA, 9), n = c(10, 10, 10, 10),
    study = c("dup", "dup", "three", "four"))
  fit <- suppressWarnings(meta_prop(dat, "event", "n", "study",
    ci_method = "classic"))
  expect_false(anyNA(fit$meta$TE))
  expect_equal(nrow(fit$exclusion_log), 1L)
  expect_match(fit$exclusion_log$Reason, "event")
  expect_equal(anyDuplicated(fit$meta$studlab), 0L)

  sg <- data.frame(event = c(1, 2, 3, 4), n = rep(10, 4),
    study = letters[1:4], group = c("singleton", "other", "other", "other"))
  expect_warning(
    out <- meta_prop(sg, "event", "n", "study", "group",
      ci_method = "classic"),
    "singleton"
  )
  expect_equal(nrow(out$meta.subgroup.summary), 2L)

  ratio <- data.frame(a = c(0, 1), na = c(10, 10),
    c = c(1, 0), nc = c(10, 10), lab = c("same", "same"))
  rr <- suppressWarnings(meta_ratio(ratio, "a", "na", "c", "nc",
    studylab = "lab", ci_method = "classic"))
  expect_equal(anyDuplicated(rr$meta$studlab), 0L)
  ratio$a[1] <- -1
  expect_error(meta_ratio(ratio, "a", "na", "c", "nc"), "non-negative")
})

test_that("forest plot handles all-boundary proportions", {
  d <- data.frame(event = c(0, 100), n = c(100, 100), study = c("zero", "all"))
  path <- tempfile(fileext = ".pdf")
  fit <- suppressWarnings(meta_prop(d, "event", "n", "study",
    ci_method = "classic"))
  expect_true(forest_meta(fit, save_as = "pdf", filename = path))
  expect_true(file.exists(path))
})
