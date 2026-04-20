# ggsave-dims.R
#
# Compute ggsave() width/height that yield a fixed panel content area.
# Motivation: ggsave() sets total device dimensions, so the actual panel
# shrinks as axis labels, titles, and legends grow. This helper renders the
# plot grob on a null sizing device, measures the chrome outside the panel
# block, and returns device dimensions that preserve the target panel size.
# ---------------------------------------------------------------------------

#' Compute `ggsave()` dimensions for a fixed panel content area
#'
#' Given a fitted ggplot, returns `width` and `height` values such that, when
#' passed to [ggplot2::ggsave()], the resulting file has a panel content area
#' matching `width` / `height`. The "panel content area" is the rectangular
#' bounding box of the gtable cells tagged `panel` — i.e., the smallest
#' rectangle that encloses every plotting panel. Whatever grobs fall inside
#' that rectangle (e.g., inter-panel gutters and strip rows that sit between
#' facet rows) are counted as part of the target; everything outside it
#' (axes, axis titles, plot title, caption, legend, plot margins, and any
#' strips that sit above/below or beside the panel block such as
#' `facet_grid` side strips) is counted as chrome.
#'
#' Useful for multi-panel figure sets where a constant data region is
#' required across PDFs regardless of label length or legend placement.
#' Always measured with a PDF sizing device, which is why `units` is limited
#' to length (inches, cm, mm) — DPI is irrelevant for vector output.
#'
#' @param plot   A ggplot (or patchwork) object.
#' @param width  Target panel content area width, in `units`.
#' @param height Target panel content area height, in `units`.
#' @param units  One of `"in"`, `"cm"`, `"mm"`. Default `"in"`.
#'
#' @return A named list with elements `width`, `height`, `units` — shaped to
#'   splat directly into [ggplot2::ggsave()] via [do.call()] (see examples).
#'
#' @examples
#' \dontrun{
#' p <- ggplot2::ggplot(mtcars, ggplot2::aes(hp, mpg)) +
#'   ggplot2::geom_point() +
#'   ggplot2::labs(title = "Long title that eats vertical space",
#'                 x = "Horsepower", y = "Miles per gallon")
#'
#' dims <- hv_ggsave_dims(p, width = 4, height = 3)
#' do.call(
#'   ggplot2::ggsave,
#'   c(list(filename = "fig.pdf", plot = p), dims)
#' )
#' }
#' @importFrom ggplot2 ggplotGrob
#' @importFrom grid convertWidth convertHeight
#' @importFrom grDevices pdf dev.off
#' @export
hv_ggsave_dims <- function(plot, width, height, units = c("in", "cm", "mm")) {
  if (!inherits(plot, "ggplot"))
    stop("`plot` must be a ggplot object.", call. = FALSE)
  .check_scalar_positive(width,  "width")
  .check_scalar_positive(height, "height")
  units <- match.arg(units)

  g <- ggplot2::ggplotGrob(plot)

  panel <- g$layout[grepl("^panel", g$layout$name), , drop = FALSE]
  if (nrow(panel) == 0L)
    stop("Could not locate any panel cells in the ggplot grob.", call. = FALSE)

  panel_rows <- seq.int(min(panel$t), max(panel$b))
  panel_cols <- seq.int(min(panel$l), max(panel$r))

  # Null PDF device so grid unit conversions resolve against a real device
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE, after = FALSE)

  outside_w <- sum(grid::convertWidth(
    g$widths[-panel_cols], units, valueOnly = TRUE
  ))
  outside_h <- sum(grid::convertHeight(
    g$heights[-panel_rows], units, valueOnly = TRUE
  ))

  list(
    width  = width  + outside_w,
    height = height + outside_h,
    units  = units
  )
}
