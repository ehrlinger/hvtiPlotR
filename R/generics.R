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

#' hvtiPlotR Plot Generic
#'
#' Provides a single entry point for generating hvtiPlotR plots.
#'
#' @param type Character keyword identifying the plot type. Supported values:
#'   `"mirror_histogram"`, `"stacked_histogram"`, `"covariate_balance"`,
#'   `"goodness_followup"`, `"survival_curve"`, `"upset"`,
#'   `"nonparametric_curve"`, `"nonparametric_ordinal"`.
#' @param ... Additional arguments passed to the underlying plotting function.
#'
#' @return The object produced by the requested plotting function.
#' @export
hvti_plot <- function(type = c("mirror_histogram", "stacked_histogram",
                               "covariate_balance", "goodness_followup",
                               "survival_curve", "upset", "sankey",
                               "trends", "spaghetti", "longitudinal_counts",
                               "nonparametric_curve",
                               "nonparametric_ordinal"), ...) {
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
  mirror_histogram(...)
}

#' @export
hvti_plot.hvti_plot_stacked_histogram <- function(type, ...) {
  stacked_histogram(...)
}

#' @export
hvti_plot.hvti_plot_covariate_balance <- function(type, ...) {
  covariate_balance(...)
}

#' @export
hvti_plot.hvti_plot_goodness_followup <- function(type, ...) {
  goodness_followup(...)
}

#' @export
hvti_plot.hvti_plot_survival_curve <- function(type, ...) {
  survival_curve(...)
}

#' @export
hvti_plot.hvti_plot_upset <- function(type, ...) {
  upset_plot(...)
}

#' @export
hvti_plot.hvti_plot_sankey <- function(type, ...) {
  sankey_plot(...)
}

#' @export
hvti_plot.hvti_plot_trends <- function(type, ...) {
  trends_plot(...)
}

#' @export
hvti_plot.hvti_plot_spaghetti <- function(type, ...) {
  spaghetti_plot(...)
}

#' @export
hvti_plot.hvti_plot_longitudinal_counts <- function(type, ...) {
  longitudinal_counts_plot(...)
}

#' @export
hvti_plot.hvti_plot_nonparametric_curve <- function(type, ...) {
  nonparametric_curve_plot(...)
}

#' @export
hvti_plot.hvti_plot_nonparametric_ordinal <- function(type, ...) {
  nonparametric_ordinal_plot(...)
}
