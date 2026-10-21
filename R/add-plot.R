# add-plot.R
#
# Fit-to-slide placement. hv_ph_location() anchors a plot's panel to a fixed
# slide rectangle; the chrome around it (axis text and titles, facet strips,
# plot titles) then floats outside the rectangle and can run off the slide or
# into the slide title. hv_fit_location() keeps the panel where it is and
# shrinks the theme's text in steps until the chrome fits. hv_add_plot()
# places the result on the current slide of an officer deck, as an editable
# vector or, when the vector insert fails, as a PNG at the same location.
# ---------------------------------------------------------------------------

# Multiply every absolute text size and text margin in a plot's theme by `f`.
# Sizes given as rel() follow their parent and are left alone, so nothing is
# scaled twice; margins in font-relative units ("lines", "char") already
# follow the size. A patchwork scales each of its plots and its annotation
# theme as well. Tick length is left alone: the PPT themes draw ticks inward,
# so they add no chrome outside the panel.
.hv_scale_text <- function(plot, f) {
  if (isTRUE(all.equal(f, 1))) return(plot)

  if (inherits(plot, "patchwork")) {
    plot$patches$plots <- lapply(plot$patches$plots, .hv_scale_text, f = f)
    # patchwork draws the annotation with theme_get() + its own theme unless
    # that theme is complete, which is what complete_theme() resolves, so
    # inherited title, subtitle and caption sizes scale too.
    annotation_theme <- plot$patches$annotation$theme
    if (!inherits(annotation_theme, "theme")) annotation_theme <- ggplot2::theme()
    plot$patches$annotation$theme <- annotation_theme +
      .hv_scaled_text_theme(annotation_theme, f, complete = TRUE)
  }
  if (!inherits(plot, "ggplot")) return(plot)

  plot + .hv_scaled_text_theme(plot$theme, f, complete = TRUE)
}

.hv_absolute_units <- c("points", "bigpts", "picas", "inches", "cm", "mm",
                        "dida", "cicero", "scaledpts")

# A theme() carrying `f` times every absolute element_text size and margin in
# `theme`. `complete = TRUE` resolves the theme against the default first, so
# a plot that never set a size still has one to scale. A margin is scaled
# only when all four sides are absolute; an NA side, from margin_part(),
# stays NA.
.hv_scaled_text_theme <- function(theme, f, complete) {
  if (complete) theme <- ggplot2::complete_theme(theme)
  scaled <- list()
  for (name in names(theme)) {
    el <- theme[[name]]
    if (!inherits(el, "element_text")) next
    args <- list()
    size <- el$size
    if (is.numeric(size) && length(size) == 1L && !inherits(size, "rel")) {
      args$size <- size * f
    }
    margin <- el$margin
    if (grid::is.unit(margin) && all(grid::unitType(margin) %in% .hv_absolute_units)) {
      args$margin <- margin * f
    }
    if (length(args) > 0L) scaled[[name]] <- do.call(ggplot2::element_text, args)
  }
  do.call(ggplot2::theme, scaled)
}

