###############################################################################
## Reusable stacked histogram for grouped count or proportion distributions.
## Inspired by the dp.trends template used across CCF cardiac surgery studies.
###############################################################################
##
## Quick start
## -----------
## Generate sample data, build the plot, then layer on scales and a theme:
##
##   dta <- sample_stacked_histogram_data()
##
##   # Proportion (fill) variant
##   p <- stacked_histogram(dta, x_col = "year", group_col = "category",
##                          position = "fill")
##
##   p +
##     ggplot2::scale_fill_brewer(palette = "Set1", name = "Category") +
##     ggplot2::scale_color_brewer(palette = "Set1", name = "Category") +
##     hvti_theme("manuscript")
##
###############################################################################

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

# Validate stacked_histogram inputs
validate_stacked_histogram_input <- function(data, x_col, group_col, binwidth, position) {
  assertthat::assert_that(is.data.frame(data), msg = "`data` must be a data.frame.")
  missing_cols <- setdiff(c(x_col, group_col), names(data))
  assertthat::assert_that(length(missing_cols) == 0,
                          msg = sprintf(
                            "Missing required columns: %s",
                            paste(missing_cols, collapse = ", ")
                          ))
  assertthat::assert_that(is.numeric(data[[x_col]]), msg = sprintf("`%s` must be numeric.", x_col))
  assertthat::assert_that(assertthat::is.number(binwidth) &&
                            binwidth > 0, msg = "`binwidth` must be a positive numeric scalar.")
  assertthat::assert_that(position %in% c("stack", "fill"), msg = '`position` must be "stack" or "fill".')
}

# Build the bare ggplot object without scale or label modifications
#' @importFrom ggplot2 ggplot aes geom_histogram
build_stacked_histogram_plot <- function(data, x_col, group_col, binwidth, position) {
  ggplot2::ggplot(data, ggplot2::aes(
    x      = .data[[x_col]],
    fill   = factor(.data[[group_col]]),
    colour = factor(.data[[group_col]])
  )) +
    ggplot2::geom_histogram(binwidth = binwidth,
                            position = position)
}

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

