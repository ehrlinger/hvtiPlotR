# panel-size.R
#
# Figure dimensions for a multi-panel plot, chosen from its facet layout.
# A single-panel figure is 6 in wide by 4 in tall, the CORR figure standard
# (hvtiRtemplates dev/specs/2026-10-13-figure-standard-design.md). A faceted
# figure cannot be held to that without shrinking every panel, so its size is
# derived instead: a panel block sized from the number of panel rows and
# columns, plus the chrome outside it, measured by hv_ggsave_dims().
# ---------------------------------------------------------------------------

#' Figure dimensions for a faceted plot
#'
#' Chooses `ggsave()` dimensions from a plot's facet layout, so a faceted
#' figure keeps panels of a readable size however many there are. A plot with
#' one panel gets the standard 6 by 4 inch figure. A plot with several gets
#' 3 by 2 inch panels, half the standard figure in each direction, plus the
#' space its axes, titles, strips and legend need, measured by
#' [hv_ggsave_dims()].
#'
#' When those panels, with the gutters and interior strips between them, would
#' make the figure wider than `max_width` or taller than `max_height`, every
#' panel shrinks by the same factor, so each keeps its 3:2 shape. A panel
#' narrower than 1.6 inches leaves no room for 12 pt tick labels, so below
#' that the function stops: the facets do not fit on one page, and
#' `ggforce::facet_wrap_paginate()` splits them across several. A paginated
#' plot is sized by the one page it draws.
#'
#' The panel block is measured, not the whole figure, because the chrome
#' around it varies: a long axis title or a legend at the top would otherwise
#' come out of every panel.
#'
#' @param plot       A ggplot object. Faceted with [ggplot2::facet_wrap()] or
#'   [ggplot2::facet_grid()], or not faceted at all. A patchwork is refused:
#'   its panels sit in nested tables the function cannot count.
#' @param max_width  The widest figure allowed, in `units`. `NULL`, the default,
#'   is 6.5 inches, a journal's text width, converted to `units`.
#' @param max_height The tallest figure allowed, in `units`. `NULL`, the default,
#'   is 9 inches, converted to `units`; with the 6.5 inch width it fits a page.
#' @param units      One of `"in"`, `"cm"`, `"mm"`. Default `"in"`.
#'
#' @return A named list with elements `width`, `height` and `units`, shaped to
#'   splat into [ggplot2::ggsave()] via [do.call()], as [hv_ggsave_dims()]
#'   returns.
#'
#' @seealso [hv_ggsave_dims()], which measures the chrome.
#'
#' @examples
#' \donttest{
#' p <- ggplot2::ggplot(mtcars, ggplot2::aes(hp, mpg)) +
#'   ggplot2::geom_point() +
#'   ggplot2::facet_wrap(~cyl)
#' dims <- hv_panel_size(p)
#' do.call(
#'   ggplot2::ggsave,
#'   c(list(filename = file.path(tempdir(), "facets.pdf"), plot = p), dims)
#' )
#' }
#' @export
hv_panel_size <- function(plot, max_width = NULL, max_height = NULL, units = c("in", "cm", "mm")) {
  if (!inherits(plot, "ggplot"))
    stop("`plot` must be a ggplot object.", call. = FALSE)
  # A patchwork nests each plot's panels inside its own table, so the drawn
  # grob shows no facet grid and would pass as one 6 by 4 panel. Say so.
  if (inherits(plot, "patchwork"))
    stop(paste0("`plot` is a patchwork, whose panels hv_panel_size() cannot count. ",
                "Size it by hand, or draw the panels as facets of one plot."), call. = FALSE)
  units <- match.arg(units)
  per_inch <- c(`in` = 1, cm = 2.54, mm = 25.4)[[units]]
  # An omitted limit is the page, 6.5 by 9 inches, in whatever `units` asks for.
  if (is.null(max_width)) max_width <- 6.5 * per_inch
  if (is.null(max_height)) max_height <- 9 * per_inch
  .check_scalar_positive(max_width, "max_width")
  .check_scalar_positive(max_height, "max_height")

  # The drawn grob, not ggplot_build()'s layout: a paginated facet builds every
  # page's panels but draws one page, and the page is what gets sized. The null
  # device comes first, because ggplotGrob() otherwise opens and leaves one.
  close_device <- .null_device()
  on.exit(close_device(), add = TRUE)
  g <- ggplot2::ggplotGrob(plot)
  panels <- g$layout[grepl("^panel", g$layout$name), , drop = FALSE]
  nrow <- length(unique(panels$t))
  ncol <- length(unique(panels$l))
  if (nrow <= 1L && ncol <= 1L)
    return(list(width = 6 * per_inch, height = 4 * per_inch, units = units))

  # hv_ggsave_dims() counts the gutters and interior strips between panels as
  # part of the panel block, so take them out of the room before the panels
  # are sized; otherwise a wide panel.spacing passes the floor with narrow panels.
  gutter <- .panel_gutters(g, panels)
  chrome <- hv_ggsave_dims(plot, width = 1, height = 1, units = "in")
  room <- c(width = max_width / per_inch - (chrome$width - 1) - gutter[["width"]],
            height = max_height / per_inch - (chrome$height - 1) - gutter[["height"]])
  block <- .panel_block(nrow, ncol, room) + gutter
  hv_ggsave_dims(plot, width = block[["width"]] * per_inch,
                 height = block[["height"]] * per_inch, units = units)
}

# The space, in inches, between the panels of a drawn plot: the columns and rows
# inside the panel block that hold no panel (gutters, and the strips and axes of
# interior facet rows). Returns c(width = , height = ).
.panel_gutters <- function(g, panels) {
  inside <- function(lo, hi) seq.int(min(lo), max(hi))
  held <- function(lo, hi) unique(unlist(Map(seq.int, lo, hi)))
  cols <- setdiff(inside(panels$l, panels$r), held(panels$l, panels$r))
  rows <- setdiff(inside(panels$t, panels$b), held(panels$t, panels$b))
  # The caller has a null device open, so the conversions resolve against it.
  # One row or one column of panels has nothing between them to measure.
  c(width = if (length(cols)) sum(grid::convertWidth(g$widths[cols], "in", valueOnly = TRUE)) else 0,
    height = if (length(rows)) sum(grid::convertHeight(g$heights[rows], "in", valueOnly = TRUE)) else 0)
}

# The panel block, in inches, for `nrow` rows and `ncol` columns of panels:
# 3 by 2 inch panels, shrunk together to fit `room` (c(width =, height =), the
# space left once the chrome and the gutters are placed), and never narrower than
# 1.6 inches. The result is the panels alone, without the gutters between them.
.panel_block <- function(nrow, ncol, room) {
  cell <- c(width = 3, height = 2)
  shrink <- min(1, room[["width"]] / (ncol * cell[["width"]]), room[["height"]] / (nrow * cell[["height"]]))
  if (cell[["width"]] * shrink < 1.6) {
    stop(sprintf(paste0("%d by %d panels do not fit the page: each would be %.2f in wide, under the 1.6 in ",
                        "a panel needs. Split them across pages with ggforce::facet_wrap_paginate()."),
                 nrow, ncol, cell[["width"]] * shrink), call. = FALSE)
  }
  c(width = ncol * cell[["width"]] * shrink, height = nrow * cell[["height"]] * shrink)
}
