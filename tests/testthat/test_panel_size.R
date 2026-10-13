# Tests for hv_panel_size()
library(testthat)
library(ggplot2)

p0 <- ggplot(mtcars, aes(hp, mpg)) + geom_point()

test_that("hv_panel_size rejects a non-ggplot and bad limits", {
  expect_error(hv_panel_size("not a plot"), "must be a ggplot")
  expect_error(hv_panel_size(p0, max_width = 0), "positive")
  expect_error(hv_panel_size(p0, max_height = NA_real_), "positive")
  expect_error(hv_panel_size(p0, units = "px"))
})

test_that("a single panel gets the standard 6 by 4 inch figure", {
  expect_identical(hv_panel_size(p0), list(width = 6, height = 4, units = "in"))
  expect_equal(hv_panel_size(p0, units = "cm"), list(width = 6 * 2.54, height = 4 * 2.54, units = "cm"))
})

test_that(".panel_block gives 3 by 2 inch panels when they fit", {
  expect_equal(.panel_block(1, 2, c(width = 9, height = 9)), c(width = 6, height = 2))
  expect_equal(.panel_block(3, 1, c(width = 9, height = 9)), c(width = 3, height = 6))
})

test_that(".panel_block shrinks every panel by one factor, keeping 3:2", {
  # Three columns need 9 in; 6 in of room shrinks each panel by 2/3, to 2 by 1.33.
  block <- .panel_block(2, 3, c(width = 6, height = 9))
  expect_equal(block, c(width = 6, height = 2 * 2 * 2 / 3))
  expect_equal((block[["width"]] / 3) / (block[["height"]] / 2), 1.5)
  # Height binds too: six rows need 12 in; 9 in of room shrinks by 3/4.
  expect_equal(.panel_block(6, 1, c(width = 6, height = 9)), c(width = 2.25, height = 9))
})

test_that(".panel_block stops below 1.75 inch panels and names pagination", {
  # Four columns in 6 in would be 1.5 in each.
  expect_error(.panel_block(1, 4, c(width = 6, height = 9)), "facet_wrap_paginate")
  expect_silent(.panel_block(1, 3, c(width = 5.25, height = 9)))
})

test_that("a faceted plot stays inside the page, chrome included", {
  p <- p0 + facet_wrap(~cyl)
  dims <- hv_panel_size(p)
  expect_lte(dims$width, 6 + 1e-8)
  expect_lte(dims$height, 9 + 1e-8)
  # One row of three is 9 in of panels, so every panel shrinks to fit 6 in.
  expect_lt(dims$height, 4)
  # Two rows of two: taller than one row of three.
  tall <- hv_panel_size(p0 + facet_wrap(~gear + am, ncol = 2))
  expect_gt(tall$height, dims$height)
})

test_that("a facet grid too wide for the page stops", {
  wide <- p0 + facet_grid(~carb)
  expect_error(hv_panel_size(wide), "facet_wrap_paginate")
})
