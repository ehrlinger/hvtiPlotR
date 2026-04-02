#' hvtiPlotR Theme Generic
#'
#' Provides a single entry point for obtaining any supported hvtiPlotR theme.
#'
#' @param style Character keyword identifying the theme style. Supported values:
#'   - `"ppt"` / `"dark_ppt"` — dark background, white text
#'     ([hv_theme_dark_ppt()]); default PPT theme
#'   - `"light_ppt"` — light/transparent background, black text
#'     ([hv_theme_light_ppt()])
#'   - `"manuscript"` — clean white background for journal figures
#'     ([hv_theme_manuscript()])
#'   - `"poster"` — medium font for conference posters ([hv_theme_poster()])
#' @param ... Additional parameters forwarded to the underlying theme
#'   constructor.
#'
#' @return A [ggplot2::theme()] object.
#'
#' @examples
#' library(ggplot2)
#' p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) + geom_point()
#'
#' p + hv_theme("manuscript")   # journal figure
#' p + hv_theme("poster")       # conference poster
#' p + hv_theme("light_ppt")    # light-background slide
#'
#' \dontrun{
#' # Dark PPT — best viewed against a dark slide background
#' p + hv_theme("dark_ppt") +
#'   ggplot2::theme(plot.background = ggplot2::element_rect(fill = "navy"))
#' }
#'
#' @export
hv_theme <- function(style = c("ppt", "dark_ppt", "light_ppt",
                                  "manuscript", "poster"), ...) {
  style <- match.arg(style)
  class(style) <- c(paste0("hv_theme_", style), class(style))
  UseMethod("hv_theme", style)
}

#' @export
hv_theme.default <- function(style, ...) {
  stop(sprintf("Unsupported hvtiPlotR theme style: %s", style), call. = FALSE)
}

#' @export
hv_theme.hv_theme_ppt <- function(style, ...) {
  hv_theme_dark_ppt(...)
}

#' @export
hv_theme.hv_theme_dark_ppt <- function(style, ...) {
  hv_theme_dark_ppt(...)
}

#' @export
hv_theme.hv_theme_light_ppt <- function(style, ...) {
  hv_theme_light_ppt(...)
}

#' @export
hv_theme.hv_theme_manuscript <- function(style, ...) {
  hv_theme_manuscript(...)
}

#' @export
hv_theme.hv_theme_poster <- function(style, ...) {
  hv_theme_poster(...)
}
