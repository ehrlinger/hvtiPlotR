# Bind ggplot columns up-front to silence R CMD check notes about global vars.
if (getRversion() >= "2.15.1") {
  utils::globalVariables(c("operation_year", "follow_up", "segment_end", "state"))
}

# ---------------------------------------------------------------------------
# Sample data generator
# ---------------------------------------------------------------------------

#' Generate Sample Goodness-of-Follow-Up Data
#'
#' Produces a reproducible data frame suitable for testing and demonstrating
#' [goodness_followup()]. Operation dates are drawn uniformly over the study
#' period; death and non-fatal event times are simulated from exponential
#' distributions and censored at each patient's potential follow-up. The
#' `deads` column approximates active/systematic death ascertainment by
#' restricting to deaths within 90% of the potential follow-up window,
#' mirroring the distinction between `dead` and `deads` in the legacy
#' `tp.dp.gfup.R` template.
#'
#' The column names match the defaults of [goodness_followup()]:
#' `iv_opyrs`, `iv_dead`, `dead`. The event-panel columns (`iv_event`,
#' `ev_event`, `deads`) are included so callers can pass `event_col`,
#' `event_time_col`, and `death_for_event_col` directly.
#'
#' @param n Integer number of patients to simulate. Default `300`.
#' @param origin_year Integer calendar year corresponding to zero in
#'   `iv_opyrs`. Default `1990`.
#' @param study_start,study_end Date (or coercible string) defining the
#'   operation date window.
#' @param close_date Date (or coercible string) for the follow-up closing
#'   date. Must be >= `study_end`.
#' @param death_rate Annual hazard for death (exponential model). Default
#'   `0.05` (median survival ~14 years).
#' @param event_rate Annual hazard for the non-fatal event (exponential
#'   model). Default `0.08` (median time-to-event ~9 years).
#' @param seed Integer random seed for reproducibility. Default `42`.
#'
#' @return A data frame with columns:
#'   \describe{
#'     \item{`iv_opyrs`}{Years from `origin_year` to operation date.}
#'     \item{`iv_dead`}{Follow-up years to death or censoring.}
#'     \item{`dead`}{Logical — all-source death indicator.}
#'     \item{`iv_event`}{Follow-up years to non-fatal event or censoring.}
#'     \item{`ev_event`}{Logical — non-fatal event indicator.}
#'     \item{`deads`}{Logical — active/systematic death indicator (subset of
#'       `dead`).}
#'   }
#'
#' @examples
#' dta <- sample_goodness_followup_data()
#' head(dta)
#'
#' # Death panel
#' result <- goodness_followup(dta)
#' result$death_plot +
#'   ggplot2::scale_color_manual(
#'     values = c("Alive" = "blue", "Dead" = "red"), name = NULL
#'   ) +
#'   ggplot2::scale_shape_manual(values = c(1, 4), name = NULL) +
#'   ggplot2::labs(x = "Operation Date", y = "Follow-up (years)")
#'
#' # Event panel
#' result2 <- goodness_followup(
#'   dta,
#'   event_col           = "ev_event",
#'   event_time_col      = "iv_event",
#'   death_for_event_col = "deads",
#'   event_levels        = c("No event", "Relapse", "Death")
#' )
#' result2$event_plot +
#'   ggplot2::scale_color_manual(
#'     values = c("No event" = "blue", "Relapse" = "green3", "Death" = "red"),
#'     name   = NULL
#'   ) +
#'   ggplot2::scale_shape_manual(values = c(1, 2, 4), name = NULL) +
#'   ggplot2::labs(x = "Operation Date", y = "Follow-up (years)")
#'
#' @importFrom stats rexp
#' @export
sample_goodness_followup_data <- function(
  n           = 300,
  origin_year = 1990,
  study_start = as.Date("1990-01-01"),
  study_end   = as.Date("2019-12-31"),
  close_date  = as.Date("2021-08-06"),
  death_rate  = 0.05,
  event_rate  = 0.08,
  seed        = 42
) {
  if (!is.numeric(n) || length(n) != 1L || n < 1L)
    stop("`n` must be a positive integer scalar.", call. = FALSE)
  if (!is.numeric(death_rate) || death_rate <= 0)
    stop("`death_rate` must be a positive number.", call. = FALSE)
  if (!is.numeric(event_rate) || event_rate <= 0)
    stop("`event_rate` must be a positive number.", call. = FALSE)

  study_start <- as.Date(study_start)
  study_end   <- as.Date(study_end)
  close_date  <- as.Date(close_date)

  if (study_start >= study_end)
    stop("`study_start` must be before `study_end`.", call. = FALSE)
  if (close_date < study_end)
    stop("`close_date` must be on or after `study_end`.", call. = FALSE)

  set.seed(seed)

  # Operation dates: uniform over the study period
  study_span <- as.integer(study_end - study_start)
  op_dates   <- study_start + sample.int(study_span, n, replace = TRUE)

  # iv_opyrs: years from origin_year Jan-1 to each operation date
  origin_date <- as.Date(paste0(origin_year, "-01-01"))
  iv_opyrs    <- round(as.numeric(op_dates - origin_date) / 365.2425, 4)

  # Potential follow-up: years from operation to close_date
  pfup <- as.numeric(close_date - op_dates) / 365.2425

  # Death: exponential, censored at potential follow-up
  death_time <- stats::rexp(n, rate = death_rate)
  dead       <- death_time <= pfup
  iv_dead    <- round(pmin(death_time, pfup), 4)

  # Non-fatal event: exponential, censored at potential follow-up
  event_time <- stats::rexp(n, rate = event_rate)
  ev_event   <- event_time <= pfup
  iv_event   <- round(pmin(event_time, pfup), 4)

  # Active/systematic death: restrict to 90% of potential follow-up.
  # This approximates the shorter active ascertainment window vs. passive
  # surveillance — mirrors the dead/deads distinction in the template.
  deads <- death_time <= (pfup * 0.90)

  data.frame(
    iv_opyrs = iv_opyrs,
    iv_dead  = iv_dead,
    dead     = dead,
    iv_event = iv_event,
    ev_event = ev_event,
    deads    = deads
  )
}

