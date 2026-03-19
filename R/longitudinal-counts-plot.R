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
#  - Hard-coded theme() calls replaced by hvti_theme("manuscript")
#  - Bar chart and table returned as a named list; patchwork composes them
#    (replaces the manual grid.layout / mmplot() pattern)
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
#' @seealso [longitudinal_counts_plot()], [sample_spaghetti_data()]
#'
#' @examples
#' dta <- sample_longitudinal_counts_data(n_patients = 300, seed = 42)
#' dta
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
  # Start at time 0 so the first bin ("≥0 Days") is populated, and add a
  # break at 2.5 years so the "≥2.5 Years" label corresponds to a real window.
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

#' Longitudinal Participation Counts Bar Chart
#'
#' Produces a grouped bar chart showing how many patients and measurements are
#' available at each discrete follow-up time point. Pair with
#' [longitudinal_counts_table()] via `patchwork` for the full two-panel layout.
#'
#' @param data      Long-format data frame. See [sample_longitudinal_counts_data()].
#' @param x_col     Name of the discrete time-label column. Default `"time_label"`.
#' @param count_col Name of the numeric count column. Default `"count"`.
#' @param group_col Name of the series grouping column. Default `"series"`.
#' @param position  Bar position: `"dodge"` (default) or `"stack"`.
#'
#' @return A bare [ggplot2::ggplot()] object.
#'
#' @seealso [longitudinal_counts_table()], [sample_longitudinal_counts_data()]
#'
#' @examples
#' library(ggplot2)
#' dta <- sample_longitudinal_counts_data(n_patients = 300, seed = 42L)
#'
#' longitudinal_counts_plot(dta) +
#'   scale_fill_manual(
#'     values = c(Patients = "steelblue", Measurements = "firebrick"),
#'     name   = NULL
#'   ) +
#'   scale_y_continuous(labels = scales::comma,
#'                      breaks = seq(0, 2000, 500),
#'                      expand = c(0, 0)) +
#'   coord_cartesian(ylim = c(0, 2200)) +
#'   labs(x = "Follow-up Window", y = "Count (n)") +
#'   hvti_theme("manuscript") +
#'   theme(legend.position = c(0.85, 0.85))
#'
#' @importFrom ggplot2 ggplot aes geom_bar
#' @importFrom rlang .data
#' @export
longitudinal_counts_plot <- function(data,
                                     x_col     = "time_label",
                                     count_col = "count",
                                     group_col = "series",
                                     position  = "dodge") {
  if (!is.data.frame(data))
    stop("`data` must be a data frame.")
  for (col in c(x_col, count_col, group_col)) {
    if (!(col %in% names(data)))
      stop(paste0("Column '", col, "' not found in `data`."))
  }
  if (!(position %in% c("dodge", "stack")))
    stop('`position` must be "dodge" or "stack".')

  ggplot2::ggplot(
    data,
    ggplot2::aes(x = .data[[x_col]], y = .data[[count_col]], fill = .data[[group_col]])
  ) +
    ggplot2::geom_bar(stat = "identity", position = position)
}

# ---------------------------------------------------------------------------

#' Longitudinal Participation Counts Table Panel
#'
#' Produces a numeric data table rendered as a ggplot text panel, intended to
#' be composed below [longitudinal_counts_plot()] via `patchwork`.
#'
#' @param data         Long-format data frame. See [sample_longitudinal_counts_data()].
#' @param x_col        Name of the discrete time-label column. Default `"time_label"`.
#' @param count_col    Name of the numeric count column. Default `"count"`.
#' @param group_col    Name of the series grouping column. Default `"series"`.
#' @param label_format Formatting function applied to count values.
#'   `NULL` (default) auto-selects: uses [scales::comma] when the `scales`
#'   package is installed, otherwise falls back to [base::as.character].
#'   Pass `identity` to display counts with no formatting.
#'
#' @return A bare [ggplot2::ggplot()] object (text table panel).
#'
#' @seealso [longitudinal_counts_plot()], [sample_longitudinal_counts_data()]
#'
#' @examples
#' library(ggplot2)
#' dta <- sample_longitudinal_counts_data(n_patients = 300, seed = 42L)
#'
#' longitudinal_counts_table(dta) +
#'   scale_colour_manual(
#'     values = c(Patients = "steelblue", Measurements = "firebrick"),
#'     guide  = "none"
#'   ) +
#'   hvti_theme("manuscript")
#'
#' @importFrom ggplot2 ggplot aes geom_text scale_y_discrete theme element_blank
#' @importFrom rlang .data
#' @export
longitudinal_counts_table <- function(data,
                                      x_col        = "time_label",
                                      count_col    = "count",
                                      group_col    = "series",
                                      label_format = NULL) {
  if (!is.data.frame(data))
    stop("`data` must be a data frame.")
  for (col in c(x_col, count_col, group_col)) {
    if (!(col %in% names(data)))
      stop(paste0("Column '", col, "' not found in `data`."))
  }

  if (is.null(label_format)) {
    if (requireNamespace("scales", quietly = TRUE)) {
      label_format <- scales::comma
    } else {
      label_format <- as.character
    }
  }

  fmt_fn <- label_format

  table_data        <- data
  table_data$.label <- fmt_fn(data[[count_col]])

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
