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
#' lands at the specified slide coordinates — regardless of how much room the
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
#' @param plot         A ggplot (or patchwork) object.
#' @param panel_width  Target panel width, in `units`.
#' @param panel_height Target panel height, in `units`.
#' @param panel_left   Distance from left edge of slide to the left edge of
#'   the panel, in `units`.
#' @param panel_top    Distance from top edge of slide to the top edge of
#'   the panel, in `units`.
#' @param units        One of `"in"`, `"cm"`, `"mm"`. Default `"in"`.
#'
#' @return A named list with elements `width`, `height`, `left`, `top` — all
#'   in `units`. Splat into [officer::ph_location()] via [do.call()].
#'
#' @seealso [hv_ggsave_dims()] for the sizing-only analogue used with
#'   [ggplot2::ggsave()], and [save_ppt()] which accepts a `panel_box`
#'   argument that delegates to this helper.
#'
#' @examples
#' \dontrun{
#' p <- ggplot2::ggplot(mtcars, ggplot2::aes(hp, mpg)) +
#'   ggplot2::geom_point() +
#'   hv_theme("dark_ppt")
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

  g <- ggplot2::ggplotGrob(plot)

  panel <- g$layout[grepl("^panel", g$layout$name), , drop = FALSE]
  if (nrow(panel) == 0L)
    stop("Could not locate any panel cells in the ggplot grob.", call. = FALSE)

  panel_col_lo <- min(panel$l)
  panel_col_hi <- max(panel$r)
  panel_row_lo <- min(panel$t)
  panel_row_hi <- max(panel$b)

  n_cols <- length(g$widths)
  n_rows <- length(g$heights)

  # Null PDF sizing device so grid unit conversions resolve against a real device
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE, after = FALSE)

  sum_width <- function(idx) {
    if (length(idx) == 0L) return(0)
    sum(grid::convertWidth(g$widths[idx], units, valueOnly = TRUE))
  }
  sum_height <- function(idx) {
    if (length(idx) == 0L) return(0)
    sum(grid::convertHeight(g$heights[idx], units, valueOnly = TRUE))
  }

  left_chrome   <- sum_width(seq_len(panel_col_lo - 1L))
  right_chrome  <- sum_width(
    if (panel_col_hi < n_cols) seq.int(panel_col_hi + 1L, n_cols) else integer(0)
  )
  top_chrome    <- sum_height(seq_len(panel_row_lo - 1L))
  bottom_chrome <- sum_height(
    if (panel_row_hi < n_rows) seq.int(panel_row_hi + 1L, n_rows) else integer(0)
  )

  loc <- list(
    width  = panel_width  + left_chrome + right_chrome,
    height = panel_height + top_chrome  + bottom_chrome,
    left   = panel_left   - left_chrome,
    top    = panel_top    - top_chrome
  )

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
