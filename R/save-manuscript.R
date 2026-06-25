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
#' @param ... Further arguments passed to [ggplot2::ggsave()].
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
#' }
#'
#' @importFrom ggplot2 ggsave
#' @export
save_manuscript <- function(plot, file, width = 6, height = 4, units = "in",
                            device = NULL, dpi = 300, ...) {
  if (!inherits(plot, "ggplot"))
    stop("`plot` must be a ggplot object.", call. = FALSE)
  if (!is.character(file) || length(file) != 1L)
    stop("`file` must be a single file path.", call. = FALSE)
  pos_num <- function(x) is.numeric(x) && length(x) == 1L && is.finite(x) && x > 0
  if (!pos_num(width))
    stop("`width` must be a single positive number.", call. = FALSE)
  if (!pos_num(height))
    stop("`height` must be a single positive number.", call. = FALSE)
  if (!pos_num(dpi))
    stop("`dpi` must be a single positive number.", call. = FALSE)
  units <- match.arg(units, c("in", "cm", "mm", "px"))
  out_dir <- dirname(file)
  if (!dir.exists(out_dir))
    stop("Output directory does not exist: ", out_dir, call. = FALSE)

  ggplot2::ggsave(filename = file, plot = plot, device = device,
                  width = width, height = height, units = units, dpi = dpi, ...)
  invisible(file)
}
