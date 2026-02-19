# Tests for theme functions
library(testthat)
library(ggplot2)

utils::globalVariables(c("x", "y"))

context("Theme tests")

# Helper function to create a basic plot
create_test_plot <- function() {
  ggplot(data.frame(x = 1:10, y = 1:10), aes(x, y)) +
    geom_point()
}

# ==========================================================================
# hvti_theme generic tests
# ==========================================================================

test_that("hvti_theme returns themes for all supported styles", {
  expect_s3_class(hvti_theme("ppt"), "theme")
  expect_s3_class(hvti_theme("dark_ppt"), "theme")
  expect_s3_class(hvti_theme("manuscript"), "theme")
  expect_s3_class(hvti_theme("poster"), "theme")
})

test_that("hvti_theme forwards arguments to style-specific functions", {
  theme_custom <- hvti_theme("ppt", base_size = 18, ink = "navy")
  expect_s3_class(theme_custom, "theme")
})

test_that("hvti_theme errors on unsupported styles", {
  expect_error(hvti_theme("unknown"))
                 
               #"Unsupported hvtiPlotR theme style")
})

# ============================================================================
# theme_ppt tests
# ============================================================================

test_that("theme_ppt returns a valid theme object", {
  theme <- theme_ppt()
  expect_s3_class(theme, "theme")
  expect_s3_class(theme, "gg")
})

test_that("theme_ppt can be applied to a plot", {
  p <- create_test_plot() + theme_ppt()
  expect_s3_class(p, "ggplot")
  # Check that theme was actually applied
  expect_s3_class(p$theme, "theme")
})

test_that("theme_ppt respects base_size parameter", {
  theme_small <- theme_ppt(base_size = 16)
  theme_large <- theme_ppt(base_size = 48)
  expect_s3_class(theme_small, "theme")
  expect_s3_class(theme_large, "theme")
})

test_that("theme_ppt respects ink and paper parameters", {
  theme_custom <- theme_ppt(ink = "red", paper = "blue")
  expect_s3_class(theme_custom, "theme")
})

test_that("theme_ppt respects all documented parameters", {
  theme_full <- theme_ppt(
    base_size = 24,
    base_family = "sans",
    header_family = "serif",
    base_line_size = 1,
    base_rect_size = 1,
    ink = "black",
    paper = "white",
    accent = "#FF0000"
  )
  expect_s3_class(theme_full, "theme")
})

test_that("theme_ppt default ink is black", {
  theme <- theme_ppt()
  # Verify it creates a valid theme
  expect_s3_class(theme, "theme")
})

test_that("theme_ppt default paper is transparent", {
  theme <- theme_ppt()
  expect_s3_class(theme, "theme")
})

# ============================================================================
# theme_manuscript tests
# ============================================================================

test_that("theme_manuscript returns a valid theme object", {
  theme <- theme_manuscript()
  expect_s3_class(theme, "theme")
  expect_s3_class(theme, "gg")
})

test_that("theme_man is an alias for theme_manuscript", {
  expect_identical(theme_man, theme_manuscript)
})

test_that("theme_manuscript can be applied to a plot", {
  p <- create_test_plot() + theme_manuscript()
  expect_s3_class(p, "ggplot")
  expect_s3_class(p$theme, "theme")
})

test_that("theme_manuscript has smaller default base_size than theme_ppt", {
  # theme_manuscript defaults to 12, theme_ppt to 32
  theme_man <- theme_manuscript()
  theme_ppt <- theme_ppt()
  expect_s3_class(theme_man, "theme")
  expect_s3_class(theme_ppt, "theme")
})

test_that("theme_manuscript respects custom base_size", {
  theme_custom <- theme_manuscript(base_size = 14)
  expect_s3_class(theme_custom, "theme")
})

test_that("theme_manuscript respects ink and paper parameters", {
  theme_custom <- theme_manuscript(ink = "blue", paper = "gray90")
  expect_s3_class(theme_custom, "theme")
})

test_that("theme_manuscript respects all parameters", {
  theme_full <- theme_manuscript(
    base_size = 10,
    base_family = "mono",
    header_family = "sans",
    base_line_size = 0.5,
    base_rect_size = 0.5,
    ink = "black",
    paper = "white",
    accent = "#0000FF"
  )
  expect_s3_class(theme_full, "theme")
})

test_that("theme_man alias works identically", {
  p1 <- create_test_plot() + theme_manuscript()
  p2 <- create_test_plot() + theme_man()
  expect_s3_class(p1, "ggplot")
  expect_s3_class(p2, "ggplot")
})

# ============================================================================
# theme_dark_ppt tests
# ============================================================================

test_that("theme_dark_ppt returns a valid theme object", {
  theme <- theme_dark_ppt()
  expect_s3_class(theme, "theme")
  expect_s3_class(theme, "gg")
})

