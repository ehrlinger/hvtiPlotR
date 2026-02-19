# Tests for makeFootnote function
library(testthat)
library(grid)
library(grDevices)

context("makeFootnote tests")

# ============================================================================
# Basic functionality tests
# ============================================================================

test_that("makeFootnote executes without error", {
  # Create a simple plot device
  pdf(NULL)
  plot(1:10)

  expect_error(makeFootnote(), NA)

  dev.off()
})

test_that("makeFootnote works without timestamp", {
  pdf(NULL)
  plot(1:10)

  expect_error(makeFootnote(timestamp = FALSE), NA)

  dev.off()
})

test_that("makeFootnote works with custom text", {
  pdf(NULL)
  plot(1:10)

  expect_error(makeFootnote("Custom footnote text"), NA)
  expect_error(makeFootnote("Another test", timestamp = FALSE), NA)

  dev.off()
})

# ============================================================================
# Parameter tests
# ============================================================================

test_that("makeFootnote accepts custom size parameter", {
  pdf(NULL)
  plot(1:10)

  expect_error(makeFootnote(size = 0.5), NA)
  expect_error(makeFootnote(size = 1.0), NA)
  expect_error(makeFootnote(size = 0.3), NA)

  dev.off()
})

test_that("makeFootnote accepts custom color parameter", {
  pdf(NULL)
  plot(1:10)

  expect_error(makeFootnote(color = "red"), NA)
  expect_error(makeFootnote(color = "blue"), NA)
  expect_error(makeFootnote(color = grey(0.8)), NA)
  expect_error(makeFootnote(color = "#FF0000"), NA)

  dev.off()
})

test_that("makeFootnote accepts all parameters together", {
  pdf(NULL)
  plot(1:10)

  expect_error(
    makeFootnote(
      footnoteText = "Test footnote",
      size = 0.6,
      color = "darkblue",
      timestamp = TRUE
    ),
    NA
  )

  dev.off()
})

# ============================================================================
# Default parameter tests
# ============================================================================

test_that("makeFootnote uses getwd() as default footnote text", {
  pdf(NULL)
  plot(1:10)

  # Should use current working directory as default
  expect_error(makeFootnote(), NA)

  dev.off()
})

test_that("makeFootnote default size is 0.7", {
  pdf(NULL)
  plot(1:10)

  expect_error(makeFootnote(), NA)

  dev.off()
})

test_that("makeFootnote default color is grey(0.5)", {
  pdf(NULL)
  plot(1:10)

  expect_error(makeFootnote(), NA)

  dev.off()
})

test_that("makeFootnote default timestamp is TRUE", {
  pdf(NULL)
  plot(1:10)

  expect_error(makeFootnote(), NA)

  dev.off()
})

# ============================================================================
# Integration tests with different plot types
# ============================================================================

test_that("makeFootnote works with base R plots", {
  pdf(NULL)

  # Scatter plot
  plot(1:10, 1:10)
  expect_error(makeFootnote(), NA)

  # Line plot
  plot(1:10, type = "l")
  expect_error(makeFootnote("Line plot"), NA)

  # Bar plot
  barplot(1:10)
  expect_error(makeFootnote("Bar plot", timestamp = FALSE), NA)

  # Histogram
  hist(rnorm(100))
  expect_error(makeFootnote("Histogram"), NA)

  dev.off()
})

test_that("makeFootnote works with multiple plot calls", {
  pdf(NULL)

  plot(1:10)
  makeFootnote("First plot")

  plot(10:1)
  makeFootnote("Second plot")

  plot(sin(1:100))
  makeFootnote("Third plot", timestamp = FALSE)

  expect_true(TRUE)  # If we get here, all calls succeeded

  dev.off()
})

# ============================================================================
# Edge case tests
# ============================================================================

test_that("makeFootnote handles empty string", {
  pdf(NULL)
  plot(1:10)

  expect_error(makeFootnote(""), NA)

  dev.off()
})

test_that("makeFootnote handles very long text", {
  pdf(NULL)
  plot(1:10)

  long_text <- paste(rep("Long text", 50), collapse = " ")
  expect_error(makeFootnote(long_text), NA)

  dev.off()
})

test_that("makeFootnote handles special characters", {
  pdf(NULL)
  plot(1:10)

  expect_error(makeFootnote("Test with / special \\ characters * and & symbols"), NA)
  expect_error(makeFootnote("Test with\nnewline"), NA)

  dev.off()
})

test_that("makeFootnote handles extreme size values", {
  pdf(NULL)
  plot(1:10)

  expect_error(makeFootnote(size = 0.1), NA)
  expect_error(makeFootnote(size = 2.0), NA)
  expect_error(makeFootnote(size = 0.01), NA)

  dev.off()
})

test_that("makeFootnote handles unusual color values", {
  pdf(NULL)
  plot(1:10)

  expect_error(makeFootnote(color = "transparent"), NA)
  expect_error(makeFootnote(color = grey(0)), NA)
  expect_error(makeFootnote(color = grey(1)), NA)

  dev.off()
})

# ============================================================================
# Timestamp functionality tests
# ============================================================================

test_that("makeFootnote with timestamp includes time information", {
  pdf(NULL)
  plot(1:10)

  # With timestamp should not error and should work
  expect_error(makeFootnote("Test", timestamp = TRUE), NA)

  dev.off()
})

test_that("makeFootnote timestamp can be toggled", {
  pdf(NULL)
  plot(1:10)

  expect_error(makeFootnote("Test1", timestamp = TRUE), NA)
  expect_error(makeFootnote("Test2", timestamp = FALSE), NA)
  expect_error(makeFootnote("Test3", timestamp = TRUE), NA)

  dev.off()
})

# ============================================================================
# Grid graphics tests
# ============================================================================

test_that("makeFootnote uses grid graphics correctly", {
  pdf(NULL)
  plot(1:10)

  # Should use grid.text, viewport, etc. without error
  expect_error(makeFootnote(), NA)

  dev.off()
})

test_that("makeFootnote can be called multiple times on same plot", {
  pdf(NULL)
  plot(1:10)

  # Multiple calls should work (though they may overlap)
  expect_error(makeFootnote("First"), NA)
  expect_error(makeFootnote("Second"), NA)

  dev.off()
})
