#' Theme for Manuscript Figures
#'
#' A clean, white-background theme suited to journal submissions.
#' Removes grid lines, panel borders, and legends; draws solid axis lines.
#'
#' @param base_size      Base font size in points. Default `12`.
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
#' @seealso [hvti_theme()], [theme_ppt()], [theme_dark_ppt()], [theme_poster()]
#'
#' @examples
#' library(ggplot2)
#' p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) + geom_point()
#'
#' # Default manuscript theme
#' p + hvti_theme_manuscript()
#'
#' # Smaller base font for two-column journal layout
#' p + hvti_theme_manuscript(base_size = 9)
#'
#' # Via the generic dispatcher
#' p + hvti_theme("manuscript")
#'
#' @import ggplot2
#' @export
#' @aliases theme_manuscript theme_man
hvti_theme_manuscript <- function(base_size      = 12,
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
      strip.text        = element_text(size = 10),
      legend.position   = "none",
      legend.key        = element_blank(),
      panel.grid.major  = element_blank(),
      panel.grid.minor  = element_blank(),
      legend.title      = element_blank(),
      panel.background  = element_blank(),
      panel.border      = element_blank(),
      axis.line.x       = element_line(color = "black", linewidth = 0.8),
      axis.line.y       = element_line(color = "black", linewidth = 0.8),
      axis.text         = element_text(size = base_size, color = "black"),
      plot.margin       = unit(c(0.65, 0.65, 0.25, 0.25), "cm"),
      axis.title        = element_text(size = base_size)
    )
}

#' @export
#' @rdname hvti_theme_manuscript
theme_manuscript <- hvti_theme_manuscript

#' @export
#' @rdname hvti_theme_manuscript
#' @note Deprecated. Use [hvti_theme()] with `style = "manuscript"` instead.
theme_man <- hvti_theme_manuscript