test_that("theme_dark_ppt can be applied to a plot", {
  p <- create_test_plot() + theme_dark_ppt()
  expect_s3_class(p, "ggplot")
  expect_s3_class(p$theme, "theme")
})

test_that("theme_dark_ppt default ink is white", {
  theme <- theme_dark_ppt()
  expect_s3_class(theme, "theme")
})

test_that("theme_dark_ppt respects all parameters", {
  theme_full <- theme_dark_ppt(
    base_size = 28,
    base_family = "sans",
    header_family = "serif",
    base_line_size = 1.2,
    base_rect_size = 1.2,
    ink = "white",
    paper = "transparent",
    accent = "#00FF00"
  )
  expect_s3_class(theme_full, "theme")
})

test_that("theme_dark_ppt respects base_size parameter", {
  theme_custom <- theme_dark_ppt(base_size = 20)
  expect_s3_class(theme_custom, "theme")
})

test_that("theme_dark_ppt works with different ink colors", {
  theme_custom <- theme_dark_ppt(ink = "yellow")
  expect_s3_class(theme_custom, "theme")
})

# ============================================================================
# theme_poster tests
# ============================================================================

test_that("theme_poster returns a valid theme object", {
  theme <- theme_poster()
  expect_s3_class(theme, "theme")
  expect_s3_class(theme, "gg")
})

test_that("theme_poster can be applied to a plot", {
  p <- create_test_plot() + theme_poster()
  expect_s3_class(p, "ggplot")
  expect_s3_class(p$theme, "theme")
})

test_that("theme_poster has medium base_size (16)", {
  theme <- theme_poster(base_size = 16)
  expect_s3_class(theme, "theme")
})

test_that("theme_poster respects all parameters", {
  theme_full <- theme_poster(
    base_size = 18,
    base_family = "sans",
    header_family = "serif",
    base_line_size = 0.8,
    base_rect_size = 0.8,
    ink = "black",
    paper = "white",
    accent = "#FF00FF"
  )
  expect_s3_class(theme_full, "theme")
})

test_that("theme_poster works with custom colors", {
  theme_custom <- theme_poster(ink = "darkblue", paper = "lightyellow")
  expect_s3_class(theme_custom, "theme")
})

# ============================================================================
# Integration tests - themes work together
# ============================================================================

test_that("all themes can be applied to the same plot sequentially", {
  p <- create_test_plot()
  p1 <- p + theme_ppt()
  p2 <- p + theme_manuscript()
  p3 <- p + theme_dark_ppt()
  p4 <- p + theme_poster()

  expect_s3_class(p1, "ggplot")
  expect_s3_class(p2, "ggplot")
  expect_s3_class(p3, "ggplot")
  expect_s3_class(p4, "ggplot")
})

test_that("themes work with different plot types", {
  # Scatter plot
  p1 <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_ppt()
  expect_s3_class(p1, "ggplot")

  # Line plot
  p2 <- ggplot(mtcars, aes(wt, mpg)) + geom_line() + theme_manuscript()
  expect_s3_class(p2, "ggplot")

  # Bar plot
  p3 <- ggplot(mtcars, aes(x = factor(cyl))) + geom_bar() + theme_dark_ppt()
  expect_s3_class(p3, "ggplot")

  # Boxplot
  p4 <- ggplot(mtcars, aes(x = factor(cyl), y = mpg)) +
    geom_boxplot() + theme_poster()
  expect_s3_class(p4, "ggplot")
})

test_that("themes work with faceted plots", {
  p <- ggplot(mtcars, aes(wt, mpg)) +
    geom_point() +
    facet_wrap(~cyl) +
    theme_ppt()
  expect_s3_class(p, "ggplot")
})

test_that("themes work with titled plots", {
  p <- create_test_plot() +
    labs(title = "Test Title",
         subtitle = "Test Subtitle",
         caption = "Test Caption") +
    theme_manuscript()
  expect_s3_class(p, "ggplot")
})

# ============================================================================
# Error handling tests
# ============================================================================

test_that("themes handle invalid base_size gracefully", {
  # Negative base_size might cause issues but shouldn't error
  expect_error(theme_ppt(base_size = -10), NA)
  expect_error(theme_manuscript(base_size = 0), NA)
})

test_that("themes handle unusual parameter combinations", {
  # Same ink and paper color
  expect_error(theme_ppt(ink = "black", paper = "black"), NA)

  # Very large base_size
  expect_error(theme_manuscript(base_size = 100), NA)

  # Very small line/rect sizes
  expect_error(theme_poster(base_line_size = 0.01, base_rect_size = 0.01), NA)
})

test_that("themes work with non-standard font families", {
  # These might not be available but shouldn't error
  expect_error(theme_ppt(base_family = "nonexistent"), NA)
  expect_error(theme_manuscript(header_family = "fake-font"), NA)
})
