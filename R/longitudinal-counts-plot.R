# longitudinal-counts-plot.R
#
# Grouped bar chart of patient / measurement counts at discrete follow-up
# time points, with an optional numeric data table below the bars.
# Ports the pattern from tp.dp.longitudinal_patients_measures.R (template
# graph library) to hvtiPlotR.
#
# Key differences from the template:
#  - Accepts pre-aggregated long-format data — no reshape2::melt() needed
#  - Hard-coded colours ("blue", "red", "black") replaced by scale_fill_*
#    and scale_colour_* on the returned ggplot objects
#  - Hard-coded theme() calls replaced by theme_hv_poster()
#  - Bar chart and table returned via plot(x, type=) dispatch; patchwork
#    composes them (replaces the manual grid.layout / mmplot() pattern)
#  - sample_spaghetti_data() is reused in the examples to show how to
#    derive participation counts from patient-level data
# ---------------------------------------------------------------------------

#' Sample Longitudinal Counts Data
#'
#' Builds a pre-aggregated summary data frame of patient and measurement counts
#' at discrete follow-up time windows. The counts are derived by binning the
#' continuous `time` column from [sample_spaghetti_data()], so the two
#' functions share the same underlying simulation.
#'
#' @param n_patients Number of unique patients passed to
#'   [sample_spaghetti_data()]. Default `300`.
#' @param max_obs    Maximum observations per patient passed to
#'   [sample_spaghetti_data()]. Default `6`.
#' @param seed       Random seed. Default `42`.
#'
#' @return A data frame in long format with columns:
#'   - `time_label` — ordered factor of follow-up windows
#'   - `series`     — `"Patients"` or `"Measurements"`
#'   - `count`      — integer count
#'
#' @seealso [hv_longitudinal()], [sample_spaghetti_data()]
#'
#' @examples
#' dta <- sample_longitudinal_counts_data(n_patients = 300, seed = 42)
#' str(dta)                # time_label (factor), series, count
#' levels(dta$time_label)  # 7 discrete follow-up windows
#'
#' # Inspect patient counts at each window
#' subset(dta, series == "Patients")
#'
#' # Larger cohort
#' dta2 <- sample_longitudinal_counts_data(n_patients = 1000, seed = 7)
#' max(dta2$count)         # peak observation count
#' @export
sample_longitudinal_counts_data <- function(n_patients = 300,
                                            max_obs    = 6,
                                            seed       = 42L) {
  raw <- sample_spaghetti_data(
    n_patients = n_patients,
    max_obs    = max_obs,
    seed       = seed
  )

  # Discrete follow-up windows matching the template time points
  # Start at time 0 so the first bin ("\u22650 Days") is populated, and add a
  # break at 2.5 years so the "\u22652.5 Years" label corresponds to a real window.
  breaks <- c(0, 1/12, 3/12, 6/12, 1, 2, 2.5, Inf)
  labels <- c("\u22650 Days", "\u22651 Month", "\u22653 Months",
               "\u22656 Months", "\u22651 Year", "\u22652 Years",
               "\u22652.5 Years")

  raw$window <- cut(raw$time, breaks = breaks, labels = labels,
                    right = FALSE, include.lowest = TRUE)

  # Patients: unique subjects with at least one measurement in the window
  # tapply() returns NA for empty factor levels; replace with 0
  n_pat  <- tapply(raw$id, raw$window, function(x) length(unique(x)))
  n_pat[is.na(n_pat)] <- 0L
  # Measurements: total observation rows in the window
  n_meas <- tabulate(raw$window, nbins = length(labels))

  data.frame(
    time_label = rep(factor(labels, levels = labels), 2L),
    series     = rep(c("Patients", "Measurements"), each = length(labels)),
    count      = c(as.integer(n_pat), as.integer(n_meas)),
    stringsAsFactors = FALSE
  )
}

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

#' Prepare longitudinal participation counts data for plotting
#'
#' Validates a pre-aggregated long-format counts data frame and returns an
#' \code{hv_longitudinal} object.  Call \code{\link{plot.hv_longitudinal}}
#' on the result with \code{type = "plot"} for the grouped bar chart or
#' \code{type = "table"} for the numeric text-table panel.  Compose both
#' panels with \pkg{patchwork}.
#'
#' @param data      Long-format data frame; one row per series per time point.
#'   See \code{\link{sample_longitudinal_counts_data}}.
#' @param x_col     Name of the discrete time-label column. Default \code{"time_label"}.
#' @param count_col Name of the numeric count column. Default \code{"count"}.
#' @param group_col Name of the series grouping column. Default \code{"series"}.
#'
#' @return An object of class \code{c("hv_longitudinal", "hv_data")}:
#' \describe{
#'   \item{\code{$data}}{The validated input data frame.}
#'   \item{\code{$meta}}{Named list: \code{x_col}, \code{count_col},
#'     \code{group_col}, \code{n_timepoints}, \code{n_groups}, \code{n_obs}.}
#'   \item{\code{$tables}}{Empty list.}
#' }
#'
#' @seealso \code{\link{plot.hv_longitudinal}},
#'   \code{\link{sample_longitudinal_counts_data}}
#'
#' @examples
#' dta <- sample_longitudinal_counts_data(n_patients = 300, seed = 42L)
#'
#' # 1. Build data object
#' lc <- hv_longitudinal(dta)
#' lc  # prints group/time-point counts
#'
#' # 2. Bare plot -- undecorated ggplot returned by plot.hv_longitudinal
#' library(ggplot2)
#' p <- plot(lc, type = "plot")
#'
#' # 3. Decorate: fill palette, y-axis scale, labels, theme
#' p +
#'   scale_fill_manual(
#'     values = c(Patients = "steelblue", Measurements = "firebrick"),
#'     name   = NULL
#'   ) +
#'   scale_y_continuous(labels = scales::comma,
#'                      breaks = seq(0, 2000, 500),
#'                      expand = c(0, 0)) +
#'   coord_cartesian(ylim = c(0, 2200)) +
#'   labs(x = "Follow-up Window", y = "Count (n)") +
#'   theme_hv_poster() +
#'   theme(legend.position = c(0.85, 0.85))
#'
#' @importFrom rlang .data
#' @export
hv_longitudinal <- function(data,
                               x_col     = "time_label",
                               count_col = "count",
                               group_col = "series") {
  .check_df(data)
  .check_cols(data, c(x_col, count_col, group_col))

  n_timepoints <- length(unique(data[[x_col]]))
  n_groups     <- length(unique(data[[group_col]]))

  new_hv_data(
    data = as.data.frame(data),
    meta = list(
      x_col        = x_col,
      count_col    = count_col,
      group_col    = group_col,
      n_timepoints = n_timepoints,
      n_groups     = n_groups,
      n_obs        = nrow(data)
    ),
    tables   = list(),
    subclass = "hv_longitudinal"
  )
}


