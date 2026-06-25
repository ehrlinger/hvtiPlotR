# Tests for save_manuscript()
library(testthat)
library(ggplot2)

mk_plot <- function() ggplot(mtcars, aes(mpg, wt)) + geom_point()

test_that("save_manuscript writes a file and returns the path invisibly", {
  p <- mk_plot()
  f <- tempfile(fileext = ".pdf")
  expect_invisible(res <- save_manuscript(p, f))
  expect_identical(res, f)
  expect_true(file.exists(f))
  unlink(f)
})

test_that("save_manuscript validates its inputs", {
  expect_error(save_manuscript("not a plot", tempfile(fileext = ".pdf")),
               "ggplot")
  expect_error(save_manuscript(mk_plot(), c("a.pdf", "b.pdf")),
               "single file path")
})

test_that("save_manuscript honours a custom size and non-pdf format", {
  p <- mk_plot()
  f <- tempfile(fileext = ".png")
  expect_silent(save_manuscript(p, f, width = 3, height = 3, dpi = 72))
  expect_true(file.exists(f))
  unlink(f)
})
