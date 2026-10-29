#' Save a ggplot at HVTI manuscript defaults
#'
#' A thin wrapper around [ggplot2::ggsave()] that enforces the house manuscript
#' figure size, 6 inches wide by 4 inches tall, so journal figures come
#' out at a consistent size in one call. It is the manuscript counterpart of
#' [save_ppt()], which enforces the slide panel box.
#'
#' Pair it with [theme_hv_manuscript()], whose 12 pt `base_size` supplies the
#' manuscript typography. Like [save_ppt()], `save_manuscript()` fixes the
#' output geometry, not the theme; style the plot first, then save.
#'
#' The device is inferred from the file extension by default. A `.tif` or
#' `.tiff` file is written as an LZW-compressed TIFF at `dpi`, so a 6 x 4 in
#' figure is 1800 x 1200 pixels, the same geometry as the PNG, without the
#' tens of megabytes an uncompressed TIFF takes. A path with no extension takes
#' one from `format`, which defaults to `"tiff"`, the raster format journals
#' ask for. An extension you write is never overridden, so a `.png` path, such
#' as one a Quarto or R Markdown report embeds, stays a PNG: browsers do not
#' display TIFF.
#'
#' For a `.pdf`
#' where you want fonts embedded (so 12 pt type renders exactly as designed),
#' pass `device = grDevices::cairo_pdf` (on a system with cairo/X11 support).
#'
#' Publisher-accepted formats, vector (PDF, EPS) or TIFF (a raster format
#' also accepted by journals), often produce large or fragile files when
#' dragged into a Word manuscript. Word has no native PDF-as-picture support
#' and silently converts them to bloated, sometimes unreadable EMF. Pass
#' `draft_file` (typically a `.png` path) to also write a small raster copy
#' alongside `file` in the same call: keep `file` as the publisher deliverable
#' submitted to the journal, and drag `draft_file` into the Word
#' draft instead.
#'
#' Pass `footnote` to print the figure's provenance, typically the fields
#' [provenance_footnote()] builds, in a strip reserved below the plot. The
#' strip is added to the figure, never drawn over it: the plot keeps its
#' `width` x `height` and the saved file is taller by the strip. The note is
#' measured with each output device's own font metrics, so a PDF, PNG and
#' TIFF of one figure may get strips of slightly different height. It is set
#' at 8 pt and shrinks to fit one line, down to a floor of 6 pt. Past the
#' floor it wraps: first between fields, then inside a field at `/` and `.`,
#' so a long job path breaks at its directory and name parts. The first field,
#' the commit ID, is never broken. Nothing is clipped or truncated; the strip
#' grows to as many lines as the note needs. The note goes on publication
#' figures too: a journal crops it in typesetting, and the study's copy keeps
#' the record of which version of the job drew it.
#'
#' @param plot A [ggplot2::ggplot()] object, e.g. `plot(hv_*())` finished with
#'   `theme_hv_manuscript()`.
#' @param file Output file path. Its extension sets the format (`.pdf`,
#'   `.tiff`, `.png`, ...). Without an extension, `format` supplies one.
#' @param width,height,units Figure size. Default `6` x `4` `"in"`, the HVTI
#'   manuscript default.
#' @param device Graphics device. `NULL` (default) lets \pkg{ggplot2} pick from
#'   the file extension, and a TIFF is written LZW-compressed by
#'   [ragg::agg_tiff()]. When you pass a `device`, `file` is used as given and
#'   `format` adds no extension. For font embedding in a PDF, pass
#'   `grDevices::cairo_pdf` (requires cairo/X11 support).
#' @param dpi Resolution for raster formats. Default `300`.
#' @param draft_file Optional second output file path (typically `.png`). When
#'   supplied, an additional raster copy of `plot` is written here at the same
#'   `width`/`height`/`units`, for dragging into a Word draft manuscript.
#'   Default `NULL` (no draft copy written).
#' @param draft_dpi Resolution for `draft_file`. Default `NULL`, which falls
#'   back to `dpi`.
#' @param format Raster format, `"tiff"` (default) or `"png"`, for a `file` or
#'   `draft_file` given without an extension. A path that has an extension
#'   keeps it. Passing a `format` that contradicts a raster extension, such as
#'   `format = "png"` with a `.tiff` path, is an error.
#' @param footnote Optional provenance note, `NULL` (default) for none. A
#'   character vector of fields, which are joined by a middle dot (U+00B7)
#'   with a space either side, or a single string, which is split into fields
#'   at that separator. The first
#'   field is kept whole on every line break. With `NULL`, the output is
#'   exactly what it is without the argument.
#' @param ... Further arguments passed to [ggplot2::ggsave()] for the primary
#'   `file`. Not applied to `draft_file`.
#'
#' @return Invisibly, the `file` path, with the extension `format` added when
#'   it had none. With a `footnote`, the path carries the attribute `"dims"`,
#'   a list of the saved `width`, `height` and `units` of `file`, the height
#'   including the strip, and, when `draft_file` is written, `"draft_dims"`
#'   for that file.
#'
#' @seealso [provenance_footnote()] to build the `footnote` fields,
#'   [save_ppt()] for slides, [theme_hv_manuscript()] for the 12 pt
#'   typography, [hv_ggsave_dims()] for fixed-panel sizing. Worked examples live
#'   in the HVTI ggplot graphics recipes book,
#'   <https://ehrlinger.github.io/hvtiGraphics/>.
#'
#' @examples
#' \donttest{
#' p <- plot(hv_survival(sample_survival_data(n = 200, seed = 42))) +
#'   theme_hv_manuscript()
#' save_manuscript(p, file.path(tempdir(), "survival.pdf"))
#'
#' # no extension: a 300 dpi, LZW-compressed survival.tiff
#' save_manuscript(p, file.path(tempdir(), "survival"))
#'
#' # the same figure as a PNG
#' save_manuscript(p, file.path(tempdir(), "survival"), format = "png")
#'
#' # also write a small draft PNG for dragging into Word
#' save_manuscript(p, file.path(tempdir(), "survival.pdf"),
#'                  draft_file = file.path(tempdir(), "survival_draft.png"))
#'
#' # print the render's provenance in a strip below the figure
#' out <- save_manuscript(
#'   p, file.path(tempdir(), "survival.pdf"),
#'   footnote = provenance_footnote(
#'     commit = "3f9c2a1d8e", job = "30_analyses/survival.qmd",
#'     time = as.POSIXct("2026-10-29 14:40")
#'   )
#' )
#' attr(out, "dims")
#' }
#'
#' @importFrom ggplot2 ggsave
#' @importFrom ragg agg_tiff
#' @export
save_manuscript <- function(plot, file, width = 6, height = 4, units = "in",
                            device = NULL, dpi = 300,
                            draft_file = NULL, draft_dpi = NULL,
                            format = c("tiff", "png"), footnote = NULL, ...) {
  if (!inherits(plot, "ggplot"))
    stop("`plot` must be a ggplot object.", call. = FALSE)
  if (!is.character(file) || length(file) != 1L || is.na(file) || !nzchar(file))
    stop("`file` must be a single non-empty file path.", call. = FALSE)
  .check_scalar_positive(width,  "width")
  .check_scalar_positive(height, "height")
  .check_scalar_positive(dpi,    "dpi")
  units <- match.arg(units, c("in", "cm", "mm", "px"))
  if (!is.null(footnote)) footnote <- .footnote_fields(footnote)
  format_given <- !missing(format)
  format <- match.arg(format)
  # An explicit device names the format itself, so leave its path alone.
  if (is.null(device)) file <- .raster_path(file, format, format_given)
  out_dir <- dirname(file)
  if (!dir.exists(out_dir))
    stop("Output directory does not exist: ", out_dir, call. = FALSE)

  if (!is.null(draft_file)) {
    if (!is.character(draft_file) || length(draft_file) != 1L ||
        is.na(draft_file) || !nzchar(draft_file))
      stop("`draft_file` must be a single non-empty file path.", call. = FALSE)
    draft_file <- .raster_path(draft_file, format, format_given)
    draft_out_dir <- dirname(draft_file)
    if (!dir.exists(draft_out_dir))
      stop("Draft output directory does not exist: ", draft_out_dir, call. = FALSE)
    file_abs  <- file.path(normalizePath(out_dir, mustWork = FALSE), basename(file))
    draft_abs <- file.path(normalizePath(draft_out_dir, mustWork = FALSE), basename(draft_file))
    if (identical(file_abs, draft_abs))
      stop("`draft_file` must not be the same path as `file`.", call. = FALSE)
    draft_dpi <- if (is.null(draft_dpi)) dpi else draft_dpi
    .check_scalar_positive(draft_dpi, "draft_dpi")
  }

  dots <- list(...)
  if (.is_tiff(file, device) && is.null(dots$compression))
    dots$compression <- "lzw"
  if (is.null(footnote)) {
    do.call(ggplot2::ggsave,
            c(list(filename = file, plot = plot, device = device, width = width,
                   height = height, units = units, dpi = dpi), dots))
  } else {
    attr(file, "dims") <- .save_with_footnote(file, plot, footnote, device, width,
                                              height, units, dpi, dots)
  }

  if (!is.null(draft_file)) {
    draft_dots <- if (.is_tiff(draft_file)) list(compression = "lzw")
    if (is.null(footnote)) {
      do.call(ggplot2::ggsave,
              c(list(filename = draft_file, plot = plot, device = NULL,
                     width = width, height = height, units = units,
                     dpi = draft_dpi), draft_dots))
    } else {
      attr(file, "draft_dims") <- .save_with_footnote(draft_file, plot, footnote, NULL, width,
                                                      height, units, draft_dpi, draft_dots)
    }
  }

  invisible(file)
}

