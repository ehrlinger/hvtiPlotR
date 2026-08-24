# Tests for the test helper itself (tests/testthat/helper-plot-data.R).
#
# The row-count assertion in `expect_plot_has_data()` exempts a small set of
# decorator geoms. These tests pin down which layers that exemption may and may
# not cover, because the exemption is what stands between a real coverage
# assertion and a plot that "renders" carrying an empty layer.

library(testthat)

# Count the expectation failures raised by `expr` without failing this test.
# `expect_failure()` is no use here: it demands exactly one expectation, and
# `expect_plot_has_data()` raises three.
count_failures <- function(expr) {
  n <- 0L
  withCallingHandlers(
    expr,
    expectation_failure = function(e) {
      n <<- n + 1L
      invokeRestart("continue_test")
    }
  )
  n
}

test_that("a decorator geom mapped to the plotted data is still row-checked", {
  d <- data.frame(x = c("a", "b"))
  p <- ggplot2::ggplot(d, ggplot2::aes(x = .data$x)) +
    ggplot2::geom_vline(ggplot2::aes(xintercept = as.numeric(factor(.data$x))),
                        data = d[0, , drop = FALSE]) +
    ggplot2::geom_point(ggplot2::aes(y = 1))

  # The vline layer holds zero rows; the point layer holds two.
  expect_equal(layer_row_counts(p)[1], 0L)
  expect_gt(count_failures(expect_plot_has_data(p)), 0L)
})

test_that("a decorator geom given a literal intercept stays exempt", {
  d <- data.frame(x = 1:4, y = 1:4)
  p <- ggplot2::ggplot(d, ggplot2::aes(x = .data$x, y = .data$y)) +
    ggplot2::geom_point() +
    ggplot2::geom_hline(yintercept = 0)

  # The hline builds one row. Asking for four proves the exemption is what
  # carries it, not the row count.
  expect_equal(layer_row_counts(p)[2], 1L)
  expect_equal(count_failures(expect_plot_has_data(p, min_rows = 4L)), 0L)
})

test_that("an empty geom_blank layer stays exempt", {
  d <- data.frame(x = 1:4, y = 1:4)
  p <- ggplot2::ggplot(d, ggplot2::aes(x = .data$x, y = .data$y)) +
    ggplot2::geom_point() +
    ggplot2::geom_blank(data = d[0, , drop = FALSE])

  # geom_blank() exists to extend a scale and draws nothing, so a layer with no
  # rows is what it is for — not a defect, and not held to the one-row rule
  # that reference lines are.
  expect_equal(layer_row_counts(p)[2], 0L)
  expect_equal(count_failures(expect_plot_has_data(p)), 0L)
})
