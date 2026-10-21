# ph-location.R
#
# Compute officer::ph_location() arguments that anchor a ggplot's panel to a
# fixed slide rectangle across multiple slides.
# Motivation: axis label widths vary with y-axis range (e.g. "1.0" vs "100.0"),
# which shifts the panel within a fixed ph_location() and makes the plot
# background appear to move between slides. This helper measures asymmetric
# chrome (left / right / top / bottom of the panel) via ggplotGrob() and
# returns per-plot width, height, left, top so the panel lands at the same
# slide coordinates on every slide.
# ---------------------------------------------------------------------------

#' Compute `officer::ph_location()` args for a fixed-panel slide layout
#'
#' Given a fitted ggplot and a target panel rectangle (width/height/left/top
#' on the slide), returns the `width`, `height`, `left`, `top` values to pass
#' to [officer::ph_location()] such that the *panel content area* of the plot
#' lands at the specified slide coordinates, regardless of how much room the
#' axis labels, axis titles, legend, plot title, or plot margins consume.
#'
#' The panel content area is the rectangular bounding box of the gtable cells
#' tagged `panel`. Strip grobs that sit inside that bounding box are part of
#' the target; strips outside it (e.g. `facet_grid` side strips, the strip
#' row above a single-row `facet_wrap`) are treated as chrome.
#'
#' Use with [save_ppt()] via `panel_box = list(width, height, left, top)` to
#' apply this to every slide in a deck.
#'
#' For a patchwork, the whole composition is measured, through
#' [patchwork::patchworkGrob()]: the target rectangle holds the union of
#' every plot's panels, with the axes and strips between them, and the
#' outermost axes plus the [patchwork::plot_annotation()] title, subtitle and
#' caption count as chrome. A nested patchwork counts as one panel, inner
#' chrome included.
#'
#' @param plot         A ggplot (or patchwork) object.
#' @param panel_width  Target panel width, in `units`.
#' @param panel_height Target panel height, in `units`.
#' @param panel_left   Distance from left edge of slide to the left edge of
#'   the panel, in `units`.
#' @param panel_top    Distance from top edge of slide to the top edge of
#'   the panel, in `units`.
#' @param units        One of `"in"`, `"cm"`, `"mm"`. Default `"in"`.
#'
#' @return A named list with elements `width`, `height`, `left`, `top`, all
#'   in `units`. Splat into [officer::ph_location()] via [do.call()].
#'
#' @seealso [hv_ggsave_dims()] for the sizing-only analogue used with
#'   [ggplot2::ggsave()], and [save_ppt()] which accepts a `panel_box`
#'   argument that delegates to this helper.
#'
#' @examples
#' \donttest{
#' p <- ggplot2::ggplot(mtcars, ggplot2::aes(hp, mpg)) +
#'   ggplot2::geom_point() +
#'   theme_hv_ppt_dark()
#'
#' loc <- hv_ph_location(
#'   p,
#'   panel_width  = 10, panel_height = 5,
#'   panel_left   = 0.5, panel_top   = 1.5
#' )
#' # doc <- officer::read_pptx(template)
#' # doc <- officer::add_slide(doc, layout = "Title and Content")
#' # doc <- officer::ph_with(
#' #   doc, rvg::dml(ggobj = p),
#' #   location = do.call(officer::ph_location, loc)
#' # )
#' }
#'
#' @importFrom ggplot2 ggplotGrob
#' @importFrom grid convertWidth convertHeight
#' @importFrom grDevices pdf dev.off
#' @export
hv_ph_location <- function(plot,
                           panel_width,
                           panel_height,
                           panel_left,
                           panel_top,
                           units = c("in", "cm", "mm")) {
  if (!inherits(plot, "ggplot"))
    stop("`plot` must be a ggplot object.", call. = FALSE)
  .check_scalar_positive(panel_width,  "panel_width")
  .check_scalar_positive(panel_height, "panel_height")
  .check_scalar_nonneg(panel_left,     "panel_left")
  .check_scalar_nonneg(panel_top,      "panel_top")
  units <- match.arg(units)

  loc <- .hv_measure_placement(plot, panel_width, panel_height, panel_left,
                               panel_top, units)$location

  if (loc$left < 0 || loc$top < 0) {
    off <- c(
      if (loc$left < 0) sprintf("left=%.3f", loc$left) else NULL,
      if (loc$top  < 0) sprintf("top=%.3f",  loc$top)  else NULL
    )
    warning(
      "hv_ph_location(): plot chrome does not fit left/top of panel on slide (",
      paste(off, collapse = ", "), " ", units,
      "). Increase `panel_left`/`panel_top` to leave room for axis labels.",
      call. = FALSE
    )
  }

  loc
}

