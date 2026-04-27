# Tests for theme_hv_* functions and the deprecated aliases.
library(testthat)
library(ggplot2)

create_test_plot <- function() {
  ggplot(data.frame(x = 1:10, y = 1:10), aes(x, y)) +
    geom_point()
}

# ============================================================================
# theme_hv_manuscript
# ============================================================================

test_that("theme_hv_manuscript returns a valid theme object", {
  th <- theme_hv_manuscript()
  expect_s3_class(th, "theme")
  expect_s3_class(th, "gg")
})

test_that("theme_hv_manuscript composes onto a plot", {
  p <- create_test_plot() + theme_hv_manuscript()
  expect_s3_class(p, "ggplot")
  expect_s3_class(p$theme, "theme")
})

test_that("theme_hv_manuscript hides legend by default", {
  expect_identical(theme_hv_manuscript()$legend.position, "none")
})

test_that("theme_hv_manuscript ... overrides default elements", {
  th <- theme_hv_manuscript(legend.position = "right")
  expect_identical(th$legend.position, "right")
})

test_that("theme_hv_manuscript ... accepts arbitrary theme elements", {
  th <- theme_hv_manuscript(
    axis.text.y = element_text(family = "mono")
  )
  expect_identical(th$axis.text.y$family, "mono")
})

test_that("theme_hv_manuscript respects all base_grey parameters", {
  th <- theme_hv_manuscript(
    base_size      = 10,
    base_family    = "mono",
    header_family  = "sans",
    base_line_size = 0.5,
    base_rect_size = 0.5,
    ink            = "black",
    paper          = "white",
    accent         = "#0000FF"
  )
  expect_s3_class(th, "theme")
})

# ============================================================================
# theme_hv_poster
# ============================================================================

test_that("theme_hv_poster returns a valid theme object", {
  th <- theme_hv_poster()
  expect_s3_class(th, "theme")
})

test_that("theme_hv_poster composes onto a plot and accepts ... overrides", {
  th <- theme_hv_poster(legend.position = "bottom")
  expect_identical(th$legend.position, "bottom")
})

# ============================================================================
# theme_hv_ppt_dark
# ============================================================================

test_that("theme_hv_ppt_dark hides legend by default", {
  expect_identical(theme_hv_ppt_dark()$legend.position, "none")
})

test_that("theme_hv_ppt_dark retains opaque black panel fill", {
  th <- theme_hv_ppt_dark()
  expect_identical(th$panel.background$fill,   "black")
  expect_identical(th$panel.background$colour, "white")
})

test_that("theme_hv_ppt_dark uses inside-facing ticks (negative length)", {
  th <- theme_hv_ppt_dark(base_size = 32)
  tlen <- grid::convertUnit(th$axis.ticks.length, "pt", valueOnly = TRUE)
  expect_lt(tlen, 0)
  expect_equal(tlen, -32 / 4, tolerance = 1e-6)
})

test_that("theme_hv_ppt_dark axis-title margins scale with base_size", {
  m32 <- theme_hv_ppt_dark(base_size = 32)$axis.title.x$margin
  m16 <- theme_hv_ppt_dark(base_size = 16)$axis.title.x$margin
  expect_equal(as.numeric(m32[1]), 2 * as.numeric(m16[1]), tolerance = 1e-6)
})

test_that("theme_hv_ppt_dark ... can supply mono y-axis text", {
  th <- theme_hv_ppt_dark(
    axis.text.y = element_text(family = "mono")
  )
  expect_identical(th$axis.text.y$family, "mono")
})

test_that("theme_hv_ppt_dark ... can re-add bold axis face", {
  th <- theme_hv_ppt_dark(
    axis.text  = element_text(face = "bold"),
    axis.title = element_text(face = "bold")
  )
  expect_identical(th$axis.text$face,  "bold")
  expect_identical(th$axis.title$face, "bold")
})

# ============================================================================
# theme_hv_ppt_light
# ============================================================================

test_that("theme_hv_ppt_light hides legend by default", {
  expect_identical(theme_hv_ppt_light()$legend.position, "none")
})

