# tests/testthat/test_legend_inside.R
library(testthat)
library(ggplot2)

mk <- function(df) ggplot(df, aes(x, y, colour = g)) + geom_point()
# a plot whose points fill all four corners (no clear empty corner)
full_df <- data.frame(
  x = c(0, 0, 1, 1, 0.05, 0.95, 0.05, 0.95),
  y = c(0, 1, 0, 1, 0.05, 0.05, 0.95, 0.95),
  g = rep(c("a", "b"), 4)
)

test_that("hv_legend_inside validates its inputs", {
  p <- mk(full_df)
  expect_error(hv_legend_inside("not a plot"), "ggplot")
  expect_error(hv_legend_inside(p, threshold = 1.5), "\\[0, 1\\]")
  expect_error(hv_legend_inside(p, box_frac = 0.7), "0.5")
  expect_error(hv_legend_inside(p, box_frac = -1), "positive")
  expect_error(hv_legend_inside(p, fallback = "middle"))  # match.arg
})

test_that("hv_legend_inside returns a ggplot with an outside legend when the panel is full", {
  p <- hv_legend_inside(mk(full_df))
  expect_s3_class(p, "ggplot")
  expect_identical(p$theme$legend.position, "right")
})
