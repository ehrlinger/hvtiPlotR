#' Theme for PowerPoint Figures
#'
#' A large-font theme with a transparent background suited to PowerPoint
#' slides. Removes grid lines and panel borders.
#'
#' @param base_size      Base font size in points.
#'   Default `r HVTI_THEME_PPT_BASE_SIZE` (32).
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
#'
#' @return A [ggplot2::theme()] object.
#'
#' @seealso [hvti_theme()], [theme_man()], [theme_dark_ppt()], [theme_poster()]
#'
#' @import ggplot2
#' @export
#' @aliases theme_ppt
hvti_theme_ppt <- function(base_size      = HVTI_THEME_PPT_BASE_SIZE,
                            base_family    = "",
                            header_family  = NULL,
                            base_line_size = base_size / 22,
                            base_rect_size = base_size / 22,
                            ink            = "black",
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
      plot.background      = element_rect(
        fill      = "transparent",
        colour    = "transparent",
        linewidth = 2
      ),
      strip.text           = element_text(size = base_size / 2),
      panel.border         = element_blank(),
      panel.grid.major.x   = element_blank(),
      panel.grid.major.y   = element_blank(),
      panel.grid.minor     = element_blank()
    )
}

#' @export
#' @rdname hvti_theme_ppt
theme_ppt <- hvti_theme_ppt
