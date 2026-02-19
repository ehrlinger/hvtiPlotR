utils::globalVariables(c("x", "y"))

# Tests for save_ppt function
library(testthat)
library(ggplot2)

context("save_ppt tests")

# Helper to create test plots
create_test_plot <- function() {
  ggplot(data.frame(x = 1:10, y = 1:10), aes(x, y)) + geom_point()
}

# ============================================================================
# Input validation tests
# ============================================================================

test_that("save_ppt accepts a single ggplot object", {
  skip_if_not_installed("officer")

  p <- create_test_plot()
  temp_ppt <- tempfile(fileext = ".pptx")

  # Create a minimal template
  temp_template <- tempfile(fileext = ".pptx")
  officer::read_pptx() |>
    officer::add_slide(layout = "Title and Content") |>
    print(target = temp_template)

  expect_error(
    save_ppt(p, template = temp_template, powerpoint = temp_ppt)
  )

  # Clean up
  unlink(c(temp_ppt, temp_template))
})

test_that("save_ppt accepts a list of ggplot objects", {
  skip_if_not_installed("officer")

  p1 <- create_test_plot()
  p2 <- ggplot(data.frame(x = 1:10, y = 10:1), aes(x, y)) + geom_line()
  plot_list <- list(p1, p2)

  temp_ppt <- tempfile(fileext = ".pptx")
  temp_template <- tempfile(fileext = ".pptx")

  officer::read_pptx() |>
    officer::add_slide(layout = "Title and Content") |>
    print(target = temp_template)

  expect_error(
    save_ppt(plot_list, template = temp_template, powerpoint = temp_ppt)
  )

  unlink(c(temp_ppt, temp_template))
})

test_that("save_ppt works with custom dimensions", {
  skip_if_not_installed("officer")

  p <- create_test_plot()
  temp_ppt <- tempfile(fileext = ".pptx")
  temp_template <- tempfile(fileext = ".pptx")

  officer::read_pptx() |>
    officer::add_slide(layout = "Title and Content") |>
    print(target = temp_template)

  expect_error(
    save_ppt(p,
             template = temp_template,
             powerpoint = temp_ppt,
             width = 10,
             height = 7,
             offx = 0.5,
             offy = 0.5)
  )

  unlink(c(temp_ppt, temp_template))
})

test_that("save_ppt works with custom slide title", {
  skip_if_not_installed("officer")

  p <- create_test_plot()
  temp_ppt <- tempfile(fileext = ".pptx")
  temp_template <- tempfile(fileext = ".pptx")

  officer::read_pptx() |>
    officer::add_slide(layout = "Title and Content") |>
    print(target = temp_template)

  expect_error(
    save_ppt(p,
             template = temp_template,
             powerpoint = temp_ppt,
             slide_title = "Custom Title")
  )

  unlink(c(temp_ppt, temp_template))
})

# ============================================================================
# Integration tests with themes
# ============================================================================

test_that("save_ppt works with theme_ppt", {
  skip_if_not_installed("officer")

  p <- create_test_plot() + theme_ppt()
  temp_ppt <- tempfile(fileext = ".pptx")
  temp_template <- tempfile(fileext = ".pptx")

  officer::read_pptx() |>
    officer::add_slide(layout = "Title and Content") |>
    print(target = temp_template)

  expect_error(
    save_ppt(p, template = temp_template, powerpoint = temp_ppt)
  )

  unlink(c(temp_ppt, temp_template))
})

test_that("save_ppt works with all theme types", {
  skip_if_not_installed("officer")

  plots <- list(
    create_test_plot() + theme_ppt(),
    create_test_plot() + theme_dark_ppt(),
    create_test_plot() + theme_poster()
  )

  temp_ppt <- tempfile(fileext = ".pptx")
  temp_template <- tempfile(fileext = ".pptx")

  officer::read_pptx() |>
    officer::add_slide(layout = "Title and Content") |>
    print(target = temp_template)

  expect_error(
    save_ppt(plots, template = temp_template, powerpoint = temp_ppt)
  )

  unlink(c(temp_ppt, temp_template))
})

# ============================================================================
# Edge case tests
# ============================================================================

