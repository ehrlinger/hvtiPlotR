# testthat helper: muffle known third-party warnings during plot construction
#
# These warnings originate in upstream dependencies (ggsankey / ComplexUpset)
# under newer ggplot2 releases. We only muffle exact known warning families so
# newly introduced warnings still surface and fail CI expectations.

hv_muffle_known_plot_warnings <- function(expr) {
  warning_patterns <- c(
    "The `size` argument of `element_rect\(\)` is deprecated",
    "Using `size` aesthetic for lines was deprecated",
    "is not a valid theme\\.",
    "`legend\\.margin` must be specified using `margin\(\)`"
  )

  withCallingHandlers(
    expr,
    warning = function(w) {
      msg <- conditionMessage(w)
      if (any(vapply(warning_patterns, grepl, logical(1), x = msg))) {
        invokeRestart("muffleWarning")
      }
    }
  )
}
