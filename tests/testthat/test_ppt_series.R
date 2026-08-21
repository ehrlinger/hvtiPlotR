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

test_that("hv_ppt_palette returns six hex colours per mode", {
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

test_that("hv_ppt_palette n takes a prefix, in order", {
  expect_identical(hv_ppt_palette("dark", n = 4),
                   hv_ppt_palette("dark")[1:4])
  expect_length(hv_ppt_palette("light", n = 1), 1L)
})

test_that("hv_ppt_palette rejects more colours than it holds", {
  expect_error(hv_ppt_palette("dark", n = 7), "at most 6")
  expect_error(hv_ppt_palette("dark", n = 0), "positive")
  expect_error(hv_ppt_palette("sepia"), "should be one of")
})

# ============================================================================
# hv_ppt_series — shape of the returned object
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

test_that("hv_ppt_series validates colours and shapes", {
  expect_error(hv_ppt_series(colours = 1:3), "character vector")
  expect_error(hv_ppt_series(colours = c("red", NA)), "missing values")
  expect_error(hv_ppt_series(colours = character(0)), "character vector")
  expect_error(hv_ppt_series(shapes = "circle"), "numeric vector")
  expect_error(hv_ppt_series(shapes = c(16, NA)), "missing values")
})

# ============================================================================
# hv_ppt_series — composed onto a plot
# ============================================================================

test_that("a decorated trends plot still carries its data and its groups", {
  p <- plot(grouped_trends()) + hv_ppt_series()
  expect_plot_has_data(p, geoms = c("GeomSmooth", "GeomPoint"), min_groups = 4L)
})

test_that("the decorator applies its colours and shapes to the built layers", {
  p   <- plot(grouped_trends()) + hv_ppt_series("dark")
  bld <- ggplot_build(p)
  expect_setequal(unique(bld$data[[1]]$colour), hv_ppt_palette("dark", n = 4))
  expect_setequal(unique(bld$data[[2]]$shape), c(16L, 17L, 15L, 18L))
})

test_that("caller colours and shapes override the defaults", {
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
# hv_ppt_series — the legend stays off
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
  # Colour and shape share `name`, so they merge into a single legend.
  expect_identical(drawn, 1L)
})

test_that("... forwards other theme arguments to the wrapped theme", {
  dec <- hv_ppt_series(base_size = 24)
  expect_identical(dec[[1]]$axis.text$size, 24)
})

# ============================================================================
# hv_ppt_series — ungrouped plots
# ============================================================================

test_that("an ungrouped plot keeps its data when the scales go unused", {
  dta <- sample_trends_data(n = 200, groups = NULL, seed = 1)
  p   <- plot(hv_trends(dta, x_col = "year", y_col = "value",
                        group_col = NULL)) + hv_ppt_series()
  expect_plot_has_data(p, geoms = c("GeomSmooth", "GeomPoint"))
})
