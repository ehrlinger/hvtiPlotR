# Tests for hv_ppt_palette() and the hv_ppt_series() decorator.
library(testthat)
library(ggplot2)

# The test device is pdf(), which resolves fonts through a closed metrics
# table and cannot draw Arial; the package handles that at draw time (see
# test_themes.R). Muffle only those font notes, per call, so a legend
# assertion is not buried under forty of them.
grob_quietly <- function(p) {
  withCallingHandlers(
    ggplotGrob(p),
    warning = function(w) {
      if (grepl("font (family|width|metrics)", conditionMessage(w)))
        invokeRestart("muffleWarning")
    }
  )
}

grouped_trends <- function(n = 400) {
  dta <- sample_trends_data(n = n, seed = 42)
  hv_trends(dta, x_col = "year", y_col = "value", group_col = "group")
}

# ============================================================================
# hv_ppt_palette
# ============================================================================

test_that("hv_ppt_palette returns six hex colors per mode", {
  for (mode in c("dark", "light")) {
    pal <- hv_ppt_palette(mode)
    expect_type(pal, "character")
    expect_length(pal, 6L)
    expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", pal)))
    expect_false(anyDuplicated(pal) > 0L)
  }
})

test_that("hv_ppt_palette orders for the background", {
  # Black is legible on a light slide and invisible on a dark one.
  expect_true("#000000" %in% hv_ppt_palette("light"))
  expect_false("#000000" %in% hv_ppt_palette("dark"))
  expect_false(identical(hv_ppt_palette("dark")[1], hv_ppt_palette("light")[1]))
})

# WCAG 2.2 relative luminance and contrast ratio, for SC 1.4.11 (3:1 for a
# graphical object needed to read the chart).
wcag_luminance <- function(hex) {
  rgb <- grDevices::col2rgb(hex) / 255
  lin <- ifelse(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055)^2.4)
  drop(c(0.2126, 0.7152, 0.0722) %*% lin)
}
wcag_contrast <- function(fg, bg) {
  l_fg <- wcag_luminance(fg)
  l_bg <- wcag_luminance(bg)
  (pmax(l_fg, l_bg) + 0.05) / (pmin(l_fg, l_bg) + 0.05)
}

test_that("the contrast helper reproduces the WCAG reference values", {
  expect_equal(wcag_contrast("#000000", "#FFFFFF"), 21)
  expect_equal(wcag_contrast("#FFFFFF", "#FFFFFF"), 1)
  # Okabe-Ito orange, the color the light ordering dropped for falling short.
  expect_lt(wcag_contrast("#E69F00", "#FFFFFF"), 3)
})

test_that("every light color is at least 3:1 on a white slide background", {
  # theme_hv_ppt_light() leaves its panel transparent, so the series sit on the
  # slide itself; the guarantee is for the house light template, which is white.
  pal <- hv_ppt_palette("light")
  ratios <- vapply(pal, wcag_contrast, numeric(1), bg = "#FFFFFF")
  expect_true(all(ratios >= 3), info = paste(pal[ratios < 3], collapse = ", "))
})

test_that("every dark color is at least 3:1 on the black dark panel", {
  # theme_hv_ppt_dark() fills panel.background with black.
  expect_identical(theme_hv_ppt_dark()$panel.background$fill, "black")
  pal <- hv_ppt_palette("dark")
  ratios <- vapply(pal, wcag_contrast, numeric(1), bg = "#000000")
  expect_true(all(ratios >= 3), info = paste(pal[ratios < 3], collapse = ", "))
})

test_that("hv_ppt_palette n takes a prefix, in order", {
  expect_identical(hv_ppt_palette("dark", n = 4),
                   hv_ppt_palette("dark")[1:4])
  expect_length(hv_ppt_palette("light", n = 1), 1L)
})

test_that("hv_ppt_palette rejects more colors than it holds", {
  expect_error(hv_ppt_palette("dark", n = 7), "at most 6")
  expect_error(hv_ppt_palette("dark", n = 0), "positive")
  expect_error(hv_ppt_palette("sepia"), "should be one of")
})

# ============================================================================
# hv_ppt_series: shape of the returned object
# ============================================================================

test_that("hv_ppt_series returns a theme and two scales", {
  dec <- hv_ppt_series()
  expect_type(dec, "list")
  expect_length(dec, 3L)
  expect_s3_class(dec[[1]], "theme")
  expect_s3_class(dec[[2]], "Scale")
  expect_s3_class(dec[[3]], "Scale")
  expect_identical(dec[[2]]$aesthetics, "colour")
  expect_identical(dec[[3]]$aesthetics, "shape")
})

