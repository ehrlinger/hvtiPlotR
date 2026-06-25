# R/legend-inside.R

#' @noRd
# Validate args shared by hv_legend_inside().
.legend_validate <- function(threshold, box_frac, pad) {
  .check_scalar_positive(box_frac, "box_frac")
  .check_scalar_positive(pad, "pad")
  if (!is.numeric(threshold) || length(threshold) != 1L ||
      !is.finite(threshold) || threshold < 0 || threshold > 1)
    stop("`threshold` must be a single number in [0, 1].", call. = FALSE)
  if (box_frac > 0.5)
    stop("`box_frac` must be <= 0.5 (corner boxes would overlap).",
         call. = FALSE)
  invisible(TRUE)
}

hv_legend_inside <- function(plot, threshold = 0.08, box_frac = 0.30,
                             pad = 0.02, fallback = "right") {
  if (!inherits(plot, "ggplot"))
    stop("`plot` must be a ggplot object.", call. = FALSE)
  fallback <- match.arg(fallback, c("right", "left", "top", "bottom"))
  .legend_validate(threshold, box_frac, pad)

  fb <- ggplot2::theme(legend.position = fallback)

  b <- ggplot2::ggplot_build(plot)
  if (length(b$layout$panel_params) > 1L) {
    message("hv_legend_inside(): multiple panels; using the fallback legend ",
            "position ('", fallback, "').")
    return(plot + fb)
  }

  plot + fb   # placeholder until Task 3 adds corner logic
}