#' Fit a plot's chrome on the slide around a fixed panel
#'
#' Anchors the plot's panel to `panel_box` with [hv_ph_location()] and checks
#' that the whole figure, panel plus the axis text, axis titles, facet strips
#' and plot titles around it, lies on the slide and below the slide title. If
#' it does not, every text size in the plot's theme is reduced by `step`
#' (as a fraction of the original size), together with every text margin
#' set in absolute units, until it fits or reaches `min_scale`. The panel
#' never moves; only the chrome shrinks.
#'
#' At the PPT themes' 32 pt base size the defaults step the text down 2 pt
#' at a time, to 30, 28, 26 and so on, down to 12 pt.
#'
#' The figure checked is the placement box plus the actual extent of the
#' title, subtitle and caption text, placed by its `hjust` (and
#' `plot.title.position`): a title wider than the slide fails the check even
#' though its cell fits.
#'
#' Only sizes and margins set in the theme are scaled. The size of text drawn by a geom
#' (`geom_text()`, `geom_label()`) is an aesthetic, not part of the theme,
#' and is left alone. For a patchwork, `panel_box` holds the union of its
#' panels and the whole composition is measured; see [hv_ph_location()].
#'
#' @param plot A ggplot or patchwork object.
#' @param panel_box Named list `list(width, height, left, top)`, in inches:
#'   the slide rectangle for the plot's panel. See [hv_panel_box()].
#' @param slide_width,slide_height Slide size, in inches. The defaults are
#'   the 16:9 HVTI templates.
#' @param title_bottom The lowest point of the slide title, in inches. The
#'   figure must start below it. The HVTI title placeholder ends at 1.33 in;
#'   the default leaves 0.05 in under it.
#' @param edge Margin kept clear on the left, right and bottom slide edges,
#'   in inches.
#' @param min_scale Smallest text scale tried, as a fraction of the plot's
#'   own sizes. The default, `12/32`, is 12 pt text at the 32 pt PPT base
#'   size.
#' @param step Amount the scale drops at each try. The default, `2/32`, is
#'   2 pt at the 32 pt PPT base size.
#' @param align `"panel"` (the default) keeps the panel on `panel_box`, so
#'   every slide puts its panel in the same place. `"fill"` keeps the
#'   panel's height and top but sets its left edge and width from the chrome
#'   measured around it, so the whole figure spans the slide with `margin`
#'   clear on each side and sits centered. A plot with short y labels then
#'   gets a wider panel instead of a gap on the left; one with long labels
#'   keeps about the standard width. Panels no longer line up across slides.
#' @param margin Space kept clear on the left and right of the figure, in
#'   inches, with `align = "fill"`. The default, `0.45`, matches the right
#'   margin of the standard panel box.
#'
#' @return A list with elements
#'   * `plot`: the plot, its text sizes and margins scaled by `scale`;
#'   * `location`: the [hv_ph_location()] result for `panel_box`, a list
#'     `width`, `height`, `left`, `top` in inches, ready for
#'     [officer::ph_location()];
#'   * `scale`: the text scale used, `1` when the plot fit as it was;
#'   * `fits`: `TRUE` when the figure lies inside the slide limits. When it
#'     is `FALSE`, `plot` and `location` are those at `min_scale`.
#'   * `panel_box`: the panel rectangle used, `panel_box` itself unless
#'     `align = "fill"` moved it.
#'
#' @seealso [hv_add_plot()], which places the result on a slide;
#'   [hv_panel_box()], [hv_ph_location()].
#'
#' @examples
#' \donttest{
#' p <- ggplot2::ggplot(mtcars, ggplot2::aes(hp, mpg)) +
#'   ggplot2::geom_point() +
#'   ggplot2::labs(x = "Horsepower", y = "Miles per gallon") +
#'   theme_hv_ppt_dark()
#' fit <- hv_fit_location(p, hv_panel_box("dark"))
#' fit$scale
#' fit$location
#' }
#' @export
hv_fit_location <- function(plot,
                            panel_box,
                            slide_width  = 13.333,
                            slide_height = 7.5,
                            title_bottom = 1.38,
                            edge         = 0.05,
                            min_scale    = 12 / 32,
                            step         = 2 / 32,
                            align        = c("panel", "fill"),
                            margin       = 0.45) {
  align <- match.arg(align)
  if (!inherits(plot, "ggplot"))
    stop("`plot` must be a ggplot object.", call. = FALSE)
  .check_panel_box(panel_box)
  .check_scalar_positive(slide_width,  "slide_width")
  .check_scalar_positive(slide_height, "slide_height")
  .check_scalar_nonneg(title_bottom,   "title_bottom")
  .check_scalar_nonneg(edge,           "edge")
  .check_scalar_positive(min_scale,    "min_scale")
  .check_scalar_positive(step,         "step")
  .check_scalar_nonneg(margin,         "margin")
  if (min_scale > 1)
    stop("`min_scale` must be at most 1.", call. = FALSE)

  # The figure is the location box widened by any title, subtitle or caption
  # text wider than its cell.
  inside <- function(m) {
    tol <- 1e-6
    loc <- m$location
    m$text_left >= edge - tol &&
      m$text_right <= slide_width - edge + tol &&
      loc$top >= title_bottom - tol &&
      loc$top + loc$height <= slide_height - edge + tol
  }

  scales <- unique(c(seq(1, min_scale, by = -step), min_scale))
  scales <- scales[scales >= min_scale - 1e-9]
  measure <- function(p, box) {
    .hv_measure_placement(
      p,
      panel_width  = box$width,
      panel_height = box$height,
      panel_left   = box$left,
      panel_top    = box$top,
      units        = "in"
    )
  }

  for (f in scales) {
    scaled <- .hv_scale_text(plot, f)
    box <- panel_box
    measured <- measure(scaled, box)
    if (align == "fill") {
      box <- .hv_fill_box(measured, panel_box, slide_width, margin)
      if (!is.null(box)) measured <- measure(scaled, box) else box <- panel_box
    }
    loc <- measured$location
    fits <- inside(measured)
    if (fits) break
  }

  list(plot = scaled, location = loc, scale = f, fits = fits, panel_box = box)
}

