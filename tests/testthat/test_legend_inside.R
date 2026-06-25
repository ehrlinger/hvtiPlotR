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

test_that("hv_legend_inside falls back with a message on facets", {
  p <- mk(full_df) + facet_wrap(~g)
  expect_message(out <- hv_legend_inside(p), "panel")
  expect_identical(out$theme$legend.position, "right")
})

# Helper: read the inside-anchor back from a returned plot.
inside_pos <- function(p) p$theme$legend.position.inside

test_that("hv_legend_inside places the legend in the empty corner", {
  cases <- list(
    tr = c(1 - 0.02, 1 - 0.02),
    tl = c(0.02,      1 - 0.02),
    br = c(1 - 0.02,  0.02),
    bl = c(0.02,      0.02)
  )
  fixtures <- list(
    tr = data.frame(x = c(0,0,1,0.5,0.1), y = c(0,1,0,0.5,0.1)),
    tl = data.frame(x = c(0,1,1,0.5,0.9), y = c(0,0,1,0.5,0.1)),
    br = data.frame(x = c(0,0,1,0.5,0.1), y = c(0,1,1,0.5,0.9)),
    bl = data.frame(x = c(0,1,1,0.5,0.9), y = c(1,0,1,0.5,0.9))
  )
  for (corner in names(cases)) {
    df <- fixtures[[corner]]; df$g <- "a"
    p <- hv_legend_inside(ggplot(df, aes(x, y, colour = g)) + geom_point())
    expect_identical(p$theme$legend.position, "inside", info = paste("corner", corner))
    expect_equal(inside_pos(p), cases[[corner]], info = paste("corner", corner))
  }
})

test_that("hv_legend_inside respects a custom fallback when the panel is full", {
  p <- hv_legend_inside(mk(full_df), fallback = "bottom")
  expect_identical(p$theme$legend.position, "bottom")
})

test_that("hv_legend_inside falls back when there are no usable points", {
  p <- hv_legend_inside(ggplot() + theme_grey())
  expect_identical(p$theme$legend.position, "right")
})

test_that("hv_legend_inside reads coordinates in built (post-flip) space", {
  df <- data.frame(x = c(0,0,1,0.5,0.1), y = c(0,1,0,0.5,0.1), g = "a")
  p <- hv_legend_inside(
    ggplot(df, aes(x, y, colour = g)) + geom_point() + coord_flip()
  )
  expect_identical(p$theme$legend.position, "inside")
})
