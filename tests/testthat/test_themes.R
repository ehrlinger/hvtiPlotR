# Tests for theme_hv_* functions and the deprecated aliases.
library(testthat)
library(ggplot2)

create_test_plot <- function() {
  ggplot(data.frame(x = 1:10, y = 1:10), aes(.data$x, .data$y)) +
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

test_that("theme_hv_poster hides the legend by default", {
  expect_identical(theme_hv_poster()$legend.position, "none")
})

# House style names a series by annotation rather than by a key, on every
# output target. The docs stated this as a property of all four themes while
# only three carried it -- theme_hv_poster() silently inherited theme_grey()'s
# "right" until 2.7.8.
#
# The theme list is DISCOVERED rather than written out. A hard-coded list reads
# as a set-wide contract while only ever checking the themes that existed when
# it was written, so a fifth theme_hv_*() would have to opt in by being named
# here -- the same gap that let the poster theme drift in the first place.
# The deprecated aliases are hv_theme_*() and theme_*() and do not match this
# prefix, so only the canonical constructors are checked.
test_that("every exported theme_hv_*() hides the legend by default", {
  theme_fns <- sort(grep("^theme_hv_",
                         getNamespaceExports("hvtiPlotR"),
                         value = TRUE))

  # Guard the discovery itself: if the prefix ever stops matching, the
  # comparison below would pass vacuously against an empty set.
  expect_gte(length(theme_fns), 4L)

  positions <- vapply(theme_fns, function(nm) {
    calc_element("legend.position", getExportedValue("hvtiPlotR", nm)())
  }, character(1))

  # Naming the offenders rather than comparing whole vectors, so a failure
  # says which theme drifted instead of printing two parallel lists.
  expect_identical(names(positions)[positions != "none"], character(0))
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

test_that("PPT themes match the canonical Arial deck (32 bold ticks, 40 bold titles)", {
  # Canonical reference: sl.rd26.stephens.1316.driveline_infections deck,
  # slide 6 -- axis tick labels render Arial 32 Bold, axis titles Arial 40 Bold.
  for (th in list(theme_hv_ppt_dark(), theme_hv_ppt_light())) {
    # base_family flows to all text (incl. axis text/titles) via theme_grey().
    expect_identical(th$text$family, "Arial")
    # axis tick labels: Arial 32 Bold.
    expect_equal(th$axis.text$size, 32)
    expect_identical(th$axis.text$face, "bold")
    # axis titles (the x/y labels themselves): Arial 40 Bold.
    expect_equal(th$axis.title$size, 40)
    expect_identical(th$axis.title$face, "bold")
  }
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
# Arial font fallback (theme_hv_ppt_dark / theme_hv_ppt_light)
# ============================================================================

test_that("theme_hv_ppt_dark plot renders without erroring on a font-less pdf device", {
  p <- create_test_plot() + theme_hv_ppt_dark()
  f <- tempfile(fileext = ".pdf")
  grDevices::pdf(f)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_error(suppressMessages(print(p)), NA)
})

test_that("theme_hv_ppt_light plot renders without erroring on a font-less postscript device", {
  p <- create_test_plot() + theme_hv_ppt_light()
  f <- tempfile(fileext = ".ps")
  grDevices::postscript(f)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_error(suppressMessages(print(p)), NA)
})

test_that("Arial falls back to Helvetica when the active device can't resolve it", {
  p <- create_test_plot() + theme_hv_ppt_dark()
  f <- tempfile(fileext = ".pdf")
  grDevices::pdf(f)
  on.exit(grDevices::dev.off(), add = TRUE)
  resolved <- suppressMessages(.hv_resolve_ppt_family(p))
  expect_identical(resolved$theme$text$family, "Helvetica")
})

test_that("the fallback reaches text geoms, not just theme elements", {
  # ggplot2 >= 4.0 resolves a text geom's family through the theme's `geom`
  # element, which theme_grey() seeds from base_family alongside `text`.
  # Patching `text` alone left annotate("text", ...) asking for Arial, which
  # errors outright on pdf()/postscript(). House style labels series by
  # annotation, so this is the common case, not an edge one.
  skip_if_not("element_geom" %in% getNamespaceExports("ggplot2"))
  p <- create_test_plot() + theme_hv_ppt_dark() +
    annotate("text", x = 5, y = 5, label = "Group I")
  f <- tempfile(fileext = ".pdf")
  grDevices::pdf(f)
  on.exit(grDevices::dev.off(), add = TRUE)

  resolved <- suppressMessages(.hv_resolve_ppt_family(p))
  built    <- ggplot_build(resolved)
  expect_identical(unique(built$data[[2]]$family), "Helvetica")
  expect_error(suppressMessages(suppressWarnings(print(p))), NA)
})

test_that("an explicitly resolvable family is preserved (no fallback) at draw time", {
  p <- create_test_plot() + theme_hv_ppt_dark()
  f <- tempfile(fileext = ".pdf")
  grDevices::pdf(f)
  on.exit(grDevices::dev.off(), add = TRUE)
  # Simulate a device (e.g. quartz) that genuinely resolves "Arial" -- the
  # explicit/default base_family must be honoured, not silently swapped.
  testthat::local_mocked_bindings(.hv_family_resolves = function(family) TRUE)
  resolved <- .hv_resolve_ppt_family(p)
  expect_identical(resolved$theme$text$family, "Arial")
  expect_identical(resolved, p) # no fallback theme layer added at all
})

test_that("theme_hv_manuscript / theme_hv_poster are untagged and unaffected", {
  p <- create_test_plot() + theme_hv_manuscript()
  expect_null(attr(p, "hv_font_requests"))
  expect_false(inherits(p, "hv_ppt_plot"))
})

test_that("a non-Arial base_family is left untagged", {
  th <- theme_hv_ppt_dark(base_family = "mono")
  expect_null(attr(th, "hv_font_requests"))
  expect_false(inherits(th, "hv_ppt_theme"))
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

# ============================================================================
# `paper` argument controls plot.background fill (regression: was hard-coded
# "transparent", ignoring the argument)
# ============================================================================

test_that("paper sets plot.background fill in ppt and poster themes", {
  expect_identical(theme_hv_ppt_dark(paper  = "grey15")$plot.background$fill, "grey15")
  expect_identical(theme_hv_ppt_light(paper = "ivory")$plot.background$fill,  "ivory")
  expect_identical(theme_hv_poster(paper    = "navy")$plot.background$fill,   "navy")
})

test_that("ppt themes still default plot.background to transparent", {
  expect_identical(theme_hv_ppt_dark()$plot.background$fill,  "transparent")
  expect_identical(theme_hv_ppt_light()$plot.background$fill, "transparent")
})