# The gtable of the whole figure. ggplotGrob() of a patchwork builds only its
# last plot, so a patchwork goes through patchworkGrob(), which lays out
# every plot and the plot_annotation() title, subtitle and caption.
.hv_plot_gtable <- function(plot) {
  if (inherits(plot, "patchwork")) patchwork::patchworkGrob(plot)
  else ggplot2::ggplotGrob(plot)
}

# Place `plot` so the union of its panel cells lands on the panel rectangle.
# Returns `location` (width, height, left, top in `units`, the
# hv_ph_location() result) and `text_left`, `text_right`: the slide
# x-coordinates where the plot, subtitle and caption text actually start and
# end. A title wider than its cell runs past the location's edges, so the
# fit check needs these as well as the location.
.hv_measure_placement <- function(plot, panel_width, panel_height, panel_left,
                                  panel_top, units) {
  # Measure on rvg's own PowerPoint device, opened before the grob is built
  # so nothing opens Rplots.pdf. It resolves font families the way
  # rvg::dml() does when it draws the slide (through systemfonts), so the
  # label widths measured here are the ones the slide is laid out with. A
  # pdf(NULL) device resolves them through the PostScript font database
  # instead, which has no "Arial": its substitute metrics differ from the
  # slide's by an amount that depends on the label text and the platform's
  # fonts, and the panel missed panel_box by that much.
  dml_file <- tempfile(fileext = ".dml")
  rvg::dml_pptx(file = dml_file, bg = "transparent")
  on.exit(unlink(dml_file), add = TRUE)
  on.exit(grDevices::dev.off(), add = TRUE, after = FALSE)

  g <- .hv_plot_gtable(plot)

  panel <- g$layout[grepl("^panel", g$layout$name), , drop = FALSE]
  if (nrow(panel) == 0L)
    stop("Could not locate any panel cells in the ggplot grob.", call. = FALSE)

  panel_col_lo <- min(panel$l)
  panel_col_hi <- max(panel$r)
  panel_row_lo <- min(panel$t)
  panel_row_hi <- max(panel$b)

  # Inside the panel span the null (flexible) columns share what the
  # absolute ones leave of panel_width, which places every column.
  widths <- grid::convertWidth(g$widths, units, valueOnly = TRUE)
  heights <- grid::convertHeight(g$heights, units, valueOnly = TRUE)
  span <- seq.int(panel_col_lo, panel_col_hi)
  widths[span] <- .hv_resolve_widths(g$widths[span], panel_width, units)

  before <- function(x, i) sum(x[seq_len(i - 1L)])
  after  <- function(x, i) if (i < length(x)) sum(x[seq.int(i + 1L, length(x))]) else 0

  left_chrome   <- before(widths, panel_col_lo)
  right_chrome  <- after(widths, panel_col_hi)
  top_chrome    <- before(heights, panel_row_lo)
  bottom_chrome <- after(heights, panel_row_hi)

  loc <- list(
    width  = panel_width  + left_chrome + right_chrome,
    height = panel_height + top_chrome  + bottom_chrome,
    left   = panel_left   - left_chrome,
    top    = panel_top    - top_chrome
  )

  extent <- .hv_title_extent(g, widths, loc$left, units)
  text_left <- min(loc$left, extent[[1L]])
  text_right <- max(loc$left + loc$width, extent[[2L]])

  list(location = loc, text_left = text_left, text_right = text_right)
}

