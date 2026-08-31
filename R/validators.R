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
# Report times must be finite and non-negative. A non-finite or negative
# entry is not merely odd input: it survives into the risk and report tables
# as a plausible-looking row (NA reports 100% survival at time NA; Inf
# reports the final survival estimate at time Inf), so the failure is silent
# and the table is misleading rather than obviously wrong.
.check_report_times <- function(report_times, arg = "report_times") {
  if (!(is.numeric(report_times) && length(report_times) > 0L))
    stop(sprintf("`%s` must be a non-empty numeric vector.", arg),
         call. = FALSE)
  bad <- !is.finite(report_times) | report_times < 0
  if (any(bad))
    stop(
      sprintf("`%s` must be finite and non-negative. Offending value(s): %s",
              arg, paste(report_times[bad], collapse = ", ")),
      call. = FALSE
    )
  invisible(report_times)
}

#' @noRd
# Set/column selections must name distinct columns. A repeated name yields a
# data frame with a mangled duplicate column (`A`, `A.1`), which downstream
# produces contradictory regions ("A only" twice) and a nonsense "A & A"
# intersection.
.check_no_duplicates <- function(x, arg) {
  if (anyDuplicated(x))
    stop(
      sprintf("`%s` must not contain duplicate names. Repeated: %s",
              arg, paste(unique(x[duplicated(x)]), collapse = ", ")),
      call. = FALSE
    )
  invisible(x)
}

#' @noRd
# Shared missing-data contract. Incomplete rows are excluded from the
# analysis, so the object must report the *analyzed* cohort rather than the
# input cohort: printing N = nrow(data) while the fit saw fewer rows means the
# reported N does not describe the estimates. Warns once, naming the columns
# responsible, and returns the counts for $meta.
.exclude_incomplete <- function(data, columns, context = NULL) {
  keep       <- stats::complete.cases(data[, columns, drop = FALSE])
  n_input    <- nrow(data)
  n_excluded <- sum(!keep)

  if (n_excluded > 0L) {
    culprits <- columns[vapply(columns, function(cl) anyNA(data[[cl]]),
                               logical(1))]
    warning(
      sprintf(
        "%d of %d row(s) excluded%s for missing values in %s; analysing %d.",
        n_excluded, n_input,
        if (is.null(context)) "" else paste0(" from the ", context),
        paste(sprintf("`%s`", culprits), collapse = ", "),
        n_input - n_excluded
      ),
      call. = FALSE
    )
  }

  list(
    data       = data[keep, , drop = FALSE],
    n_input    = n_input,
    n_analyzed = n_input - n_excluded,
    n_excluded = n_excluded
  )
}

#' @noRd
# Grouping and label columns must be complete. A missing value here does not
# drop the row -- it silently merges it into an "NA" group, which then reads
# as a real series in the legend or, for an id column, fuses unrelated
# subjects into one trajectory. That is a data error, not something to
# account for, so it errors rather than warns. Contrast .count_incomplete(),
# which handles the value columns whose absence genuinely stops a row being
# drawn.
.check_complete_labels <- function(data, columns) {
  for (cl in columns)
    if (!is.null(cl) && anyNA(data[[cl]]))
      stop(sprintf(
        paste("`%s` must not contain missing values: they would be drawn as",
              "an \"NA\" group rather than dropped."), cl),
        call. = FALSE)
  invisible(data)
}

#' @noRd
# Missing-data accounting for the plot-only constructors. Unlike
# .exclude_incomplete(), this does NOT filter: it warns and returns the
# counts, leaving the rows in place for ggplot2 to drop at draw time.
#
# The distinction is deliberate. An analysis constructor must filter, because
# the fit it wraps already has -- reporting a cohort the fit never saw is
# simply wrong. A plot constructor has no fit; pre-filtering here would also
# swallow ggplot2's own "Removed n rows" warning, which legitimately fires
# for values outside a zoomed scale range and not only for missing ones.
# So: analysis constructors filter, plot constructors account.
.count_incomplete <- function(data, columns) {
  keep      <- stats::complete.cases(data[, columns, drop = FALSE])
  n_input   <- nrow(data)
  n_missing <- sum(!keep)

  if (n_missing > 0L) {
    culprits <- columns[vapply(columns, function(cl) anyNA(data[[cl]]),
                               logical(1))]
    warning(
      sprintf(
        "%d of %d row(s) have missing values in %s; they will not be drawn.",
        n_missing, n_input,
        paste(sprintf("`%s`", culprits), collapse = ", ")
      ),
      call. = FALSE
    )
  }

  list(n_input = n_input, n_missing = n_missing)
}

