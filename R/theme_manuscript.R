#' Theme for generating manuscript figures
#' 
#' @param base_size the base font size
#' @param base_family base font family
#' 
#' @seealso \code{theme_set} \code{theme_grey} \code{\link{theme_ppt}}
#'
#' @export theme_manuscript theme_man
#' @aliases theme_man theme_manuscript
#' @import ggplot2

theme_manuscript <- function(base_size = 12, base_family = "") {
  theme_grey(base_size = base_size, base_family = base_family) %+replace% 
    theme(
      strip.text = element_text(size = 10),
      legend.position = "none",
      legend.key = element_blank(),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      legend.title = element_blank(),
      panel.background = element_blank(),
      panel.border = element_blank(),
      axis.line.x = element_line(color = "black", size = 0.8),
      axis.line.y = element_line(color = "black", size = 0.8),
      axis.text = element_text(size = 12, color = "black"),
      plot.margin=unit(c(0.65,0.65,0.25,0.25),"cm"), #AML added. Add to template?
      axis.title = element_text(size = 15)
    )
}
theme_man <- theme_manuscript
#===========================================================================================
# For reference, this is the theme_grey definition, which has most, if not all possible
# theme elements.
# 
# theme_grey
# function (base_size = 12, base_family = "") {
#   theme(line = element_line(colour = "black", size = 0.5, linetype = 1, 
#                             lineend = "butt"), 
#         rect = element_rect(fill = "white", colour = "black", size = 0.5, linetype = 1), 
#         text = element_text(family = base_family, face = "plain", colour = "black", 
#                             size = base_size, hjust = 0.5, vjust = 0.5, angle = 0, 
#                             lineheight = 0.9), 
#         
#         axis.text = element_text(size = rel(0.8),                                                                                                                                                          colour = "grey50"), strip.text = element_text(size = rel(0.8)), 
#         axis.line = element_blank(), 
#         axis.text.x = element_text(vjust = 1), 
#         axis.text.y = element_text(hjust = 1), 
#         axis.ticks = element_line(colour = "grey50"), 
#         axis.title.x = element_text(), 
#         axis.title.y = element_text(angle = 90), 
#         axis.ticks.length = unit(0.15, "cm"), 
#         axis.ticks.margin = unit(0.1,"cm"), 
#         
#         legend.background = element_rect(colour = NA), 
#         legend.margin = unit(0.2, "cm"), 
#         legend.key = element_rect(fill = "grey95", colour = "white"), 
#         legend.key.size = unit(1.2, "lines"), 
#         legend.key.height = NULL, 
#         legend.key.width = NULL, 
#         legend.text = element_text(size = rel(0.8)), 
#         legend.text.align = NULL, 
#         legend.title = element_text(size = rel(0.8), face = "bold", hjust = 0), 
#         legend.title.align = NULL, 
#         legend.position = "right", 
#         legend.direction = NULL, 
#         legend.justification = "center", 
#         legend.box = NULL, 
#         
#         panel.background = element_rect(fill = "grey90",colour = NA), 
#         panel.border = element_blank(), 
#         panel.grid.major = element_line(colour = "white"), 
#         panel.grid.minor = element_line(colour = "grey95", size = 0.25), 
#         panel.margin = unit(0.25, "lines"), panel.margin.x = NULL, 
#         panel.margin.y = NULL, 
#         
#         strip.background = element_rect(fill = "grey80", colour = NA), 
#         strip.text.x = element_text(), 
#         strip.text.y = element_text(angle = -90), 
#         
#         plot.background = element_rect(colour = "white"), 
#         plot.title = element_text(size = rel(1.2)), 
#         plot.margin = unit(c(1, 1, 0.5, 0.5), "lines"), complete = TRUE)
# }