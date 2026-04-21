# Tests for hv_ph_location()
library(testthat)
library(ggplot2)

# ============================================================================
# Input validation
# ============================================================================

test_that("hv_ph_location rejects non-ggplot", {
  expect_error(hv_ph_location("x", 10, 5, 0.5, 1.5), "must be a ggplot")
})

test_that("hv_ph_location rejects bad panel dims / coords", {
  p <- ggplot(mtcars, aes(hp, mpg)) + geom_point()
  expect_error(hv_ph_location(p,  0, 5, 0.5, 1.5), "positive")
  expect_error(hv_ph_location(p, 10, 0, 0.5, 1.5), "positive")
  expect_error(hv_ph_location(p, 10, 5, -1,  1.5), "non-negative")
  expect_error(hv_ph_location(p, 10, 5, 0.5, -1),  "non-negative")
  expect_error(hv_ph_location(p, c(10, 20), 5, 0.5, 1.5), "scalar")
})

test_that("hv_ph_location rejects invalid units", {
  p <- ggplot(mtcars, aes(hp, mpg)) + geom_point()
  expect_error(hv_ph_location(p, 10, 5, 0.5, 1.5, units = "px"))
})

# ============================================================================
# Invariant: panel lands at (panel_left, panel_top) regardless of chrome
# ============================================================================

test_that("panel-left slide position is invariant across different chrome", {
  # Two plots with different y-axis label widths → different left chrome
  p_small <- ggplot(mtcars, aes(hp, mpg)) + geom_point() +
    scale_y_continuous(labels = function(x) sprintf("%3.1f", x))
  p_big   <- ggplot(mtcars, aes(hp, mpg)) + geom_point() +
    scale_y_continuous(labels = function(x) sprintf("%8.1f", x * 10000))

  l_s <- hv_ph_location(p_small, 10, 5, 1.0, 1.5)
  l_b <- hv_ph_location(p_big,   10, 5, 1.0, 1.5)

  # right edge on slide = loc$left + loc$width. For plots that share their
  # right-side chrome (no legend, same theme), this should be equal — i.e.
  # the panel's right edge (panel_left + panel_width) lands at the same
  # slide x on both plots.
  expect_equal(l_s$left + l_s$width,
               l_b$left + l_b$width,
               tolerance = 0.05)
  # Wider y-axis labels mean bigger left chrome, so loc$left is smaller
  expect_lt(l_b$left, l_s$left)
  # …and the total width grows by the same amount.
  expect_gt(l_b$width, l_s$width)
})

# ============================================================================
# theme_void yields zero chrome
# ============================================================================

test_that("theme_void returns panel box unchanged", {
  p <- ggplot(mtcars, aes(hp, mpg)) + geom_point() + theme_void()
  loc <- hv_ph_location(p, 10, 5, 1.0, 1.5)
  expect_equal(loc$width,  10,  tolerance = 1e-6)
  expect_equal(loc$height,  5,  tolerance = 1e-6)
  expect_equal(loc$left,  1.0,  tolerance = 1e-6)
  expect_equal(loc$top,   1.5,  tolerance = 1e-6)
})

# ============================================================================
# Negative-offset warning
# ============================================================================

test_that("emits warning when chrome overflows left/top", {
  p <- ggplot(mtcars, aes(hp, mpg)) + geom_point() +
    labs(x = "X", y = "Y") + theme(axis.title = element_text(size = 20))
  # panel_left = 0 → chrome on left cannot fit
  expect_warning(
    hv_ph_location(p, 10, 5, 0, 1.5),
    "does not fit"
  )
})

# ============================================================================
# Units consistency
# ============================================================================

test_that("units convert consistently", {
  p <- ggplot(mtcars, aes(hp, mpg)) + geom_point() +
    labs(title = "T", x = "X", y = "Y")
  l_in <- hv_ph_location(p, 10,      5,    1.0,  1.5,  units = "in")
  l_cm <- hv_ph_location(p, 10 * 2.54, 5 * 2.54, 1.0 * 2.54, 1.5 * 2.54,
                         units = "cm")
  # Total width in cm should equal total width in in * 2.54 (±rounding)
  expect_equal(l_cm$width,  l_in$width  * 2.54, tolerance = 1e-3)
  expect_equal(l_cm$height, l_in$height * 2.54, tolerance = 1e-3)
})

# ============================================================================
# Patchwork support
# ============================================================================

test_that("patchwork compositions are accepted", {
  skip_if_not_installed("patchwork")
  p1 <- ggplot(mtcars, aes(hp, mpg)) + geom_point()
  p2 <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  combo <- patchwork::wrap_plots(p1, p2)
  loc <- hv_ph_location(combo, 10, 5, 1.0, 1.5)
  expect_type(loc, "list")
  expect_named(loc, c("width", "height", "left", "top"))
})
