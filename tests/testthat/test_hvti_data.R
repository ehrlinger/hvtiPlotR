# Full test suite for hvti-data.R:
#   new_hvti_data (internal), print.hvti_data, plot.hvti_data, is_hvti_data
#
# new_hvti_data() is an internal constructor so it is exercised indirectly
# through hvti_* functions as well as directly via hvtiPlotR:::new_hvti_data.

library(hvtiPlotR)

# ---------------------------------------------------------------------------
# Helpers — minimal valid inputs
# ---------------------------------------------------------------------------

minimal_df <- data.frame(x = 1:3, y = c(1.1, 2.2, 3.3))

make_obj <- function(subclass = "hvti_dummy",
                     data     = minimal_df,
                     meta     = list(a = 1L),
                     tables   = list()) {
  hvtiPlotR:::new_hvti_data(
    data     = data,
    meta     = meta,
    tables   = tables,
    subclass = subclass
  )
}

# ---------------------------------------------------------------------------
# new_hvti_data — structure contract
# ---------------------------------------------------------------------------

test_that("new_hvti_data returns a list with $data, $meta, $tables", {
  obj <- make_obj()
  expect_true(all(c("data", "meta", "tables") %in% names(obj)))
})

test_that("new_hvti_data $data is the supplied data frame", {
  obj <- make_obj(data = minimal_df)
  expect_identical(obj$data, minimal_df)
})

test_that("new_hvti_data $meta is the supplied list", {
  meta <- list(foo = "bar", n = 42L)
  obj  <- make_obj(meta = meta)
  expect_identical(obj$meta, meta)
})

test_that("new_hvti_data $tables defaults to empty list", {
  obj <- make_obj()
  expect_identical(obj$tables, list())
})

test_that("new_hvti_data attaches two-level class: subclass + hvti_data", {
  obj <- make_obj(subclass = "hvti_special")
  expect_equal(class(obj), c("hvti_special", "hvti_data"))
})

test_that("new_hvti_data first class element is the subclass", {
  obj <- make_obj(subclass = "my_sub")
  expect_equal(class(obj)[1L], "my_sub")
})

test_that("new_hvti_data second class element is 'hvti_data'", {
  obj <- make_obj(subclass = "my_sub")
  expect_equal(class(obj)[2L], "hvti_data")
})

# ---------------------------------------------------------------------------
# new_hvti_data — validation errors
# ---------------------------------------------------------------------------

test_that("new_hvti_data errors when data is not a data frame", {
  expect_error(
    hvtiPlotR:::new_hvti_data(data = list(), meta = list(), tables = list(),
                              subclass = "x"),
    "data.frame"
  )
})

test_that("new_hvti_data errors when meta is not a list", {
  expect_error(
    hvtiPlotR:::new_hvti_data(data = minimal_df, meta = "bad",
                              tables = list(), subclass = "x"),
    "list"
  )
})

test_that("new_hvti_data errors when tables is not a list", {
  expect_error(
    hvtiPlotR:::new_hvti_data(data = minimal_df, meta = list(),
                              tables = "bad", subclass = "x"),
    "list"
  )
})

test_that("new_hvti_data errors when subclass is not a character", {
  expect_error(
    hvtiPlotR:::new_hvti_data(data = minimal_df, meta = list(),
                              tables = list(), subclass = 42L),
    "character"
  )
})

test_that("new_hvti_data errors when subclass is an empty string", {
  expect_error(
    hvtiPlotR:::new_hvti_data(data = minimal_df, meta = list(),
                              tables = list(), subclass = ""),
    "nzchar"
  )
})

# ---------------------------------------------------------------------------
# is_hvti_data
# ---------------------------------------------------------------------------

test_that("is_hvti_data returns TRUE for an hvti_data subclass object", {
  obj <- make_obj()
  expect_true(is_hvti_data(obj))
})

test_that("is_hvti_data returns TRUE for a real hvti_trends object", {
  dta <- sample_trends_data(n = 100L, seed = 1L)
  tr  <- hvti_trends(dta)
  expect_true(is_hvti_data(tr))
})

test_that("is_hvti_data returns FALSE for a plain list", {
  expect_false(is_hvti_data(list(data = minimal_df, meta = list())))
})

test_that("is_hvti_data returns FALSE for a data frame", {
  expect_false(is_hvti_data(minimal_df))
})

test_that("is_hvti_data returns FALSE for NULL", {
  expect_false(is_hvti_data(NULL))
})

test_that("is_hvti_data returns FALSE for a character string", {
  expect_false(is_hvti_data("hvti_data"))
})

# ---------------------------------------------------------------------------
# print.hvti_data — base class fallback (no subclass override)
# ---------------------------------------------------------------------------

test_that("print.hvti_data shows the subclass name", {
  obj <- make_obj(subclass = "hvti_dummy")
  expect_output(print(obj), "hvti_dummy")
})

test_that("print.hvti_data shows rows x cols", {
  obj <- make_obj(data = minimal_df)   # 3 rows, 2 cols
  expect_output(print(obj), "3")
  expect_output(print(obj), "2")
})

test_that("print.hvti_data shows meta key names when meta is non-empty", {
  obj <- make_obj(meta = list(alpha = 0.5, n = 10L))
  expect_output(print(obj), "alpha")
  expect_output(print(obj), "n")
})

test_that("print.hvti_data does NOT show meta line when meta is empty", {
  obj <- make_obj(meta = list())
  out <- capture.output(print(obj))
  expect_false(any(grepl("meta", out)))
})

test_that("print.hvti_data shows tables key names when tables is non-empty", {
  obj <- make_obj(tables = list(summary = data.frame(a = 1)))
  expect_output(print(obj), "summary")
})

test_that("print.hvti_data does NOT show tables line when tables is empty", {
  obj <- make_obj(tables = list())
  out <- capture.output(print(obj))
  expect_false(any(grepl("tables", out)))
})

test_that("print.hvti_data returns x invisibly", {
  obj <- make_obj()
  ret <- withVisible(print(obj))
  expect_false(ret$visible)
  expect_identical(ret$value, obj)
})

# ---------------------------------------------------------------------------
# print.hvti_data — NOT triggered when a subclass override is registered
# (dispatch goes to the subclass method, not the base)
# ---------------------------------------------------------------------------

test_that("print dispatches to print.hvti_spaghetti, not print.hvti_data", {
  sp  <- hvti_spaghetti(sample_spaghetti_data(n_patients = 20, seed = 1L))
  out <- capture.output(print(sp))
  # hvti_spaghetti print starts with "<hvti_spaghetti>", not "<hvti_data>"
  expect_true(any(grepl("<hvti_spaghetti>", out)))
})

# ---------------------------------------------------------------------------
# plot.hvti_data — fallback error for unregistered subclass
# ---------------------------------------------------------------------------

test_that("plot.hvti_data signals an error for an unregistered subclass", {
  obj <- make_obj(subclass = "hvti_orphan")
  expect_error(plot(obj), "No plot\\(\\) method")
})

test_that("plot.hvti_data error message names the subclass", {
  obj <- make_obj(subclass = "hvti_orphan")
  expect_error(plot(obj), "hvti_orphan")
})
