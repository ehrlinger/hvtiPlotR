# pdf_footnote.R
#
# Add a small footnote to the bottom-right corner of the current figure using
# grid graphics. Intended for draft plots: include the script name, timestamp,
# and analyst name during analysis; simply omit the call for publication-ready
# figures.
#
# Adapted from:
# https://ryouready.wordpress.com/2009/02/17/r-good-practice-adding-footnotes-to-graphics/

#' Add a Draft Footnote to a Figure
#'
#' Writes a small text annotation in the bottom-right corner of the **current**
#' graphics device using grid. Call this *after* printing or displaying the
#' plot. For publication-ready figures, simply omit the call — the plot is
#' unchanged.
#'
#' **Typical workflow:**
#' ```r
#' # During analysis (draft)
#' p <- hazard_plot(...) + hvti_theme("manuscript")
#' print(p)
#' make_footnote("analysis/mortality.R")   # adds draft annotation
#'
#' # For publication — just don't call make_footnote()
#' ggsave("figures/fig1.pdf", p, width = 11, height = 8.5)
#' ```
#'
#' @param text     Text to display. Defaults to the current working directory,
#'   which conveniently identifies the project. For the typical use case pass
#'   the script filename: `make_footnote("R/analysis.R")`.
#' @param timestamp Logical; append `Sys.time()` to `text`? Default `TRUE`.
#'   Set to `FALSE` for reproducible screenshots or when the file path already
#'   contains enough context.
#' @param prefix   String prepended to `text` before the timestamp. Default
#'   `"DRAFT \u2014 "`. Set to `""` to suppress the prefix.
#' @param size     Font size as a multiplier relative to the device default
#'   (passed to [grid::gpar()] as `cex`). Default `0.7`.
#' @param colour   Font colour. Default `grey(0.5)` (medium grey), which is
#'   visually unobtrusive on both screen and print.
#' @param x        Horizontal position in normalised parent coordinates
#'   (`"npc"`). Default `1` (right edge). Decrease to move left.
#' @param y        Vertical position in `"npc"`. Default `0` (bottom). Increase
#'   to move up.
#' @param hjust    Horizontal justification: `"right"` (default), `"left"`,
#'   or `"centre"`.
#' @param vjust    Vertical justification: `"bottom"` (default), `"top"`,
#'   or `"centre"`.
#' @param margin_mm Margin in mm pulled back from the `x`/`y` position.
#'   Default `2`.
#'
#' @return Called for its side effect (draws text on the current device).
#'   Returns `invisible(NULL)`.
#'
#' @seealso [save_ppt()], [hvti_theme()]
#'
#' @examples
#' # --- Basic use after a base-R plot ----------------------------------------
#' plot(1:10, main = "Example")
#' make_footnote("examples/basic.R")
#'
#' # --- With a ggplot2 figure and manuscript theme ---------------------------
#' \dontrun{
#' library(ggplot2)
#' p <- ggplot(mtcars, aes(wt, mpg)) +
#'   geom_point() +
#'   labs(title = "Motor Trend Cars") +
#'   hvti_theme("manuscript")
#'
#' # Draft: print, then annotate
#' print(p)
#' make_footnote("R/exploratory.R")
#'
#' # Publication: save without footnote
#' ggsave("figures/fig1.pdf", p, width = 11, height = 8.5)
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
#' @importFrom grDevices grey
#' @export
make_footnote <- function(text       = getwd(),
                          timestamp  = TRUE,
                          prefix     = "DRAFT \u2014 ",
                          size       = 0.7,
                          colour     = grey(0.5),
                          x          = 1,
                          y          = 0,
                          hjust      = "right",
                          vjust      = "bottom",
                          margin_mm  = 2) {

  if (!is.character(text) || length(text) != 1L)
    stop("`text` must be a single string.", call. = FALSE)
  if (!is.numeric(size) || size <= 0)
    stop("`size` must be a positive number.", call. = FALSE)
  if (length(colour) != 1L)
    stop("`colour` must be a length-1 value.", call. = FALSE)
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
    gp    = gpar(cex = size, col = colour)
  )
  popViewport()
  invisible(NULL)
}

#' @rdname make_footnote
#' @param footnoteText Equivalent to `text` in [make_footnote()].
#' @param color        Equivalent to `colour` in [make_footnote()].
#' @export
makeFootnote <- function(footnoteText = getwd(),
                         size         = 0.7,
                         color        = grey(0.5),
                         timestamp    = TRUE) {
  make_footnote(
    text      = footnoteText,
    size      = size,
    colour    = color,
    timestamp = timestamp,
    prefix    = "DRAFT \u2014 "
  )
}