#' Build goodness-of-follow-up plots
#'
#' Converts raw follow-up extracts (either in-memory data frames or SAS
#' transport files) into tidy frames, then draws the classic HVI goodness of
#' follow-up visualizations. The function always produces a death panel
#' (`death_plot`). When `event_col` is supplied it additionally produces a
#' non-fatal event panel (`event_plot`) that encodes a three-level outcome
#' state: no event / non-fatal event / death before event.
#'
#' The function focuses on preparing the data, mapping states to aesthetics,
#' and drawing the scaffolding geoms; callers are expected to finish the styling
#' via standard `ggplot2` modifiers (`scale_*()`, `labs()`, `theme_*()`),
#' keeping the plotting workflow flexible.
#'
#' @param data Data frame or path to a SAS transport (`.xpt`) file containing
#'   the follow-up data.
#' @param iv_opyrs_col Column name holding the numeric interval (in years) from
#'   `origin_year` to the operation date.
#' @param death_col Logical (or coercible) indicator for death. Used for the
#'   death panel and, by default, for the death component of the event panel.
#' @param death_time_col Column containing follow-up time to death (or
#'   censoring) expressed in years.
#' @param origin_year Reference calendar year that matches zero in
#'   `iv_opyrs_col`.
#' @param study_start,study_end,close_date Dates that define the diagonal
#'   potential follow-up line.
#' @param tolower_names When `TRUE`, column names are converted to lower case
#'   prior to processing.
#' @param death_levels Length-2 character vector naming the "alive" and "dead"
#'   states for the death panel. Default `c("Alive", "Dead")`.
#' @param event_col Column name for the non-fatal event indicator (logical or
#'   0/1). When `NULL` (default) the event panel is skipped.
#' @param event_time_col Column containing follow-up time to the non-fatal
#'   event or censoring, expressed in years. Required when `event_col` is
#'   supplied.
#' @param death_for_event_col Death indicator column used to classify deaths
#'   within the event panel. Defaults to `death_col` when `NULL`. Supplying a
#'   separate column (e.g. `"deads"` for systematic/active follow-up) allows
#'   the two panels to use different death ascertainment strategies.
#' @param event_levels Length-3 character vector naming the three outcome
#'   states in the event panel: no event / non-fatal event / death before
#'   event. Default `c("No event", "Non-fatal event", "Death")`.
#' @param alpha Transparency passed to the point and segment layers.
#' @param segment_drop Amount (in years) subtracted from each follow-up value
#'   to draw the short vertical tick beneath each point.
#' @param diagonal_color,diagonal_linetype,diagonal_linewidth Styling controls
#'   for the potential follow-up reference line.
#'
#' @return A list containing:
#'   * `death_plot`: ggplot object — death follow-up panel.
#'   * `death_data`: transformed data frame used in `death_plot`.
#'   * `event_plot`: ggplot object — non-fatal event panel, or `NULL` when
#'     `event_col` is not supplied.
#'   * `event_data`: transformed data frame used in `event_plot`, or `NULL`.
#'   * `diagonal`: reference line data frame shared by both panels.
#'
#' @details
#' **Death panel** — each patient is plotted at their operation date (x) and
#' follow-up time (y). A binary `state` factor (alive / dead) drives colour
#' and shape.
#'
#' **Event panel** — same scaffold, but `state` is a three-level factor:
#' \enumerate{
#'   \item `event_levels[1]` — alive and event-free at censoring.
#'   \item `event_levels[2]` — non-fatal event occurred first.
#'   \item `event_levels[3]` — died before the non-fatal event.
#' }
#' The coding mirrors the `ev_evnt` variable constructed in the legacy
#' `tp.dp.gfup.R` template.
#'
#' @examples
#' dta <- sample_goodness_followup_data()
#'
#' # Death panel only
#' result <- goodness_followup(dta)
#' result$death_plot +
#'   ggplot2::scale_color_manual(
#'     values = c("Alive" = "blue", "Dead" = "red"), name = NULL
#'   ) +
#'   ggplot2::scale_shape_manual(values = c(1, 4), name = NULL) +
#'   ggplot2::labs(x = "Operation Date", y = "Follow-up (years)")
#'
#' # Death panel + non-fatal event panel
#' result2 <- goodness_followup(
#'   dta,
#'   event_col           = "ev_event",
#'   event_time_col      = "iv_event",
#'   death_for_event_col = "deads",
#'   event_levels        = c("No event", "Relapse", "Death")
#' )
#' result2$event_plot +
#'   ggplot2::scale_color_manual(
#'     values = c("No event" = "blue", "Relapse" = "green3", "Death" = "red"),
#'     name   = NULL
#'   ) +
#'   ggplot2::scale_shape_manual(values = c(1, 2, 4), name = NULL) +
#'   ggplot2::labs(x = "Operation Date", y = "Follow-up (years)")
#'
#' @export
goodness_followup <- function(
  data,
  iv_opyrs_col        = "iv_opyrs",
  death_col           = "dead",
  death_time_col      = "iv_dead",
  origin_year         = 1990,
  study_start         = as.Date("1990-01-01"),
  study_end           = as.Date("2019-12-31"),
  close_date          = as.Date("2021-08-06"),
  tolower_names       = TRUE,
  death_levels        = c("Alive", "Dead"),
  event_col           = NULL,
  event_time_col      = NULL,
  death_for_event_col = NULL,
  event_levels        = c("No event", "Non-fatal event", "Death"),
  alpha               = 0.8,
  segment_drop        = 0.2,
  diagonal_color      = "orange",
  diagonal_linetype   = "dashed",
  diagonal_linewidth  = 0.6
) {
  if (length(death_levels) != 2)
    stop("`death_levels` must contain exactly two labels.", call. = FALSE)
  if (!is.numeric(alpha) || alpha <= 0 || alpha > 1)
    stop("`alpha` must be a numeric value in (0, 1].", call. = FALSE)
  if (!is.numeric(segment_drop) || segment_drop < 0)
    stop("`segment_drop` must be a non-negative numeric value.", call. = FALSE)

  if (!is.null(event_col)) {
    if (is.null(event_time_col))
      stop(
        "When `event_col` is supplied, `event_time_col` must also be provided.",
        call. = FALSE
      )
    if (length(event_levels) != 3)
      stop("`event_levels` must contain exactly three labels.", call. = FALSE)
  }

  payload    <- gf_materialize_followup_data(data, tolower_names)
  study_start <- gf_coerce_date(study_start, "study_start")
  study_end   <- gf_coerce_date(study_end,   "study_end")
  close_date  <- gf_coerce_date(close_date,  "close_date")

  if (study_start > study_end)
    stop("`study_start` must be earlier than or equal to `study_end`.",
         call. = FALSE)
  if (close_date < study_end)
    stop("`close_date` must be greater than or equal to `study_end`.",
         call. = FALSE)

  gf_require_columns(payload, c(iv_opyrs_col, death_time_col, death_col))
  diag_df <- gf_build_diagonal(study_start, study_end, close_date, origin_year)

  # --- Death panel -----------------------------------------------------------
  death_df <- gf_prepare_frame(payload, c(iv_opyrs_col, death_time_col, death_col))
  if (!nrow(death_df))
    stop("No rows available to build the death follow-up plot.", call. = FALSE)

  death_data <- gf_build_death_frame(
    death_df, iv_opyrs_col, death_time_col, death_col,
    death_levels, origin_year, segment_drop
  )
  death_plot <- gf_build_followup_plot(
    death_data, diag_df, alpha,
    diagonal_color, diagonal_linetype, diagonal_linewidth
  )

  # --- Event panel (optional) -----------------------------------------------
  event_plot <- NULL
  event_data <- NULL

  if (!is.null(event_col)) {
    eff_death_col <-
      if (is.null(death_for_event_col)) death_col else death_for_event_col
    gf_require_columns(
      payload, c(iv_opyrs_col, event_time_col, event_col, eff_death_col)
    )
    event_df <- gf_prepare_frame(
      payload, c(iv_opyrs_col, event_time_col, event_col, eff_death_col)
    )
    if (!nrow(event_df))
      stop("No rows available to build the event follow-up plot.", call. = FALSE)

    event_data <- gf_build_event_frame(
      event_df, iv_opyrs_col, event_time_col, event_col,
      eff_death_col, event_levels, origin_year, segment_drop
    )
    event_plot <- gf_build_followup_plot(
      event_data, diag_df, alpha,
      diagonal_color, diagonal_linetype, diagonal_linewidth
    )
  }

  list(
    death_plot = death_plot,
    death_data = death_data,
    event_plot = event_plot,
    event_data = event_data,
    diagonal   = diag_df
  )
}

