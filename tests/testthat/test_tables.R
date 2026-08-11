test_that("table_meta: returns gt object for meta_ratio", {
  gt <- table_meta(.fix_ratio_events)
  expect_s3_class(gt, "gt_tbl")
})

test_that("table_meta: returns gt object for meta_mean", {
  gt <- table_meta(.fix_mean)
  expect_s3_class(gt, "gt_tbl")
})

test_that("table_meta: returns gt object for meta_prop", {
  gt <- table_meta(.fix_prop)
  expect_s3_class(gt, "gt_tbl")
})

test_that("table_meta: custom title applied (ratio)", {
  gt <- table_meta(.fix_ratio_events, title = "My Custom Title")
  hdr <- gt$`_heading`
  expect_match(as.character(hdr$title), "My Custom Title")
})

test_that("table_meta: custom title applied (mean)", {
  gt <- table_meta(.fix_mean, title = "Mean Difference Table")
  hdr <- gt$`_heading`
  expect_match(as.character(hdr$title), "Mean Difference Table")
})

test_that("table_meta: custom title applied (prop)", {
  gt <- table_meta(.fix_prop, title = "Proportion Table")
  hdr <- gt$`_heading`
  expect_match(as.character(hdr$title), "Proportion Table")
})

test_that("table_meta: has no default title (ratio)", {
  gt <- table_meta(.fix_ratio_events)
  expect_null(gt$`_heading`$title)
})

test_that("table_meta: has no default title (prop)", {
  gt <- table_meta(.fix_prop)
  expect_null(gt$`_heading`$title)
})

test_that("table_meta: I2 footnote present", {
  gt <- table_meta(.fix_ratio_events)
  ftns <- gt$`_footnotes`
  fn_txt <- paste(unlist(lapply(ftns$footnotes, as.character)), collapse = " ")
  expect_match(fn_txt, "proportion of total observed variability")
})

test_that("table_meta: error for wrong class", {
  expect_error(table_meta(list()), "Only supports")
})

test_that("table_meta: saves to pdf", {
  skip_if_no_chrome()
  tmp <- tempfile(fileext = ".pdf")
  expect_message(
    table_meta(.fix_prop, save_as = "pdf", filename = tmp),
    "saved to"
  )
  expect_true(file.exists(tmp))
  unlink(tmp)
})

test_that("table_meta: saves to docx", {
  tmp <- tempfile(fileext = ".docx")
  expect_message(
    table_meta(.fix_prop, save_as = "docx", filename = tmp),
    "saved to"
  )
  expect_true(file.exists(tmp))
  unlink(tmp)
})

test_that("table_meta: auto filename created when NULL", {
  skip_if_no_chrome()
  expect_message(
    table_meta(.fix_prop, save_as = "pdf"),
    "saved to"
  )
})

# ── table_influence ───────────────────────────────────────────────────────────

test_that("table_influence: returns gt object for meta_prop", {
  gt <- table_influence(.fix_prop)
  expect_s3_class(gt, "gt_tbl")
})

test_that("table_influence: returns gt object for meta_ratio", {
  gt <- table_influence(.fix_ratio_events)
  expect_s3_class(gt, "gt_tbl")
})

test_that("table_influence: returns gt object for meta_mean", {
  gt <- table_influence(.fix_mean)
  expect_s3_class(gt, "gt_tbl")
})

test_that("table_influence: custom title applied", {
  gt <- table_influence(.fix_prop, title = "LOO Analysis")
  hdr <- gt$`_heading`
  expect_match(as.character(hdr$title), "LOO Analysis")
})

test_that("table_influence: has no default title", {
  gt <- table_influence(.fix_prop)
  expect_null(gt$`_heading`$title)
})

test_that("table_influence: heterogeneity columns present by default", {
  gt <- table_influence(.fix_prop)
  col_ids <- gt$`_boxhead`$var
  expect_true(any(grepl("I", col_ids)))
  expect_true(any(grepl("Tau", col_ids)))
})

