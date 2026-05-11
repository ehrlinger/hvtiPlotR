# Full test suite for hvti-data.R:
#   new_hv_data (internal), print.hv_data, plot.hv_data, is_hv_data
#
# new_hv_data() is an internal constructor so it is exercised indirectly
# through hv_* functions as well as directly via hvtiPlotR:::new_hv_data.

library(hvtiPlotR)

# ---------------------------------------------------------------------------
# Helpers — minimal valid inputs
# ---------------------------------------------------------------------------

minimal_df <- data.frame(x = 1:3, y = c(1.1, 2.2, 3.3))

make_obj <- function(subclass = "hv_dummy",
                     data     = minimal_df,
                     meta     = list(a = 1L),
                     tables   = list()) {
  hvtiPlotR:::new_hv_data(
    data     = data,
    meta     = meta,
    tables   = tables,
    subclass = subclass
  )
}

# ---------------------------------------------------------------------------
# new_hv_data — structure contract
# ---------------------------------------------------------------------------

test_that("new_hv_data returns a list with $data, $meta, $tables", {
  obj <- make_obj()
  expect_true(all(c("data", "meta", "tables") %in% names(obj)))
})

test_that("new_hv_data $data is the supplied data frame", {
  obj <- make_obj(data = minimal_df)
  expect_identical(obj$data, minimal_df)
})

test_that("new_hv_data $meta is the supplied list", {
  meta <- list(foo = "bar", n = 42L)
  obj  <- make_obj(meta = meta)
  expect_identical(obj$meta, meta)
})

test_that("new_hv_data $tables defaults to empty list", {
  obj <- make_obj()
  expect_identical(obj$tables, list())
})

test_that("new_hv_data attaches two-level class: subclass + hv_data", {
  obj <- make_obj(subclass = "hv_special")
  expect_equal(class(obj), c("hv_special", "hv_data"))
})

test_that("new_hv_data first class element is the subclass", {
  obj <- make_obj(subclass = "my_sub")
  expect_equal(class(obj)[1L], "my_sub")
})

test_that("new_hv_data second class element is 'hv_data'", {
  obj <- make_obj(subclass = "my_sub")
  expect_equal(class(obj)[2L], "hv_data")
})

# ---------------------------------------------------------------------------
# new_hv_data — validation errors
# ---------------------------------------------------------------------------

test_that("new_hv_data errors when data is not a data frame", {
  expect_error(
    hvtiPlotR:::new_hv_data(data = list(), meta = list(), tables = list(),
                              subclass = "x"),
    "data.frame"
  )
})

test_that("new_hv_data errors when meta is not a list", {
  expect_error(
    hvtiPlotR:::new_hv_data(data = minimal_df, meta = "bad",
                              tables = list(), subclass = "x"),
    "list"
  )
})

test_that("new_hv_data errors when tables is not a list", {
  expect_error(
    hvtiPlotR:::new_hv_data(data = minimal_df, meta = list(),
                              tables = "bad", subclass = "x"),
    "list"
  )
})

test_that("new_hv_data errors when subclass is not a character", {
  expect_error(
    hvtiPlotR:::new_hv_data(data = minimal_df, meta = list(),
                              tables = list(), subclass = 42L),
    "character"
  )
})

test_that("new_hv_data errors when subclass is an empty string", {
  expect_error(
    hvtiPlotR:::new_hv_data(data = minimal_df, meta = list(),
                              tables = list(), subclass = ""),
    "nzchar"
  )
})

# ---------------------------------------------------------------------------
# is_hv_data
# ---------------------------------------------------------------------------

test_that("is_hv_data returns TRUE for an hv_data subclass object", {
  obj <- make_obj()
  expect_true(is_hv_data(obj))
})

test_that("is_hv_data returns TRUE for a real hv_trends object", {
  dta <- sample_trends_data(n = 100L, seed = 1L)
  tr  <- hv_trends(dta)
  expect_true(is_hv_data(tr))
})

test_that("is_hv_data returns FALSE for a plain list", {
  expect_false(is_hv_data(list(data = minimal_df, meta = list())))
})

test_that("is_hv_data returns FALSE for a data frame", {
  expect_false(is_hv_data(minimal_df))
})

test_that("is_hv_data returns FALSE for NULL", {
  expect_false(is_hv_data(NULL))
})

test_that("is_hv_data returns FALSE for a character string", {
  expect_false(is_hv_data("hv_data"))
})

# ---------------------------------------------------------------------------
# print.hv_data — base class fallback (no subclass override)
# ---------------------------------------------------------------------------

test_that("print.hv_data shows the subclass name", {
  obj <- make_obj(subclass = "hv_dummy")
  expect_output(print(obj), "hv_dummy")
})

test_that("print.hv_data shows rows x cols", {
  obj <- make_obj(data = minimal_df)   # 3 rows, 2 cols
  expect_output(print(obj), "3")
  expect_output(print(obj), "2")
})

test_that("print.hv_data shows meta key names when meta is non-empty", {
  obj <- make_obj(meta = list(alpha = 0.5, n = 10L))
  expect_output(print(obj), "alpha")
  expect_output(print(obj), "n")
})

test_that("print.hv_data does NOT show meta line when meta is empty", {
  obj <- make_obj(meta = list())
  out <- capture.output(print(obj))
  expect_false(any(grepl("meta", out)))
})