#' Print an hv_longitudinal object
#'
#' @param x   An \code{hv_longitudinal} object from \code{\link{hv_longitudinal}}.
#' @param ... Ignored.
#' @return \code{x}, invisibly.
#' @export
print.hv_longitudinal <- function(x, ...) {
  m <- x$meta
  cat("<hv_longitudinal>\n")
  cat(sprintf("  Time points : %d\n", m$n_timepoints))
  cat(sprintf("  Groups      : %d  (%d rows)\n", m$n_groups, m$n_obs))
  cat(sprintf("  x / count / group : %s / %s / %s\n",
              m$x_col, m$count_col, m$group_col))
  invisible(x)
}


#' Plot an hv_longitudinal object
#'
#' Draws either a grouped bar chart of counts by time point (\code{type = "plot"})
#' or a numeric text-table panel suitable for composing below the bar chart via
#' \pkg{patchwork} (\code{type = "table"}).
#'
#' @param x            An \code{hv_longitudinal} object.
#' @param type         Which panel to produce: \code{"plot"} (default) or
#'   \code{"table"}.
#' @param position     Bar position for \code{type = "plot"}: \code{"dodge"}
#'   (default) or \code{"stack"}.
#' @param label_format Formatting function applied to count values for
#'   \code{type = "table"}.  \code{NULL} (default) auto-selects
#'   \code{scales::comma} when the \pkg{scales} package is installed, otherwise
#'   falls back to \code{base::as.character}.  Pass \code{identity} to display
#'   counts without formatting.
#' @param ...          Ignored; present for S3 consistency.
#'
#' @return A bare \code{\link[ggplot2]{ggplot}} object.
#'
#' @seealso \code{\link{hv_longitudinal}}
#'
#' @examples
#' library(ggplot2)
#' dta <- sample_longitudinal_counts_data(n_patients = 300, seed = 42L)
#' lc  <- hv_longitudinal(dta)
#'
#' # Bar chart
#' plot(lc, type = "plot") +
#'   scale_fill_manual(
#'     values = c(Patients = "steelblue", Measurements = "firebrick"),
#'     name   = NULL
#'   ) +
#'   labs(x = "Follow-up Window", y = "Count (n)") +
#'   theme_hv_poster()
#'
#' # Text table panel
#' plot(lc, type = "table") +
#'   scale_colour_manual(
#'     values = c(Patients = "steelblue", Measurements = "firebrick"),
#'     guide  = "none"
#'   ) +
#'   theme_hv_poster()
#'
#' # Compose with patchwork
#' # p_bar   <- plot(lc, type = "plot")   + <decorators>
#' # p_table <- plot(lc, type = "table")  + <decorators>
#' # p_bar / p_table + patchwork::plot_layout(heights = c(3, 1))
#'
#' @importFrom ggplot2 ggplot aes geom_bar geom_text scale_y_discrete theme
#'   element_blank
#' @importFrom rlang .data
#' @export
plot.hv_longitudinal <- function(x,
                                    type         = c("plot", "table"),
                                    position     = "dodge",
                                    label_format = NULL,
                                    ...) {
  type <- match.arg(type)

  data      <- x$data
  x_col     <- x$meta$x_col
  count_col <- x$meta$count_col
  group_col <- x$meta$group_col

  if (type == "plot") {
    if (!(position %in% c("dodge", "stack")))
      stop('`position` must be "dodge" or "stack".', call. = FALSE)

    ggplot2::ggplot(
      data,
      ggplot2::aes(
        x    = .data[[x_col]],
        y    = .data[[count_col]],
        fill = .data[[group_col]]
      )
    ) +
      ggplot2::geom_bar(stat = "identity", position = position)

  } else {
    # type == "table"
    if (is.null(label_format)) {
      if (requireNamespace("scales", quietly = TRUE)) {
        label_format <- scales::comma
      } else {
        label_format <- as.character
      }
    }

    table_data        <- data
    table_data$.label <- label_format(data[[count_col]])

    ggplot2::ggplot(
      table_data,
      ggplot2::aes(
        x      = .data[[x_col]],
        y      = .data[[group_col]],
        label  = .data$.label,
        colour = .data[[group_col]]
      )
    ) +
      ggplot2::geom_text(size = 4) +
      ggplot2::scale_y_discrete(limits = rev) +
      ggplot2::theme(
        axis.text.x  = ggplot2::element_blank(),
        axis.ticks   = ggplot2::element_blank(),
        axis.title   = ggplot2::element_blank()
      )
  }
}