test_that("theme_hv_ppt_light has transparent panel fill (template shows through)", {
  th <- theme_hv_ppt_light()
  expect_identical(th$panel.background$fill,   "transparent")
  expect_identical(th$panel.background$colour, "black")
  expect_identical(th$plot.background$fill,    "transparent")
})

test_that("theme_hv_ppt_light uses inside-facing ticks (negative length)", {
  th <- theme_hv_ppt_light(base_size = 32)
  tlen <- grid::convertUnit(th$axis.ticks.length, "pt", valueOnly = TRUE)
  expect_lt(tlen, 0)
  expect_equal(tlen, -32 / 4, tolerance = 1e-6)
})

# ============================================================================
# Composition with different plot types
# ============================================================================

test_that("themes work with a faceted plot", {
  p <- ggplot(mtcars, aes(wt, mpg)) +
    geom_point() +
    facet_wrap(~cyl) +
    theme_hv_ppt_dark()
  expect_s3_class(p, "ggplot")
})

test_that("themes work with a titled plot", {
  p <- create_test_plot() +
    labs(title = "Test Title", subtitle = "Test Subtitle") +
    theme_hv_manuscript()
  expect_s3_class(p, "ggplot")
})

test_that("themes accept unusual parameter combinations without error", {
  expect_error(theme_hv_ppt_dark(base_size = -10),                  NA)
  expect_error(theme_hv_manuscript(base_size = 0),                  NA)
  expect_error(theme_hv_manuscript(base_size = 100),                NA)
  expect_error(theme_hv_poster(base_line_size = 0.01,
                               base_rect_size = 0.01),              NA)
  expect_error(theme_hv_manuscript(base_family = "nonexistent"),    NA)
  expect_error(theme_hv_ppt_dark(ink = "yellow"),                   NA)
})

# ============================================================================
# Deprecated aliases — still work, emit a deprecation warning
# ============================================================================

test_that("theme_man is a deprecated alias for theme_hv_manuscript", {
  expect_warning(th <- theme_man(), "deprecated")
  expect_s3_class(th, "theme")
  expect_identical(suppressWarnings(theme_man())$legend.position,
                   theme_hv_manuscript()$legend.position)
})

test_that("theme_manuscript is a deprecated alias", {
  expect_warning(th <- theme_manuscript(), "deprecated")
  expect_s3_class(th, "theme")
})

test_that("hv_theme_manuscript is a deprecated alias", {
  expect_warning(th <- hv_theme_manuscript(), "deprecated")
  expect_s3_class(th, "theme")
})

test_that("theme_poster / hv_theme_poster are deprecated aliases", {
  expect_warning(theme_poster(),    "deprecated")
  expect_warning(hv_theme_poster(), "deprecated")
})

test_that("theme_ppt / theme_dark_ppt / hv_theme_ppt / hv_theme_dark_ppt all map to theme_hv_ppt_dark", {
  expect_warning(t1 <- theme_ppt(),         "deprecated")
  expect_warning(t2 <- theme_dark_ppt(),    "deprecated")
  expect_warning(t3 <- hv_theme_ppt(),      "deprecated")
  expect_warning(t4 <- hv_theme_dark_ppt(), "deprecated")
  ref <- theme_hv_ppt_dark()
  expect_identical(t1$panel.background$fill, ref$panel.background$fill)
  expect_identical(t2$panel.background$fill, ref$panel.background$fill)
  expect_identical(t3$panel.background$fill, ref$panel.background$fill)
  expect_identical(t4$panel.background$fill, ref$panel.background$fill)
})

test_that("theme_light_ppt / hv_theme_light_ppt are deprecated aliases", {
  expect_warning(t1 <- theme_light_ppt(),    "deprecated")
  expect_warning(t2 <- hv_theme_light_ppt(), "deprecated")
  ref <- theme_hv_ppt_light()
  expect_identical(t1$panel.background$fill, ref$panel.background$fill)
  expect_identical(t2$panel.background$fill, ref$panel.background$fill)
})

test_that("hv_theme dispatcher has been removed", {
  expect_false(exists("hv_theme", mode = "function",
                      envir = asNamespace("hvtiPlotR")))
})
