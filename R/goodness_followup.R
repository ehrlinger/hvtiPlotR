#' Build goodness-of-follow-up plots
#'
#' Converts raw follow-up extracts (either in-memory data frames or SAS
#' transport files) into tidy frames, then draws the classic HVI goodness of
#' follow-up visualizations focused on mortality. The function focuses on
#' preparing the data, mapping states to aesthetics, and
#' drawing the scaffolding geoms; callers are expected to finish the styling via
#' standard `ggplot2` modifiers (`scale_*()`, `labs()`, `theme_*()`), keeping the
#' plotting workflow flexible. The visualizations focus solely on death.
#'
#' @param data Data frame or path to a SAS transport (`.xpt`) file containing
#'   the follow-up data.
#' @param iv_opyrs_col Column name holding the numeric interval (in years) from
#'   `origin_year` to the operation date.
#' @param death_col Logical (or coercible) indicator for death.
#' @param death_time_col Column containing follow-up time to death (or censoring)
#'   expressed in years.
#' @param origin_year Reference calendar year that matches zero in
#'   `iv_opyrs_col`.
#' @param study_start,study_end,close_date Dates that define the diagonal
#'   potential follow-up line.
#' @param tolower_names When TRUE, column names are converted to lower case prior
#'   to processing. This mirrors the behavior of the legacy template.
#' @param death_levels Length-2 character vector used to name the "alive" and
#'   "dead" states.
#' @param alpha Transparency passed to the point and segment layers.
#' @param segment_drop Amount (in years) subtracted from each follow-up value to
#'   draw the short vertical segment beneath each point.
#' @param diagonal_color,diagonal_linetype,diagonal_linewidth Styling controls for
#'   the potential follow-up reference line.
#'
#' @return A list containing:
#'   * `death_plot`: ggplot object displaying the death follow-up chart.
#'   * `death_data`: transformed data frame used in the plot.
#'   * `diagonal`: reference line data frame.
#'
#' @details
#' The helper automatically normalizes column names (when requested), converts
#' logical indicators, and trims incomplete rows prior to plotting. Because all
#' scales, shapes, legends, and labels are left untouched, consumers can compose
#' the final appearance with standard `ggplot2` calls. The visualizations emphasize death-only functionality.
#'
#' @examples
#' set.seed(42)
#' example_followup <- data.frame(
#'   iv_opyrs = runif(40, 0, 30),
#'   iv_dead = runif(40, 0, 25),
#'   dead = sample(c(TRUE, FALSE), 40, TRUE)
#' )
#'
#' plots <- goodness_followup(example_followup)
#'
#' plots$death_plot +
#'   ggplot2::scale_color_brewer(palette = "Set1") +
#'   ggplot2::scale_shape_manual(values = c(1, 4)) +
#'   ggplot2::labs(
#'     x = "Operation Date",
#'     y = "Follow-up (years)",
#'     color = "Death",
#'     shape = "Death"
#'   )
#' @export
goodness_followup <- function(
  data,
  iv_opyrs_col = "iv_opyrs",
  death_col = "dead",
  death_time_col = "iv_dead",
  origin_year = 1990,
  study_start = as.Date("1990-01-01"),
  study_end = as.Date("2019-12-31"),
  close_date = as.Date("2021-08-06"),
  tolower_names = TRUE,
  death_levels = c("Alive", "Dead"),
  alpha = 0.8,
  segment_drop = 0.2,
  diagonal_color = "orange",
  diagonal_linetype = "dashed",
  diagonal_linewidth = 0.6
) {
  if (length(death_levels) != 2) {
    stop("`death_levels` must contain exactly two labels.", call. = FALSE)
  }
  if (!is.numeric(alpha) || alpha <= 0 || alpha > 1) {
    stop("`alpha` must be a numeric value in (0, 1].", call. = FALSE)
  }
  if (!is.numeric(segment_drop) || segment_drop < 0) {
    stop("`segment_drop` must be a non-negative numeric value.", call. = FALSE)
  }
  payload <- gf_materialize_followup_data(data, tolower_names)
  study_start <- gf_coerce_date(study_start, "study_start")
  study_end <- gf_coerce_date(study_end, "study_end")
  close_date <- gf_coerce_date(close_date, "close_date")
  if (study_start > study_end) {
    stop("`study_start` must be earlier than or equal to `study_end`.", call. = FALSE)
  }
  if (close_date < study_end) {
    stop("`close_date` must be greater than or equal to `study_end`.", call. = FALSE)
  }

  gf_require_columns(payload, c(iv_opyrs_col, death_time_col, death_col))
  diag_df <- gf_build_diagonal(study_start, study_end, close_date, origin_year)

  death_df <- gf_prepare_frame(payload, c(iv_opyrs_col, death_time_col, death_col))
  if (!nrow(death_df)) {
    stop("No rows available to build the death follow-up plot.", call. = FALSE)
  }
  death_data <- gf_build_death_frame(
    death_df,
    iv_opyrs_col,
    death_time_col,
    death_col,
    death_levels,
    origin_year,
    segment_drop
  )
  death_plot <- gf_build_followup_plot(
    death_data,
    diag_df,
    alpha,
    diagonal_color,
    diagonal_linetype,
    diagonal_linewidth
  )

  list(
    death_plot = death_plot,
    death_data = death_data,
    diagonal = diag_df
  )
}

