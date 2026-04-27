#' hvtiPlotR ggplot2 themes
#'
#' Drop-in replacements for [ggplot2::theme_bw()] and friends, carrying the
#' Cardiovascular Outcomes, Registries and Research (CORR) house style for
#' four publication contexts:
#'
#' * `theme_hv_manuscript()` - clean white background for journal figures
#' * `theme_hv_poster()` - medium-font theme with visible axis lines for posters
#' * `theme_hv_ppt_dark()` - dark panel background, white text, large font
#' * `theme_hv_ppt_light()` - light/transparent panel background, black text
#'
#' Each theme follows the `theme_bw()` contract: pass `base_size` /
#' `base_family` to control global typography, then chain a `+ theme(...)`
#' call to override anything else. Additionally, any extra named argument is
#' forwarded straight into a final [ggplot2::theme()] call so callers can
#' tweak elements inline:
#'
#' ```
#' theme_hv_manuscript(legend.position = "right")
#' theme_hv_ppt_dark(axis.text.y = element_text(family = "mono"))
#' ```
#'
#' Caller-supplied elements override the hvtiPlotR defaults.
#'
#' @param base_size      Base font size in points.
#' @param base_family    Base font family. Default `""` (device default).
#' @param header_family  Font family for headers, or `NULL` to inherit
#'   `base_family`. Default `NULL`.
#' @param base_line_size Line size used for axis lines and borders.
#'   Default `base_size / 22`.
#' @param base_rect_size Rectangle border size. Default `base_size / 22`.
#' @param ink            Foreground (text and line) colour.
#' @param paper          Background colour.
#' @param accent         Accent colour used by some `theme_grey()` elements.
#'   Default `"#3366FF"`.
#' @param ...            Additional named theme elements forwarded to a final
#'   [ggplot2::theme()] call. Use this to override any theme element from the
#'   call site, e.g. `legend.position = "right"`.
#'
#' @return A [ggplot2::theme()] object.
#'
#' @name hvtiPlotR-themes
#' @import ggplot2
NULL

