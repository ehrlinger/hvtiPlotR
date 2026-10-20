# Tests for the fit-to-slide placement: .hv_scale_text(), hv_fit_location(),
# hv_add_plot() and the save_ppt() route through it.

library(testthat)
library(ggplot2)

fit_plot <- function() {
  ggplot(mtcars, aes(.data$hp, .data$mpg)) + geom_point() + labs(x = "Horsepower", y = "MPG")
}

# y labels that fit at small sizes but not at 32 pt within 2.9 in.
long_label_plot <- function() {
  d <- data.frame(
    x = 1:3,
    y = factor(c("Mitral valve repair", "Aortic valve replace", "CABG only"))
  )
  ggplot(d, aes(.data$x, .data$y)) + geom_point() + theme_gray(base_size = 32)
}

fitted_doc <- function(template = system.file("extdata", "hv_ppt_template.pptx",
                                              package = "hvtiPlotR")) {
  doc <- officer::read_pptx(template)
  doc <- officer::add_slide(doc, layout = hv_ppt_layout("figure"))
  officer::ph_with(doc, "Title", location = officer::ph_location_type("title"))
}

# Top-level vector groups ("grpSp", from rvg) and pictures ("pic") on slide
# `i` of a written deck, with their placement in inches.
slide_graphics <- function(path, i) {
  x <- xml2::read_xml(unz(path, sprintf("ppt/slides/slide%d.xml", i)))
  nodes <- xml2::xml_find_all(x, "//p:spTree/p:grpSp | //p:spTree/p:pic")
  inches <- function(node, child, attr) {
    xfrm <- xml2::xml_find_first(node, "./p:grpSpPr/a:xfrm | ./p:spPr/a:xfrm")
    as.numeric(xml2::xml_attr(xml2::xml_find_first(xfrm, child), attr)) / 914400
  }
  data.frame(
    kind   = xml2::xml_name(nodes),
    left   = vapply(nodes, inches, numeric(1), child = "a:off", attr = "x"),
    top    = vapply(nodes, inches, numeric(1), child = "a:off", attr = "y"),
    width  = vapply(nodes, inches, numeric(1), child = "a:ext", attr = "cx"),
    height = vapply(nodes, inches, numeric(1), child = "a:ext", attr = "cy")
  )
}

test_that("hv_panel_box depends on the slide format, not the color template", {
  wide <- list(width = 9.98, height = 4.15, left = 2.9, top = 1.85)
  standard <- list(width = 7.25, height = 4.15, left = 2.3, top = 1.85)
  for (mode in c("dark", "light", "slate")) {
    expect_identical(hv_panel_box(mode), wide)
    expect_identical(hv_panel_box(mode, format = "wide"), wide)
    expect_identical(hv_panel_box(mode, format = "standard"), standard)
  }
  expect_false(identical(hv_panel_box(format = "wide"), hv_panel_box(format = "standard")))
  # The standard box fits a 10 in slide with 0.45 in on the right.
  expect_equal(10 - standard$left - standard$width, 0.45)
  expect_error(hv_panel_box(format = "square"))
})

test_that(".hv_template_format reads the slide format from the template", {
  skip_if_not_installed("officer")
  for (file in c("hv_ppt_template.pptx", "hv_ppt_template_light.pptx",
                 "hv_ppt_template_slate.pptx")) {
    template <- system.file("extdata", file, package = "hvtiPlotR")
    expect_identical(.hv_template_format(template), "wide")
  }
  four_three <- withr::local_tempfile(fileext = ".pptx")
  print(officer::read_pptx(), target = four_three) # officer's default deck is 4:3
  expect_identical(.hv_template_format(four_three), "standard")
  expect_identical(.hv_doc_format(officer::read_pptx(four_three)), "standard")
  expect_error(.hv_slide_format(16, 9), "panel_box")
})

test_that(".hv_scale_text scales absolute sizes and leaves rel() alone", {
  p <- fit_plot() + theme_hv_ppt_dark()
  half <- .hv_scale_text(p, 0.5)
  th <- ggplot2::complete_theme(half$theme)
  expect_equal(th$text$size, 16)
  expect_equal(th$axis.text$size, 16)
  expect_equal(th$axis.title$size, 20)
  expect_equal(th$strip.text$size, 12)
  # rel() follows its parent, so it is not scaled a second time.
  expect_true(inherits(th$plot.title$size, "rel"))
  expect_equal(as.numeric(th$plot.title$size), 1.2)
  expect_identical(.hv_scale_text(p, 1), p)
})

test_that(".hv_scale_text scales a plot with no theme of its own", {
  half <- .hv_scale_text(fit_plot(), 0.5)
  expect_equal(ggplot2::complete_theme(half$theme)$text$size, 5.5)
})

test_that(".hv_scale_text scales every plot of a patchwork", {
  skip_if_not_installed("patchwork")
  p <- fit_plot() + theme_hv_ppt_dark()
  pw <- patchwork::wrap_plots(p, p)
  half <- .hv_scale_text(pw, 0.5)
  expect_equal(half$patches$plots[[1]]$theme$axis.text$size, 16)
  expect_equal(half$theme$axis.text$size, 16)
})

test_that("hv_fit_location keeps scale 1 for a plot that fits", {
  box <- hv_panel_box()
  fit <- hv_fit_location(fit_plot(), box)
  expect_identical(fit$scale, 1)
  expect_true(fit$fits)
  expect_named(fit, c("plot", "location", "scale", "fits"))
})

