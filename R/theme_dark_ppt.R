#' Dark PowerPoint Theme (default PPT theme)
#'
#' A large-font theme with a **black panel background and white text**, suited
#' to dark-mode PowerPoint slides. This is the default hvtiPlotR PPT theme —
#' `hv_theme_ppt()` and `theme_ppt()` are aliases for this function.
#' For a light-background variant use [hv_theme_light_ppt()].
#' Removes grid lines and panel borders.
#'
#' Legend is hidden by default since PowerPoint figures are typically
#' annotated directly on the panel; add `+ theme(legend.position = "right")`
#' (or similar) to override. Axis-text and axis-title margins are scaled from
#' `base_size` via ggplot2's `half_line = base_size / 2` convention, so the
#' spacing stays proportional when `base_size` changes.
#'
#' @templateVar fn hv_theme_dark_ppt
#' @template ppt-axis-customisation
#'
#' @param base_size      Base font size in points (applies to axis text).
#'   Default `32`.
#' @param base_family    Base font family. Default `""` (device default).
#' @param header_family  Font family for headers, or `NULL` to inherit
#'   `base_family`. Default `NULL`.
#' @param base_line_size Line size used for axis lines and borders.
#'   Default `base_size / 22`.
#' @param base_rect_size Rectangle border size. Default `base_size / 22`.
#' @param ink            Foreground (text and line) colour. Default `"white"`.
#' @param paper          Background colour. Default `"transparent"`.
#' @param accent         Accent colour used by some `theme_grey()` elements.
#'   Default `"#3366FF"`.
#' @param bold           If `TRUE`, axis text and axis titles are rendered
#'   with `face = "bold"`. Default `FALSE`.
#' @param mono_y         If `TRUE`, y-axis tick labels are rendered in a
#'   fixed-width (`"mono"`) font family, overriding `base_family` for the
#'   y-axis tick labels only (the rest of the plot still uses `base_family`).
#'   This keeps label widths constant across slides whose y-axis ranges
#'   differ (e.g. `"1.0"` vs `"100.0"`), preventing the panel from appearing
#'   to shift between slides when exported via `rvg`/`officer`. Default
#'   `FALSE`.
#' @param title_size     Font size in points for axis titles. `NULL` (the
#'   default) means "inherit `base_size`", so axis titles and tick labels
#'   are the same size. Set to a larger value (e.g. `40`) to make titles
#'   more prominent than tick labels.
#'
#' @return A [ggplot2::theme()] object.
#'
#' @seealso [hv_theme()], [hv_theme_light_ppt()], [theme_man()],
#'   [theme_poster()]
#'
#' @examples
#' library(ggplot2)
#' p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) + geom_point()
#'
#' # Dark PPT theme — large font, white text, black panel
#' p + hv_theme_dark_ppt()
#'
#' # Via alias
#' p + theme_ppt()
#'
#' # Bold axis text/titles
#' p + hv_theme_dark_ppt(bold = TRUE)
#'
#' # Monospace y-axis labels (stable width across slides with different ranges)
#' p + hv_theme_dark_ppt(mono_y = TRUE)
#'
#' # Larger axis titles than tick labels
#' p + hv_theme_dark_ppt(title_size = 40)
#'
#' # Override the default hidden legend
#' p + hv_theme_dark_ppt() + theme(legend.position = "right")
#'
#' \dontrun{
#' # Best viewed against a dark slide background
#' p + hv_theme_dark_ppt() +
#'   ggplot2::theme(plot.background = ggplot2::element_rect(fill = "navy"))
#' }
#'
#' @import ggplot2
#' @export
#' @aliases theme_dark_ppt theme_ppt hv_theme_ppt
hv_theme_dark_ppt <- function(base_size      = 32,
                              base_family    = "",
                              header_family  = NULL,
                              base_line_size = base_size / 22,
                              base_rect_size = base_size / 22,
                              ink            = "white",
                              paper          = "transparent",
                              accent         = "#3366FF",
                              bold           = FALSE,
                              mono_y         = FALSE,
                              title_size     = NULL) {
  hv_theme_ppt_impl(
    variant        = "dark",
    base_size      = base_size,
    base_family    = base_family,
    header_family  = header_family,
    base_line_size = base_line_size,
    base_rect_size = base_rect_size,
    ink            = ink,
    paper          = paper,
    accent         = accent,
    bold           = bold,
    mono_y         = mono_y,
    title_size     = title_size
  )
}

#' @export
#' @rdname hv_theme_dark_ppt
theme_dark_ppt <- hv_theme_dark_ppt

#' @export
#' @rdname hv_theme_dark_ppt
theme_ppt <- hv_theme_dark_ppt

#' @export
#' @rdname hv_theme_dark_ppt
hv_theme_ppt <- hv_theme_dark_ppt
