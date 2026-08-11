test_that("all plot and table titles are opt-in", {
  output_functions <- list(
    forest_meta = forest_meta,
    forest_influence = forest_influence,
    forest_cumulative = forest_cumulative,
    plot_heterogeneity = plot_heterogeneity,
    plot_baujat = plot_baujat,
    doi_plot = doi_plot,
    bubble_plot = bubble_plot,
    plot_meta_reg = plot_meta_reg,
    plot_umbrella = plot_umbrella,
    plot_study_overlap = plot_study_overlap,
    table_meta = table_meta,
    table_influence = table_influence,
    table_cumulative_meta = table_cumulative_meta,
    table_subgroups = table_subgroups,
    table_publication_bias = table_publication_bias,
    table_meta_reg = table_meta_reg,
    table_umbrella = table_umbrella
  )
  for (name in names(output_functions)) {
    expect_true("title" %in% names(formals(output_functions[[name]])),
      info = paste(name, "must expose a title argument"))
    expect_null(formals(output_functions[[name]])$title,
      info = paste(name, "must default to no title"))
  }
})

test_that("optional gt headings are absent unless explicitly requested", {
  base <- gt::gt(data.frame(value = 1))
  untitled <- metapropul:::.gt_optional_title(base)
  titled <- metapropul:::.gt_optional_title(base, "Requested heading")
  empty <- metapropul:::.gt_optional_title(base, "")

  expect_null(untitled$`_heading`$title)
  expect_null(empty$`_heading`$title)
  expect_equal(titled$`_heading`$title, "Requested heading")
})

test_that("forest row reservations protect axes and statistics", {
  expect_equal(metapropul:::.forest_bottom_rows(2), 2L)
  expect_equal(metapropul:::.forest_bottom_rows(10), 2L)
  expect_equal(metapropul:::.forest_bottom_rows(50), 3L)
  expect_equal(metapropul:::.forest_bottom_rows(200), 3L)
  expect_equal(metapropul:::.forest_bottom_rows(13, TRUE), 3L)
})

test_that("automatic sizing remains usable through 200 studies", {
  sizes <- lapply(c(2, 10, 50, 100, 200),
    metapropul:::.auto_plot_sizing, type = "prop")
  heights <- vapply(sizes, `[[`, numeric(1), "height")
  fonts <- vapply(sizes, `[[`, numeric(1), "fontsize")
  spacing <- vapply(sizes, `[[`, numeric(1), "spacing")

  expect_true(all(diff(heights) >= 0))
  expect_true(all(diff(fonts) <= 0))
  expect_true(all(diff(spacing) <= 0))
  expect_gte(sizes[[5]]$height, 30)
  expect_lte(sizes[[5]]$fontsize, 6)
})
