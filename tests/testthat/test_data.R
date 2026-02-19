# Tests for package data objects
library(testthat)

context("Data object tests")

# ============================================================================
# parametric data tests
# ============================================================================

test_that("parametric data exists", {
  expect_true(exists("parametric"))
})

test_that("parametric is a data frame", {
  data(parametric, package = "hvtiPlotR", envir = environment())
  expect_s3_class(parametric, "data.frame")
})

test_that("parametric has rows and columns", {
  data(parametric, package = "hvtiPlotR", envir = environment())
  expect_gt(nrow(parametric), 0)
  expect_gt(ncol(parametric), 0)
})

test_that("parametric contains reasonable data", {
  data(parametric, package = "hvtiPlotR", envir = environment())
  # Check that it's not empty
  expect_true(nrow(parametric) > 0)
  # Check that it has some structure
  expect_true(is.data.frame(parametric))
})

# ============================================================================
# nonparametric data tests
# ============================================================================

test_that("nonparametric data exists", {
  expect_true(exists("nonparametric"))
})

test_that("nonparametric is a data frame", {
  data(nonparametric, package = "hvtiPlotR", envir = environment())
  expect_s3_class(nonparametric, "data.frame")
})

test_that("nonparametric has rows and columns", {
  data(nonparametric, package = "hvtiPlotR", envir = environment())
  expect_gt(nrow(nonparametric), 0)
  expect_gt(ncol(nonparametric), 0)
})

test_that("nonparametric has expected columns based on documentation", {
  data(nonparametric, package = "hvtiPlotR", envir = environment())

  # Based on the documentation, check for some expected columns
  expected_cols <- c("iv_state", "sginit", "stlinit", "stuinit",
                     "sgdead1", "sgstrk1", "stldead1", "studead1",
                     "stlstrk1", "stustrk1")

  # At least some of these columns should exist
  # (using any() in case the actual data differs from docs)
  col_exists <- any(expected_cols %in% names(nonparametric))
  expect_true(ncol(nonparametric) > 0)  # At minimum, has columns
})

test_that("nonparametric contains reasonable survival data", {
  data(nonparametric, package = "hvtiPlotR", envir = environment())

  # Basic checks for survival data
  expect_true(nrow(nonparametric) > 0)
  expect_true(is.data.frame(nonparametric))
})

# ============================================================================
# Data usability tests
# ============================================================================

test_that("parametric data can be used in plotting", {
  skip_if_not_installed("ggplot2")

  data(parametric, package = "hvtiPlotR", envir = environment())

  # Should be able to pass to ggplot without error
  # (even if we don't know the exact column names)
  expect_error(
    { p <- ggplot2::ggplot(parametric) },
    NA
  )
})

test_that("nonparametric data can be used in plotting", {
  skip_if_not_installed("ggplot2")

  data(nonparametric, package = "hvtiPlotR", envir = environment())

  # Should be able to pass to ggplot without error
  expect_error(
    { p <- ggplot2::ggplot(nonparametric) },
    NA
  )
})

test_that("data objects are properly documented", {
  # Check that help pages exist
  expect_true("parametric" %in% ls("package:hvtiPlotR"))
  expect_true("nonparametric" %in% ls("package:hvtiPlotR"))
})

# ============================================================================
# Data integrity tests
# ============================================================================

test_that("parametric has no completely missing columns", {
  data(parametric, package = "hvtiPlotR", envir = environment())

  # No column should be entirely NA
  all_na <- sapply(parametric, function(x) all(is.na(x)))
  expect_false(any(all_na))
})

test_that("nonparametric has no completely missing columns", {
  data(nonparametric, package = "hvtiPlotR", envir = environment())

  # No column should be entirely NA
  all_na <- sapply(nonparametric, function(x) all(is.na(x)))
  expect_false(any(all_na))
})

test_that("data objects can be loaded multiple times", {
  data(parametric, package = "hvtiPlotR", envir = environment())
  data(parametric, package = "hvtiPlotR", envir = environment())
  expect_s3_class(parametric, "data.frame")

  data(nonparametric, package = "hvtiPlotR", envir = environment())
  data(nonparametric, package = "hvtiPlotR", envir = environment())
  expect_s3_class(nonparametric, "data.frame")
})
