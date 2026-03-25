# Shared input-validation helpers
#
# These internal functions consolidate the three most common validation
# patterns across the package:
#   1. Check that an object is a data frame.
#   2. Check that one or more columns exist in a data frame.
#   3. Check that a column is numeric.
#
# All helpers throw with call. = FALSE so the error points at the user-facing
# function, not at the internal validator.

# ---------------------------------------------------------------------------

#' @noRd
.check_df <- function(x, arg = "data") {
  if (!is.data.frame(x))
    stop(sprintf("`%s` must be a data frame.", arg), call. = FALSE)
  invisible(x)
}

#' @noRd
.check_cols <- function(data, cols, data_arg = "data") {
  missing <- setdiff(cols, names(data))
  if (length(missing))
    stop(
      sprintf("Missing required column(s) in `%s`: %s",
              data_arg, paste(missing, collapse = ", ")),
      call. = FALSE
    )
  invisible(data)
}

#' @noRd
.check_col <- function(data, col, data_arg = "data") {
  if (!is.null(col) && !(col %in% names(data)))
    stop(
      sprintf("Column '%s' not found in `%s`. Available: %s",
              col, data_arg, paste(names(data), collapse = ", ")),
      call. = FALSE
    )
  invisible(data)
}

#' @noRd
.check_numeric_col <- function(data, col, data_arg = "data") {
  if (!is.numeric(data[[col]]))
    stop(sprintf("`%s` must be numeric.", col), call. = FALSE)
  invisible(data)
}

#' @noRd
# Finite, positive scalar (e.g. point sizes, line widths).
.check_scalar_positive <- function(x, arg) {
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x <= 0)
    stop(sprintf("`%s` must be a finite, positive numeric scalar.", arg),
         call. = FALSE)
  invisible(x)
}

#' @noRd
# Finite, non-negative scalar (e.g. thresholds that may be zero).
.check_scalar_nonneg <- function(x, arg) {
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x < 0)
    stop(sprintf("`%s` must be a finite, non-negative numeric scalar.", arg),
         call. = FALSE)
  invisible(x)
}

#' @noRd
# Standard alpha validator — enforces [0, 1] (fully transparent to opaque).
# Using (0, 1] was inconsistent across functions and contradicted docs that
# stated [0, 1]; alpha = 0 is valid in ggplot2 and useful for hiding elements.
.check_alpha <- function(alpha) {
  if (!is.numeric(alpha) || length(alpha) != 1L ||
      is.na(alpha) || alpha < 0 || alpha > 1)
    stop("`alpha` must be a number in [0, 1].", call. = FALSE)
  invisible(alpha)
}
