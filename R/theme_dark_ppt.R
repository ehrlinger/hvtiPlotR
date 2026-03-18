#' Dark PowerPoint Theme (default PPT theme)
#'
#' A large-font theme with a **black panel background and white text**, suited
#' to dark-mode PowerPoint slides. This is the default hvtiPlotR PPT theme —
#' `hvti_theme_ppt()` and `theme_ppt()` are aliases for this function.
#' For a light-background variant use [hvti_theme_light_ppt()].
#' Removes grid lines and panel borders.
#'
#' @param base_size      Base font size in points.
#'   Default `r HVTI_THEME_DARK_PPT_BASE_SIZE` (32).
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
#' @seealso [hvti_theme()], [hvti_theme_light_ppt()], [theme_man()],
#'   [theme_poster()]
#'
#' @import ggplot2
#' @export
#' @aliases theme_dark_ppt theme_ppt hvti_theme_ppt
hvti_theme_dark_ppt <- function(base_size      = HVTI_THEME_DARK_PPT_BASE_SIZE,
                                base_family    = "",
                                header_family  = NULL,
                                base_line_size = base_size / 22,
                                base_rect_size = base_size / 22,
                                ink            = "white",
                                paper          = "transparent",
                                accent         = "#3366FF") {
  hvti_theme_base(
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
#' @rdname hvti_theme_dark_ppt
theme_dark_ppt <- hvti_theme_dark_ppt

#' @export
#' @rdname hvti_theme_dark_ppt
theme_ppt <- hvti_theme_dark_ppt

#' @export
#' @rdname hvti_theme_dark_ppt
hvti_theme_ppt <- hvti_theme_dark_ppt
