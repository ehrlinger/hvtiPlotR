#' hvtiPlotR Theme Generic
#'
#' Provides a single entry point for obtaining any supported hvtiPlotR theme.
#'
#' @param style Character keyword identifying the theme style. Supported values:
#'   - `"ppt"` / `"dark_ppt"` — dark background, white text
#'     ([hvti_theme_dark_ppt()]); default PPT theme
#'   - `"light_ppt"` — light/transparent background, black text
#'     ([hvti_theme_light_ppt()])
#'   - `"manuscript"` — clean white background for journal figures
#'     ([hvti_theme_manuscript()])
#'   - `"poster"` — medium font for conference posters ([hvti_theme_poster()])
#' @param ... Additional parameters forwarded to the underlying theme
#'   constructor.
#'
#' @return A [ggplot2::theme()] object.
#'
#' @examples
#' library(ggplot2)
#' p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) + geom_point()
#'
#' p + hvti_theme("manuscript")   # journal figure
#' p + hvti_theme("poster")       # conference poster
#' p + hvti_theme("light_ppt")    # light-background slide
#'
#' \dontrun{
#' # Dark PPT — best viewed against a dark slide background
#' p + hvti_theme("dark_ppt") +
#'   ggplot2::theme(plot.background = ggplot2::element_rect(fill = "navy"))
#' }
#'
#' @export
hvti_theme <- function(style = c("ppt", "dark_ppt", "light_ppt",
                                  "manuscript", "poster"), ...) {
  style <- match.arg(style)
  class(style) <- c(paste0("hvti_theme_", style), class(style))
  UseMethod("hvti_theme", style)
}

#' @export
hvti_theme.default <- function(style, ...) {
  stop(sprintf("Unsupported hvtiPlotR theme style: %s", style), call. = FALSE)
}

#' @export
hvti_theme.hvti_theme_ppt <- function(style, ...) {
  hvti_theme_dark_ppt(...)
}

#' @export
hvti_theme.hvti_theme_dark_ppt <- function(style, ...) {
  hvti_theme_dark_ppt(...)
}

#' @export
hvti_theme.hvti_theme_light_ppt <- function(style, ...) {
  hvti_theme_light_ppt(...)
}

#' @export
hvti_theme.hvti_theme_manuscript <- function(style, ...) {
  hvti_theme_manuscript(...)
}

#' @export
hvti_theme.hvti_theme_poster <- function(style, ...) {
  hvti_theme_poster(...)
}
