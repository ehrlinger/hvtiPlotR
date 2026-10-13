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

test_that(".panel_block stops below 1.6 inch panels and names pagination", {
  # Four columns in 6 in would be 1.5 in each.
  expect_error(.panel_block(1, 4, c(width = 6, height = 9)), "facet_wrap_paginate")
  expect_silent(.panel_block(1, 3, c(width = 5.25, height = 9)))
})

test_that("a faceted plot stays inside the page, chrome included", {
  p <- p0 + facet_wrap(~cyl)
  dims <- hv_panel_size(p)
  expect_lte(dims$width, 6.5 + 1e-8)
  expect_lte(dims$height, 9 + 1e-8)
  # One row of three is 9 in of panels, so every panel shrinks to fit 6.5 in.
  expect_lt(dims$height, 4)
  # Two rows of two: taller than one row of three.
  tall <- hv_panel_size(p0 + facet_wrap(~gear + am, ncol = 2))
  expect_gt(tall$height, dims$height)
})

test_that("a facet grid too wide for the page stops", {
  wide <- p0 + facet_grid(~carb)
  expect_error(hv_panel_size(wide), "facet_wrap_paginate")
})

test_that("gutters between panels do not count as panel width", {
  # Three columns with 0.75 in gutters leave about 1.5 in panels inside 6.5 in: below the floor.
  wide_gutters <- p0 + facet_wrap(~cyl) + theme(panel.spacing = grid::unit(0.75, "in"))
  expect_error(hv_panel_size(wide_gutters), "facet_wrap_paginate")
  expect_no_error(hv_panel_size(p0 + facet_wrap(~cyl)))
})

test_that("a paginated facet is sized by the page it draws, not every page", {
  skip_if_not_installed("ggforce")
  # 40 facets, two to a page: counting every page would ask for 20 rows of 2.
  many <- data.frame(x = rep(1:2, 40), y = rep(1:2, 40), g = rep(seq_len(40), each = 2))
  paged <- ggplot(many, aes(x, y)) + geom_point() +
    ggforce::facet_wrap_paginate(~g, nrow = 1, ncol = 2, page = 1)
  dims <- hv_panel_size(paged)
  expect_lte(dims$width, 6.5 + 1e-8)
  expect_lte(dims$height, 9 + 1e-8)
})

test_that("omitted limits are 6.5 by 9 inches whatever the units", {
  p <- p0 + facet_wrap(~cyl)
  inches <- hv_panel_size(p)
  expect_equal(hv_panel_size(p, units = "cm")$width, inches$width * 2.54, tolerance = 1e-6)
  expect_equal(hv_panel_size(p, units = "mm")$height, inches$height * 25.4, tolerance = 1e-6)
})

test_that("a patchwork stops rather than passing as one panel", {
  skip_if_not_installed("patchwork")
  stacked <- patchwork::wrap_plots(p0, p0, p0, ncol = 1)
  expect_error(hv_panel_size(stacked), "patchwork")
})

test_that("three columns fit the default page and four do not", {
  three <- hv_panel_size(p0 + facet_wrap(~cyl))
  expect_lte(three$width, 6.5 + 1e-8)
  expect_error(hv_panel_size(p0 + facet_wrap(~carb, nrow = 1)), "facet_wrap_paginate")
})