# The panel rectangle that makes a measured figure span the slide with
# `margin` clear on each side, so it sits centered: the panel's height and
# top are kept, and its left edge and width make room for the chrome
# measured on each side (axis text and titles, legends, title overhang).
# NULL when the chrome leaves no room for a panel.
.hv_fill_box <- function(measured, panel_box, slide_width, margin) {
  left_chrome  <- panel_box$left - measured$text_left
  right_chrome <- measured$text_right - (panel_box$left + panel_box$width)
  width <- slide_width - 2 * margin - left_chrome - right_chrome
  if (width <= 0) return(NULL)
  list(width  = width,
       height = panel_box$height,
       left   = margin + left_chrome,
       top    = panel_box$top)
}

# The slide format of an rpptx, from its slide size.
.hv_doc_format <- function(doc) {
  if (!inherits(doc, "rpptx"))
    stop("`doc` must be an rpptx object from officer::read_pptx().", call. = FALSE)
  size <- officer::slide_size(doc)
  .hv_slide_format(size$width, size$height)
}

.check_panel_box <- function(panel_box) {
  expected <- c("width", "height", "left", "top")
  if (!is.list(panel_box) || !all(expected %in% names(panel_box)))
    stop("`panel_box` must be a list with elements `width`, `height`, `left`, `top`.",
         call. = FALSE)
  invisible(panel_box)
}

# The vector and PNG inserts are separate functions so a test can force the
# vector path to fail and exercise the fallback.
.hv_ph_with_dml <- function(doc, plot, location) {
  # bg = "transparent" in both places: rvg's canvas and officer's shape fill
  # are each an opaque white box otherwise. See add_plot_slide().
  suppress_officer_bg_warnings(
    officer::ph_with(
      doc,
      value    = rvg::dml(ggobj = plot, bg = "transparent"),
      location = do.call(officer::ph_location,
                         c(location, list(bg = "transparent")))
    )
  )
}

.hv_ph_with_png <- function(doc, plot, location, dpi) {
  png_file <- tempfile(fileext = ".png")
  on.exit(unlink(png_file), add = TRUE)
  ragg::agg_png(png_file, width = location$width, height = location$height,
                units = "in", res = dpi, background = "transparent")
  tryCatch(print(plot), finally = grDevices::dev.off())
  suppress_officer_bg_warnings(
    officer::ph_with(
      doc,
      value    = officer::external_img(png_file, width = location$width,
                                       height = location$height),
      location = do.call(officer::ph_location,
                         c(location, list(bg = "transparent")))
    )
  )
}

