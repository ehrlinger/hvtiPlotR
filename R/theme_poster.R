#' Theme for generating poster figures through powerpoint
#'
#' @param base_size the base font size
#' @param base_family base font family
#' @param header_family = NULL,
#' @param base_line_size = base_size / 22,
#' @param base_rect_size = base_size / 22,
#' @param ink = "white",
#' @param paper = "transparent",
#' @param accent = "#3366FF"
#'
#' @seealso \code{theme_set} \code{theme_grey} \code{\link{theme_man}}
#'
#' @import ggplot2
#' @export hvti_theme_poster
#' @aliases theme_poster

hvti_theme_poster <- function(base_size = HVTI_THEME_POSTER_BASE_SIZE,
                              base_family = "",
                              header_family = NULL,
                              base_line_size = base_size / 22,
                              base_rect_size = base_size / 22,
                              ink = "black",
                              paper = "white",
                              accent = "#3366FF") {
  theme_grey(
    base_size = base_size,
    base_family = base_family,
    header_family = header_family,
    base_line_size = base_line_size,
    base_rect_size = base_rect_size,
    ink = ink,
    paper = paper,
    accent = accent
  ) %+replace%
    theme(
      plot.background = element_rect(
        fill = 'transparent',
        colour = 'transparent',
        linewidth = 2
      ),
      axis.text  = element_text(size = HVTI_THEME_POSTER_AXIS_TEXT_SIZE, color = "black"),
      axis.line = element_line(color = "black", linewidth = 1),
      strip.text = element_text(size = 8),
      panel.border = element_blank(),
      panel.background = element_rect(
        fill = "white",
        colour = "black",
        linewidth = 1
      ),
      axis.ticks = element_line(colour = "black", linewidth = 1),
      # legend.position="none",
      panel.grid.major.x =  element_blank(),
      panel.grid.major.y =  element_blank(),
      panel.grid.minor =  element_blank()
    )
}

theme_poster <- hvti_theme_poster