# Widths of `widths` in `units` when they fill `total`: absolute widths keep
# their size (a null unit converts to 0) and the null columns share the rest
# in proportion to their null values.
.hv_resolve_widths <- function(widths, total, units) {
  out <- grid::convertWidth(widths, units, valueOnly = TRUE)
  nulls <- ifelse(grid::unitType(widths) == "null", as.numeric(widths), 0)
  if (sum(nulls) > 0) {
    out <- out + max(total - sum(out), 0) * nulls / sum(nulls)
  }
  out
}

# The leftmost start and rightmost end, in slide x-coordinates, of the title,
# subtitle and caption text in gtable `g`, whose columns are `widths` wide
# and whose left edge is at `x0`: of the plot, of any patchwork plot or
# annotation, and, recursing into each nested gtable (a nested patchwork's
# table) placed in its cell, of theirs. A titleGrob draws its text at hjust
# across its cell. Legends are skipped. Returns c(Inf, -Inf) when there is
# no such text.
.hv_title_extent <- function(g, widths, x0, units) {
  lo <- Inf
  hi <- -Inf
  for (i in seq_len(nrow(g$layout))) {
    grob <- g$grobs[[i]]
    name <- g$layout$name[[i]]
    l <- g$layout$l[[i]]
    r <- g$layout$r[[i]]
    cell_left <- x0 + sum(widths[seq_len(l - 1L)])
    cell_width <- sum(widths[seq.int(l, r)])

    if (inherits(grob, "gtable") && !startsWith(name, "guide-box")) {
      inner <- .hv_title_extent(grob, .hv_resolve_widths(grob$widths, cell_width, units),
                                cell_left, units)
      lo <- min(lo, inner[[1L]])
      hi <- max(hi, inner[[2L]])
      next
    }
    if (!grepl("^(title|subtitle|caption)(-[0-9]+)?$", name) ||
        !inherits(grob, "titleGrob")) next
    text <- Filter(function(k) inherits(k, "text"), grob$children)
    if (length(text) == 0L || !isTRUE(all(text[[1L]]$rot == 0))) next
    hjust <- if (is.numeric(text[[1L]]$hjust)) text[[1L]]$hjust[[1L]] else 0.5
    w <- grid::convertWidth(grid::grobWidth(grob), units, valueOnly = TRUE)
    start <- cell_left + hjust * (cell_width - w)
    lo <- min(lo, start)
    hi <- max(hi, start + w)
  }
  c(lo, hi)
}

