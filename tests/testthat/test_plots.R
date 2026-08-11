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

test_that("validate_rob checks templates without plotting", {
  rob <- data.frame(study = c("A", "B"), D1 = c("Low", "High"),
    D2 = c("Some concerns", "Low"))
  result <- validate_rob(rob, "study", tool = "Custom",
    domains = c("D1", "D2"), levels = c("Low", "Some concerns", "High"))
  expect_s3_class(result, "rob_validation")
  expect_true(result$valid)
  expect_equal(sum(result$frequencies$Studies), 4L)
})

test_that("publication_bias: numerical tests run for meta_prop with PLOGIT", {
  result <- publication_bias(.fix_prop)
  expect_true(is.list(result))
  expect_true(any(c("egger", "begg", "trimfill") %in% names(result)))
  expect_s3_class(table_publication_bias(result), "gt_tbl")
  expect_true(is.data.frame(table_publication_bias(result, output = "data")))
})

test_that("publication_bias: unavailable test statistics are reported safely", {
  expect_no_error(publication_bias(.fix_prop_subgroup))
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

test_that("publication_bias: k < 10 returns availability status", {
  small <- dat_bcg[1:9, ]
  r_small <- meta_prop(small, event = "tpos", n = "npos", studylab = "author")

  expect_message(
    result <- publication_bias(r_small),
    "k < 10"
  )
  expect_s3_class(result, "publication_bias_result")
  expect_true(is.data.frame(result$status))
  expect_false(any(result$status$Available))
  expect_true(all(grepl("fewer than 10", result$status$Reason)))
})

test_that("publication_bias: k < 10 still permits a descriptive funnel", {
  small <- dat_bcg[1:9, ]
  fit <- suppressWarnings(meta_prop(small, "tpos", "npos", "author",
    duplicate_action = "make_unique"))
  path <- tempfile(fileext = ".pdf")
  expect_message(publication_bias(fit, plot_method = "original",
    save_as = "pdf", filename = path), "saved")
  expect_true(file.exists(path))
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
    studylab = "author",
    min_studies_per_parameter = 5
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
    studylab = "author",
    min_studies_per_parameter = 5
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

# ── risk-of-bias plots ────────────────────────────────────────────────────────

test_that("custom ROB plots use semantic colours by default", {
  rob <- data.frame(
    study = c("A", "B", "C"),
    d1 = c("low", "some", "high"),
    overall = c("low", "some", "high")
  )
  traffic <- plot_rob(rob, "study", tool = "Custom",
    domains = c("d1", "overall"), levels = c("low", "some", "high"))
  summary_plot <- plot_rob_summary(rob, "study", tool = "Custom",
    domains = c("d1", "overall"), levels = c("low", "some", "high"))
  expected <- c("#02C100", "#E2B007", "#BF0000")
  expect_setequal(unique(ggplot2::ggplot_build(traffic)$data[[1]]$fill), expected)
  expect_setequal(unique(ggplot2::ggplot_build(summary_plot)$data[[1]]$fill), expected)
})

test_that("forest_rob aligns ROB domains with fitted study labels", {
  fit <- suppressWarnings(meta_prop(dat_bcg, "tpos", "npos", "author"))
  labels <- fit$meta$studlab
  rob <- data.frame(
    study = rev(labels),
    domain_1 = rep(c("Low", "High"), length.out = length(labels)),
    domain_2 = rep(c("Some concerns", "Low"), length.out = length(labels)),
    overall = rep(c("Low", "High"), length.out = length(labels))
  )
  file <- tempfile(fileext = ".pdf")

  expect_invisible(forest_rob(
    fit, rob, "study", tool = "Custom",
    domains = c("domain_1", "domain_2", "overall"),
    levels = c("Low", "Some concerns", "High"),
    save_as = "pdf", filename = file, width = 14, height = 10
  ))
  expect_gt(file.info(file)$size, 1000)

  expect_error(forest_rob(
    fit, rob[-1, ], "study", tool = "Custom",
    domains = c("domain_1", "domain_2", "overall"),
    levels = c("Low", "Some concerns", "High")
  ), "missing fitted study")

  duplicated <- rbind(rob, rob[1, ])
  expect_error(forest_rob(
    fit, duplicated, "study", tool = "Custom",
    domains = c("domain_1", "domain_2", "overall"),
    levels = c("Low", "Some concerns", "High")
  ), "duplicate study labels")
})
