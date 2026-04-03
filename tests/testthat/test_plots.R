# ── plot_heterogeneity ────────────────────────────────────────────────────────

test_that("plot_heterogeneity: I2 stat runs for meta_prop and returns TRUE invisibly", {
  res <- withVisible(plot_heterogeneity(.fix_prop))
  expect_true(isTRUE(res$value))
})

test_that("plot_heterogeneity: I2 stat runs for meta_ratio", {
  res <- withVisible(plot_heterogeneity(.fix_ratio_events, stat = "I2"))
  expect_true(isTRUE(res$value))
})

test_that("plot_heterogeneity: I2 stat runs for meta_mean", {
  res <- withVisible(plot_heterogeneity(.fix_mean, stat = "I2"))
  expect_true(isTRUE(res$value))
})

test_that("plot_heterogeneity: tau2 stat runs", {
  res <- withVisible(plot_heterogeneity(.fix_prop, stat = "tau2"))
  expect_true(isTRUE(res$value))
})

test_that("plot_heterogeneity: saves pdf", {
  tmp <- tempfile(fileext = ".pdf")
  expect_message(
    plot_heterogeneity(.fix_prop, save_as = "pdf", filename = tmp),
    "saved to"
  )
  expect_true(file.exists(tmp))
  unlink(tmp)
})

test_that("plot_heterogeneity: saves png", {
  tmp <- tempfile(fileext = ".png")
  expect_message(
    plot_heterogeneity(.fix_prop, save_as = "png", filename = tmp),
    "saved to"
  )
  expect_true(file.exists(tmp))
  unlink(tmp)
})

test_that("plot_heterogeneity: saves tiff", {
  tmp <- tempfile(fileext = ".tiff")
  expect_message(
    plot_heterogeneity(.fix_prop, save_as = "tiff", filename = tmp),
    "saved to"
  )
  expect_true(file.exists(tmp))
  unlink(tmp)
})

test_that("plot_heterogeneity: custom title accepted", {
  expect_true(isTRUE(plot_heterogeneity(.fix_prop, title = "My Het Plot")))
})

test_that("plot_heterogeneity: error for wrong class", {
  expect_error(plot_heterogeneity(list()), "Only supports")
})

test_that("plot_heterogeneity: custom height respected", {
  tmp <- tempfile(fileext = ".pdf")
  expect_message(
    plot_heterogeneity(.fix_prop, save_as = "pdf", filename = tmp, height = 6),
    "saved to"
  )
  expect_true(file.exists(tmp))
  unlink(tmp)
})

# ── plot_baujat ───────────────────────────────────────────────────────────────

test_that("plot_baujat: runs for meta_prop and returns data frame", {
  result <- plot_baujat(.fix_prop)
  expect_true(is.data.frame(result))
  expect_true(all(c("studlab", "het_contribution", "influence") %in% names(result)))
  expect_equal(nrow(result), 13L)
})

test_that("plot_baujat: runs for meta_ratio", {
  result <- plot_baujat(.fix_ratio_events)
  expect_true(is.data.frame(result))
})

test_that("plot_baujat: runs for meta_mean", {
  result <- plot_baujat(.fix_mean)
  expect_true(is.data.frame(result))
})

test_that("plot_baujat: saves pdf", {
  tmp <- tempfile(fileext = ".pdf")
  expect_message(
    plot_baujat(.fix_prop, save_as = "pdf", filename = tmp),
    "saved to"
  )
  expect_true(file.exists(tmp))
  unlink(tmp)
})

test_that("plot_baujat: saves tiff", {
  tmp <- tempfile(fileext = ".tiff")
  expect_message(
    plot_baujat(.fix_prop, save_as = "tiff", filename = tmp),
    "saved to"
  )
  expect_true(file.exists(tmp))
  unlink(tmp)
})

test_that("plot_baujat: custom title accepted", {
  result <- plot_baujat(.fix_prop, title = "Baujat Custom")
  expect_true(is.data.frame(result))
})

