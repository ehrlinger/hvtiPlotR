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
##   sh  <- hv_stacked(dta, x_col = "year", group_col = "category",
##                       position = "fill")
##
##   plot(sh) +
##     ggplot2::scale_fill_brewer(palette = "Set1", name = "Category") +
##     ggplot2::scale_color_brewer(palette = "Set1", name = "Category") +
##     hv_theme("manuscript")
##
###############################################################################

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

#' Prepare stacked histogram data for plotting
#'
#' Validates a patient-level or observation-level data frame and returns an
#' \code{hv_stacked} object.  Call \code{\link{plot.hv_stacked}} on the
#' result to obtain a bare \code{ggplot2} stacked (or proportional) histogram
#' that you can decorate with colour scales, axis labels, and
#' \code{\link{hv_theme}}.
#'
#' @param data      A data frame.
#' @param x_col     Name of the numeric column to bin along the x-axis.
#'   Default \code{"year"}.
#' @param group_col Name of the column whose distinct values define the stacked
#'   groups.  Will be coerced to a factor inside the aesthetic mapping.
#'   Default \code{"category"}.
#' @param binwidth  Width of each histogram bin, in the same units as
#'   \code{x_col}. Default \code{1}.
#' @param position  Bar position: \code{"stack"} (raw counts, the default)
#'   or \code{"fill"} (proportions that sum to 1 within each bin).
#'
#' @return An object of class \code{c("hv_stacked", "hv_data")}:
#' \describe{
#'   \item{\code{$data}}{The validated input data frame.}
#'   \item{\code{$meta}}{Named list: \code{x_col}, \code{group_col},
#'     \code{binwidth}, \code{position}, \code{n_obs}, \code{n_groups}.}
#'   \item{\code{$tables}}{Empty list.}
#' }
#'
#' @seealso \code{\link{plot.hv_stacked}},
#'   \code{\link{sample_stacked_histogram_data}}
#'
#' @examples
#' dta <- sample_stacked_histogram_data()
#' sh  <- hv_stacked(dta, x_col = "year", group_col = "category")
#' sh   # prints obs / group count
#'
#' plot(sh) +
#'   ggplot2::scale_fill_brewer(palette = "Set1", name = "Category") +
#'   ggplot2::scale_color_brewer(palette = "Set1", name = "Category") +
#'   ggplot2::labs(x = "Year", y = "Count") +
#'   hv_theme("manuscript")
#'
#' @importFrom rlang .data
#' @export
hv_stacked <- function(data,
                          x_col     = "year",
                          group_col = "category",
                          binwidth  = 1,
                          position  = c("stack", "fill")) {
  position <- match.arg(position)
  .check_df(data)
  .check_cols(data, c(x_col, group_col))
  .check_numeric_col(data, x_col)
  if (!is.numeric(binwidth) || length(binwidth) != 1L || !(binwidth > 0))
    stop("`binwidth` must be a positive numeric scalar.", call. = FALSE)

  n_groups <- length(unique(data[[group_col]]))

  new_hv_data(
    data = as.data.frame(data),
    meta = list(
      x_col     = x_col,
      group_col = group_col,
      binwidth  = binwidth,
      position  = position,
      n_obs     = nrow(data),
      n_groups  = n_groups
    ),
    tables   = list(),
    subclass = "hv_stacked"
  )
}


#' Print an hv_stacked object
#'
#' @param x   An \code{hv_stacked} object from \code{\link{hv_stacked}}.
#' @param ... Ignored.
#' @return \code{x}, invisibly.
#' @export
print.hv_stacked <- function(x, ...) {
  m <- x$meta
  cat("<hv_stacked>\n")
  cat(sprintf("  N obs       : %d  (%d groups)\n", m$n_obs, m$n_groups))
  cat(sprintf("  x / group   : %s / %s\n", m$x_col, m$group_col))
  cat(sprintf("  binwidth    : %g\n", m$binwidth))
  cat(sprintf("  position    : %s\n", m$position))
  invisible(x)
}


#' Plot an hv_stacked object
#'
#' Draws a stacked (or proportional fill) histogram for the grouped numeric
#' variable stored in the \code{hv_stacked} object.
#'
#' @param x   An \code{hv_stacked} object.
#' @param ... Ignored; present for S3 consistency.
#'
#' @return A bare \code{\link[ggplot2]{ggplot}} object.  Add scales, labels,
#'   and themes with the usual \code{+} operator.
#'
#' @seealso \code{\link{hv_stacked}}, \code{\link{hv_theme}}
#'
#' @examples
#' dta <- sample_stacked_histogram_data()
#'
#' # Count histogram
#' plot(hv_stacked(dta, x_col = "year", group_col = "category")) +
#'   ggplot2::scale_fill_brewer(palette = "Set1", name = "Category") +
#'   ggplot2::scale_color_brewer(palette = "Set1", name = "Category") +
#'   ggplot2::labs(x = "Year", y = "Count") +
#'   hv_theme("manuscript")
#'
#' # Proportional (fill) histogram with manual colours
#' plot(hv_stacked(dta, x_col = "year", group_col = "category",
#'                   position = "fill")) +
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
#'   hv_theme("manuscript")
#'
#' @importFrom ggplot2 ggplot aes geom_histogram
#' @importFrom rlang .data
#' @export
plot.hv_stacked <- function(x, ...) {
  m <- x$meta
  ggplot2::ggplot(x$data, ggplot2::aes(
    x      = .data[[m$x_col]],
    fill   = factor(.data[[m$group_col]]),
    colour = factor(.data[[m$group_col]])
  )) +
    ggplot2::geom_histogram(binwidth = m$binwidth,
                            position = m$position)
}


#' Generate Sample Data for Stacked Histogram
#'
#' Creates a minimal data frame suitable for demonstrating or testing
#' \code{\link{hv_stacked}}.
#'
#' @param n_years      Integer. Number of consecutive years to simulate starting
#'   from \code{start_year}. Defaults to `20`.
#' @param start_year   Integer. First calendar year in the sequence. Defaults to
#'   `2000`.
#' @param n_categories Integer. Number of distinct groups. Defaults to `3`.
#' @param seed         Integer passed to \code{\link[base]{set.seed}} for
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
                                          seed         = 42L) {
  if (!is.numeric(n_years) || length(n_years) != 1L || n_years < 1L ||
      n_years %% 1 != 0)
    stop("`n_years` must be a positive integer.", call. = FALSE)
  if (!is.numeric(n_categories) || length(n_categories) != 1L ||
      n_categories < 1L || n_categories %% 1 != 0)
    stop("`n_categories` must be a positive integer.", call. = FALSE)
  if (!is.numeric(start_year) || length(start_year) != 1L ||
      !is.finite(start_year) || start_year %% 1 != 0)
    stop("`start_year` must be a finite integer-valued number.", call. = FALSE)

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
