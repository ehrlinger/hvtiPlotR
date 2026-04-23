#' @section Axis customisation via `+ theme(...)`:
#' The theme sets sensible defaults, but every element can be overridden
#' after the fact with a `+ theme(...)` call:
#'
#' ```r
#' # Monospace y-axis labels (already set when mono_y = TRUE, but also
#' # achievable ad-hoc — useful when y-axis ranges vary across slides and
#' # you need stable label widths):
#' p + <%= fn %>() +
#'   theme(axis.text.y = element_text(family = "mono"))
#'
#' # Inward ticks of a specific physical length (negative = inward):
#' p + <%= fn %>() +
#'   theme(axis.ticks.length = unit(-0.25, "cm"))
#'
#' # Nudge x-axis tick labels down (vjust) and away from the axis (margin):
#' p + <%= fn %>() +
#'   theme(axis.text.x = element_text(vjust = 2.05,
#'                                    margin = margin(t = 0.55, unit = "cm")))
#'
#' # Separate axis title size from axis text size:
#' p + <%= fn %>() +
#'   theme(axis.title = element_text(size = 40))
#'
#' # Rotate x-axis labels:
#' p + <%= fn %>() +
#'   theme(axis.text.x = element_text(angle = 45, hjust = 1))
#'
#' # Restore the legend:
#' p + <%= fn %>() +
#'   theme(legend.position = "right")
#' ```
#'
#' Note that `element_text()` calls in `+ theme()` are *relative* to the
#' values already set by the theme, so you only need to specify the
#' attributes you want to change.
