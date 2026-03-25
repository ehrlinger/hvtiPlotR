#' Theme for Poster Figures
#'
#' A medium-font theme with a white panel background and visible axis lines,
#' suited to conference posters produced via PowerPoint.
#' Removes grid lines.
#'
#' @param base_size      Base font size in points.
#'   Default `16`.
#' @param base_family    Base font family. Default `""` (device default).
#' @param header_family  Font family for headers, or `NULL` to inherit
#'   `base_family`. Default `NULL`.
#' @param base_line_size Line size used for axis lines and borders.
#'   Default `base_size / 22`.
#' @param base_rect_size Rectangle border size. Default `base_size / 22`.
#' @param ink            Foreground (text and line) colour. Default `"black"`.
#' @param paper          Background colour. Default `"white"`.
#' @param accent         Accent colour used by some `theme_grey()` elements.
#'   Default `"#3366FF"`.
#'
#' @return A [ggplot2::theme()] object.
#'
#' @seealso [hvti_theme()], [theme_man()], [theme_ppt()], [theme_dark_ppt()]
#'
#' @examples
#' library(ggplot2)
#' p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) + geom_point()
#'
#' # Default poster theme (16 pt base font)
#' p + hvti_theme_poster()
#'
#' # Larger font for a wide-format poster
#' p + hvti_theme_poster(base_size = 20)
#'
#' # Via alias
#' p + theme_poster()
#'
#' @import ggplot2
#' @export
#' @aliases theme_poster
hvti_theme_poster <- function(base_size      = 16,
                               base_family    = "",
                               header_family  = NULL,
                               base_line_size = base_size / 22,
                               base_rect_size = base_size / 22,
                               ink            = "black",
                               paper          = "white",
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
      plot.background  = element_rect(
        fill      = "transparent",
        colour    = "transparent",
        linewidth = 2
      ),
      axis.text        = element_text(
        size  = base_size,
        color = "black"
      ),
      axis.line        = element_line(color = "black", linewidth = 1),
      strip.text       = element_text(size = 8),
      panel.border     = element_blank(),
      panel.background = element_rect(
        fill      = "white",
        colour    = "black",
        linewidth = 1
      ),
      axis.ticks       = element_line(colour = "black", linewidth = 1),
      panel.grid.major.x = element_blank(),
      panel.grid.major.y = element_blank(),
      panel.grid.minor   = element_blank()
    )
}

#' @export
#' @rdname hvti_theme_poster
theme_poster <- hvti_theme_poster
