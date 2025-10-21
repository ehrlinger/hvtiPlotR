#' Theme for generating powerpoint figures
#'
#' White background with black text.
#'
#' @param base_size the base font size
#' @param base_family base font family
#' @param header_family = NULL,
#' @param base_line_size = base_size / 22,
#' @param base_rect_size = base_size / 22,
#' @param ink = "white",
#' @param paper = "transparent",
#' @param accent = "#3366FF"
#' @seealso \code{theme_set} \code{theme_grey} \code{\link{theme_man}}
#'
#' @export theme_dark_ppt
#'
#' @import ggplot2

theme_dark_ppt <- function(base_size = 32,
                           base_family = "",
                           header_family = NULL,
                           base_line_size = base_size / 22,
                           base_rect_size = base_size / 22,
                           ink = "white",
                           paper = "transparent",
                           accent = "#3366FF"){
  theme_grey(
    base_size = base_size,
    base_family = base_family,
    ink = ink,
    paper = paper
  ) %+replace%
    theme(
      plot.background = element_rect(
        fill = 'transparent',
        colour = 'transparent',
        size = 2
      ),
      axis.text  = element_text(size = base_size, color = "white"),
      ## For forest plots, we need smaller y axis text for labels
      axis.line = element_line(color = "white", linewidth = 1),
      strip.text = element_text(size = base_size/2),
      panel.border = element_blank(),
      panel.background = element_rect(
        fill = "black",
        colour = "white",
        size = 1
      ),
      axis.ticks = element_line(colour = "white", linewidth = 1),
      panel.grid.major.x =  element_blank(),
      panel.grid.major.y =  element_blank(),
      panel.grid.minor =  element_blank()
    )
}
  #===========================================================================================
  # For reference, this is the theme_grey definition, which has most, if not all possible
  # theme elements.
  # theme_grey <- function (base_size = 11,
  #                         base_family = "",
  #                         header_family = NULL,
  #                         base_line_size = base_size / 22,
  #                         base_rect_size = base_size / 22,
  #                         ink = "black",
  #                         paper = "white",
  #                         accent = "#3366FF")
  # {
  #   half_line <- base_size / 2
  #   t <- theme(
  #     line = element_line(
  #       colour = ink,
  #       linewidth = base_line_size,
  #       linetype = 1,
  #       lineend = "butt",
  #       linejoin = "round"
  #     ),
  #     rect = element_rect(
  #       fill = paper,
  #       colour = ink,
  #       linewidth = base_rect_size,
  #       linetype = 1,
  #       linejoin = "round"
  #     ),
  #     text = element_text(
  #       family = base_family,
  #       face = "plain",
  #       colour = ink,
  #       size = base_size,
  #       lineheight = 0.9,
  #       hjust = 0.5,
  #       vjust = 0.5,
  #       angle = 0,
  #       margin = margin(),
  #       debug = FALSE
  #     ),
  #     title = element_text(family = header_family),
  #     spacing = unit(half_line, "pt"),
  #     margins = margin_auto(half_line),
  #     point = element_point(
  #       colour = ink,
  #       shape = 19,
  #       fill = paper,
  #       size = (base_size / 11) * 1.5,
  #       stroke = base_line_size
  #     ),
  #     polygon = element_polygon(
  #       fill = paper,
  #       colour = ink,
  #       linewidth = base_rect_size,
  #       linetype = 1,
  #       linejoin = "round"
  #     ),
  #     geom = element_geom(
  #       ink = ink,
  #       paper = paper,
  #       accent = accent,
  #       linewidth = base_line_size,
  #       borderwidth = base_line_size,
  #       linetype = 1L,
  #       bordertype = 1L,
  #       family = base_family,
  #       fontsize = base_size,
  #       pointsize = (base_size / 11) *
  #         1.5,
  #       pointshape = 19
  #     ),
  #     axis.line = element_blank(),
  #     axis.line.x = NULL,
  #     axis.line.y = NULL,
  #     axis.text = element_text(
  #       size = rel(0.8),
  #       colour = col_mix(ink, paper, 0.302)
  #     ),
  #     axis.text.x = element_text(margin = margin(t = 0.8 *
  #                                                  half_line /
  #                                                  2), vjust = 1),
  #     axis.text.x.top = element_text(margin = margin(b = 0.8 *
  #                                                      half_line /
  #                                                      2), vjust = 0),
  #     axis.text.y = element_text(margin = margin(r = 0.8 *
  #                                                  half_line /
  #                                                  2), hjust = 1),
  #     axis.text.y.right = element_text(margin = margin(l = 0.8 *
  #                                                        half_line /
  #                                                        2), hjust = 0),
  #     axis.text.r = element_text(
  #       margin = margin(l = 0.8 *
  #                         half_line /
  #                         2, r = 0.8 * half_line / 2),
  #       hjust = 0.5
  #     ),
  #     axis.ticks = element_line(colour = col_mix(ink, paper, 0.2)),
  #     axis.ticks.length = rel(0.5),
  #     axis.ticks.length.x = NULL,
  #     axis.ticks.length.x.top = NULL,
  #     axis.ticks.length.x.bottom = NULL,
  #     axis.ticks.length.y = NULL,
  #     axis.ticks.length.y.left = NULL,
  #     axis.ticks.length.y.right = NULL,
  #     axis.minor.ticks.length = rel(0.75),
  #     axis.title.x = element_text(margin = margin(t = half_line /
  #                                                   2), vjust = 1),
  #     axis.title.x.top = element_text(margin = margin(b = half_line / 2), vjust = 0),
  #     axis.title.y = element_text(
  #       angle = 90,
  #       margin = margin(r = half_line /
  #                         2),
  #       vjust = 1
  #     ),
  #     axis.title.y.right = element_text(
  #       angle = -90,
  #       margin = margin(l = half_line /
  #                         2),
  #       vjust = 1
  #     ),
  #     legend.background = element_rect(colour = NA),
  #     legend.spacing = rel(2),
  #     legend.spacing.x = NULL,
  #     legend.spacing.y = NULL,
  #     legend.margin = NULL,
  #     legend.key = NULL,
  #     legend.key.size = unit(1.2, "lines"),
  #     legend.key.height = NULL,
  #     legend.key.width = NULL,
  #     legend.key.spacing = NULL,
  #     legend.text = element_text(size = rel(0.8)),
  #     legend.title = element_text(hjust = 0),
  #     legend.ticks.length = rel(0.2),
  #     legend.position = "right",
  #     legend.direction = NULL,
  #     legend.justification = "center",
  #     legend.box = NULL,
  #     legend.box.margin = margin_auto(0),
  #     legend.box.background = element_blank(),
  #     legend.box.spacing = rel(2),
  #     panel.background = element_rect(fill = col_mix(ink, paper, 0.92), colour = NA),
  #     panel.border = element_blank(),
  #     panel.grid = element_line(colour = paper),
  #     panel.grid.minor = element_line(linewidth = rel(0.5)),
  #     panel.spacing = NULL,
  #     panel.spacing.x = NULL,
  #     panel.spacing.y = NULL,
  #     panel.ontop = FALSE,
  #     strip.background = element_rect(fill = col_mix(ink, paper, 0.85), colour = NA),
  #     strip.clip = "on",
  #     strip.text = element_text(
  #       colour = col_mix(ink, paper, 0.1),
  #       size = rel(0.8),
  #       margin = margin_auto(0.8 *
  #                              half_line)
  #     ),
  #     strip.text.x = NULL,
  #     strip.text.y = element_text(angle = -90),
  #     strip.text.y.left = element_text(angle = 90),
  #     strip.placement = "inside",
  #     strip.placement.x = NULL,
  #     strip.placement.y = NULL,
  #     strip.switch.pad.grid = unit(half_line / 2, "pt"),
  #     strip.switch.pad.wrap = unit(half_line / 2, "pt"),
  #     plot.background = element_rect(colour = paper),
  #     plot.title = element_text(
  #       size = rel(1.2),
  #       hjust = 0,
  #       vjust = 1,
  #       margin = margin(b = half_line)
  #     ),
  #     plot.title.position = "panel",
  #     plot.subtitle = element_text(
  #       hjust = 0,
  #       vjust = 1,
  #       margin = margin(b = half_line)
  #     ),
  #     plot.caption = element_text(
  #       size = rel(0.8),
  #       hjust = 1,
  #       vjust = 1,
  #       margin = margin(t = half_line)
  #     ),
  #     plot.caption.position = "panel",
  #     plot.tag = element_text(
  #       size = rel(1.2),
  #       hjust = 0.5,
  #       vjust = 0.5
  #     ),
  #     plot.tag.position = "topleft",
  #     plot.margin = NULL,
  #     complete = TRUE
  #   )
  #   ggplot_global$theme_all_null %+replace% t
  # }