test_that("a PPT-themed plot fits the wide window at full size", {
  # 32 pt x text plus the 40 pt x title and its margin need about 1.43 in
  # below the panel; the wide window leaves 1.45 in inside the slide edge.
  p <- fit_plot() + theme_hv_ppt_dark()
  # The pdf(NULL) measuring device lacks Arial; filter that benign warning
  # as hv_add_plot() does.
  fit <- suppress_font_db_warnings(hv_fit_location(p, hv_panel_box(format = "wide")))
  expect_identical(fit$scale, 1)
  expect_true(fit$fits)
})

test_that("hv_fit_location shrinks long y labels until they fit; the panel stays", {
  box <- hv_panel_box()
  p <- long_label_plot()
  full <- suppressWarnings(hv_ph_location(p, box$width, box$height, box$left, box$top))
  expect_lt(full$left, 0.05) # overflows the left edge at full size

  fit <- hv_fit_location(p, box)
  expect_lt(fit$scale, 1)
  expect_gte(fit$scale, 12 / 32)
  expect_true(fit$fits)
  expect_gte(fit$location$left, 0.05)

  # The panel lands on the same rectangle at either scale.
  panel_of <- function(plot, loc) {
    g <- ggplot2::ggplotGrob(plot)
    grDevices::pdf(NULL)
    on.exit(grDevices::dev.off())
    lo <- min(g$layout$l[g$layout$name == "panel"])
    left_chrome <- sum(grid::convertWidth(g$widths[seq_len(lo - 1L)], "in", valueOnly = TRUE))
    loc$left + left_chrome
  }
  expect_equal(panel_of(fit$plot, fit$location), box$left, tolerance = 1e-6)
  expect_equal(panel_of(p, full), box$left, tolerance = 1e-6)
  expect_equal(fit$location$top, full$top)
})

test_that("hv_fit_location reports a plot that does not fit even at min_scale", {
  d <- data.frame(x = 1, y = strrep("a very long label ", 6))
  p <- ggplot(d, aes(.data$x, .data$y)) + geom_point() + theme_gray(base_size = 32)
  fit <- hv_fit_location(p, hv_panel_box())
  expect_false(fit$fits)
  expect_equal(fit$scale, 12 / 32)
})

test_that("hv_fit_location validates its arguments", {
  expect_error(hv_fit_location("x", hv_panel_box()), "must be a ggplot")
  expect_error(hv_fit_location(fit_plot(), list(width = 1)), "panel_box")
  expect_error(hv_fit_location(fit_plot(), hv_panel_box(), min_scale = 2), "at most 1")
})

test_that("hv_add_plot places an editable vector on the panel box", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")
  out <- withr::local_tempfile(fileext = ".pptx")

  doc <- hv_add_plot(fitted_doc(), fit_plot())
  info <- attr(doc, "hv_fit")
  expect_false(info$png)
  expect_identical(info$scale, 1)
  print(doc, target = out)

  shapes <- slide_graphics(out, 1)
  expect_identical(shapes$kind, "grpSp")
  expect_equal(shapes$left, info$location$left, tolerance = 1e-3)
  expect_equal(shapes$top, info$location$top, tolerance = 1e-3)
  expect_equal(shapes$width, info$location$width, tolerance = 1e-3)
})

test_that("hv_add_plot falls back to a PNG at the same location", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")
  skip_if_not_installed("ragg")
  local_mocked_bindings(.hv_ph_with_dml = function(...) stop("xmlSAX2Characters: huge text node"))
  out <- withr::local_tempfile(fileext = ".pptx")

  doc <- hv_add_plot(fitted_doc(), fit_plot())
  info <- attr(doc, "hv_fit")
  expect_true(info$png)
  print(doc, target = out)

  shapes <- slide_graphics(out, 1)
  expect_identical(shapes$kind, "pic")
  expect_equal(shapes$left, info$location$left, tolerance = 1e-3)
  expect_equal(shapes$top, info$location$top, tolerance = 1e-3)
  expect_equal(shapes$height, info$location$height, tolerance = 1e-3)
})

test_that("hv_add_plot lets the vector error through without png_fallback", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")
  local_mocked_bindings(.hv_ph_with_dml = function(...) stop("boom"))
  expect_error(hv_add_plot(fitted_doc(), fit_plot(), png_fallback = FALSE), "boom")
})

test_that("hv_add_plot reports reduced text and a figure that does not fit", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")
  expect_message(hv_add_plot(fitted_doc(), long_label_plot()), "text reduced")
  expect_warning(hv_add_plot(fitted_doc(), long_label_plot(), fit = FALSE),
                 "runs off the slide")
})

test_that("save_ppt writes fitted slides for all three bundled templates", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")
  themes <- list(dark = theme_hv_ppt_dark(), light = theme_hv_ppt_light(),
                 slate = theme_hv_ppt_slate())
  files <- c(dark = "hv_ppt_template.pptx", light = "hv_ppt_template_light.pptx",
             slate = "hv_ppt_template_slate.pptx")
  for (mode in names(files)) {
    template <- system.file("extdata", files[[mode]], package = "hvtiPlotR")
    out <- withr::local_tempfile(fileext = ".pptx")
    p <- fit_plot() + themes[[mode]]
    suppressMessages(save_ppt(list(p, p), template = template, powerpoint = out,
                              slide_titles = c("One", "Two")))
    expect_equal(length(officer::read_pptx(out)), 2L)
    for (i in 1:2) {
      shapes <- slide_graphics(out, i)
      expect_identical(shapes$kind, "grpSp")
      # The figure sits below the title and inside the slide.
      expect_gte(shapes$top, 1.38 - 1e-3)
      expect_gte(shapes$left, 0.05 - 1e-3)
      expect_lte(shapes$top + shapes$height, 7.5 - 0.05 + 1e-3)
      expect_lte(shapes$left + shapes$width, 13.333 - 0.05 + 1e-3)
    }
  }
})