# Internal helpers ---------------------------------------------------------

# Keeps data acquisition isolated so the plotting code can assume a vanilla
# data.frame (future refactors could swap in arrow/databases here).
gf_materialize_followup_data <- function(data, tolower_names) {
  if (is.character(data) && length(data) == 1L) {
    if (!file.exists(data))
      stop(sprintf("File '%s' does not exist.", data), call. = FALSE)
    if (!requireNamespace("haven", quietly = TRUE))
      stop("Reading SAS transport files requires the 'haven' package.",
           call. = FALSE)
    data <- haven::read_xpt(data)
  }
  data <- as.data.frame(data)
  if (tolower_names) names(data) <- tolower(names(data))
  data
}

# Centralizes loose date inputs so validation stays consistent and new date
# types only need to be supported in one place.
gf_coerce_date <- function(x, label) {
  if (inherits(x, "Date")) return(x)
  out <- try(as.Date(x), silent = TRUE)
  if (inherits(out, "try-error") || is.na(out))
    stop(sprintf("`%s` must be coercible to Date.", label), call. = FALSE)
  out
}

# Date arithmetic lives here so any calendar tweak (365 vs 365.25, business
# calendars, etc.) can be changed without touching multiple helpers.
gf_years_between <- function(later, earlier) {
  as.numeric(later - earlier) / 365.2425
}