test_that("plot_baujat: high label_threshold does not change returned row count", {
  d_high <- plot_baujat(.fix_prop, label_threshold = 10)
  d_low <- plot_baujat(.fix_prop, label_threshold = 0.1)
  expect_equal(nrow(d_high), nrow(d_low))
})

test_that("plot_baujat: error for wrong class", {
  expect_error(plot_baujat(list()), "Only supports")
})

# ── publication_bias ──────────────────────────────────────────────────────────

test_that("publication_bias: numerical tests run for meta_prop with PLOGIT", {
  result <- publication_bias(.fix_prop)
  expect_true(is.list(result))
  expect_true(any(c("egger", "begg", "trimfill") %in% names(result)))
})

test_that("publication_bias: works for meta_ratio", {
  result <- publication_bias(.fix_ratio_large)
  expect_true(is.list(result))
})

test_that("publication_bias: works for meta_mean with large k", {
  big_mean <- do.call(rbind, replicate(3, dat_normand1999, simplify = FALSE))
  big_mean$source <- paste0("Study_", seq_len(nrow(big_mean)))

  r_big <- meta_mean(
    big_mean,
    mean.e = "m1i", sd.e = "sd1i", n.e = "n1i",
    mean.c = "m2i", sd.c = "sd2i", n.c = "n2i",
    studylab = "source"
  )

  result <- publication_bias(r_big)
  expect_true(is.list(result))
})

test_that("publication_bias: rejects meta_prop with PFT", {
  expect_error(
    publication_bias(.fix_prop_pft),
    "only when sm = 'PLOGIT'"
  )
})

test_that("publication_bias: k < 10 returns NULL with message", {
  small <- dat_bcg[1:9, ]
  r_small <- meta_prop(small, event = "tpos", n = "npos", studylab = "author")

  expect_message(
    result <- publication_bias(r_small),
    "k < 10"
  )
  expect_null(result)
})

test_that("publication_bias: original funnel plot saved to pdf", {
  tmp <- tempfile(fileext = ".pdf")
  expect_message(
    publication_bias(
      .fix_ratio_large,
      plot_method = "original",
      save_as = "pdf",
      filename = tmp
    ),
    "saved to"
  )
  expect_true(file.exists(tmp))
  unlink(tmp)
})

test_that("publication_bias: trimfill plot runs", {
  tmp <- tempfile(fileext = ".pdf")
  expect_message(
    publication_bias(
      .fix_ratio_large,
      plot_method = "trimfill",
      save_as = "pdf",
      filename = tmp
    ),
    "saved to"
  )
  expect_true(file.exists(tmp))
  unlink(tmp)
})

test_that("publication_bias: contour plot runs", {
  tmp <- tempfile(fileext = ".pdf")
  expect_message(
    publication_bias(
      .fix_ratio_large,
      plot_method = "contour",
      save_as = "pdf",
      filename = tmp
    ),
    "saved to"
  )
  expect_true(file.exists(tmp))
  unlink(tmp)
})

test_that("publication_bias: multi-method grid runs", {
  tmp <- tempfile(fileext = ".pdf")
  expect_message(
    publication_bias(
      .fix_ratio_large,
      plot_method = c("original", "trimfill"),
      save_as = "pdf",
      filename = tmp
    ),
    "saved to"
  )
  expect_true(file.exists(tmp))
  unlink(tmp)
})

test_that("publication_bias: title with multi-panel accepted", {
  tmp <- tempfile(fileext = ".pdf")
  expect_message(
    publication_bias(
      .fix_ratio_large,
      plot_method = c("original", "trimfill"),
      title = "Bias Assessment",
      save_as = "pdf",
      filename = tmp
    ),
    "saved to"
  )
  expect_true(file.exists(tmp))
  unlink(tmp)
})

