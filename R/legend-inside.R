# R/legend-inside.R

#' @noRd
# Validate args shared by hv_legend_inside().
.legend_validate <- function(threshold, box_frac, pad) {
  .check_scalar_positive(box_frac, "box_frac")
  .check_scalar_positive(pad, "pad")
  if (!is.numeric(threshold) || length(threshold) != 1L ||
      !is.finite(threshold) || threshold < 0 || threshold > 1)
    stop("`threshold` must be a single number in [0, 1].", call. = FALSE)
  if (box_frac > 0.5)
    stop("`box_frac` must be <= 0.5 (corner boxes would overlap).",
         call. = FALSE)
  invisible(TRUE)
}

#' @noRd
# Collect finite (x, y) from every layer of a built plot, in npc panel
# coordinates [0, 1] via the coord's own transform (so coord_flip and other
# coordinate systems are handled correctly).
.legend_points <- function(b) {
  coord <- b$layout$coord
  pp    <- b$layout$panel_params[[1]]
  parts <- lapply(b$data, function(d) {
    if (!all(c("x", "y") %in% names(d))) return(NULL)
    td <- coord$transform(d, pp)
    data.frame(x = td$x, y = td$y)
  })
  parts <- Filter(Negate(is.null), parts)
  if (length(parts) == 0L) return(NULL)
  xy <- do.call(rbind, parts)
  xy[is.finite(xy$x) & is.finite(xy$y), , drop = FALSE]
}

#' @noRd
# Fraction of points inside each of the four corner boxes (named tr/tl/br/bl).
# x, y are already in npc [0, 1].
.legend_corner_occupancy <- function(x, y, box_frac) {
  n <- length(x)
  frac <- function(hx, hy) {
    xin <- if (hx) x >= (1 - box_frac) else x <= box_frac
    yin <- if (hy) y >= (1 - box_frac) else y <= box_frac
    sum(xin & yin) / n
  }
  c(tr = frac(TRUE, TRUE), tl = frac(FALSE, TRUE),
    br = frac(TRUE, FALSE), bl = frac(FALSE, FALSE))
}

#' @noRd
# Theme layer anchoring an inside legend at a corner (modern ggplot2 4.0 API).
.legend_corner_theme <- function(corner, pad) {
  a <- switch(corner,
    tr = list(pos = c(1 - pad, 1 - pad), just = c(1, 1)),
    tl = list(pos = c(pad,     1 - pad), just = c(0, 1)),
    br = list(pos = c(1 - pad, pad),     just = c(1, 0)),
    bl = list(pos = c(pad,     pad),     just = c(0, 0))
  )
  ggplot2::theme(
    legend.position             = "inside",
    legend.position.inside      = a$pos,
    legend.justification.inside = a$just
  )
}

#' Place a ggplot legend inside the emptiest panel corner
#'
#' Inspects a built plot, finds the panel corner with the fewest data points,
#' and anchors the legend there. When no corner is clear of data (e.g. dense
#' multi-curve panels), or the plot is faceted, the legend is sent to an outside
#' position instead. The CORR house convention is in-panel legends placed in
#' dead space; this automates the corner choice.
#'
#' Apply it *after* the house theme (which sets `legend.position = "none"`) so
#' its position wins.
#'
#' @param plot A single-panel \code{ggplot}.
#' @param threshold Maximum fraction of data points allowed in the chosen corner
#'   box for an in-panel legend. If the emptiest corner exceeds it, `fallback`
#'   is used. Default `0.08`.
#' @param box_frac Corner-box size as a fraction of panel width and height
#'   (`<= 0.5`). Default `0.30`.
#' @param pad Inset of the legend anchor from the panel edge, in npc units.
#'   Default `0.02`.
#' @param fallback Outside `legend.position` used when no corner is empty enough
#'   or the plot cannot be reasoned about (facets). One of `"right"`, `"left"`,
#'   `"top"`, `"bottom"`. Default `"right"`.
#' @param prefer Optional preferred corner: one of `"topright"`, `"topleft"`,
#'   `"bottomright"`, `"bottomleft"`. When set and that corner is clear (its
#'   occupancy is within `threshold`), the legend is placed there even if another
#'   corner is emptier. If the preferred corner is occupied, the emptiest-corner
#'   logic applies as usual. Default `NULL` (pick the emptiest corner).
#'
#' @return The input `plot` with a \code{\link[ggplot2]{theme}} layer added that
#'   sets the legend position.
#'
#' @seealso Worked recipe with rendered output:
#'   \url{https://ehrlinger.github.io/hvti_graphics/legends.html}.
#'
#' @examples
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   library(ggplot2)
#'   p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) + geom_point()
#'   hv_legend_inside(p)
#' }
#'
#' @importFrom ggplot2 ggplot_build theme
#' @export
hv_legend_inside <- function(plot, threshold = 0.08, box_frac = 0.30,
                             pad = 0.02, fallback = "right", prefer = NULL) {
  if (!inherits(plot, "ggplot"))
    stop("`plot` must be a ggplot object.", call. = FALSE)
  fallback <- match.arg(fallback, c("right", "left", "top", "bottom"))
  if (!is.null(prefer)) {
    prefer <- match.arg(prefer, c("topright", "topleft",
                                  "bottomright", "bottomleft"))
    prefer <- c(topright = "tr", topleft = "tl",
                bottomright = "br", bottomleft = "bl")[[prefer]]
  }
  .legend_validate(threshold, box_frac, pad)

  fb <- ggplot2::theme(legend.position = fallback)

  b <- ggplot2::ggplot_build(plot)
  if (length(b$layout$panel_params) > 1L) {
    message("hv_legend_inside(): multiple panels; using the fallback legend ",
            "position ('", fallback, "').")
    return(plot + fb)
  }

  pts <- .legend_points(b)
  if (is.null(pts) || nrow(pts) == 0L) return(plot + fb)

  occ <- .legend_corner_occupancy(pts$x, pts$y, box_frac)

  # A clear preferred corner wins, even if another corner is emptier.
  if (!is.null(prefer) && occ[[prefer]] <= threshold)
    return(plot + .legend_corner_theme(prefer, pad))

  best <- names(occ)[which.min(occ)]   # ties -> first: tr, tl, br, bl
  if (occ[[best]] <= threshold)
    plot + .legend_corner_theme(best, pad)
  else
    plot + fb
}
