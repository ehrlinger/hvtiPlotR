# save_ppt.R
#
# Ported from tp.ppt.officer.R (template graph library).
# Key change: replaces body_add_plot() with ph_with() + rvg::dml() so plots
# land in the slide as editable DrawingML vector objects rather than raster
# images. The title is placed via ph_location_type(type = "title") so it
# lives in the correct placeholder and respects the template's text formatting.
# ---------------------------------------------------------------------------

# Internal helpers -----------------------------------------------------------

ensure_officer_available <- function() {
  if (!requireNamespace("officer", quietly = TRUE)) {
    stop("Package `officer` must be installed to use `save_ppt()`.",
         call. = FALSE)
  }
}

ensure_rvg_available <- function() {
  if (!requireNamespace("rvg", quietly = TRUE)) {
    stop("Package `rvg` must be installed to use `save_ppt()`.",
         call. = FALSE)
  }
}

officer_safe_call <- function(expr, action) {
  tryCatch(expr, error = function(e) {
    stop(sprintf("Failed to %s: %s", action, e$message), call. = FALSE)
  })
}

# Filter officer's known benign XML-namespace warnings that fire whenever
# ph_location() is called with a `bg` argument. The warnings come from
# officer's internal libxml2 processing ("Namespace prefix a on solidFill
# is not defined [201]" etc.) and do not affect the validity of the output
# .pptx file; suppressing them keeps save_ppt's output clean.
suppress_officer_bg_warnings <- function(expr) {
  withCallingHandlers(
    expr,
    warning = function(w) {
      if (grepl("Namespace prefix a on (solidFill|srgbClr|alpha) is not defined",
                conditionMessage(w))) {
        invokeRestart("muffleWarning")
      }
    }
  )
}

# Add one editable slide -----------------------------------------------------

add_plot_slide <- function(doc, plot, title, layout, master, width, height,
                           left, top) {
  dml_obj <- rvg::dml(ggobj = plot)

  doc <- officer_safe_call(
    officer::add_slide(doc, layout = layout, master = master),
    action = "add slide"
  )
  doc <- officer_safe_call(
    officer::ph_with(
      doc,
      value    = title,
      location = officer::ph_location_type(type = "title")
    ),
    action = "set slide title"
  )
  doc <- officer_safe_call(
    suppress_officer_bg_warnings(
      officer::ph_with(
        doc,
        value    = dml_obj,
        location = officer::ph_location(
          width  = width,
          height = height,
          left   = left,
          top    = top,
          # Make the placeholder shape's fill transparent so the slide
          # template background (blue gradient on dark templates, plain
          # white on manuscript templates) shows through any area
          # outside the ggplot's own panel. Without this, officer's
          # default ph_location creates a rectangle shape with a white
          # fill, which appears as an opaque white box behind the plot
          # on dark templates.
          bg     = "transparent"
        )
      )
    ),
    action = "add plot to slide"
  )
  doc
}

# Public function ------------------------------------------------------------

