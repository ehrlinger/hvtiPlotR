utils::globalVariables(c("x", "y"))

library(testthat)
library(ggplot2)

# Helper: minimal test plot
create_test_plot <- function() {
  ggplot(data.frame(x = 1:10, y = 1:10), aes(x, y)) + geom_point()
}

# Helper: create a minimal in-memory pptx template and write to a temp file
make_temp_template <- function() {
  tmp <- tempfile(fileext = ".pptx")
  officer::read_pptx() |>
    officer::add_slide(layout = "Title and Content") |>
    print(target = tmp)
  tmp
}

# ============================================================================
# Success paths
# ============================================================================

test_that("save_ppt writes a file for a single ggplot", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")

  p            <- create_test_plot()
  temp_template <- make_temp_template()
  temp_ppt     <- tempfile(fileext = ".pptx")
  on.exit(unlink(c(temp_ppt, temp_template)))

  expect_no_error(
    save_ppt(p, template = temp_template, powerpoint = temp_ppt)
  )
  expect_true(file.exists(temp_ppt))
})

test_that("save_ppt writes a file for a list of ggplots", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")

  plots        <- list(create_test_plot(),
                       ggplot(data.frame(x = 1:5, y = 5:1), aes(x, y)) +
                         geom_line())
  temp_template <- make_temp_template()
  temp_ppt     <- tempfile(fileext = ".pptx")
  on.exit(unlink(c(temp_ppt, temp_template)))

  expect_no_error(
    save_ppt(plots, template = temp_template, powerpoint = temp_ppt,
             slide_titles = c("Plot A", "Plot B"))
  )
  expect_true(file.exists(temp_ppt))
})

test_that("save_ppt recycles a single slide_titles string across all plots", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")

  plots        <- list(create_test_plot(), create_test_plot())
  temp_template <- make_temp_template()
  temp_ppt     <- tempfile(fileext = ".pptx")
  on.exit(unlink(c(temp_ppt, temp_template)))

  expect_no_error(
    save_ppt(plots, template = temp_template, powerpoint = temp_ppt,
             slide_titles = "Same title")
  )
})

test_that("save_ppt works with custom width, height, left, top", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")

  p            <- create_test_plot()
  temp_template <- make_temp_template()
  temp_ppt     <- tempfile(fileext = ".pptx")
  on.exit(unlink(c(temp_ppt, temp_template)))

  expect_no_error(
    save_ppt(p, template = temp_template, powerpoint = temp_ppt,
             width = 8, height = 5, left = 0.5, top = 1.5)
  )
})

test_that("save_ppt works with theme_ppt", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")

  p            <- create_test_plot() + hv_theme_ppt()
  temp_template <- make_temp_template()
  temp_ppt     <- tempfile(fileext = ".pptx")
  on.exit(unlink(c(temp_ppt, temp_template)))

  expect_no_error(
    save_ppt(p, template = temp_template, powerpoint = temp_ppt)
  )
})

test_that("save_ppt works with all hvtiPlotR themes", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")

  plots <- list(
    create_test_plot() + hv_theme_ppt(),
    create_test_plot() + hv_theme_dark_ppt(),
    create_test_plot() + hv_theme_poster()
  )
  temp_template <- make_temp_template()
  temp_ppt     <- tempfile(fileext = ".pptx")
  on.exit(unlink(c(temp_ppt, temp_template)))

  expect_no_error(
    save_ppt(plots, template = temp_template, powerpoint = temp_ppt)
  )
})

test_that("save_ppt returns the output path invisibly", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")

  p            <- create_test_plot()
  temp_template <- make_temp_template()
  temp_ppt     <- tempfile(fileext = ".pptx")
  on.exit(unlink(c(temp_ppt, temp_template)))

  result <- save_ppt(p, template = temp_template, powerpoint = temp_ppt)
  expect_equal(result, temp_ppt)
})

# ============================================================================
# Validation failures
# ============================================================================

test_that("save_ppt errors on empty list", {
  skip_if_not_installed("officer")

  temp_template <- make_temp_template()
  on.exit(unlink(temp_template))

  expect_error(
    save_ppt(list(), template = temp_template,
             powerpoint = tempfile(fileext = ".pptx")),
    "list cannot be empty"
  )
})