test_that("hv_ppt_series defaults to the palette for its mode", {
  expect_identical(hv_ppt_series("dark")[[2]]$palette(6L),
                   hv_ppt_palette("dark"))
  expect_identical(hv_ppt_series("light")[[2]]$palette(6L),
                   hv_ppt_palette("light"))
})

test_that("hv_ppt_series wraps the theme matching its mode", {
  # theme_hv_ppt_dark() draws white axis text, theme_hv_ppt_light() black.
  expect_identical(hv_ppt_series("dark")[[1]]$axis.text$colour, "white")
  expect_identical(hv_ppt_series("light")[[1]]$axis.text$colour, "black")
})

test_that("hv_ppt_series validates colors and shapes", {
  expect_error(hv_ppt_series(colours = 1:3), "character vector")
  expect_error(hv_ppt_series(colours = c("red", NA)), "missing values")
  expect_error(hv_ppt_series(colours = character(0)), "character vector")
  expect_error(hv_ppt_series(shapes = "circle"), "numeric vector")
  expect_error(hv_ppt_series(shapes = c(16, NA)), "missing values")
})

# ============================================================================
# hv_ppt_series: composed onto a plot
# ============================================================================

test_that("a decorated trends plot still carries its data and its groups", {
  p <- plot(grouped_trends()) + hv_ppt_series()
  expect_plot_has_data(p, geoms = c("GeomSmooth", "GeomPoint"), min_groups = 4L)
})

test_that("the decorator applies its colors and shapes to the built layers", {
  p   <- plot(grouped_trends()) + hv_ppt_series("dark")
  bld <- ggplot_build(p)
  expect_setequal(unique(bld$data[[1]]$colour), hv_ppt_palette("dark", n = 4))
  expect_setequal(unique(bld$data[[2]]$shape), c(16L, 17L, 15L, 18L))
})

test_that("caller colors and shapes override the defaults", {
  p <- plot(grouped_trends()) +
    hv_ppt_series(colours = c("red", "blue", "green", "orange"),
                  shapes  = c(1, 2, 5, 6))
  bld <- ggplot_build(p)
  expect_setequal(unique(bld$data[[1]]$colour),
                  c("red", "blue", "green", "orange"))
  expect_setequal(unique(bld$data[[2]]$shape), c(1, 2, 5, 6))
})

test_that("the list route preserves the PPT font-fallback tagging", {
  # theme_hv_ppt_*() tags itself `hv_ppt_theme` so ggplot_add() can carry the
  # Arial request onto the plot. Adding via a list must not bypass that.
  p <- plot(grouped_trends()) + hv_ppt_series()
  expect_s3_class(p, "hv_ppt_plot")
  expect_identical(attr(p, "hv_font_requests"), c(text = "Arial"))
})

# ============================================================================
# hv_ppt_series: the legend stays off
# ============================================================================

test_that("hv_ppt_series leaves the house-style legend off", {
  # CORR figures name the series by annotation, so the decorator must not
  # quietly reinstate the legend that every theme_hv_*() suppresses.
  dec <- hv_ppt_series()
  expect_identical(dec[[1]]$legend.position, "none")

  p <- plot(grouped_trends()) + dec
  grob <- grob_quietly(p)
  boxes <- grob$grobs[grepl("guide-box", grob$layout$name)]
  drawn <- sum(!vapply(boxes, inherits, logical(1), "zeroGrob"))
  expect_identical(drawn, 0L)
})

test_that("a caller can ask for a legend back through ...", {
  p <- plot(grouped_trends()) +
    hv_ppt_series(legend.position = "top", name = "Repair type")
  grob  <- grob_quietly(p)
  boxes <- grob$grobs[grepl("guide-box", grob$layout$name)]
  drawn <- sum(!vapply(boxes, inherits, logical(1), "zeroGrob"))
  # Color and shape share `name`, so they merge into a single legend.
  expect_identical(drawn, 1L)
})

test_that("... forwards other theme arguments to the wrapped theme", {
  dec <- hv_ppt_series(base_size = 24)
  expect_identical(dec[[1]]$axis.text$size, 24)
})

# ============================================================================
# hv_ppt_series: ungrouped plots
# ============================================================================

test_that("an ungrouped plot keeps its data when the scales go unused", {
  dta <- sample_trends_data(n = 200, groups = NULL, seed = 1)
  p   <- plot(hv_trends(dta, x_col = "year", y_col = "value",
                        group_col = NULL)) + hv_ppt_series()
  expect_plot_has_data(p, geoms = c("GeomSmooth", "GeomPoint"))
})
