# Tests for save_manuscript()
library(testthat)
library(ggplot2)

mk_plot <- function() ggplot(mtcars, aes(mpg, wt)) + geom_point()

test_that("save_manuscript writes a file and returns the path invisibly", {
  p <- mk_plot()
  f <- tempfile(fileext = ".pdf")
  on.exit(unlink(f), add = TRUE)
  vis <- withVisible(save_manuscript(p, f))
  expect_false(vis$visible)
  expect_identical(vis$value, f)
  expect_true(file.exists(f))
})

test_that("save_manuscript validates its inputs", {
  p <- mk_plot()
  expect_error(save_manuscript("not a plot", tempfile(fileext = ".pdf")),
               "ggplot")
  expect_error(save_manuscript(p, c("a.pdf", "b.pdf")), "file path")
  expect_error(save_manuscript(p, NA_character_), "file path")
  expect_error(save_manuscript(p, ""), "file path")
  expect_error(save_manuscript(p, tempfile(fileext = ".pdf"), width = -1),
               "positive")
  expect_error(save_manuscript(p, tempfile(fileext = ".pdf"), dpi = 0),
               "positive")
  expect_error(save_manuscript(p, file.path(tempdir(), "no_such_dir", "f.pdf")),
               "directory does not exist")
})

test_that("save_manuscript honours a custom size and non-pdf format", {
  p <- mk_plot()
  f <- tempfile(fileext = ".png")
  on.exit(unlink(f), add = TRUE)
  expect_silent(save_manuscript(p, f, width = 3, height = 3, dpi = 72))
  expect_true(file.exists(f))
})
