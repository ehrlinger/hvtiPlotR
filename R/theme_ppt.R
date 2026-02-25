#' Theme for generating powerpoint figures
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
#' @import tidyverse
#' @export hvti_theme_ppt
#' @aliases theme_ppt

hvti_theme_ppt <- function(base_size = HVTI_THEME_PPT_BASE_SIZE,
                           base_family = "",
                           header_family = NULL,
                           base_line_size = base_size / 22,
                           base_rect_size = base_size / 22,
                           ink = "black",
                           paper = "transparent",
                           accent = "#3366FF") {
  theme_grey(base_size = base_size,
             base_family = base_family,
             header_family = header_family,
             base_line_size = base_line_size,
             base_rect_size = base_rect_size,
             ink = ink,
             paper = paper,
             accent = accent) %+replace%
    theme(
      plot.background = element_rect(
        fill = 'transparent',
        colour = 'transparent',
        linewidth = 2
      ),
      strip.text = element_text(size = base_size/2),
      panel.border = element_blank(),
      panel.grid.major.x =  element_blank(),
      panel.grid.major.y =  element_blank(),
      panel.grid.minor =  element_blank()
    )
}

#' @export
#' @rdname hvti_theme_ppt
theme_ppt <- hvti_theme_ppt