# Generates the dashed "potential follow-up" diagonal shared by both panels.
gf_build_diagonal <- function(study_start, study_end, close_date, origin_year) {
  maxpfup <- gf_years_between(close_date, study_start)
  minpfup <- gf_years_between(close_date, study_end)
  op_span <- gf_years_between(study_end, study_start)
  data.frame(
    operation_year = c(origin_year, origin_year + op_span),
    follow_up      = c(maxpfup, minpfup)
  )
}

# Guard clause shared across helpers.
gf_require_columns <- function(data, columns) {
  missing_cols <- setdiff(columns, names(data))
  if (length(missing_cols))
    stop(
      sprintf("Missing required column(s): %s",
              paste(missing_cols, collapse = ", ")),
      call. = FALSE
    )
}

# Removes incomplete rows once so downstream builders don't each need their own
# NA handling branches.
gf_prepare_frame <- function(data, columns) {
  idx <- stats::complete.cases(data[, columns, drop = FALSE])
  data[idx, columns, drop = FALSE]
}

# Encapsulates death-specific transformations (scale, factor levels, offsets).
gf_build_death_frame <- function(df, iv_col, follow_col, flag_col,
                                 levels, origin_year, segment_drop) {
  operation_year <- origin_year + as.numeric(df[[iv_col]])
  follow_up      <- as.numeric(df[[follow_col]])
  state          <- ifelse(as.logical(df[[flag_col]]), levels[2], levels[1])
  data.frame(
    operation_year = operation_year,
    follow_up      = follow_up,
    segment_end    = pmax(follow_up - segment_drop, 0),
    state          = factor(state, levels = levels)
  )
}