test_that("save_ppt errors when list contains non-ggplot objects", {
  skip_if_not_installed("officer")

  temp_template <- make_temp_template()
  on.exit(unlink(temp_template))

  expect_error(
    save_ppt(list(create_test_plot(), "not a plot"),
             template  = temp_template,
             powerpoint = tempfile(fileext = ".pptx")),
    "must be ggplot objects"
  )
})

test_that("save_ppt errors when object is neither ggplot nor list", {
  skip_if_not_installed("officer")

  temp_template <- make_temp_template()
  on.exit(unlink(temp_template))

  expect_error(
    save_ppt("not a plot", template = temp_template,
             powerpoint = tempfile(fileext = ".pptx")),
    "ggplot"
  )
})

test_that("save_ppt errors when template path does not exist", {
  skip_if_not_installed("officer")

  expect_error(
    save_ppt(create_test_plot(),
             template   = tempfile(fileext = ".pptx"),
             powerpoint = tempfile(fileext = ".pptx")),
    "existing PowerPoint file"
  )
})

test_that("save_ppt errors on non-positive width", {
  skip_if_not_installed("officer")

  temp_template <- make_temp_template()
  on.exit(unlink(temp_template))

  expect_error(
    save_ppt(create_test_plot(), template = temp_template,
             powerpoint = tempfile(fileext = ".pptx"), width = 0),
    "width"
  )
})

test_that("save_ppt errors on non-positive height", {
  skip_if_not_installed("officer")

  temp_template <- make_temp_template()
  on.exit(unlink(temp_template))

  expect_error(
    save_ppt(create_test_plot(), template = temp_template,
             powerpoint = tempfile(fileext = ".pptx"), height = -1),
    "height"
  )
})

test_that("save_ppt errors on negative left offset", {
  skip_if_not_installed("officer")

  temp_template <- make_temp_template()
  on.exit(unlink(temp_template))

  expect_error(
    save_ppt(create_test_plot(), template = temp_template,
             powerpoint = tempfile(fileext = ".pptx"), left = -0.5),
    "left"
  )
})

# ============================================================================
# Edge case: slide_titles length mismatch
# ============================================================================

test_that("save_ppt recycles a single slide_title across a multi-plot list", {
  # save_ppt uses rep_len() — a single title is recycled, not an error.
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")

  temp_template <- make_temp_template()
  on.exit(unlink(temp_template))

  pptx_out <- tempfile(fileext = ".pptx")
  on.exit(unlink(pptx_out), add = TRUE)

  plots <- list(create_test_plot(), create_test_plot())
  expect_no_error(
    save_ppt(
      object       = plots,
      template     = temp_template,
      powerpoint   = pptx_out,
      slide_titles = "Shared Title"   # single title recycled to both slides
    )
  )
  expect_true(file.exists(pptx_out))
})

# ============================================================================
# panel_box parameter (fixed-panel slide placement)
# ============================================================================

test_that("save_ppt writes a deck using panel_box layout", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")

  # Two plots with different y-axis label widths → different chrome per slide
  p1 <- ggplot(mtcars, aes(hp, mpg)) + geom_point() +
    scale_y_continuous(labels = function(x) sprintf("%3.1f", x))
  p2 <- ggplot(mtcars, aes(hp, mpg)) + geom_point() +
    scale_y_continuous(labels = function(x) sprintf("%8.1f", x * 10000))

  tmp_tpl <- make_temp_template()
  tmp_out <- tempfile(fileext = ".pptx")
  on.exit(unlink(c(tmp_tpl, tmp_out)))

  expect_no_error(
    save_ppt(
      list(p1, p2),
      template     = tmp_tpl,
      powerpoint   = tmp_out,
      slide_titles = c("Small", "Big"),
      panel_box    = list(width = 10, height = 5, left = 1.5, top = 1.5)
    )
  )
  expect_true(file.exists(tmp_out))
})

test_that("save_ppt rejects panel_box missing required fields", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")

  p      <- create_test_plot()
  tmp_tpl <- make_temp_template()
  tmp_out <- tempfile(fileext = ".pptx")
  on.exit(unlink(c(tmp_tpl, tmp_out)))

  expect_error(
    save_ppt(p, template = tmp_tpl, powerpoint = tmp_out,
             panel_box = list(width = 10, height = 5)),
    "panel_box"
  )
})