test_that("print.hv_data shows tables key names when tables is non-empty", {
  obj <- make_obj(tables = list(summary = data.frame(a = 1)))
  expect_output(print(obj), "summary")
})

test_that("print.hv_data does NOT show tables line when tables is empty", {
  obj <- make_obj(tables = list())
  out <- capture.output(print(obj))
  expect_false(any(grepl("tables", out)))
})

test_that("print.hv_data returns x invisibly", {
  obj <- make_obj()
  ret <- withVisible(print(obj))
  expect_false(ret$visible)
  expect_identical(ret$value, obj)
})

# ---------------------------------------------------------------------------
# print.hv_data — NOT triggered when a subclass override is registered
# (dispatch goes to the subclass method, not the base)
# ---------------------------------------------------------------------------

test_that("print dispatches to print.hv_spaghetti, not print.hv_data", {
  sp  <- hv_spaghetti(sample_spaghetti_data(n_patients = 20, seed = 1L))
  out <- capture.output(print(sp))
  # hv_spaghetti print starts with "<hv_spaghetti>", not "<hv_data>"
  expect_true(any(grepl("<hv_spaghetti>", out)))
})

# ---------------------------------------------------------------------------
# plot.hv_data — fallback error for unregistered subclass
# ---------------------------------------------------------------------------

test_that("plot.hv_data signals an error for an unregistered subclass", {
  obj <- make_obj(subclass = "hv_orphan")
  expect_error(plot(obj), "No plot\\(\\) method")
})

test_that("plot.hv_data error message names the subclass", {
  obj <- make_obj(subclass = "hv_orphan")
  expect_error(plot(obj), "hv_orphan")
})

# ---------------------------------------------------------------------------
# summary.hv_data — default implementation
# ---------------------------------------------------------------------------

test_that("summary.hv_data returns the object invisibly", {
  obj <- make_obj(tables = list(report = data.frame(a = 1:3)))
  # Check both: returned value equals input, AND it was returned invisibly.
  out <- capture.output(res <- summary(obj))
  expect_identical(res, obj)
  vis <- withVisible(summary(obj))
  expect_false(vis$visible)
})

test_that("summary.hv_data prints each named $tables entry", {
  obj <- make_obj(tables = list(report = data.frame(a = 1:3),
                                risk   = data.frame(b = 4:6)))
  out <- paste(capture.output(summary(obj)), collapse = "\n")
  expect_match(out, "\\$tables\\$report")
  expect_match(out, "\\$tables\\$risk")
})

test_that("summary.hv_data handles an empty $tables slot", {
  obj <- make_obj(tables = list())
  expect_silent_summary <- capture.output(summary(obj))
  # Header line is printed; no $tables sections appear
  expect_false(any(grepl("\\$tables\\$", expect_silent_summary)))
})

# ---------------------------------------------------------------------------
# autoplot.hv_data — ggplot2 ecosystem hook
# ---------------------------------------------------------------------------

test_that("autoplot.hv_data dispatches to plot() and returns a ggplot", {
  km <- hv_survival(sample_survival_data(n = 80, seed = 1))
  a <- autoplot(km)
  p <- plot(km)
  # Compare on structural properties rather than expect_identical(), which is
  # brittle against environment captures and other internal-state differences
  # between two separate build calls.
  expect_s3_class(a, "ggplot")
  expect_identical(class(a), class(p))
  expect_identical(
    vapply(a$layers, function(l) class(l$geom)[1], character(1)),
    vapply(p$layers, function(l) class(l$geom)[1], character(1))
  )
})

test_that("autoplot.hv_data forwards extra arguments to plot()", {
  km <- hv_survival(sample_survival_data(n = 80, seed = 1))
  a <- autoplot(km, type = "cumhaz")
  p <- plot(km, type = "cumhaz")
  expect_s3_class(a, "ggplot")
  expect_identical(
    vapply(a$layers, function(l) class(l$geom)[1], character(1)),
    vapply(p$layers, function(l) class(l$geom)[1], character(1))
  )
})

test_that("autoplot.hv_data is registered as an S3 method", {
  expect_true(
    !is.null(utils::getS3method("autoplot", "hv_data",
                                envir = asNamespace("hvtiPlotR")))
  )
})

test_that("ggplot2::autoplot generic is re-exported from hvtiPlotR", {
  # Without this re-export, callers who load only hvtiPlotR (without
  # library(ggplot2)) would not have `autoplot()` visible, even though the
  # S3 method is registered. This catches NAMESPACE drift.
  expect_true("autoplot" %in% getNamespaceExports("hvtiPlotR"))
})

# ---------------------------------------------------------------------------
# as.data.frame.hv_data — tidyverse-pipeline accessor
# ---------------------------------------------------------------------------

test_that("as.data.frame.hv_data returns the $data slot unchanged", {
  obj <- make_obj()
  expect_identical(as.data.frame(obj), obj$data)
})

test_that("data.frame() coercion dispatches through as.data.frame.hv_data", {
  obj <- make_obj()
  expect_s3_class(data.frame(obj), "data.frame")
  expect_identical(data.frame(obj), obj$data)
})

test_that("as.data.frame.hv_data ignores row.names and optional formals", {
  obj <- make_obj()
  expect_identical(
    as.data.frame(obj, row.names = NULL, optional = FALSE),
    obj$data
  )
  expect_identical(
    as.data.frame(obj, row.names = c("a", "b", "c"), optional = TRUE),
    obj$data
  )
})
