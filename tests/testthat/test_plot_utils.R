# Tests for .auto_plot_sizing — the internal sizing helper

test_that(".auto_plot_sizing: returns list with height, width, fontsize", {
  s <- metapropul:::.auto_plot_sizing(10)
  expect_named(s, c("height", "width", "fontsize"))
})

test_that(".auto_plot_sizing: default type runs and returns numeric values", {
  s <- metapropul:::.auto_plot_sizing(10)
  expect_true(is.numeric(s$height))
  expect_true(is.numeric(s$width))
  expect_true(is.numeric(s$fontsize))
})

test_that(".auto_plot_sizing: fontsize 11 for small k", {
  s <- metapropul:::.auto_plot_sizing(5)
  expect_equal(s$fontsize, 11)
})

test_that(".auto_plot_sizing: fontsize 10 for k=25", {
  s <- metapropul:::.auto_plot_sizing(25)
  expect_equal(s$fontsize, 10)
})

test_that(".auto_plot_sizing: fontsize 9 for k=60", {
  s <- metapropul:::.auto_plot_sizing(60)
  expect_equal(s$fontsize, 9)
})

test_that(".auto_plot_sizing: fontsize 8 for k=110", {
  s <- metapropul:::.auto_plot_sizing(110)
  expect_equal(s$fontsize, 8)
})

test_that(".auto_plot_sizing: fontsize 7 for k=210", {
  s <- metapropul:::.auto_plot_sizing(210)
  expect_equal(s$fontsize, 7)
})

test_that(".auto_plot_sizing: height increases with k", {
  s5 <- metapropul:::.auto_plot_sizing(5)
  s50 <- metapropul:::.auto_plot_sizing(50)
  expect_true(s50$height > s5$height)
})

test_that(".auto_plot_sizing: influence type uses larger overhead", {
  s_ratio <- metapropul:::.auto_plot_sizing(20, type = "ratio")
  s_infl <- metapropul:::.auto_plot_sizing(20, type = "influence")
  expect_true(s_infl$height > s_ratio$height)
})

test_that(".auto_plot_sizing: subgroup type wider than ratio", {
  s_ratio <- metapropul:::.auto_plot_sizing(20, type = "ratio")
  s_sub <- metapropul:::.auto_plot_sizing(20, type = "subgroup")
  expect_true(s_sub$width > s_ratio$width)
})

test_that(".auto_plot_sizing: prop type wider than ratio for large k", {
  s_ratio <- metapropul:::.auto_plot_sizing(60, type = "ratio")
  s_prop <- metapropul:::.auto_plot_sizing(60, type = "prop")
  expect_true(s_prop$width >= s_ratio$width)
})

test_that(".auto_plot_sizing: mean type width is 14 for standard k", {
  s <- metapropul:::.auto_plot_sizing(10, type = "mean")
  expect_equal(s$width, 14)
})

test_that(".auto_plot_sizing: explicit height overrides auto", {
  s <- metapropul:::.auto_plot_sizing(100, height = 20)
  expect_equal(s$height, 20)
})

test_that(".auto_plot_sizing: explicit width overrides auto", {
  s <- metapropul:::.auto_plot_sizing(100, width = 20)
  expect_equal(s$width, 20)
})

test_that(".auto_plot_sizing: width and height are positive", {
  s <- metapropul:::.auto_plot_sizing(50, type = "ratio")
  expect_true(s$height > 0)
  expect_true(s$width > 0)
  expect_true(s$fontsize > 0)
})

test_that(".auto_plot_sizing: error for non-numeric k", {
  expect_error(metapropul:::.auto_plot_sizing("a"), "positive number")
})

test_that(".auto_plot_sizing: error for k <= 0", {
  expect_error(metapropul:::.auto_plot_sizing(0), "positive number")
})

test_that(".auto_plot_sizing: height minimum is 5", {
  s <- metapropul:::.auto_plot_sizing(1)
  expect_true(s$height >= 5)
})
