# eda-interactive.R
#
# Hover labels for the categorical EDA panels. EDA pages draw no legend and no
# direct labels, so the panels stay legible; in an HTML report a reader hovers
# a bar to see its category, bin and count instead. ggiraph draws the same
# ggplot as SVG, so the page keeps the house theme, and its interactive geoms
# draw as plain geoms on a static device, so PNG and PDF output is unchanged.
# ---------------------------------------------------------------------------

# Computed variables read inside after_stat() in plot.hv_eda().
utils::globalVariables(c("fill", "count"))

# Resolve `interactive`: NULL means "HTML output, and ggiraph is installed".
.eda_interactive <- function(interactive) {
  if (is.null(interactive)) {
    return(requireNamespace("ggiraph", quietly = TRUE) &&
             requireNamespace("knitr", quietly = TRUE) &&
             isTRUE(knitr::is_html_output()))
  }
  if (!is.logical(interactive) || length(interactive) != 1L || is.na(interactive)) {
    stop("`interactive` must be NULL, TRUE or FALSE.", call. = FALSE)
  }
  if (interactive && !requireNamespace("ggiraph", quietly = TRUE)) {
    stop("`interactive = TRUE` needs the ggiraph package: install.packages(\"ggiraph\").",
         call. = FALSE)
  }
  interactive
}

# Tooltips for the bars stat_count() made, one per (bin, category) bar:
# "<category>\n<bin>: <percent> (<n> of <bin total>)" for a percent panel,
# "<category>\n<bin>: <n> (<percent>)" for a count panel. Computed after the
# stat, because bars are grouped by category across bins, so a per-row
# tooltip would not be constant within a group and stat_count() would drop
# it. `x` there is the bar's position, so `x_levels` names it.
.eda_tooltips <- function(category, x, count, x_levels, show_percent) {
  category <- ifelse(is.na(category), "(Missing)", as.character(category))
  bin      <- x_levels[as.integer(x)]
  n_bin    <- stats::ave(count, x, FUN = sum)
  pct      <- sprintf("%.1f%%", 100 * count / n_bin)
  value    <- if (show_percent) sprintf("%s (%d of %d)", pct, count, n_bin) else
    sprintf("%d (%s)", count, pct)
  paste0(category, "\n", bin, ": ", value)
}


#' Render a plot or page as an interactive HTML widget
#'
#' Wraps [ggiraph::girafe()] for EDA pages drawn with `interactive = TRUE`
#' (see [plot.hv_eda()]), so hovering a bar shows its tooltip.
#'
#' **No fonts are embedded.** By default ggiraph embeds its font files in
#' the widget, which made one 8-panel page 8.6 MB instead of 0.4 MB. Here
#' text is set in Arial (or the nearest system sans serif) and the browser
#' draws it in the reader's own copy. Saved PNG and PDF output is unaffected.
#'
#' @param x A ggplot or patchwork object.
#' @param width,height Size of the drawing in inches. Default 6.5 by 9, the
#'   printed page.
#' @param ... Passed to [ggiraph::girafe()], for example `options`.
#'
#' @return An htmlwidget of class `girafe`. Printed in a knitr or Quarto HTML
#'   document, it is drawn in place.
#'
#' @seealso [plot.hv_eda()], [plot.hv_eda_pages()]
#'
#' @examples
#' if (requireNamespace("ggiraph", quietly = TRUE)) {
#'   dta <- sample_eda_data(n = 300, seed = 42)
#'   pages <- plot(hv_eda_pages(dta, section = "percent"),
#'                 ncol = 2, nrow = 2, interactive = TRUE)
#'   widget <- hv_girafe(pages[[1]], width = 6.5, height = 6)
#'   class(widget)
#' }
#' @export
hv_girafe <- function(x, width = 6.5, height = 9, ...) {
  if (!requireNamespace("ggiraph", quietly = TRUE)) {
    stop("hv_girafe() needs the ggiraph package: install.packages(\"ggiraph\").",
         call. = FALSE)
  }
  # ggiraph imports gdtools, so it is installed whenever ggiraph is.
  fonts <- gdtools::font_set_auto()
  fonts$dependencies <- list()
  ggiraph::girafe(ggobj = x, width_svg = width, height_svg = height,
                  font_set = fonts, ...)
}
