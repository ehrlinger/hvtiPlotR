# Internal shared body for hv_theme_dark_ppt() and hv_theme_light_ppt().
#
# The two public PPT themes differ only in foreground (text / axis line /
# tick) colour and in the panel.background fill + border colour. All other
# element styling and scaling logic is identical, so we keep one source of
# truth here and expose thin public wrappers per variant.
#
# For the light variant, panel fill is transparent so the PPT slide template
# background shows through (white on a light template, a gradient on an
# AATS-style template). The black border still delimits the panel rectangle;
# the hv_ph_location() / save_ppt(panel_box=) workflow anchors that rectangle
# at a fixed slide position. Callers can restore an opaque white panel with
# `+ theme(panel.background = element_rect(fill = "white"))`.

hv_theme_ppt_impl <- function(variant,
                              base_size,
                              base_family,
                              header_family,
                              base_line_size,
                              base_rect_size,
                              ink,
                              paper,
                              accent,
                              bold,
                              mono_y,
                              title_size) {
  variant <- match.arg(variant, c("dark", "light"))

  half_line  <- base_size / 2
  face_axis  <- if (isTRUE(bold)) "bold" else "plain"
  title_size <- if (is.null(title_size)) base_size else title_size
  y_family   <- if (isTRUE(mono_y)) "mono" else base_family

  fg_colour    <- if (variant == "dark") "white" else "black"
  panel_fill   <- if (variant == "dark") "black" else "transparent"
  panel_border <- if (variant == "dark") "white" else "black"

  hv_theme_base(
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
      axis.text          = element_text(
        size   = base_size,
        colour = fg_colour,
        face   = face_axis
      ),
      axis.text.x        = element_text(
        margin = margin(t = half_line)
      ),
      axis.text.y        = element_text(
        family = y_family,
        margin = margin(r = half_line),
        hjust  = 1
      ),
      axis.title.x       = element_text(
        size   = title_size,
        face   = face_axis,
        margin = margin(t = 1.5 * half_line)
      ),
      axis.title.y       = element_text(
        size   = title_size,
        angle  = 90,
        face   = face_axis,
        margin = margin(r = 1.5 * half_line)
      ),
      axis.line          = element_line(colour = fg_colour, linewidth = 1),
      strip.text         = element_text(size = base_size / 2),
      panel.border       = element_blank(),
      panel.background   = element_rect(
        fill      = panel_fill,
        colour    = panel_border,
        linewidth = 1
      ),
      axis.ticks         = element_line(colour = fg_colour, linewidth = 1),
      axis.ticks.length  = unit(-half_line / 2, "pt"),
      panel.grid.major.x = element_blank(),
      panel.grid.major.y = element_blank(),
      panel.grid.minor   = element_blank(),
      legend.position    = "none",
      plot.margin        = unit(c(0, 0, 0, 0), "inches")
    )
}