#' Save ggplot Objects to an Editable PowerPoint Presentation
#'
#' Writes one ggplot per slide into a PowerPoint file using
#' [officer::ph_with()] and [rvg::dml()] so that every plot lands as an
#' **editable DrawingML vector graphic** — shapes, lines, and text remain
#' selectable in PowerPoint. Plots are placed via
#' [officer::ph_location()] for pixel-exact positioning; titles go into the
#' designated title placeholder via [officer::ph_location_type()].
#'
#' @param object      A single ggplot object **or** a named/unnamed list of
#'   ggplot objects. Each element produces one slide.
#' @param template    Path to an existing `.pptx` file used as the slide
#'   template. Default `"../graphs/RD.pptx"`.
#' @param powerpoint  Output path for the new `.pptx` file.
#'   Default `"../graphs/pptExample.pptx"`.
#' @param slide_titles A character vector of slide titles. Recycled to the
#'   number of plots: supply one string for all slides, or one per plot.
#'   Default `"Plot"`.
#' @param layout      PowerPoint slide layout name from the template.
#'   Default `"Title and Content"`.
#' @param master      PowerPoint master name from the template, or `NULL` to
#'   use the template's first available master. Default `NULL`.
#' @param width       Plot width in inches within the slide. Default `10.1`.
#'   Ignored when `panel_box` is supplied.
#' @param height      Plot height in inches within the slide. Default `5.8`.
#'   Ignored when `panel_box` is supplied.
#' @param left        Distance in inches from the left edge of the slide.
#'   Default `0.0`. Ignored when `panel_box` is supplied.
#' @param top         Distance in inches from the top of the slide.
#'   Default `1.2` (below a standard title bar). Ignored when `panel_box`
#'   is supplied.
#' @param panel_box   Optional named list `list(width, height, left, top)`
#'   describing the **panel content area** to anchor on every slide (in
#'   inches). When supplied, per-plot slide placement is computed via
#'   [hv_ph_location()] so the panel lands at the same slide coordinates
#'   on every slide regardless of axis-label width. When `NULL` (default),
#'   the fixed `width`/`height`/`left`/`top` arguments are used for every
#'   slide (legacy behavior).
#'
#' @return Invisibly returns the path given by `powerpoint`.
#'
#' @seealso [rvg::dml()], [officer::ph_with()], [officer::ph_location()],
#'   [theme_hv_manuscript()]
#'
#' @examples
#' \dontrun{
#' library(ggplot2)
#'
#' # Single plot — dark PPT theme matches a black-background slide
#' p1 <- ggplot(mtcars, aes(x = wt, y = mpg)) +
#'   geom_point() +
#'   labs(x = "Weight", y = "Miles per gallon", title = "Fuel economy") +
#'   theme_hv_ppt_dark()
#'
#' save_ppt(
#'   object       = p1,
#'   template     = "graphs/RD.pptx",
#'   powerpoint   = "graphs/fuel_economy.pptx",
#'   slide_titles = "Fuel Economy by Weight"
#' )
#'
#' # List of plots — one slide per plot, individual titles
#' p2 <- ggplot(mtcars, aes(x = factor(cyl), y = mpg)) +
#'   geom_boxplot() +
#'   labs(x = "Cylinders", y = "Miles per gallon") +
#'   theme_hv_ppt_dark()
#'
#' save_ppt(
#'   object       = list(p1, p2),
#'   template     = "graphs/RD.pptx",
#'   powerpoint   = "graphs/deck.pptx",
#'   slide_titles = c("Scatter: fuel economy", "Box: mpg by cylinder count")
#' )
#'
#' # Manuscript (white background) for AATS-style presentations
#' pm <- ggplot(mtcars, aes(x = wt, y = mpg)) +
#'   geom_point() +
#'   labs(x = "Weight", y = "Miles per gallon") +
#'   theme_hv_manuscript()
#'
#' save_ppt(
#'   object       = pm,
#'   template     = "graphs/RD-white.pptx",
#'   powerpoint   = "graphs/manuscript.pptx",
#'   slide_titles = "Fuel Economy"
#' )
#'
#' # ----------------------------------------------------------------------
#' # panel_box: anchor the plot panel to a fixed rectangle on every slide
#' # ----------------------------------------------------------------------
#' #
#' # Problem: when plots in a deck have different y-axis ranges
#' # (e.g. "1.0" vs "4567.2"), axis-label widths differ and shift the
#' # panel inside a fixed ph_location(). Without a panel_box the plot
#' # panel drifts between slides — visually jarring against the slide
#' # background.
#' #
#' # Solution: pass `panel_box = list(width = ..., height = ..., left = ...,
#' # top = ...)`. This describes the PANEL CONTENT AREA itself — the
#' # rectangle bounded by the axis lines, not the outer plot extent.
#' # save_ppt() calls [hv_ph_location()] for each plot, measures the
#' # axis / title / legend chrome around the panel, and adjusts per-slide
#' # placement so the panel lands at the target rectangle on every slide.
#' # The plot's OUTER dimensions therefore vary per slide (chrome floats
#' # around a constant panel), analogous to how [hv_ggsave_dims()] drives
#' # ggsave's width/height from a target panel size.
#' #
#' # Workflow: build plots with `theme_hv_ppt_light()` so the white panel
#' # + black border renders crisply in the IDE viewer during development.
#' # At save time, the PowerPoint template controls the SLIDE background
#' # (e.g. blue gradient), so a light_ppt plot on a dark slide template
#' # produces AATS-style white-panel-on-dark-slide decks.
#'
#' p_small <- ggplot(mtcars, aes(hp, mpg)) +
#'   geom_point() +
#'   scale_x_continuous(breaks = seq(0, 400, 100), expand = c(0, 0)) +
#'   scale_y_continuous(labels = function(x) sprintf("%3.1f", x)) +
#'   labs(x = "Horsepower", y = "MPG") +
#'   theme_hv_ppt_light()
#'
#' p_big <- ggplot(mtcars, aes(hp, mpg)) +
#'   geom_point() +
#'   scale_x_continuous(breaks = seq(0, 400, 100), expand = c(0, 0)) +
#'   scale_y_continuous(labels = function(x) sprintf("%8.1f", x * 10000)) +
#'   labs(x = "Horsepower", y = "MPG (x10k)") +
#'   theme_hv_ppt_light()
#'
#' # Preview each plot interactively (e.g. print(p_small) in RStudio) to
#' # check decoration before saving.
#'
#' # Without panel_box: panel drifts between slides because the big-number
#' # labels eat more horizontal space than the small-number labels.
#' save_ppt(
#'   object       = list(p_small, p_big),
#'   template     = "graphs/RD-dark.pptx",
#'   powerpoint   = "graphs/drifting_deck.pptx",
#'   slide_titles = c("Small y-axis", "Big y-axis")
#' )
#'
#' # With panel_box: target is an 8.88" x 4.51" panel at slide coordinates
#' # (2.58", 1.29"). The panel content area lands at exactly that rectangle
#' # on both slides; axis labels extend outside it as each plot requires.
#' # The 2.58" left margin leaves room for a wide "99999.9"-style y-axis
#' # label on dark PPT templates rendered at base_size = 32.
#' save_ppt(
#'   object       = list(p_small, p_big),
#'   template     = "graphs/RD-dark.pptx",
#'   powerpoint   = "graphs/anchored_deck.pptx",
#'   slide_titles = c("Small y-axis", "Big y-axis"),
#'   panel_box    = list(width = 8.88, height = 4.51, left = 2.58, top = 1.29)
#' )
#'
#' # Sizing advice: panel_left and panel_top must be large enough for the
#' # widest axis labels in the deck. If chrome extends past the left or top
#' # slide edge, hv_ph_location() emits a warning naming that edge.
#' }
#'
#' @importFrom officer read_pptx add_slide ph_with ph_location ph_location_type
#' @importFrom rvg dml
#' @export
save_ppt <- function(object,
                     template     = "../graphs/RD.pptx",
                     powerpoint   = "../graphs/pptExample.pptx",
                     slide_titles = "Plot",
                     layout       = "Title and Content",
                     master       = NULL,
                     width        = 10.1,
                     height       = 5.8,
                     left         = 0.0,
                     top          = 1.2,
                     panel_box    = NULL) {

  ensure_officer_available()
  ensure_rvg_available()

  is_plot_list <- is.list(object) && !inherits(object, "ggplot")

  # --- Validate inputs -------------------------------------------------------
  if (!(inherits(object, "ggplot") || is_plot_list))
    stop("`object` must be a ggplot or a list of ggplot objects.", call. = FALSE)
  if (is_plot_list) {
    if (length(object) == 0L)
      stop("`object` list cannot be empty.", call. = FALSE)
    if (!all(vapply(object, inherits, logical(1L), what = "ggplot")))
      stop("All elements of `object` must be ggplot objects.", call. = FALSE)
  }
  if (!(is.character(template) && length(template) == 1L && file.exists(template)))
    stop("`template` must be the path to an existing PowerPoint file.",
         call. = FALSE)
  if (!(is.character(powerpoint) && length(powerpoint) == 1L &&
        dir.exists(dirname(powerpoint))))
    stop("`powerpoint` must be a writable file path.", call. = FALSE)
  if (!(is.character(slide_titles) && length(slide_titles) >= 1L))
    stop("`slide_titles` must be a non-empty character vector.", call. = FALSE)
  if (is.null(panel_box)) {
    if (!(is.numeric(width)  && length(width)  == 1L && width  > 0 &&
          is.numeric(height) && length(height) == 1L && height > 0))
      stop("`width` and `height` must be positive numbers.", call. = FALSE)
    if (!(is.numeric(left) && length(left) == 1L && left >= 0 &&
          is.numeric(top)  && length(top)  == 1L && top  >= 0))
      stop("`left` and `top` must be non-negative numbers.", call. = FALSE)
  } else {
    expected <- c("width", "height", "left", "top")
    if (!is.list(panel_box) || !all(expected %in% names(panel_box)))
      stop("`panel_box` must be a list with elements `width`, `height`, `left`, `top`.",
           call. = FALSE)
  }

  # --- Open template ---------------------------------------------------------
  doc <- officer_safe_call(
    officer::read_pptx(path = template),
    action = "open PowerPoint template"
  )

  # --- Normalise to list -----------------------------------------------------
  plots <- if (is_plot_list) object else list(object)
  titles <- rep_len(slide_titles, length(plots))

  # --- Add one slide per plot ------------------------------------------------
  for (i in seq_along(plots)) {
    if (is.null(panel_box)) {
      slide_w <- width
      slide_h <- height
      slide_l <- left
      slide_t <- top
    } else {
      loc <- hv_ph_location(
        plots[[i]],
        panel_width  = panel_box$width,
        panel_height = panel_box$height,
        panel_left   = panel_box$left,
        panel_top    = panel_box$top,
        units        = "in"
      )
      slide_w <- loc$width
      slide_h <- loc$height
      slide_l <- loc$left
      slide_t <- loc$top
    }

    doc <- add_plot_slide(
      doc    = doc,
      plot   = plots[[i]],
      title  = titles[[i]],
      layout = layout,
      master = master,
      width  = slide_w,
      height = slide_h,
      left   = slide_l,
      top    = slide_t
    )
  }

  # --- Write output ----------------------------------------------------------
  officer_safe_call(
    print(doc, target = powerpoint),
    action = "write PowerPoint file"
  )

  invisible(powerpoint)
}