#' Place one plot on the current slide, fitted around the standard panel
#'
#' Adds `plot` to the current slide of an officer presentation with its
#' panel anchored to `panel_box`, so every plot slide of a slide format puts
#' its panel in the same place. With `fit = TRUE` the plot's text sizes and
#' text margins are reduced together by [hv_fit_location()] until axis text,
#' axis titles, facet strips and plot titles lie on the slide and below its
#' title.
#'
#' The plot goes in as an editable DrawingML vector graphic via
#' [rvg::dml()]. A dense point cloud can overflow libxml2 and make that
#' insert fail; with `png_fallback = TRUE` the plot is then rendered to a
#' transparent PNG at exactly the fitted location's size and placed at the
#' same location, so the panel still lands on `panel_box`.
#'
#' Add the slide and its title first, with [officer::add_slide()] and
#' [officer::ph_with()]; [save_ppt()] does all of this for a list of plots.
#'
#' @param doc An `rpptx` object from [officer::read_pptx()] whose current
#'   slide receives the plot.
#' @param plot A ggplot or patchwork object.
#' @param panel_box Named list `list(width, height, left, top)`, in inches.
#'   Defaults to [hv_panel_box()] for the slide format of `doc`, read from
#'   its slide size: 16:9 (every bundled template) or 4:3. A deck of any
#'   other size needs an explicit `panel_box`.
#' @param fit `TRUE` (the default) to reduce the plot's text until the
#'   figure fits on the slide. `FALSE` places the plot at its own sizes and
#'   warns if it runs off the slide or into the title.
#' @param png_fallback `TRUE` (the default) to place a PNG when the vector
#'   insert fails. `FALSE` lets the error through.
#' @param dpi Resolution of the fallback PNG. Default `300`.
#' @param ... Further arguments to [hv_fit_location()]: `title_bottom`,
#'   `edge`, `min_scale`, `step`, `align`, `margin`. The slide size is read
#'   from `doc`. `align = "fill"` widens the panel so the figure spans the
#'   slide, centered, instead of anchoring it to `panel_box`.
#'
#' @return `doc`, with the plot added, carrying an attribute `"hv_fit"`: a
#'   list `scale` (the text scale used), `fits` (whether the figure lies
#'   inside the slide limits), `png` (whether the PNG fallback was used),
#'   `location` (the placement, in inches) and `panel_box` (the panel
#'   rectangle used). A message reports reduced text;
#'   a warning reports a figure that still does not fit.
#'
#' @seealso [save_ppt()], [hv_fit_location()], [hv_panel_box()].
#'
#' @examples
#' \donttest{
#' p <- ggplot2::ggplot(mtcars, ggplot2::aes(hp, mpg)) +
#'   ggplot2::geom_point() +
#'   ggplot2::labs(x = "Horsepower", y = "Miles per gallon") +
#'   theme_hv_ppt_dark()
#'
#' template <- system.file("extdata", "hv_ppt_template.pptx",
#'                         package = "hvtiPlotR")
#' doc <- officer::read_pptx(template)
#' doc <- officer::add_slide(doc, layout = hv_ppt_layout("figure"))
#' doc <- officer::ph_with(doc, "Fuel economy",
#'                         location = officer::ph_location_type("title"))
#' doc <- hv_add_plot(doc, p)
#' attr(doc, "hv_fit")$scale
#' print(doc, target = file.path(tempdir(), "fitted.pptx"))
#' }
#' @export
hv_add_plot <- function(doc,
                        plot,
                        panel_box    = hv_panel_box(format = .hv_doc_format(doc)),
                        fit          = TRUE,
                        png_fallback = TRUE,
                        dpi          = 300,
                        ...) {
  ensure_officer_available()
  ensure_rvg_available()
  if (!inherits(doc, "rpptx"))
    stop("`doc` must be an rpptx object from officer::read_pptx().", call. = FALSE)
  if (!inherits(plot, "ggplot"))
    stop("`plot` must be a ggplot object.", call. = FALSE)
  .check_panel_box(panel_box)
  if (!(isTRUE(fit) || isFALSE(fit)))
    stop("`fit` must be TRUE or FALSE.", call. = FALSE)
  if (!(isTRUE(png_fallback) || isFALSE(png_fallback)))
    stop("`png_fallback` must be TRUE or FALSE.", call. = FALSE)
  .check_scalar_positive(dpi, "dpi")

  size <- officer::slide_size(doc)
  fit_args <- list(plot = plot, panel_box = panel_box,
                   slide_width = size$width, slide_height = size$height, ...)
  if (!fit) fit_args$min_scale <- 1
  fitted <- suppress_font_db_warnings(do.call(hv_fit_location, fit_args))

  if (!fitted$fits) {
    warning(sprintf(
      paste0("hv_add_plot(): the figure runs off the slide or into the title%s. ",
             "Shorten its labels or move `panel_box`."),
      if (fit) sprintf(" even with text at %.0f%%", 100 * fitted$scale) else ""
    ), call. = FALSE)
  } else if (fitted$scale < 1) {
    message(sprintf(
      "hv_add_plot(): text reduced to %.0f%% so the figure fits on the slide.",
      100 * fitted$scale
    ))
  }

  placed <- tryCatch(
    list(doc = .hv_ph_with_dml(doc, fitted$plot, fitted$location), png = FALSE),
    error = function(e) {
      if (!png_fallback)
        stop(sprintf("Failed to add plot to slide: %s", conditionMessage(e)),
             call. = FALSE)
      list(doc = .hv_ph_with_png(doc, fitted$plot, fitted$location, dpi),
           png = TRUE)
    }
  )
  doc <- placed$doc

  attr(doc, "hv_fit") <- list(scale    = fitted$scale,
                              fits     = fitted$fits,
                              png      = placed$png,
                              location  = fitted$location,
                              panel_box = fitted$panel_box)
  doc
}