#' Standard slide panel rectangle for a slide format
#'
#' The one fixed panel rectangle every plot slide of a slide format anchors
#' its plotting panel to, in inches. The slide format is the slide's aspect
#' ratio: `"wide"` is 16:9, 13.333 by 7.5 in, the size of every bundled HVTI
#' template; `"standard"` is 4:3, 10 by 7.5 in. The color template does not
#' matter: the dark, light and slate templates get the same rectangle.
#' [save_ppt()] and [hv_add_plot()] read the format from the template's slide
#' size and use this rectangle by default. Axis text, axis titles, facet
#' strips and plot titles flow outside it; [hv_fit_location()] keeps them on
#' the slide and out of the slide title.
#'
#' The wide rectangle is 9.98 by 4.11 in, 2.9 in from the left edge and
#' 1.85 in from the top. The numbers leave room for the chrome around the
#' panel:
#'
#' * 2.9 in on the left for long y-axis labels and the rotated y-axis title;
#' * about 0.45 in above the panel, below the title placeholder that ends at
#'   1.33 in, for facet strips and plot titles;
#' * 1.54 in below the panel (7.5 - 1.85 - 4.11), or 1.49 in inside the
#'   0.05 in slide edge, for the x-axis chrome of [theme_hv_ppt_dark()],
#'   [theme_hv_ppt_light()] and [theme_hv_ppt_slate()]: their 32 pt x-axis
#'   text and 40 pt x-axis title with its margin need about 1.48 in in
#'   Arial Bold, so a plot in these themes fits at full size.
#'
#' The standard (4:3) rectangle is **provisional**: no 4:3 template is
#' bundled, and the rectangle has not yet been checked on a real 4:3 deck.
#' It follows the same rules, assuming the 4:3 title placeholder also ends
#' near 1.33 in: the same top (1.85 in) and height (4.11 in), 2.3 in on the
#' left for y labels and 0.45 in on the right, so 7.25 by 4.11 in at 2.3 in
#' left.
#'
#' In hvtiPlotR 2.8.14 and 2.8.15 both rectangles were 4.15 in high.
#' Through hvtiPlotR 2.8.13 the rectangle was 8.79 by 3.9 in at 2.67 in
#' left, 1.6 in top. Pass
#' `panel_box = list(width = 8.79, height = 3.9, left = 2.67, top = 1.6)`
#' to [save_ppt()] or [hv_add_plot()] to rebuild an old deck at its old
#' geometry.
#'
#' @param mode `"dark"`, `"light"` or `"slate"`. Kept for backward
#'   compatibility: every color template gets the same rectangle, so it has
#'   no effect.
#' @param format `"wide"` (16:9, the default) or `"standard"` (4:3,
#'   provisional).
#' @return A named list `width`, `height`, `left`, `top`, in inches, ready for
#'   the `panel_box` argument of [save_ppt()] and [hv_add_plot()].
#' @seealso [save_ppt()], [hv_add_plot()], [hv_fit_location()],
#'   [hv_ph_location()]
#' @examples
#' hv_panel_box()
#' hv_panel_box(format = "standard")
#' @export
hv_panel_box <- function(mode = c("dark", "light", "slate"),
                         format = c("wide", "standard")) {
  match.arg(mode)
  format <- match.arg(format)
  switch(format,
    wide     = list(width = 9.98, height = 4.11, left = 2.9, top = 1.85),
    standard = list(width = 7.25, height = 4.11, left = 2.3, top = 1.85)
  )
}

# The slide format of a slide size in inches: "wide" for 13.333 x 7.5,
# "standard" for 10 x 7.5. Any other size has no standard panel box.
.hv_slide_format <- function(width, height) {
  near <- function(a, b) abs(a - b) < 0.01
  if (near(width, 13.333) && near(height, 7.5)) return("wide")
  if (near(width, 10) && near(height, 7.5)) return("standard")
  stop(sprintf(
    paste0("The slide is %.3f x %.3f in, which has no standard panel box ",
           "(16:9 is 13.333 x 7.5 in, 4:3 is 10 x 7.5 in). ",
           "Pass `panel_box = list(width, height, left, top)` explicitly."),
    width, height
  ), call. = FALSE)
}

# The slide format of a template file, from its slide size. A path that is
# not a file gives "wide"; save_ppt() reports the bad path itself.
.hv_template_format <- function(template) {
  if (!(is.character(template) && length(template) == 1L &&
        file.exists(template))) {
    return("wide")
  }
  size <- officer::slide_size(officer::read_pptx(template))
  .hv_slide_format(size$width, size$height)
}

# "light" or "slate" when `template` is that bundled template, else "dark".
.hv_template_mode <- function(template) {
  if (!(is.character(template) && length(template) == 1L &&
        file.exists(template))) {
    return("dark")
  }
  bundled <- c(light = "hv_ppt_template_light.pptx",
               slate = "hv_ppt_template_slate.pptx")
  for (mode in names(bundled)) {
    path <- system.file("extdata", bundled[[mode]], package = "hvtiPlotR")
    if (nzchar(path) &&
        identical(normalizePath(template), normalizePath(path))) {
      return(mode)
    }
  }
  "dark"
}
