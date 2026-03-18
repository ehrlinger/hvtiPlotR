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
  breaks <- c(-Inf, 0, 1/12, 3/12, 6/12, 1, 2, Inf)
  labels <- c("\u22650 Days", "\u22651 Month", "\u22653 Months",
               "\u22656 Months", "\u22651 Year", "\u22652 Years",
               "\u22652.5 Years")

  raw$window <- cut(raw$time, breaks = breaks, labels = labels,
                    right = FALSE, include.lowest = TRUE)

  # Patients: unique subjects with at least one measurement in the window
  n_pat  <- tapply(raw$id, raw$window, function(x) length(unique(x)))
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

#' Longitudinal Participation Counts Plot
#'
#' Produces a grouped bar chart showing how many patients and measurements are
#' available at each discrete follow-up time point — a data-completeness /
#' study-design summary. Optionally pairs the bars with a numeric data table
#' rendered below, matching the two-panel layout from the SAS template.
#'
#' Returns a named list so the caller can compose the panels independently or
#' together via `patchwork`:
#' ```r
#' result <- longitudinal_counts_plot(dta)
#' result$bar_plot / result$table_plot +
#'   patchwork::plot_layout(heights = c(3, 1))
#' ```
#'
#' @param data         Long-format data frame with one row per
#'   (time point × series) combination. See [sample_longitudinal_counts_data()]
#'   for the expected structure.
#' @param x_col        Name of the discrete time-label column. Must be a
#'   factor or character. Default `"time_label"`.
#' @param count_col    Name of the numeric count column. Default `"count"`.
#' @param group_col    Name of the series grouping column (e.g. `"Patients"` vs
#'   `"Measurements"`). Default `"series"`.
#' @param position     Bar position: `"dodge"` (default, side-by-side) or
#'   `"stack"`.
#' @param label_format Function used to format count values in the data table.
#'   Default [scales::comma]. Pass `NULL` for no formatting.
#'
#' @return A named list with two elements:
#'   - `$bar_plot`   — grouped bar chart ([ggplot2::ggplot()])
#'   - `$table_plot` — numeric data table as a ggplot text panel
#'
#' @seealso [sample_longitudinal_counts_data()], [sample_spaghetti_data()],
#'   [hvti_theme()]
#' @aliases participation_plot counts_plot
#'
#' @examples
#' library(ggplot2)
#'
#' dta <- sample_longitudinal_counts_data(n_patients = 300, seed = 42)
#' result <- longitudinal_counts_plot(dta)
#'
#' # --- Bar chart with manuscript theme ------------------------------------
#' result$bar_plot +
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
#' # --- Table panel alone --------------------------------------------------
#' result$table_plot +
#'   scale_colour_manual(
#'     values = c(Patients = "steelblue", Measurements = "firebrick"),
#'     guide  = "none"
#'   ) +
#'   hvti_theme("manuscript")
#'
#' # --- Combined bar + table via patchwork ---------------------------------
#' \dontrun{
#' library(patchwork)
#'
#' (result$bar_plot +
#'    scale_fill_manual(
#'      values = c(Patients = "steelblue", Measurements = "firebrick"),
#'      name   = NULL
#'    ) +
#'    scale_y_continuous(labels = scales::comma, expand = c(0, 0)) +
#'    labs(x = NULL, y = "Count (n)") +
#'    hvti_theme("manuscript") +
#'    theme(legend.position = c(0.85, 0.85),
#'          axis.text.x = element_blank(),
#'          axis.ticks.x = element_blank())) /
#' (result$table_plot +
#'    scale_colour_manual(
#'      values = c(Patients = "steelblue", Measurements = "firebrick"),
#'      guide  = "none"
#'    ) +
#'    hvti_theme("manuscript")) +
#' plot_layout(heights = c(3, 1))
#' }
#'
#' # --- Deriving counts from patient-level data ----------------------------
#' \dontrun{
#' # sample_spaghetti_data() has continuous time; bin it yourself:
#' raw <- sample_spaghetti_data(n_patients = 300, seed = 42)
#' breaks <- c(-Inf, 0, 1/12, 3/12, 6/12, 1, 2, Inf)
#' labels <- c(">=0d", ">=1m", ">=3m", ">=6m", ">=1y", ">=2y", ">=2.5y")
#' raw$window <- cut(raw$time, breaks, labels = labels,
#'                   right = FALSE, include.lowest = TRUE)
#' n_pat  <- tapply(raw$id, raw$window, function(x) length(unique(x)))
#' n_meas <- tabulate(raw$window, nbins = length(labels))
#' dta_custom <- data.frame(
#'   time_label = rep(factor(labels, levels = labels), 2),
#'   series     = rep(c("Patients", "Measurements"), each = length(labels)),
#'   count      = c(as.integer(n_pat), as.integer(n_meas))
#' )
#' longitudinal_counts_plot(dta_custom)$bar_plot +
#'   scale_fill_brewer(palette = "Set1", name = NULL) +
#'   labs(x = "Follow-up Window", y = "n") +
#'   hvti_theme("manuscript")
#' }
#'
#' # --- Save ---------------------------------------------------------------
#' \dontrun{
#' p <- result$bar_plot +
#'   scale_fill_manual(
#'     values = c(Patients = "steelblue", Measurements = "firebrick"),
#'     name = NULL
#'   ) +
#'   labs(x = "Follow-up Window", y = "Count (n)") +
#'   hvti_theme("manuscript")
#' ggsave("longitudinal_counts.pdf", p, width = 11, height = 8.5)
#' }
#'
#' @importFrom ggplot2 ggplot aes geom_bar geom_text scale_x_discrete
#'   scale_y_discrete
#' @importFrom rlang sym
#' @export
longitudinal_counts_plot <- function(data,
                                     x_col        = "time_label",
                                     count_col    = "count",
                                     group_col    = "series",
                                     position     = "dodge",
                                     label_format = scales::comma) {

  # --- Validation -----------------------------------------------------------
  assertthat::assert_that(
    is.data.frame(data),
    msg = "`data` must be a data frame."
  )
  for (col in c(x_col, count_col, group_col)) {
    assertthat::assert_that(
      col %in% names(data),
      msg = paste0("Column '", col, "' not found in `data`.")
    )
  }
  assertthat::assert_that(
    position %in% c("dodge", "stack"),
    msg = '`position` must be "dodge" or "stack".'
  )

  x_sym     <- rlang::sym(x_col)
  count_sym <- rlang::sym(count_col)
  group_sym <- rlang::sym(group_col)

  # --- Bar chart ------------------------------------------------------------
  bar_plot <- ggplot2::ggplot(
    data,
    ggplot2::aes(
      x    = !!x_sym,
      y    = !!count_sym,
      fill = !!group_sym
    )
  ) +
    ggplot2::geom_bar(stat = "identity", position = position)

  # --- Data table -----------------------------------------------------------
  # Format labels
  fmt_fn <- if (is.null(label_format)) as.character else label_format

  table_data        <- data
  table_data$.label <- fmt_fn(data[[count_col]])

  table_plot <- ggplot2::ggplot(
    table_data,
    ggplot2::aes(
      x      = !!x_sym,
      y      = !!group_sym,
      label  = .data$.label,
      colour = !!group_sym
    )
  ) +
    ggplot2::geom_text(size = 4) +
    ggplot2::scale_y_discrete(limits = rev) +
    ggplot2::theme(
      axis.text.x  = ggplot2::element_blank(),
      axis.ticks   = ggplot2::element_blank(),
      axis.title   = ggplot2::element_blank()
    )

  list(bar_plot = bar_plot, table_plot = table_plot)
}