#' Stacked Histogram
#'
#' Builds a stacked (or proportional fill) histogram for a grouped numeric
#' variable. The returned ggplot object intentionally omits scale and label
#' modifications so the caller can layer on their own colour/fill scales,
#' axis labels, and themes without fighting existing defaults.
#'
#' @param data A data frame.
#' @param x_col Name of the numeric column to bin along the x-axis.
#' @param group_col Name of the column whose distinct values define the stacked
#'   groups. Will be coerced to a factor inside the aesthetic mapping.
#' @param binwidth Width of each histogram bin, in the same units as `x_col`.
#'   Defaults to `1`.
#' @param position Either `"stack"` (raw counts, the default) or `"fill"`
#'   (proportions that sum to 1 within each bin).
#'
#' @return A \code{\link[ggplot2]{ggplot}} object.  Add scales, labels, and
#'   themes with the usual `+` operator.
#'
#' @examples
#' dta <- sample_stacked_histogram_data()
#'
#' # --- Count histogram (default) -------------------------------------------
#' p_count <- stacked_histogram(dta, x_col = "year", group_col = "category")
#'
#' # Add colour / fill scales and a theme
#' p_count +
#'   ggplot2::scale_fill_brewer(palette = "Set1", name = "Category") +
#'   ggplot2::scale_color_brewer(palette = "Set1", name = "Category") +
#'   ggplot2::labs(x = "Year", y = "Count") +
#'   hvti_theme("manuscript")
#'
#' # Save to disk
#' \dontrun{
#' ggplot2::ggsave(
#'   filename = "histogram_count.pdf",
#'   plot     = p_count +
#'     ggplot2::scale_fill_brewer(palette = "Set1", name = "Category") +
#'     ggplot2::scale_color_brewer(palette = "Set1", name = "Category") +
#'     ggplot2::labs(x = "Year", y = "Count") +
#'     hvti_theme("manuscript"),
#'   width  = 11,
#'   height = 8
#' )
#' }
#'
#' # --- Proportional (fill) histogram ----------------------------------------
#' p_fill <- stacked_histogram(dta, x_col = "year", group_col = "category",
#'                             position = "fill")
#'
#' # Manual colour palette with custom legend labels
#' p_fill +
#'   ggplot2::scale_fill_manual(
#'     values = c("1" = "pink", "2" = "cyan", "3" = "orangered"),
#'     labels = c("1" = "Group A", "2" = "Group B", "3" = "Group C"),
#'     name   = "Category"
#'   ) +
#'   ggplot2::scale_color_manual(
#'     values = c("1" = "pink", "2" = "cyan", "3" = "orangered"),
#'     guide  = "none"
#'   ) +
#'   ggplot2::labs(x = "Year", y = "Proportion") +
#'   hvti_theme("manuscript")
#'
#' # Save the proportion plot
#' \dontrun{
#' ggplot2::ggsave(
#'   filename = "histogram_proportion.pdf",
#'   plot     = p_fill +
#'     ggplot2::scale_fill_manual(
#'       values = c("1" = "pink", "2" = "cyan", "3" = "orangered"),
#'       name   = "Category"
#'     ) +
#'     ggplot2::scale_color_manual(
#'       values = c("1" = "pink", "2" = "cyan", "3" = "orangered"),
#'       guide  = "none"
#'     ) +
#'     ggplot2::labs(x = "Year", y = "Proportion") +
#'     hvti_theme("manuscript"),
#'   width  = 11,
#'   height = 8
#' )
#' }
#'
#' @importFrom ggplot2 ggplot aes geom_histogram
#' @export
stacked_histogram <- function(data,
                              x_col     = "year",
                              group_col = "category",
                              binwidth  = 1,
                              position  = c("stack", "fill")) {
  position <- match.arg(position)
  validate_stacked_histogram_input(data, x_col, group_col, binwidth, position)
  build_stacked_histogram_plot(data, x_col, group_col, binwidth, position)
}

#' Generate Sample Data for Stacked Histogram
#'
#' Creates a minimal data frame suitable for demonstrating or testing
#' \code{\link{stacked_histogram}}.
#'
#' @param n_years Integer. Number of consecutive years to simulate starting
#'   from \code{start_year}. Defaults to `20`.
#' @param start_year Integer. First calendar year in the sequence. Defaults to
#'   `2000`.
#' @param n_categories Integer. Number of distinct groups. Defaults to `3`.
#' @param seed Integer passed to \code{\link[base]{set.seed}} for
#'   reproducibility. Defaults to `42`.
#'
#' @return A data frame with columns \code{year} (integer) and
#'   \code{category} (integer, 1 to \code{n_categories}).
#'
#' @examples
#' dta <- sample_stacked_histogram_data()
#' head(dta)
#' table(dta$year, dta$category)
#'
#' @importFrom stats rpois
#' @export
sample_stacked_histogram_data <- function(n_years      = 20,
                                          start_year   = 2000,
                                          n_categories = 3,
                                          seed         = 42) {
  assertthat::assert_that(assertthat::is.count(n_years), 
                          msg = "`n_years` must be a positive integer.")
  assertthat::assert_that(assertthat::is.count(n_categories), 
                          msg = "`n_categories` must be a positive integer.")
  
  set.seed(seed)
  years <- start_year + seq_len(n_years) - 1L
  
  rows <- lapply(years, function(yr) {
    n <- stats::rpois(1, lambda = 20)
    if (n == 0L)
      n <- 1L
    data.frame(year     = rep(yr, n),
               category = sample(seq_len(n_categories), n, replace = TRUE))
  })
  
  do.call(rbind, rows)
}

utils::globalVariables(c(".data"))