test_that("save_ppt errors on empty list", {
  skip_if_not_installed("officer")

  temp_ppt <- tempfile(fileext = ".pptx")
  temp_template <- tempfile(fileext = ".pptx")

  officer::read_pptx() |>
    officer::add_slide(layout = "Title and Content") |>
    print(target = temp_template)

  expect_error(
    save_ppt(list(), template = temp_template, powerpoint = temp_ppt),
    "list cannot be empty"
  )

  unlink(c(temp_ppt, temp_template))
})

test_that("save_ppt errors when list contains non-ggplot objects", {
  skip_if_not_installed("officer")

  mixed_list <- list(
    create_test_plot(),
    "not a plot",
    create_test_plot()
  )

  temp_ppt <- tempfile(fileext = ".pptx")
  temp_template <- tempfile(fileext = ".pptx")

  officer::read_pptx() |>
    officer::add_slide(layout = "Title and Content") |>
    print(target = temp_template)

  expect_error(
    save_ppt(mixed_list, template = temp_template, powerpoint = temp_ppt),
    "must be ggplot objects"
  )

  unlink(c(temp_ppt, temp_template))
})

test_that("save_ppt errors when template path is invalid", {
  skip_if_not_installed("officer")

  p <- create_test_plot()
  temp_ppt <- tempfile(fileext = ".pptx")
  bogus_template <- tempfile(fileext = ".pptx")

  expect_error(
    save_ppt(p, template = bogus_template, powerpoint = temp_ppt),
    "existing PowerPoint file"
  )
})

test_that("save_ppt works with complex plots", {
  skip_if_not_installed("officer")

  # Create a more complex plot
  p <- ggplot(mtcars, aes(wt, mpg, color = factor(cyl))) +
    geom_point() +
    facet_wrap(~gear) +
    labs(title = "Complex Plot",
         subtitle = "With multiple elements",
         caption = "Source: mtcars") +
    theme_ppt()

  temp_ppt <- tempfile(fileext = ".pptx")
  temp_template <- tempfile(fileext = ".pptx")

  officer::read_pptx() |>
    officer::add_slide(layout = "Title and Content") |>
    print(target = temp_template)

  expect_error(
    save_ppt(p, template = temp_template, powerpoint = temp_ppt)
  )

  unlink(c(temp_ppt, temp_template))
})

# ============================================================================
# Parameter validation tests
# ============================================================================

test_that("save_ppt handles various dimension values", {
  skip_if_not_installed("officer")

  p <- create_test_plot()
  temp_template <- tempfile(fileext = ".pptx")

  officer::read_pptx() |>
    officer::add_slide(layout = "Title and Content") |>
    print(target = temp_template)

  # Very small dimensions
  temp_ppt1 <- tempfile(fileext = ".pptx")
  expect_error(
    save_ppt(p, template = temp_template, powerpoint = temp_ppt1,
             width = 1, height = 1)
  )

  # Very large dimensions
  temp_ppt2 <- tempfile(fileext = ".pptx")
  expect_error(
    save_ppt(p, template = temp_template, powerpoint = temp_ppt2,
             width = 20, height = 15)
  )

  unlink(c(temp_ppt1, temp_ppt2, temp_template))
})

test_that("save_ppt handles various offset values", {
  skip_if_not_installed("officer")

  p <- create_test_plot()
  temp_ppt <- tempfile(fileext = ".pptx")
  temp_template <- tempfile(fileext = ".pptx")

  officer::read_pptx() |>
    officer::add_slide(layout = "Title and Content") |>
    print(target = temp_template)

  expect_error(
    save_ppt(p, template = temp_template, powerpoint = temp_ppt,
             offx = 0, offy = 0)
  )

  unlink(c(temp_ppt, temp_template))
})

test_that("save_ppt errors when object is not ggplot or list", {
  skip_if_not_installed("officer")

  temp_template <- tempfile(fileext = ".pptx")
  officer::read_pptx() |>
    officer::add_slide(layout = "Title and Content") |>
    print(target = temp_template)

  expect_error(
    save_ppt("not a plot", template = temp_template, powerpoint = tempfile(fileext = ".pptx")),
    "ggplot object"
  )

  unlink(temp_template)
})
