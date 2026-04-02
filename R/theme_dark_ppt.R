#' Dark PowerPoint Theme (default PPT theme)
#'
#' A large-font theme with a **black panel background and white text**, suited
#' to dark-mode PowerPoint slides. This is the default hvtiPlotR PPT theme —
#' `hv_theme_ppt()` and `theme_ppt()` are aliases for this function.
#' For a light-background variant use [hv_theme_light_ppt()].
#' Removes grid lines and panel borders.
#'
#' @param base_size      Base font size in points.
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
                                accent         = "#3366FF") {
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
      axis.text          = element_text(size = base_size, color = "white"),
      axis.line          = element_line(color = "white", linewidth = 1),
      strip.text         = element_text(size = base_size / 2),
      panel.border       = element_blank(),
      panel.background   = element_rect(
        fill      = "black",
        colour    = "white",
        linewidth = 1
      ),
      axis.ticks         = element_line(colour = "white", linewidth = 1),
      panel.grid.major.x = element_blank(),
      panel.grid.major.y = element_blank(),
      panel.grid.minor   = element_blank(),
      plot.margin        = unit(c(0, 0, 0, 0), "inches")
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
