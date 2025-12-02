#' Theme for generating manuscript figures
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
#'
#' @seealso \code{theme_set} \code{theme_grey} \code{\link{theme_ppt}}
#'
#' @export theme_manuscript theme_man
#' @aliases theme_man theme_manuscript
#' @import ggplot2

theme_manuscript <- function(base_size = 12,
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
      strip.text = element_text(size = 10),
      legend.position = "none",
      legend.key = element_blank(),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      legend.title = element_blank(),
      panel.background = element_blank(),
      panel.border = element_blank(),
      axis.line.x = element_line(color = "black", linewidth = 0.8),
      axis.line.y = element_line(color = "black", linewidth = 0.8),
      axis.text = element_text(size = base_size, color = "black"),
      plot.margin = unit(c(0.65, 0.65, 0.25, 0.25), "cm"),
      #AML added. Add to template?
      axis.title = element_text(size = base_size)
    )
}
theme_man <- theme_manuscript
#===========================================================================================
# For reference, this is the theme_grey definition, which has most, if not all possible
# theme elements.
#
