# Internal shared base for all hvtiPlotR themes
#
# Calls theme_grey() with the standard parameter set used by every theme.
# Each public theme function calls this, then applies %+replace% theme(...)
# for its own style overrides.

hvti_theme_base <- function(base_size,
                             base_family,
                             header_family,
                             base_line_size,
                             base_rect_size,
                             ink,
                             paper,
                             accent) {
  theme_grey(
    base_size      = base_size,
    base_family    = base_family,
    header_family  = header_family,
    base_line_size = base_line_size,
    base_rect_size = base_rect_size,
    ink            = ink,
    paper          = paper,
    accent         = accent
  )
}
