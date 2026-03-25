#' Light PowerPoint Theme
#'
#' A large-font theme with a **white/transparent background** suited to
#' light-background PowerPoint slides (e.g. AATS-style). Removes grid lines
#' and panel borders.
#'
#' For the default dark-background PowerPoint theme use
#' [hvti_theme_dark_ppt()] or its alias `hvti_theme_ppt()`.
#'
#' @param base_size      Base font size in points.
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
#'
#' @return A [ggplot2::theme()] object.
#'
#' @seealso [hvti_theme()], [hvti_theme_dark_ppt()], [theme_man()],
#'   [theme_poster()]
#'
#' @examples
#' library(ggplot2)
#' p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) + geom_point()
#'
#' # Light PPT theme — large font, black text, transparent background
#' p + hvti_theme_light_ppt()
#'
#' # Via alias
#' p + theme_light_ppt()
#'
#' # Via the generic dispatcher
#' p + hvti_theme("light_ppt")
#'
#' @import ggplot2
#' @export
#' @aliases theme_light_ppt
hvti_theme_light_ppt <- function(base_size      = 32,
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
      plot.background    = element_rect(
        fill      = "transparent",
        colour    = "transparent",
        linewidth = 2
      ),
      strip.text         = element_text(size = base_size / 2),
      panel.border       = element_blank(),
      panel.grid.major.x = element_blank(),
      panel.grid.major.y = element_blank(),
      panel.grid.minor   = element_blank(),
      plot.margin        = unit(c(0, 0, 0, 0), "inches")
    )
}

#' @export
#' @rdname hvti_theme_light_ppt
theme_light_ppt <- hvti_theme_light_ppt
