#' Save a ggplot at HVTI manuscript defaults
#'
#' A thin wrapper around [ggplot2::ggsave()] that enforces the house manuscript
#' figure size — **6 inches wide by 4 inches tall** — so journal figures come
#' out at a consistent size in one call. It is the manuscript counterpart of
#' [save_ppt()], which enforces the slide panel box.
#'
#' Pair it with [theme_hv_manuscript()], whose 12 pt `base_size` supplies the
#' manuscript typography. Like [save_ppt()], `save_manuscript()` fixes the
#' output geometry, not the theme — style the plot first, then save.
#'
#' The device is inferred from the file extension by default. For a `.pdf`
#' where you want fonts embedded (so 12 pt type renders exactly as designed),
#' pass `device = grDevices::cairo_pdf` — on a system with cairo/X11 support.
#'
#' Publisher-accepted vector formats (PDF, EPS, TIFF) often produce large or
#' fragile files when dragged into a Word manuscript — Word has no native
#' PDF-as-picture support and silently converts them to bloated, sometimes
#' unreadable EMF. Pass `draft_file` (typically a `.png` path) to also write a
#' small raster copy alongside `file` in the same call: keep `file` as the
#' vector deliverable actually submitted to the journal, and drag
#' `draft_file` into the Word draft instead.
#'
#' @param plot A [ggplot2::ggplot()] object, e.g. `plot(hv_*())` finished with
#'   `theme_hv_manuscript()`.
#' @param file Output file path. Its extension sets the format (`.pdf`, `.png`,
#'   ...).
#' @param width,height,units Figure size. Default `6` x `4` `"in"` — the HVTI
#'   manuscript default.
#' @param device Graphics device. `NULL` (default) lets \pkg{ggplot2} pick from
#'   the file extension. For font embedding in a PDF, pass
#'   `grDevices::cairo_pdf` (requires cairo/X11 support).
#' @param dpi Resolution for raster formats. Default `300`.
#' @param draft_file Optional second output file path (typically `.png`). When
#'   supplied, an additional raster copy of `plot` is written here at the same
#'   `width`/`height`/`units`, for dragging into a Word draft manuscript.
#'   Default `NULL` (no draft copy written).
#' @param draft_dpi Resolution for `draft_file`. Default `NULL`, which falls
#'   back to `dpi`.
#' @param ... Further arguments passed to [ggplot2::ggsave()] for the primary
#'   `file`. Not applied to `draft_file`.
#'
#' @return Invisibly, the `file` path.
#'
#' @seealso [save_ppt()] for slides, [theme_hv_manuscript()] for the 12 pt
#'   typography, [hv_ggsave_dims()] for fixed-panel sizing. Worked examples live
#'   in the HVTI ggplot graphics recipes book,
#'   <https://ehrlinger.github.io/hvti_graphics/>.
#'
#' @examples
#' \donttest{
#' p <- plot(hv_survival(sample_survival_data(n = 200, seed = 42))) +
#'   theme_hv_manuscript()
#' save_manuscript(p, file.path(tempdir(), "survival.pdf"))
#'
#' # also write a small draft PNG for dragging into Word
#' save_manuscript(p, file.path(tempdir(), "survival.pdf"),
#'                  draft_file = file.path(tempdir(), "survival_draft.png"))
#' }
#'
#' @importFrom ggplot2 ggsave
#' @export
save_manuscript <- function(plot, file, width = 6, height = 4, units = "in",
                            device = NULL, dpi = 300,
                            draft_file = NULL, draft_dpi = NULL, ...) {
  if (!inherits(plot, "ggplot"))
    stop("`plot` must be a ggplot object.", call. = FALSE)
  if (!is.character(file) || length(file) != 1L || is.na(file) || !nzchar(file))
    stop("`file` must be a single non-empty file path.", call. = FALSE)
  .check_scalar_positive(width,  "width")
  .check_scalar_positive(height, "height")
  .check_scalar_positive(dpi,    "dpi")
  units <- match.arg(units, c("in", "cm", "mm", "px"))
  out_dir <- dirname(file)
  if (!dir.exists(out_dir))
    stop("Output directory does not exist: ", out_dir, call. = FALSE)

  if (!is.null(draft_file)) {
    if (!is.character(draft_file) || length(draft_file) != 1L ||
        is.na(draft_file) || !nzchar(draft_file))
      stop("`draft_file` must be a single non-empty file path.", call. = FALSE)
    draft_out_dir <- dirname(draft_file)
    if (!dir.exists(draft_out_dir))
      stop("Draft output directory does not exist: ", draft_out_dir, call. = FALSE)
    draft_dpi <- if (is.null(draft_dpi)) dpi else draft_dpi
    .check_scalar_positive(draft_dpi, "draft_dpi")
  }

  ggplot2::ggsave(filename = file, plot = plot, device = device,
                  width = width, height = height, units = units, dpi = dpi, ...)

  if (!is.null(draft_file)) {
    ggplot2::ggsave(filename = draft_file, plot = plot, device = NULL,
                    width = width, height = height, units = units, dpi = draft_dpi)
  }

  invisible(file)
}