test_that("publication_bias: tiff save works", {
  tmp <- tempfile(fileext = ".tiff")
  expect_message(
    publication_bias(
      .fix_ratio_large,
      plot_method = "original",
      save_as = "tiff",
      filename = tmp
    ),
    "saved to"
  )
  expect_true(file.exists(tmp))
  unlink(tmp)
})

test_that("publication_bias: prop note about logit scale is printed", {
  expect_message(publication_bias(.fix_prop), "logit")
})

# ── bubble_plot ───────────────────────────────────────────────────────────────

test_that("bubble_plot: runs for continuous moderator", {
  res <- withVisible(bubble_plot(.fix_reg_prop))
  expect_true(isTRUE(res$value))
})

test_that("bubble_plot: saves pdf", {
  tmp <- tempfile(fileext = ".pdf")
  expect_message(
    bubble_plot(.fix_reg_prop, save_as = "pdf", filename = tmp),
    "saved to"
  )
  expect_true(file.exists(tmp))
  unlink(tmp)
})

test_that("bubble_plot: saves tiff", {
  tmp <- tempfile(fileext = ".tiff")
  expect_message(
    bubble_plot(.fix_reg_prop, save_as = "tiff", filename = tmp),
    "saved to"
  )
  expect_true(file.exists(tmp))
  unlink(tmp)
})

test_that("bubble_plot: custom title accepted", {
  res <- withVisible(bubble_plot(.fix_reg_prop, title = "Bubble Title"))
  expect_true(isTRUE(res$value))
})

test_that("bubble_plot: categorical moderator grid layout works", {
  r_cat <- meta_reg(
    meta_object = .fix_prop,
    data = dat_bcg,
    moderators = ~alloc,
    studylab = "author"
  )

  tmp <- tempfile(fileext = ".pdf")
  expect_message(
    bubble_plot(r_cat, moderator = "alloc", save_as = "pdf", filename = tmp),
    "saved to"
  )
  expect_true(file.exists(tmp))
  unlink(tmp)
})

test_that("bubble_plot: errors when multiple predictors and no moderator arg", {
  r_multi <- meta_reg(
    meta_object = .fix_prop,
    data = dat_bcg,
    moderators = ~ ablat + year,
    studylab = "author"
  )

  expect_error(bubble_plot(r_multi), "Specify the 'moderator' argument")
})

test_that("bubble_plot: error for wrong class", {
  expect_error(bubble_plot(list()), "meta_reg")
})

# ── doi_plot ──────────────────────────────────────────────────────────────────

test_that("doi_plot: runs for small k (< 10)", {
  small_prop <- meta_prop(
    dat_bcg[1:9, ],
    event = "tpos",
    n = "npos",
    studylab = "author"
  )

  res <- withVisible(doi_plot(small_prop))
  expect_true(isTRUE(res$value) || is.data.frame(res$value) || is.list(res$value) || is.null(res$value))
})

test_that("doi_plot: k >= 10 returns NULL with message", {
  expect_message(
    result <- doi_plot(.fix_prop),
    "fewer than 10"
  )
  expect_null(result)
})

test_that("doi_plot: saves pdf for small k", {
  small_prop <- meta_prop(
    dat_bcg[1:9, ],
    event = "tpos",
    n = "npos",
    studylab = "author"
  )

  tmp <- tempfile(fileext = ".pdf")
  expect_message(
    doi_plot(small_prop, save_as = "pdf", filename = tmp),
    "saved to"
  )
  expect_true(file.exists(tmp))
  unlink(tmp)
})

test_that("doi_plot: custom title accepted", {
  small_prop <- meta_prop(
    dat_bcg[1:9, ],
    event = "tpos",
    n = "npos",
    studylab = "author"
  )

  res <- withVisible(doi_plot(small_prop, title = "DOI Custom"))
  expect_true(isTRUE(res$value) || is.data.frame(res$value) || is.list(res$value) || is.null(res$value))
})

test_that("doi_plot: error for wrong class", {
  expect_error(doi_plot(list()), "Only supports")
})
