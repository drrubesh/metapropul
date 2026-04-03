test_that("forest_meta: runs for meta_ratio (viewer)", {
  expect_message(forest_meta(.fix_ratio_events), "Viewer|saved")
})

test_that("forest_meta: runs for meta_mean (viewer)", {
  expect_message(forest_meta(.fix_mean), "Viewer|saved")
})

test_that("forest_meta: runs for meta_prop (viewer)", {
  expect_message(forest_meta(.fix_prop), "Viewer|saved")
})

test_that("forest_meta: returns TRUE invisibly", {
  expect_true(invisible_result <- withVisible(forest_meta(.fix_prop))$value)
})

test_that("forest_meta: saves pdf for meta_ratio", {
  tmp <- tempfile(fileext = ".pdf")
  expect_message(
    forest_meta(.fix_ratio_events, save_as = "pdf", filename = tmp),
    "saved to"
  )
  expect_true(file.exists(tmp))
  unlink(tmp)
})

test_that("forest_meta: saves pdf for meta_mean", {
  tmp <- tempfile(fileext = ".pdf")
  expect_message(
    forest_meta(.fix_mean, save_as = "pdf", filename = tmp),
    "saved to"
  )
  expect_true(file.exists(tmp))
  unlink(tmp)
})

test_that("forest_meta: saves pdf for meta_prop", {
  tmp <- tempfile(fileext = ".pdf")
  expect_message(
    forest_meta(.fix_prop, save_as = "pdf", filename = tmp),
    "saved to"
  )
  expect_true(file.exists(tmp))
  unlink(tmp)
})

test_that("forest_meta: saves png", {
  tmp <- tempfile(fileext = ".png")
  expect_message(
    forest_meta(.fix_prop, save_as = "png", filename = tmp),
    "saved to"
  )
  expect_true(file.exists(tmp))
  unlink(tmp)
})

test_that("forest_meta: saves tiff", {
  tmp <- tempfile(fileext = ".tiff")
  expect_message(
    forest_meta(.fix_prop, save_as = "tiff", filename = tmp),
    "saved to"
  )
  expect_true(file.exists(tmp))
  unlink(tmp)
})

test_that("forest_meta: auto filename when NULL", {
  expect_message(forest_meta(.fix_prop, save_as = "pdf"), "saved to")
})

test_that("forest_meta: title parameter accepted", {
  expect_message(
    forest_meta(.fix_prop, title = "My Forest Plot"),
    "Viewer|saved"
  )
})

test_that("forest_meta: empty title suppresses title", {
  expect_message(
    forest_meta(.fix_prop, title = ""),
    "Viewer|saved"
  )
})

test_that("forest_meta: subgroup meta_ratio runs", {
  expect_message(forest_meta(.fix_ratio_subgroup), "Viewer|saved")
})

test_that("forest_meta: subgroup meta_prop runs", {
  expect_message(forest_meta(.fix_prop_subgroup), "Viewer|saved")
})

test_that("forest_meta: large k ratio (metagen path)", {
  expect_message(forest_meta(.fix_ratio_large), "Viewer|saved")
})

test_that("forest_meta: layout meta accepted for ratio", {
  expect_message(
    forest_meta(.fix_ratio_events, layout = "meta"),
    "Viewer|saved"
  )
})

test_that("forest_meta: layout JAMA accepted for mean", {
  tmp <- tempfile(fileext = ".pdf")
  expect_message(
    forest_meta(.fix_mean, save_as = "pdf", filename = tmp, layout = "JAMA"),
    "saved to"
  )
  unlink(tmp)
})

test_that("forest_meta: BMJ layout for mean uses extra width", {
  tmp <- tempfile(fileext = ".pdf")
  expect_message(
    forest_meta(.fix_mean, save_as = "pdf", filename = tmp, layout = "BMJ"),
    "saved to"
  )
  unlink(tmp)
})

test_that("forest_meta: custom height/width accepted", {
  tmp <- tempfile(fileext = ".pdf")
  expect_message(
    forest_meta(.fix_prop,
      save_as = "pdf", filename = tmp,
      height = 8, width = 12
    ),
    "saved to"
  )
  unlink(tmp)
})

test_that("forest_meta: error for wrong class", {
  expect_error(forest_meta(list()), "'x' must be")
})

# ── forest_influence ──────────────────────────────────────────────────────────

test_that("forest_influence: runs for meta_prop (viewer)", {
  expect_message(forest_influence(.fix_prop), "Viewer|saved|Plots pane")
})

test_that("forest_influence: runs for meta_ratio", {
  expect_message(forest_influence(.fix_ratio_events), "Viewer|saved|Plots pane")
})

test_that("forest_influence: runs for meta_mean", {
  expect_message(forest_influence(.fix_mean), "Viewer|saved|Plots pane")
})

test_that("forest_influence: saves pdf", {
  tmp <- tempfile(fileext = ".pdf")
  expect_message(
    forest_influence(.fix_prop, save_as = "pdf", filename = tmp),
    "saved to"
  )
  expect_true(file.exists(tmp))
  unlink(tmp)
})

test_that("forest_influence: saves tiff", {
  tmp <- tempfile(fileext = ".tiff")
  expect_message(
    forest_influence(.fix_prop, save_as = "tiff", filename = tmp),
    "saved to"
  )
  expect_true(file.exists(tmp))
  unlink(tmp)
})

test_that("forest_influence: title parameter accepted", {
  expect_message(
    forest_influence(.fix_prop, title = "Influence Analysis"),
    "Viewer|saved|Plots pane"
  )
})

test_that("forest_influence: error for wrong class", {
  expect_error(forest_influence(list()), "meta_prop.*meta_ratio.*meta_mean")
})

# ── forest_cumulative ─────────────────────────────────────────────────────────

test_that("forest_cumulative: runs for meta_prop", {
  expect_message(forest_cumulative(.fix_prop), "Viewer|saved")
})

test_that("forest_cumulative: runs for meta_ratio", {
  expect_message(forest_cumulative(.fix_ratio_events), "Viewer|saved")
})

test_that("forest_cumulative: runs for meta_mean", {
  expect_message(forest_cumulative(.fix_mean), "Viewer|saved")
})

test_that("forest_cumulative: saves pdf", {
  tmp <- tempfile(fileext = ".pdf")
  expect_message(
    forest_cumulative(.fix_prop, save_as = "pdf", filename = tmp),
    "saved to"
  )
  expect_true(file.exists(tmp))
  unlink(tmp)
})

test_that("forest_cumulative: title parameter accepted", {
  expect_message(
    forest_cumulative(.fix_prop, title = "Cumulative Plot"),
    "Viewer|saved"
  )
})

test_that("forest_cumulative: error for wrong class", {
  expect_error(forest_cumulative(list()), "Only supports")
})
