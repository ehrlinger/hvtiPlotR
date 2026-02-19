#' hvtiPlotR Theme Generic
#'
#' Provides a single entry point for obtaining any supported hvtiPlotR theme.
#'
#' @param style Character keyword identifying the theme style. Supported values are
#'   "ppt", "dark_ppt", "manuscript", and "poster".
#' @param ... Additional parameters forwarded to the underlying theme constructor.
#'
#' @return A ggplot2 theme object.
#' @export
hvti_theme <- function(style = c("ppt", "dark_ppt", "manuscript", "poster"), ...) {
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
  hvti_theme_ppt(...)
}

#' @export
hvti_theme.hvti_theme_dark_ppt <- function(style, ...) {
  hvti_theme_dark_ppt(...)
}

#' @export
hvti_theme.hvti_theme_manuscript <- function(style, ...) {
  hvti_theme_manuscript(...)
}

#' @export
hvti_theme.hvti_theme_poster <- function(style, ...) {
  hvti_theme_poster(...)
}

#' hvtiPlotR Plot Generic
#'
#' Provides a single entry point for generating hvtiPlotR plots.
#'
#' @param type Character keyword identifying the plot type. Currently only
#'   "mirror_histogram" is supported.
#' @param ... Additional arguments passed to the underlying plotting function.
#'
#' @return The object produced by the requested plotting function (e.g., a list
#'   containing plot elements and diagnostics).
#' @export
hvti_plot <- function(type = c("mirror_histogram"), ...) {
  type <- match.arg(type)
  class(type) <- c(paste0("hvti_plot_", type), class(type))
  UseMethod("hvti_plot", type)
}

#' @export
hvti_plot.default <- function(type, ...) {
  stop(sprintf("Unsupported hvtiPlotR plot type: %s", type), call. = FALSE)
}

#' @export
hvti_plot.hvti_plot_mirror_histogram <- function(type, ...) {
  plot_mirror_histogram(...)
}
