# pdf_footnote.R
#
# Add a small footnote to the bottom-right corner of the current figure using
# grid graphics. Intended for draft plots: include the script name, timestamp,
# and analyst name during analysis. A saved figure, publication included, takes
# its provenance from save_manuscript(footnote =) instead.
#
# Adapted from:
# https://ryouready.wordpress.com/2009/02/17/r-good-practice-adding-footnotes-to-graphics/

#' Add a Draft Footnote to a Figure
#'
#' Writes a small text annotation in the bottom-right corner of the **current**
#' graphics device using grid. Call this *after* printing or displaying the
#' plot. It draws over the figure, so it suits a draft on screen. For a saved
#' figure, publication included, pass `footnote` to [save_manuscript()]
#' instead: it prints the render's provenance in a strip below the plot, which
#' a journal crops in typesetting while the study's copy keeps it.
#'
#' **Typical workflow:**
#' ```r
#' # During analysis (draft)
#' p <- plot(hv_hazard(...)) + theme_hv_manuscript()
#' print(p)
#' make_footnote("analysis/mortality.R")   # adds draft annotation
#'
#' # Saved figure, publication included: provenance in a strip below the plot
#' save_manuscript(p, "figures/fig1.pdf",
#'                 footnote = provenance_footnote(commit, "analysis/mortality.R"))
#' ```
#'
#' @param text     Text to display. Defaults to the current working directory;
#'   for most uses pass the script filename instead: `make_footnote("R/analysis.R")`.
#' @param timestamp Logical; if TRUE, `Sys.time()` is appended to `text`. Default `TRUE`.
#'   Set to `FALSE` for reproducible output.
#' @param prefix   String prepended to `text` before the timestamp. Default
#'   `"DRAFT \u2014 "`. Set to `""` to suppress the prefix.
#' @param size     Font size as a multiplier relative to the device default
#'   (passed to [grid::gpar()] as `cex`). Default `0.7`.
#' @param color    Font color. Default `gray(0.5)` (medium gray), which is
#'   visually unobtrusive on both screen and print.
#' @param colour   The same as `color`: an alias kept for existing code. Give
#'   one or the other; both with different values is an error.
#' @param x        Horizontal position in normalized parent coordinates
#'   (`"npc"`). Default `1` (right edge). Decrease to move left.
#' @param y        Vertical position in `"npc"`. Default `0` (bottom). Increase
#'   to move up.
#' @param hjust    Horizontal justification: `"right"` (default), `"left"`,
#'   or `"center"`.
#' @param vjust    Vertical justification: `"bottom"` (default), `"top"`,
#'   or `"center"`.
#' @param margin_mm Margin in mm pulled back from the `x`/`y` position.
#'   Default `2`.
#'
#' @return Called for its side effect (draws text on the current device).
#'   Returns `invisible(NULL)`.
#'
#' @seealso [save_manuscript()] and [provenance_footnote()] for the note on a
#'   saved figure, [save_ppt()], [theme_hv_manuscript()]
#'
#' @examples
#' # --- Basic use after a base-R plot ----------------------------------------
#' plot(1:10, main = "Example")
#' make_footnote("examples/basic.R")
#'
#' # --- With a ggplot2 figure and manuscript theme ---------------------------
#' \donttest{
#' library(ggplot2)
#' p <- ggplot(mtcars, aes(wt, mpg)) +
#'   geom_point() +
#'   labs(title = "Motor Trend Cars") +
#'   theme_hv_manuscript()
#'
#' # Draft: print, then annotate
#' print(p)
#' make_footnote("R/exploratory.R")
#'
#' # Saved figure: the provenance goes in a strip below the plot
#' save_manuscript(p, file.path(tempdir(), "fig1.pdf"),
#'                 footnote = provenance_footnote("3f9c2a1", "R/exploratory.R"))
#' }
#'
#' # --- Custom position and no timestamp ------------------------------------
#' plot(1:10)
#' make_footnote("Preliminary results", timestamp = FALSE, prefix = "")
#'
#' # --- Suppress the DRAFT prefix -------------------------------------------
#' plot(1:10)
#' make_footnote(
#'   text      = paste("Analyst: J. Ehrlinger |", Sys.Date()),
#'   timestamp = FALSE,
#'   prefix    = ""
#' )
#'
#' @importFrom grid pushViewport viewport popViewport gpar grid.text unit
#' @importFrom grDevices gray
#' @export
make_footnote <- function(text       = getwd(),
                          timestamp  = TRUE,
                          prefix     = "DRAFT \u2014 ",
                          size       = 0.7,
                          colour     = gray(0.5),
                          x          = 1,
                          y          = 0,
                          hjust      = "right",
                          vjust      = "bottom",
                          margin_mm  = 2,
                          color      = colour) {
  .check_spelling_pair("color", "colour", !missing(color), !missing(colour), color, colour)

  if (!is.character(text) || length(text) != 1L)
    stop("`text` must be a single string.", call. = FALSE)
  if (!is.numeric(size) || size <= 0)
    stop("`size` must be a positive number.", call. = FALSE)
  if (length(color) != 1L)
    stop("`color` must be a length-1 value.", call. = FALSE)
  if (!is.logical(timestamp) || length(timestamp) != 1L)
    stop("`timestamp` must be TRUE or FALSE.", call. = FALSE)

  label <- paste0(prefix, text)
  if (timestamp)
    label <- paste(label, format(Sys.time(), "%Y-%m-%d %H:%M"))

  # Offset x/y from the edge by margin_mm
  x_unit <- if (x >= 0.5) {
    unit(x, "npc") - unit(margin_mm, "mm")
  } else {
    unit(x, "npc") + unit(margin_mm, "mm")
  }
  y_unit <- if (y <= 0.5) {
    unit(y, "npc") + unit(margin_mm, "mm")
  } else {
    unit(y, "npc") - unit(margin_mm, "mm")
  }

  pushViewport(viewport())
  grid.text(
    label = label,
    x     = x_unit,
    y     = y_unit,
    just  = c(hjust, vjust),
    gp    = gpar(cex = size, col = color)
  )
  popViewport()
  invisible(NULL)
}

#' @rdname make_footnote
#' @param footnoteText Equivalent to `text` in [make_footnote()].
#' @export
# camelCase on purpose: makeFootnote() and footnoteText are the names this
# package exported before the rename to make_footnote(), and an export is
# part of the contract with every package that draws through this one.
makeFootnote <- function(footnoteText = getwd(), # nolint: object_name_linter.
                         size         = 0.7,
                         color        = gray(0.5),
                         timestamp    = TRUE) {
  make_footnote(
    text      = footnoteText,
    size      = size,
    color     = color,
    timestamp = timestamp,
    prefix    = "DRAFT \u2014 "
  )
}
