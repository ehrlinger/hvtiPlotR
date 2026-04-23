#' Light PowerPoint Theme
#'
#' A large-font theme with a **white/transparent background** suited to
#' light-background PowerPoint slides (e.g. AATS-style). Removes grid lines
#' and panel borders.
#'
#' For the default dark-background PowerPoint theme use
#' [hv_theme_dark_ppt()] or its alias `hv_theme_ppt()`.
#'
#' Legend is hidden by default since PowerPoint figures are typically
#' annotated directly on the panel; add `+ theme(legend.position = "right")`
#' (or similar) to override. Axis-text and axis-title margins are scaled from
#' `base_size` via ggplot2's `half_line = base_size / 2` convention, so the
#' spacing stays proportional when `base_size` changes.
#'
#' @section Axis customisation via `+ theme(...)`:
#' The theme sets sensible defaults, but every element can be overridden
#' after the fact with a `+ theme(...)` call:
#'
#' ```r
#' # Monospace y-axis labels (already set when mono_y = TRUE, but also
#' # achievable ad-hoc — useful when y-axis ranges vary across slides and
#' # you need stable label widths):
#' p + hv_theme_light_ppt() +
#'   theme(axis.text.y = element_text(family = "mono"))
#'
#' # Inward ticks of a specific physical length (negative = inward):
#' p + hv_theme_light_ppt() +
#'   theme(axis.ticks.length = unit(-0.25, "cm"))
#'
#' # Nudge x-axis tick labels down (vjust) and away from the axis (margin):
#' p + hv_theme_light_ppt() +
#'   theme(axis.text.x = element_text(vjust = 2.05,
#'                                    margin = margin(t = 0.55, unit = "cm")))
#'
#' # Separate axis title size from axis text size:
#' p + hv_theme_light_ppt() +
#'   theme(axis.title = element_text(size = 40))
#'
#' # Rotate x-axis labels:
#' p + hv_theme_light_ppt() +
#'   theme(axis.text.x = element_text(angle = 45, hjust = 1))
#'
#' # Restore the legend:
#' p + hv_theme_light_ppt() +
#'   theme(legend.position = "right")
#' ```
#'
#' Note that `element_text()` calls in `+ theme()` are *relative* to the
#' values already set by the theme, so you only need to specify the
#' attributes you want to change.
#'
#' @param base_size      Base font size in points (applies to axis text).
#'   Default `32`.
#' @param base_family    Base font family. Default `""` (device default).
#' @param header_family  Font family for headers, or `NULL` to inherit
#'   `base_family`. Default `NULL`.
#' @param base_line_size Line size used for axis lines and borders.
#'   Default `base_size / 22`.
#' @param base_rect_size Rectangle border size. Default `base_size / 22`.
#' @param ink            Foreground (text and line) colour. Default `"black"`.
#' @param paper          Background colour. Default `"transparent"`.
#' @param accent         Accent colour used by some `theme_grey()` elements.
#'   Default `"#3366FF"`.
#' @param bold           If `TRUE`, axis text and axis titles are rendered
#'   with `face = "bold"`. Default `FALSE`.
#' @param mono_y         If `TRUE`, y-axis tick labels are rendered in a
#'   fixed-width (`"mono"`) font family. This keeps label widths constant
#'   across slides whose y-axis ranges differ (e.g. `"1.0"` vs `"100.0"`),
#'   preventing the panel from appearing to shift between slides when exported
#'   via `rvg`/`officer`. Default `FALSE`.
#' @param title_size     Font size in points for axis titles. When `NULL`
#'   (default) axis titles inherit `base_size`. Set to a larger value (e.g.
#'   `40`) to make titles more prominent than tick labels.
#'
#' @return A [ggplot2::theme()] object.
#'
#' @seealso [hv_theme()], [hv_theme_dark_ppt()], [theme_man()],
#'   [theme_poster()]
#'
#' @examples
#' library(ggplot2)
#' p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) + geom_point()
#'
#' # Light PPT theme — large font, black text, transparent background
#' p + hv_theme_light_ppt()
#'
#' # Via alias
#' p + theme_light_ppt()
#'
#' # Bold axis text/titles
#' p + hv_theme_light_ppt(bold = TRUE)
#'
#' # Monospace y-axis labels (stable width across slides with different ranges)
#' p + hv_theme_light_ppt(mono_y = TRUE)
#'
#' # Larger axis titles than tick labels
#' p + hv_theme_light_ppt(title_size = 40)
#'
#' # Via the generic dispatcher
#' p + hv_theme("light_ppt")
#'
#' @import ggplot2
#' @export
#' @aliases theme_light_ppt
hv_theme_light_ppt <- function(base_size      = 32,
                                  base_family    = "",
                                  header_family  = NULL,
                                  base_line_size = base_size / 22,
                                  base_rect_size = base_size / 22,
                                  ink            = "black",
                                  paper          = "transparent",
                                  accent         = "#3366FF",
                                  bold           = FALSE,
                                  mono_y         = FALSE,
                                  title_size     = NULL) {
  half_line  <- base_size / 2
  face_axis  <- if (isTRUE(bold)) "bold" else "plain"
  title_size <- if (is.null(title_size)) base_size else title_size
  y_family   <- if (isTRUE(mono_y)) "mono" else base_family

  hv_theme_base(
    base_size      = base_size,
    base_family    = base_family,
    header_family  = header_family,
    base_line_size = base_line_size,
    base_rect_size = base_rect_size,
    ink            = ink,
    paper          = paper,
    accent         = accent
  ) %+replace%
    theme(
      plot.background    = element_rect(
        fill      = "transparent",
        colour    = "transparent",
        linewidth = 2
      ),
      axis.text          = element_text(
        size   = base_size,
        colour = "black",
        face   = face_axis
      ),
      axis.text.x        = element_text(
        margin = margin(t = half_line)
      ),
      axis.text.y        = element_text(
        family = y_family,
        margin = margin(r = half_line),
        hjust  = 1
      ),
      axis.title.x       = element_text(
        size   = title_size,
        face   = face_axis,
        margin = margin(t = 1.5 * half_line)
      ),
      axis.title.y       = element_text(
        size   = title_size,
        angle  = 90,
        face   = face_axis,
        margin = margin(r = 1.5 * half_line)
      ),
      axis.line          = element_line(colour = "black", linewidth = 1),
      strip.text         = element_text(size = base_size / 2),
      panel.border       = element_blank(),
      # Transparent panel fill so the PPT slide template background (white
      # on a light template, blue-gradient on a dark AATS-style template)
      # shows through. The black border still delimits the panel rectangle;
      # the `hv_ph_location()` / `save_ppt(panel_box=)` workflow anchors
      # that rectangle at a fixed slide position. Use
      # `+ theme(panel.background = element_rect(fill = "white"))` to
      # restore an opaque white panel if that's needed for a specific
      # template.
      panel.background   = element_rect(
        fill      = "transparent",
        colour    = "black",
        linewidth = 1
      ),
      axis.ticks         = element_line(colour = "black", linewidth = 1),
      axis.ticks.length  = unit(-half_line / 2, "pt"),
      panel.grid.major.x = element_blank(),
      panel.grid.major.y = element_blank(),
      panel.grid.minor   = element_blank(),
      legend.position    = "none",
      plot.margin        = unit(c(0, 0, 0, 0), "inches")
    )
}

#' @export
#' @rdname hv_theme_light_ppt
theme_light_ppt <- hv_theme_light_ppt