# Encapsulates event-panel transformations. Produces a three-level state:
#   levels[1] = no event (alive and event-free at censoring)
#   levels[2] = non-fatal event occurred first
#   levels[3] = death before the non-fatal event
# This mirrors the ev_evnt coding in the legacy tp.dp.gfup.R template.
gf_build_event_frame <- function(df, iv_col, follow_col, event_col,
                                 death_col, levels, origin_year,
                                 segment_drop) {
  operation_year <- origin_year + as.numeric(df[[iv_col]])
  follow_up      <- as.numeric(df[[follow_col]])
  event_flag     <- as.logical(df[[event_col]])
  death_flag     <- as.logical(df[[death_col]])
  state <- ifelse(event_flag, levels[2],
                  ifelse(death_flag, levels[3], levels[1]))
  data.frame(
    operation_year = operation_year,
    follow_up      = follow_up,
    segment_end    = pmax(follow_up - segment_drop, 0),
    state          = factor(state, levels = levels)
  )
}

# Shared plotting scaffold — works for both the binary death panel and the
# three-level event panel because both use the same column names.
gf_build_followup_plot <- function(data, diagonal, alpha,
                                   diagonal_color, diagonal_linetype,
                                   diagonal_linewidth) {
  ggplot2::ggplot(data, ggplot2::aes(operation_year, follow_up)) +
    ggplot2::geom_point(
      ggplot2::aes(color = state, shape = state), alpha = alpha
    ) +
    ggplot2::geom_segment(
      ggplot2::aes(
        xend  = operation_year,
        yend  = segment_end,
        color = state
      ),
      alpha = alpha
    ) +
    ggplot2::geom_line(
      data         = diagonal,
      ggplot2::aes(operation_year, follow_up),
      inherit.aes  = FALSE,
      linewidth    = diagonal_linewidth,
      linetype     = diagonal_linetype,
      color        = diagonal_color
    )
}