test_that("table_influence: heterogeneity columns suppressed when FALSE", {
  gt <- table_influence(.fix_prop, include_heterogeneity = FALSE)
  col_ids <- gt$`_boxhead`$var
  expect_false(any(grepl("I\u00b2", col_ids)))
})

test_that("table_influence: I2 footnote present", {
  gt <- table_influence(.fix_prop)
  ftns <- gt$`_footnotes`
  fn_txt <- paste(unlist(lapply(ftns$footnotes, as.character)), collapse = " ")
  expect_match(fn_txt, "proportion of total observed variability")
})

test_that("table_influence: error for wrong class", {
  expect_error(table_influence(list()), "must be of class")
})

test_that("table_influence: saves to pdf", {
  skip_if_no_chrome()
  tmp <- tempfile(fileext = ".pdf")
  expect_message(
    table_influence(.fix_prop, save_as = "pdf", filename = tmp),
    "saved to"
  )
  unlink(tmp)
})

# ── table_cumulative_meta ─────────────────────────────────────────────────────

test_that("table_cumulative_meta: returns gt for meta_prop", {
  gt <- table_cumulative_meta(.fix_prop)
  expect_s3_class(gt, "gt_tbl")
})

test_that("table_cumulative_meta: returns gt for meta_ratio", {
  gt <- table_cumulative_meta(.fix_ratio_events)
  expect_s3_class(gt, "gt_tbl")
})

test_that("table_cumulative_meta: returns gt for meta_mean", {
  gt <- table_cumulative_meta(.fix_mean)
  expect_s3_class(gt, "gt_tbl")
})

test_that("table_cumulative_meta: custom title applied", {
  gt <- table_cumulative_meta(.fix_prop, title = "Cumulative Evidence")
  hdr <- gt$`_heading`
  expect_match(as.character(hdr$title), "Cumulative Evidence")
})

test_that("table_cumulative_meta: has Step column", {
  gt <- table_cumulative_meta(.fix_prop)
  col_ids <- gt$`_boxhead`$var
  expect_true("Step" %in% col_ids)
})

test_that("table_cumulative_meta: heterogeneity suppressed when FALSE", {
  gt <- table_cumulative_meta(.fix_prop, include_heterogeneity = FALSE)
  col_ids <- gt$`_boxhead`$var
  expect_false(any(grepl("I\u00b2", col_ids)))
})

test_that("table_cumulative_meta: I2 footnote present", {
  gt <- table_cumulative_meta(.fix_prop)
  ftns <- gt$`_footnotes`
  fn_txt <- paste(unlist(lapply(ftns$footnotes, as.character)), collapse = " ")
  expect_match(fn_txt, "proportion of total observed variability")
})

test_that("table_cumulative_meta: error for wrong class", {
  expect_error(table_cumulative_meta(list()), "Only supports")
})

test_that("table_cumulative_meta: saves to pdf", {
  skip_if_no_chrome()
  tmp <- tempfile(fileext = ".pdf")
  expect_message(
    table_cumulative_meta(.fix_prop, save_as = "pdf", filename = tmp),
    "saved to"
  )
  unlink(tmp)
})
test_that("table_subgroups returns data and gt outputs", {
  value <- table_subgroups(.fix_prop_subgroup, output = "data")
  expect_true(is.list(value))
  expect_true(is.data.frame(value$estimates))
  expect_s3_class(table_subgroups(.fix_prop_subgroup), "gt_tbl")
})
test_that("table titles are opt-in", {
  untitled <- table_meta(.fix_prop)
  titled <- table_meta(.fix_prop, title = "Requested title")
  expect_null(untitled$`_heading`$title)
  expect_equal(titled$`_heading`$title, "Requested title")

  expect_null(table_influence(.fix_prop)$`_heading`$title)
  expect_null(table_cumulative_meta(.fix_prop)$`_heading`$title)
})
