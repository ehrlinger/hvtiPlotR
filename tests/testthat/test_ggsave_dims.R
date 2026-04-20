# Tests for hv_ggsave_dims()
library(testthat)
library(ggplot2)

# ============================================================================
# Input validation
# ============================================================================

test_that("hv_ggsave_dims rejects non-ggplot plot", {
  expect_error(hv_ggsave_dims("not a plot", 4, 3),
               "must be a ggplot")
})

test_that("hv_ggsave_dims rejects non-positive or non-scalar dims", {
  p <- ggplot(mtcars, aes(hp, mpg)) + geom_point()
  expect_error(hv_ggsave_dims(p,  0, 3), "positive")
  expect_error(hv_ggsave_dims(p,  4, 0), "positive")
  expect_error(hv_ggsave_dims(p, -1, 3), "positive")
  expect_error(hv_ggsave_dims(p, c(4, 5), 3), "single")
  expect_error(hv_ggsave_dims(p, NA_real_, 3), "positive")
})

test_that("hv_ggsave_dims rejects invalid units", {
  p <- ggplot(mtcars, aes(hp, mpg)) + geom_point()
  expect_error(hv_ggsave_dims(p, 4, 3, units = "px"))
})

# ============================================================================
# Core behaviour
# ============================================================================

test_that("theme_void yields zero chrome overhead", {
  p <- ggplot(mtcars, aes(hp, mpg)) + geom_point() + theme_void()
  dims <- hv_ggsave_dims(p, 4, 3)
  expect_equal(dims$width,  4, tolerance = 1e-6)
  expect_equal(dims$height, 3, tolerance = 1e-6)
  expect_identical(dims$units, "in")
})

test_that("labelled plot has positive chrome overhead", {
  p <- ggplot(mtcars, aes(hp, mpg)) + geom_point() +
    labs(title = "T", x = "X label", y = "Y label")
  dims <- hv_ggsave_dims(p, 4, 3)
  expect_gt(dims$width,  4)
  expect_gt(dims$height, 3)
})

test_that("adding a legend increases chrome along the relevant axis", {
  base <- ggplot(mtcars, aes(hp, mpg, color = factor(cyl))) + geom_point() +
    theme(legend.position = "none")
  with_legend_right <- base + theme(legend.position = "right")
  d_base  <- hv_ggsave_dims(base,              4, 3)
  d_right <- hv_ggsave_dims(with_legend_right, 4, 3)
  expect_gt(d_right$width, d_base$width)
})

test_that("faceting adds strip overhead while preserving target area", {
  base  <- ggplot(mtcars, aes(hp, mpg)) + geom_point()
  faceted <- base + facet_wrap(~ cyl)
  d_base    <- hv_ggsave_dims(base,    6, 3)
  d_faceted <- hv_ggsave_dims(faceted, 6, 3)
  # Facet strips add height overhead
  expect_gt(d_faceted$height, d_base$height)
})

# ============================================================================
# Units
# ============================================================================

test_that("units conversion is consistent", {
  p <- ggplot(mtcars, aes(hp, mpg)) + geom_point() +
    labs(title = "Unit test", x = "X", y = "Y")
  d_in <- hv_ggsave_dims(p,  4,  3,  units = "in")
  d_cm <- hv_ggsave_dims(p, 10.16, 7.62, units = "cm")  # 4 in, 3 in
  # Overhead in cm should match overhead in in * 2.54
  in_over_w <- d_in$width  - 4
  cm_over_w <- d_cm$width  - 10.16
  expect_equal(cm_over_w, in_over_w * 2.54, tolerance = 1e-3)
})

# ============================================================================
# ggsave() integration
# ============================================================================

test_that("output splats into ggsave() via do.call()", {
  p <- ggplot(mtcars, aes(hp, mpg)) + geom_point() +
    labs(title = "t")
  dims <- hv_ggsave_dims(p, 4, 3)
  tmp  <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp), add = TRUE)
  expect_silent(
    do.call(ggplot2::ggsave,
            c(list(filename = tmp, plot = p), dims))
  )
  expect_true(file.exists(tmp))
  expect_gt(file.info(tmp)$size, 0)
})