# A path's extension, lower case, or "" when it has none.
.file_ext <- function(path) {
  m <- regmatches(basename(path), regexpr("[.][[:alnum:]]+$", basename(path)))
  if (length(m)) tolower(substring(m, 2L)) else ""
}

# Give an extension-less path the `format` extension. An extension the caller
# wrote wins, so a `.png` meant for an HTML report is never turned into a TIFF
# a browser cannot show; a `format` passed explicitly that contradicts it errors.
.raster_path <- function(path, format, format_given) {
  ext <- .file_ext(path)
  if (!nzchar(ext)) return(paste0(path, ".", format))
  is_tiff <- ext %in% c("tif", "tiff")
  if (format_given && (is_tiff || ext == "png") &&
      !identical(if (is_tiff) "tiff" else "png", format))
    stop("`format = \"", format, "\"` contradicts the extension of `",
         basename(path), "`.", call. = FALSE)
  path
}

# Whether ggsave() will open its TIFF device for this path and device. That
# device is ragg::agg_tiff() behind ggplot2's adapter (ggsave() uses ragg only
# when it is installed, hence ragg in Imports and the importFrom above), which drops `type` and
# `antialias` with a warning. It writes uncompressed, about 6 MB for a 6 x 4 in
# figure at 300 dpi; the caller adds lossless LZW, which brings it under 100 KB.
# A device function is the caller's own, so it is left as it is.
.is_tiff <- function(path, device = NULL) {
  if (is.null(device)) return(.file_ext(path) %in% c("tif", "tiff"))
  is.character(device) && device %in% c("tif", "tiff")
}