# Internal: build the theme_grey() base shared by all four public themes.
# The arg signature matches modern ggplot2's theme_grey().
.hv_base <- function(base_size, base_family, header_family,
                     base_line_size, base_rect_size,
                     ink, paper, accent) {
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

# ----------------------------------------------------------------------------
# theme_hv_manuscript
# ----------------------------------------------------------------------------

#' @rdname hvtiPlotR-themes
#' @export
theme_hv_manuscript <- function(base_size      = 12,
                                base_family    = "",
                                header_family  = NULL,
                                base_line_size = base_size / 22,
                                base_rect_size = base_size / 22,
                                ink            = "black",
                                paper          = "white",
                                accent         = "#3366FF",
                                ...) {
  base <- .hv_base(base_size, base_family, header_family,
                   base_line_size, base_rect_size,
                   ink, paper, accent) %+replace%
    theme(
      strip.text       = element_text(size = 10),
      legend.position  = "none",
      legend.key       = element_blank(),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      legend.title     = element_blank(),
      panel.background = element_blank(),
      panel.border     = element_blank(),
      axis.line.x      = element_line(colour = "black", linewidth = 0.8),
      axis.line.y      = element_line(colour = "black", linewidth = 0.8),
      axis.text        = element_text(size = base_size, colour = "black"),
      plot.margin      = unit(c(0.65, 0.65, 0.25, 0.25), "cm"),
      axis.title       = element_text(size = base_size)
    )
  if (...length() > 0L) base <- base %+replace% theme(...)
  base
}

# ----------------------------------------------------------------------------
# theme_hv_poster
# ----------------------------------------------------------------------------

#' @rdname hvtiPlotR-themes
#' @export
theme_hv_poster <- function(base_size      = 16,
                            base_family    = "",
                            header_family  = NULL,
                            base_line_size = base_size / 22,
                            base_rect_size = base_size / 22,
                            ink            = "black",
                            paper          = "white",
                            accent         = "#3366FF",
                            ...) {
  base <- .hv_base(base_size, base_family, header_family,
                   base_line_size, base_rect_size,
                   ink, paper, accent) %+replace%
    theme(
      plot.background    = element_rect(fill = "transparent",
                                        colour = "transparent",
                                        linewidth = 2),
      axis.text          = element_text(size = base_size, colour = "black"),
      axis.line          = element_line(colour = "black", linewidth = 1),
      strip.text         = element_text(size = 8),
      panel.border       = element_blank(),
      panel.background   = element_rect(fill = "white",
                                        colour = "black",
                                        linewidth = 1),
      axis.ticks         = element_line(colour = "black", linewidth = 1),
      panel.grid.major.x = element_blank(),
      panel.grid.major.y = element_blank(),
      panel.grid.minor   = element_blank()
    )
  if (...length() > 0L) base <- base %+replace% theme(...)
  base
}

# ----------------------------------------------------------------------------
# theme_hv_ppt_dark  (default PPT theme)
# ----------------------------------------------------------------------------

#' @rdname hvtiPlotR-themes
#' @details
#' `theme_hv_ppt_dark()` is the default PPT theme: a black panel with white
#' text suited to dark slide backgrounds. Use [theme_hv_ppt_light()] when the
#' slide template is light. Both PPT themes hide the legend by default --
#' override with `legend.position = "right"` (or chain `+ theme(...)`).
#'
#' Margins on axis text/title are scaled from `base_size` via the standard
#' `half_line = base_size / 2` convention, so spacing stays proportional when
#' `base_size` changes.
#' @export
theme_hv_ppt_dark <- function(base_size      = 32,
                              base_family    = "",
                              header_family  = NULL,
                              base_line_size = base_size / 22,
                              base_rect_size = base_size / 22,
                              ink            = "white",
                              paper          = "transparent",
                              accent         = "#3366FF",
                              ...) {
  half_line <- base_size / 2
  base <- .hv_base(base_size, base_family, header_family,
                   base_line_size, base_rect_size,
                   ink, paper, accent) %+replace%
    theme(
      plot.background    = element_rect(fill = "transparent",
                                        colour = "transparent",
                                        linewidth = 2),
      axis.text          = element_text(size = base_size, colour = "white"),
      axis.text.x        = element_text(margin = margin(t = half_line)),
      axis.text.y        = element_text(margin = margin(r = half_line),
                                        hjust  = 1),
      axis.title.x       = element_text(margin = margin(t = 1.5 * half_line)),
      axis.title.y       = element_text(angle  = 90,
                                        margin = margin(r = 1.5 * half_line)),
      axis.line          = element_line(colour = "white", linewidth = 1),
      strip.text         = element_text(size = base_size / 2),
      panel.border       = element_blank(),
      panel.background   = element_rect(fill = "black",
                                        colour = "white",
                                        linewidth = 1),
      axis.ticks         = element_line(colour = "white", linewidth = 1),
      axis.ticks.length  = unit(-half_line / 2, "pt"),
      panel.grid.major.x = element_blank(),
      panel.grid.major.y = element_blank(),
      panel.grid.minor   = element_blank(),
      legend.position    = "none",
      plot.margin        = unit(c(0, 0, 0, 0), "inches")
    )
  if (...length() > 0L) base <- base %+replace% theme(...)
  base
}

# ----------------------------------------------------------------------------
# theme_hv_ppt_light
# ----------------------------------------------------------------------------

#' @rdname hvtiPlotR-themes
#' @export
theme_hv_ppt_light <- function(base_size      = 32,
                               base_family    = "",
                               header_family  = NULL,
                               base_line_size = base_size / 22,
                               base_rect_size = base_size / 22,
                               ink            = "black",
                               paper          = "transparent",
                               accent         = "#3366FF",
                               ...) {
  half_line <- base_size / 2
  base <- .hv_base(base_size, base_family, header_family,
                   base_line_size, base_rect_size,
                   ink, paper, accent) %+replace%
    theme(
      plot.background    = element_rect(fill = "transparent",
                                        colour = "transparent",
                                        linewidth = 2),
      axis.text          = element_text(size = base_size, colour = "black"),
      axis.text.x        = element_text(margin = margin(t = half_line)),
      axis.text.y        = element_text(margin = margin(r = half_line),
                                        hjust  = 1),
      axis.title.x       = element_text(margin = margin(t = 1.5 * half_line)),
      axis.title.y       = element_text(angle  = 90,
                                        margin = margin(r = 1.5 * half_line)),
      axis.line          = element_line(colour = "black", linewidth = 1),
      strip.text         = element_text(size = base_size / 2),
      panel.border       = element_blank(),
      # Transparent panel fill so the PPT slide template background shows
      # through; the black border still delimits the panel rectangle, and the
      # `hv_ph_location()` / `save_ppt(panel_box=)` workflow anchors that
      # rectangle at a fixed slide position. Use
      # `+ theme(panel.background = element_rect(fill = "white"))` to restore
      # an opaque white panel for templates that need it.
      panel.background   = element_rect(fill = "transparent",
                                        colour = "black",
                                        linewidth = 1),
      axis.ticks         = element_line(colour = "black", linewidth = 1),
      axis.ticks.length  = unit(-half_line / 2, "pt"),
      panel.grid.major.x = element_blank(),
      panel.grid.major.y = element_blank(),
      panel.grid.minor   = element_blank(),
      legend.position    = "none",
      plot.margin        = unit(c(0, 0, 0, 0), "inches")
    )
  if (...length() > 0L) base <- base %+replace% theme(...)
  base
}

# ----------------------------------------------------------------------------
# Deprecated aliases (v2.x)
#
# Old names continue to work but emit a one-shot deprecation warning. Remove
# in a future major release.
# ----------------------------------------------------------------------------

.hv_theme_deprecated <- function(old, new) {
  .Deprecated(new = new, old = old,
              package = "hvtiPlotR",
              msg = sprintf(
                "'%s()' is deprecated. Use '%s()' instead.", old, new))
}

#' @rdname hvtiPlotR-themes
#' @export
hv_theme_manuscript <- function(...) {
  .hv_theme_deprecated("hv_theme_manuscript", "theme_hv_manuscript")
  theme_hv_manuscript(...)
}

#' @rdname hvtiPlotR-themes
#' @export
theme_manuscript <- function(...) {
  .hv_theme_deprecated("theme_manuscript", "theme_hv_manuscript")
  theme_hv_manuscript(...)
}

#' @rdname hvtiPlotR-themes
#' @export
theme_man <- function(...) {
  .hv_theme_deprecated("theme_man", "theme_hv_manuscript")
  theme_hv_manuscript(...)
}

#' @rdname hvtiPlotR-themes
#' @export
hv_theme_poster <- function(...) {
  .hv_theme_deprecated("hv_theme_poster", "theme_hv_poster")
  theme_hv_poster(...)
}

#' @rdname hvtiPlotR-themes
#' @export
theme_poster <- function(...) {
  .hv_theme_deprecated("theme_poster", "theme_hv_poster")
  theme_hv_poster(...)
}

#' @rdname hvtiPlotR-themes
#' @export
hv_theme_dark_ppt <- function(...) {
  .hv_theme_deprecated("hv_theme_dark_ppt", "theme_hv_ppt_dark")
  theme_hv_ppt_dark(...)
}

#' @rdname hvtiPlotR-themes
#' @export
theme_dark_ppt <- function(...) {
  .hv_theme_deprecated("theme_dark_ppt", "theme_hv_ppt_dark")
  theme_hv_ppt_dark(...)
}

#' @rdname hvtiPlotR-themes
#' @export
hv_theme_ppt <- function(...) {
  .hv_theme_deprecated("hv_theme_ppt", "theme_hv_ppt_dark")
  theme_hv_ppt_dark(...)
}

#' @rdname hvtiPlotR-themes
#' @export
theme_ppt <- function(...) {
  .hv_theme_deprecated("theme_ppt", "theme_hv_ppt_dark")
  theme_hv_ppt_dark(...)
}

#' @rdname hvtiPlotR-themes
#' @export
hv_theme_light_ppt <- function(...) {
  .hv_theme_deprecated("hv_theme_light_ppt", "theme_hv_ppt_light")
  theme_hv_ppt_light(...)
}

#' @rdname hvtiPlotR-themes
#' @export
theme_light_ppt <- function(...) {
  .hv_theme_deprecated("theme_light_ppt", "theme_hv_ppt_light")
  theme_hv_ppt_light(...)
}