# Internal helpers ---------------------------------------------------------

# Keeps data acquisition isolated so the plotting code can assume a vanilla
# data.frame (future refactors could swap in arrow/databases here).
gf_materialize_followup_data <- function(data, tolower_names) {
  if (is.character(data) && length(data) == 1L) {
    if (!file.exists(data)) {
      stop(sprintf("File '%s' does not exist.", data), call. = FALSE)
    }
    if (!requireNamespace("haven", quietly = TRUE)) {
      stop("Reading SAS transport files requires the 'haven' package.", call. = FALSE)
    }
    data <- haven::read_xpt(data)
  }
  data <- as.data.frame(data)
  if (tolower_names) {
    names(data) <- tolower(names(data))
  }
  data
}

# Centralizes loose date inputs so validation stays consistent and new date
# types only need to be supported in one place.
gf_coerce_date <- function(x, label) {
  if (inherits(x, "Date")) {
    return(x)
  }
  out <- try(as.Date(x), silent = TRUE)
  if (inherits(out, "try-error") || is.na(out)) {
    stop(sprintf("`%s` must be coercible to Date.", label), call. = FALSE)
  }
  out
}

# Date arithmetic lives here so any calendar tweak (365 vs 365.25, business
# calendars, etc.) can be changed without touching multiple helpers.
gf_years_between <- function(later, earlier) {
  as.numeric(later - earlier) / 365.2425
}

# Generates the dashed "potential follow-up" diagonal shared by both panels; if
# business logic changes this is the single source of truth.
gf_build_diagonal <- function(study_start, study_end, close_date, origin_year) {
  maxpfup <- gf_years_between(close_date, study_start)
  minpfup <- gf_years_between(close_date, study_end)
  op_span <- gf_years_between(study_end, study_start)
  data.frame(
    operation_year = c(origin_year, origin_year + op_span),
    follow_up = c(maxpfup, minpfup)
  )
}

# Guard clause shared across helpers; keeping it centralized helps a future
# validation framework drop in without rewriting each caller.
gf_require_columns <- function(data, columns) {
  missing_cols <- setdiff(columns, names(data))
  if (length(missing_cols)) {
    stop(
      sprintf(
        "Missing required column(s): %s",
        paste(missing_cols, collapse = ", ")
      ),
      call. = FALSE
    )
  }
}

# Removes incomplete rows once so downstream builders don't each need their own
# NA handling branches.
gf_prepare_frame <- function(data, columns) {
  idx <- stats::complete.cases(data[, columns, drop = FALSE])
  data[idx, columns, drop = FALSE]
}

# Encapsulates all death-specific transformations (scale, factor levels, line
# offsets) to keep the main function declarative.
gf_build_death_frame <- function(df,
                                  iv_col,
                                  follow_col,
                                  flag_col,
                                  levels,
                                  origin_year,
                                  segment_drop) {
  operation_year <- origin_year + as.numeric(df[[iv_col]])
  follow_up <- as.numeric(df[[follow_col]])
  state <- ifelse(as.logical(df[[flag_col]]), levels[2], levels[1])
  data.frame(
    operation_year = operation_year,
    follow_up = follow_up,
    segment_end = pmax(follow_up - segment_drop, 0),
    state = factor(state, levels = levels)
  )
}

# Shared plotting scaffold so aesthetics stay identical across any future
# follow-up panels; future layout changes belong here instead of the public API.
gf_build_followup_plot <- function(data,
                                   diagonal,
                                   alpha,
                                   diagonal_color,
                                   diagonal_linetype,
                                   diagonal_linewidth) {
  ggplot2::ggplot(data, ggplot2::aes(operation_year, follow_up)) +
    ggplot2::geom_point(ggplot2::aes(color = state, shape = state), alpha = alpha) +
    ggplot2::geom_segment(
      ggplot2::aes(
        xend = operation_year,
        yend = segment_end,
        color = state,
        shape = state
      ),
      alpha = alpha
    ) +
    ggplot2::geom_line(
      data = diagonal,
      ggplot2::aes(operation_year, follow_up),
      inherit.aes = FALSE,
      linewidth = diagonal_linewidth,
      linetype = diagonal_linetype,
      color = diagonal_color
    )
}
