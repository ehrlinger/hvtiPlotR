# ------------------------------------------------------------------------
# Arial font fallback for theme_hv_ppt_dark() / theme_hv_ppt_light()
# ------------------------------------------------------------------------
#
# CORR house style calls for Arial on PPT slides, so both theme_hv_ppt_dark()
# and theme_hv_ppt_light() default base_family to "Arial". Arial is not one
# of the 14 standard PostScript fonts, so R's own postscript()/pdf() devices
# -- which resolve family names through a small, closed metrics table
# (grDevices::postscriptFonts()/pdfFonts()) rather than the OS font manager
# -- cannot draw it and error partway through rendering ("invalid font
# type"). Devices that resolve fonts through the OS font manager instead
# (quartz, cairo, ragg, RStudio's graphics device) are unaffected: they draw
# Arial directly when it's installed. macOS quartz in particular renders it
# correctly even though `postscriptFonts("Arial")` is NULL there, so
# registry membership can't be used as a proxy for "can this device draw
# Arial" -- we ask the ACTIVE device directly instead (see
# `.hv_family_resolves()`).
#
# Resolution happens at DRAW time, not at theme-construction time.
# theme_hv_ppt_dark()/light() are typically called well before the output
# device is opened (build the plot, then ggsave()/postscript() it later,
# possibly in a different call or even a different session), so nothing is
# known about the eventual device when the theme object is built. The theme
# constructors only *tag* the plot with which font family was requested;
# the actual availability check happens inside print()/grid.draw(), right
# before control passes to ggplot2's own drawing code, via the standard
# ggplot_add()/print()/grid.draw() S3 extension points. No global font
# registry (postscriptFonts()/pdfFonts()) is touched, so nothing outside
# the one plot being drawn is ever mutated.

# Session-local flag so the fallback explanation prints at most once.
.hv_font_fallback_env <- new.env(parent = emptyenv())
.hv_font_fallback_env$warned <- FALSE

.hv_warn_font_fallback_once <- function() {
  if (isTRUE(.hv_font_fallback_env$warned)) {
    return(invisible())
  }
  .hv_font_fallback_env$warned <- TRUE
  message(
    "hvtiPlotR: the active graphics device cannot resolve the 'Arial' ",
    "font family (common on postscript()/pdf() output, e.g. headless ",
    "Linux rendering); falling back to 'Helvetica', a metrically ",
    "compatible substitute, for this plot. Devices that resolve system ",
    "fonts directly (quartz, cairo, RStudio's graphics device) are ",
    "unaffected and continue to use real Arial where it is installed. ",
    "This message prints once per session."
  )
  invisible()
}

# Ask whether the currently active graphics device can resolve `family`,
# purely by inspecting device state -- never by drawing/measuring anything
# on the live device. An earlier version of this probe pushed and popped a
# throwaway grid viewport to measure string width, which is safe on
# ordinary devices but corrupts recording devices with a fixed page budget
# (rvg::dml()'s PowerPoint device errors "only supports one page" if
# anything is drawn to it before the real content). Inspecting device state
# has no such side effect.
#
# R's own postscript()/pdf() devices are the only ones whose font
# resolution is governed by grDevices::postscriptFonts()/pdfFonts() -- a
# small, closed table -- so that registry is authoritative only for them.
# Every other device (quartz, cairo_pdf/cairo_ps, ragg/agg raster devices,
# RStudio's graphics device, rvg's PowerPoint recording device, ...)
# resolves font families through the OS font manager directly and never
# consults these tables, so the request is trusted as-is.
.hv_family_resolves <- function(family) {
  dev_name <- names(grDevices::dev.cur())
  if (is.null(dev_name) || identical(dev_name, "null device")) {
    return(TRUE)
  }
  if (identical(dev_name, "pdf")) {
    return(family %in% names(grDevices::pdfFonts()))
  }
  if (identical(dev_name, "postscript")) {
    return(family %in% names(grDevices::postscriptFonts()))
  }
  TRUE
}

# Tag `theme_obj` with which of its family arguments need a fallback check
# at draw time. Called only from theme_hv_ppt_dark()/theme_hv_ppt_light();
# theme_hv_manuscript()/theme_hv_poster() default base_family to "" (device
# default) and never call this.
.hv_tag_ppt_font_requests <- function(theme_obj, base_family, header_family) {
  requests <- character(0)
  if (identical(base_family, "Arial")) requests["text"] <- "Arial"
  if (identical(header_family, "Arial")) requests["title"] <- "Arial"
  if (length(requests) == 0L) {
    return(theme_obj)
  }
  attr(theme_obj, "hv_font_requests") <- requests
  class(theme_obj) <- union("hv_ppt_theme", class(theme_obj))
  theme_obj
}

# Swap any tracked "Arial" request for "Helvetica" on this one plot when the
# active device can't resolve Arial. `requests` is a named character vector
# mapping a theme root element ("text" and/or "title") to the family it
# requested, set by .hv_tag_ppt_font_requests() and carried onto the plot by
# ggplot_add.hv_ppt_theme().
.hv_resolve_ppt_family <- function(x) {
  requests <- attr(x, "hv_font_requests", exact = TRUE)
  if (is.null(requests)) {
    return(x)
  }
  needs_fallback <- !vapply(requests, .hv_family_resolves, logical(1))
  if (!any(needs_fallback)) {
    return(x)
  }
  .hv_warn_font_fallback_once()
  fallback_roots <- names(requests)[needs_fallback]
  overrides <- lapply(fallback_roots, function(nm) {
    ggplot2::element_text(family = "Helvetica")
  })
  names(overrides) <- fallback_roots

  # ggplot2 >= 4.0 resolves a text geom's `family` through the theme's `geom`
  # element (element_geom()), which theme_grey() seeds from base_family
  # alongside `text`. Patching `text` alone leaves geom_text() and
  # annotate("text", ...) still asking the device for Arial, and on
  # postscript()/pdf() that is fatal ("invalid font type"), not merely ugly.
  # House style labels series by annotation rather than by a legend, so a
  # PPT-themed plot usually carries a text geom. Guarded on the symbol
  # because DESCRIPTION still admits ggplot2 3.5, where it does not exist.
  if ("text" %in% fallback_roots &&
      "element_geom" %in% getNamespaceExports("ggplot2"))
    overrides[["geom"]] <- ggplot2::element_geom(family = "Helvetica")

  x + do.call(ggplot2::theme, overrides)
}

#' @export
ggplot_add.hv_ppt_theme <- function(object, plot, ...) {
  requests <- attr(object, "hv_font_requests", exact = TRUE)
  plot <- NextMethod()
  if (!is.null(requests)) {
    attr(plot, "hv_font_requests") <- requests
    class(plot) <- union("hv_ppt_plot", class(plot))
  }
  plot
}

#' @export
print.hv_ppt_plot <- function(x, ...) {
  x <- .hv_resolve_ppt_family(x)
  NextMethod()
}

#' @export
grid.draw.hv_ppt_plot <- function(x, ...) {
  x <- .hv_resolve_ppt_family(x)
  NextMethod()
}