#' @noRd
# The grouping keys tapply() produces, in tapply()'s own order, with the
# original type intact. as.numeric(names(tapply(...))) silently turns factor
# labels and Dates into NA, dropping those summary points from the plot.
.tapply_keys <- function(x) {
  if (is.factor(x)) factor(levels(x), levels = levels(x)) else sort(unique(x))
}

#' @noRd
# Finite, non-negative numeric column (e.g. event counts, which cannot be
# negative and must not silently render a downward bar).
.check_count_col <- function(data, col) {
  v <- data[[col]]
  if (!is.numeric(v))
    stop(sprintf("`%s` must be numeric. Got: %s", col, class(v)[1L]),
         call. = FALSE)
  bad <- !is.na(v) & (!is.finite(v) | v < 0)
  if (any(bad))
    stop(
      sprintf("`%s` must be finite and non-negative. Offending value(s): %s",
              col, paste(unique(v[bad]), collapse = ", ")),
      call. = FALSE
    )
  invisible(data)
}

#' @noRd
# Evaluate `expr`, muffling only lifecycle deprecation warnings raised by a
# dependency we do not control. Deliberately narrow: any other warning still
# propagates, so this cannot mask a problem in our own code. A blanket
# suppressWarnings() would.
.suppress_deprecation <- function(expr) {
  withCallingHandlers(
    expr,
    warning = function(w) {
      if (inherits(w, "lifecycle_warning_deprecated") ||
          grepl("deprecated", conditionMessage(w), fixed = TRUE))
        invokeRestart("muffleWarning")
    }
  )
}

#' @noRd
# Evaluate `expr`, muffling only the glyph-substitution warning R raises when
# a graphics device cannot render a character (e.g. the bullet the `consort`
# package puts in its exclusion labels, on pdf()/postscript()). The figure is
# still drawn; only the glyph degrades. Narrow by design.
.suppress_glyph_warning <- function(expr) {
  withCallingHandlers(
    expr,
    warning = function(w) {
      if (grepl("mbcsToSbcs|conversion failure", conditionMessage(w)))
        invokeRestart("muffleWarning")
    }
  )
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

#' @noRd
# Hazard-multiplier `groups` vectors must be named, distinct, finite and
# strictly positive. Like `.check_report_times()`, the failure mode here is
# silence rather than noise: the multiplier divides the Weibull scale, so a
# negative one yields negative follow-up times, zero yields an infinite scale
# (an arm in which nobody ever has an event), and `NA` yields `NA` times. All
# three survive into an at-risk table as plausible-looking counts --
# `.atrisk_table()` counts `sum(time >= t, na.rm = TRUE)` and simply reports
# a smaller number -- so the figure is misleading rather than obviously wrong.
.check_hazard_groups <- function(groups, arg = "groups") {
  if (!(is.numeric(groups) && length(groups) > 0L))
    stop(sprintf("`%s` must be a non-empty numeric vector of hazard multipliers.", arg),
         call. = FALSE)
  nms <- names(groups)
  # nzchar(NA) is TRUE (keepNA = FALSE), so anyNA() must be checked separately.
  if (is.null(nms) || anyNA(nms) || !all(nzchar(nms)))
    stop(sprintf("`%s` must be a named numeric vector; every element needs a non-empty name.", arg),
         call. = FALSE)
  if (anyDuplicated(nms) > 0L)
    stop(sprintf("`%s` names must be distinct. Duplicated: %s",
                 arg, paste(unique(nms[duplicated(nms)]), collapse = ", ")),
         call. = FALSE)
  bad <- !is.finite(groups) | groups <= 0
  if (any(bad))
    stop(
      sprintf("`%s` multipliers must be finite and > 0. Offending value(s): %s",
              arg, paste(sprintf("%s = %s", nms[bad], groups[bad]), collapse = ", ")),
      call. = FALSE
    )
  invisible(groups)
}
