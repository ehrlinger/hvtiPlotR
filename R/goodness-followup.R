# ---------------------------------------------------------------------------
# Sample data generator
# ---------------------------------------------------------------------------

#' Generate Sample Goodness-of-Follow-Up Data
#'
#' Produces a reproducible data frame suitable for testing and demonstrating
#' [hv_followup()]. Operation dates are drawn uniformly over the study
#' period; death and non-fatal event times are simulated from exponential
#' distributions and censored at each patient's potential follow-up. The
#' `deads` column approximates active/systematic death ascertainment by
#' restricting to deaths within 90% of the potential follow-up window,
#' mirroring the distinction between `dead` and `deads` in the legacy
#' `tp.dp.gfup.R` template.
#'
#' The column names match the defaults of [hv_followup()]:
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
#' gf <- hv_followup(dta)
#' plot(gf) +
#'   ggplot2::scale_color_manual(
#'     values = c("Alive" = "blue", "Dead" = "red"), name = NULL
#'   ) +
#'   ggplot2::scale_shape_manual(values = c(1, 4), name = NULL) +
#'   ggplot2::labs(x = "Operation Date", y = "Follow-up (years)")
#'
#' # Event panel
#' gf2 <- hv_followup(dta, event_col = "ev_event",
#'                       event_time_col = "iv_event",
#'                       death_for_event_col = "deads")
#' plot(gf2, type = "event") +
#'   ggplot2::scale_color_manual(
#'     values = c("No event" = "blue", "Non-fatal event" = "green3",
#'                "Death" = "red"),
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
  seed        = 42L
) {
  if (!(is.numeric(n) && length(n) == 1L && n >= 1L && n %% 1 == 0))
    stop("`n` must be a positive integer scalar.", call. = FALSE)
  if (!is.numeric(death_rate) || death_rate <= 0)
    stop("`death_rate` must be a positive number.", call. = FALSE)
  if (!is.numeric(event_rate) || event_rate <= 0)
    stop("`event_rate` must be a positive number.", call. = FALSE)

  study_start <- as.Date(study_start)
  study_end   <- as.Date(study_end)
  close_date  <- as.Date(close_date)

  if (anyNA(study_start))
    stop("`study_start` must be a valid date (or coercible to Date).", call. = FALSE)
  if (anyNA(study_end))
    stop("`study_end` must be a valid date (or coercible to Date).", call. = FALSE)
  if (anyNA(close_date))
    stop("`close_date` must be a valid date (or coercible to Date).", call. = FALSE)

  if (study_start >= study_end)
    stop("`study_start` must be before `study_end`.", call. = FALSE)
  if (close_date < study_end)
    stop("`close_date` must be on or after `study_end`.", call. = FALSE)

  set.seed(seed)

  # Operation dates: uniform over the study period
  study_span <- as.integer(study_end - study_start)
  op_dates   <- study_start + sample.int(study_span + 1, n, replace = TRUE) - 1

  # iv_opyrs: years from origin_year Jan-1 to each operation date
  origin_date <- as.Date(paste0(origin_year, "-01-01"))
  iv_opyrs    <- round(as.numeric(op_dates - origin_date) / 365.2425, 4)

  # Potential follow-up: years from operation to close_date
  pfup <- as.numeric(close_date - op_dates) / 365.2425

  # Death: exponential, censored at potential follow-up
  death_time <- stats::rexp(n, rate = death_rate)
  dead       <- death_time <= pfup
  iv_dead    <- round(pmin(death_time, pfup), 4)

  # Non-fatal event: exponential, competing with death and censored at
  # potential follow-up. For the event panel, follow-up time is the minimum
  # of event time, death time, and potential follow-up. An event is only
  # recorded if it occurs before death and before censoring.
  event_time    <- stats::rexp(n, rate = event_rate)
  iv_event_time <- pmin(event_time, death_time, pfup)
  ev_event      <- (event_time < death_time) & (event_time <= pfup)
  iv_event      <- round(iv_event_time, 4)

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

#' Prepare goodness-of-follow-up data for plotting
#'
#' Validates dates, builds per-patient follow-up frames, and returns an
#' \code{hv_followup} object containing the data for both the death panel
#' (\code{type = "followup"}) and, optionally, the event panel
#' (\code{type = "event"}).  Call \code{\link{plot.hv_followup}} on the
#' result to obtain a bare \code{ggplot2} object.
#'
#' @param data               A data frame with one row per patient.
#'   See \code{\link{sample_goodness_followup_data}}.
#' @param iv_opyrs_col       Name of the operation-year column.
#'   Default \code{"iv_opyrs"}.
#' @param death_col          Name of the binary death-indicator column.
#'   Default \code{"dead"}.
#' @param death_time_col     Name of the time-to-death column.
#'   Default \code{"iv_dead"}.
#' @param event_col          Name of the non-fatal event indicator column.
#'   Required to compute the event panel (\code{type = "event"}).
#'   Default \code{NULL} (event panel unavailable).
#' @param event_time_col     Name of the time-to-event column.
#'   Required when \code{event_col} is supplied.  Default \code{NULL}.
#' @param death_for_event_col Name of the death column to use specifically in
#'   the event panel (defaults to \code{death_col} when \code{NULL}).
#' @param origin_year        Integer; calendar year used as the y-axis origin.
#'   Default \code{1990}.
#' @param study_start        Start of study period.  Default
#'   \code{as.Date("1990-01-01")}.
#' @param study_end          End of study enrolment.  Default
#'   \code{as.Date("2019-12-31")}.
#' @param close_date         Data close date.  Must be \eqn{\geq}
#'   \code{study_end}.  Default \code{as.Date("2021-08-06")}.
#' @param tolower_names      Logical; whether to lower-case column names when
#'   materialising the data.  Default \code{TRUE}.
#' @param death_levels       Length-2 character vector labelling the two death
#'   states (alive first).  Default \code{c("Alive", "Dead")}.
#' @param event_levels       Length-3 character vector for the event panel
#'   (event-free, non-fatal event, death).
#'   Default \code{c("No event", "Non-fatal event", "Death")}.
#' @param segment_drop       Numeric; vertical offset (years) for the segment
#'   endpoint below the follow-up point.  Default \code{0.2}.
#'
#' @return An object of class \code{c("hv_followup", "hv_data")}:
#' \describe{
#'   \item{\code{$data}}{Per-patient data frame for the death panel.}
#'   \item{\code{$meta}}{Column names, date parameters, state levels,
#'     \code{has_event} flag.}
#'   \item{\code{$tables}}{Named list with \code{diagonal} (the study-period
#'     reference diagonal) and, when event columns are supplied,
#'     \code{event_data}.}
#' }
#'
#' @seealso \code{\link{plot.hv_followup}},
#'   \code{\link{sample_goodness_followup_data}}
#'
#' @examples
#' dta <- sample_goodness_followup_data()
#'
#' # 1. Build data object
#' gf <- hv_followup(dta)
#' gf  # prints follow-up summary
#'
#' # 2. Bare plot -- undecorated ggplot returned by plot.hv_followup
#' p <- plot(gf)
#'
#' # 3. Decorate: colour palette, axis labels, theme
#' p +
#'   ggplot2::scale_color_manual(
#'     values = c("Alive" = "steelblue", "Dead" = "firebrick"),
#'     name = NULL
#'   ) +
#'   ggplot2::labs(x = "Operation Date", y = "Follow-up (years)") +
#'   theme_hv_poster()
#'
#' # With event panel -- same 3-step pattern
#' gf2 <- hv_followup(dta, event_col = "ev_event", event_time_col = "iv_event")
#' plot(gf2, type = "event") +
#'   ggplot2::scale_color_manual(
#'     values = c("No event" = "blue", "Non-fatal event" = "green3",
#'                "Death" = "red"),
#'     name = NULL
#'   ) +
#'   ggplot2::scale_shape_manual(values = c(1, 2, 4), name = NULL) +
#'   ggplot2::labs(x = "Operation Date", y = "Follow-up (years)") +
#'   theme_hv_poster()
#'
#' @export
hv_followup <- function(
  data,
  iv_opyrs_col         = "iv_opyrs",
  death_col            = "dead",
  death_time_col       = "iv_dead",
  event_col            = NULL,
  event_time_col       = NULL,
  death_for_event_col  = NULL,
  origin_year          = 1990,
  study_start          = as.Date("1990-01-01"),
  study_end            = as.Date("2019-12-31"),
  close_date           = as.Date("2021-08-06"),
  tolower_names        = TRUE,
  death_levels         = c("Alive", "Dead"),
  event_levels         = c("No event", "Non-fatal event", "Death"),
  segment_drop         = 0.2
) {
  if (length(death_levels) != 2L)
    stop("`death_levels` must contain exactly two labels.", call. = FALSE)
  if (length(event_levels) != 3L)
    stop("`event_levels` must contain exactly three labels.", call. = FALSE)
  if (!is.numeric(segment_drop) || segment_drop < 0)
    stop("`segment_drop` must be a non-negative numeric value.", call. = FALSE)
  if (!is.null(event_col) && is.null(event_time_col))
    stop("Supply `event_time_col` when `event_col` is provided.", call. = FALSE)

  payload     <- gf_materialize_followup_data(data, tolower_names)
  study_start <- gf_coerce_date(study_start, "study_start")
  study_end   <- gf_coerce_date(study_end,   "study_end")
  close_date  <- gf_coerce_date(close_date,  "close_date")

  if (study_start > study_end)
    stop("`study_start` must be earlier than or equal to `study_end`.",
         call. = FALSE)
  if (close_date < study_end)
    stop("`close_date` must be greater than or equal to `study_end`.",
         call. = FALSE)

  # --- Diagonal (shared by both panels) ------------------------------------
  diag_df <- gf_build_diagonal(study_start, study_end, close_date, origin_year)

  # --- Death panel ----------------------------------------------------------
  gf_require_columns(payload, c(iv_opyrs_col, death_time_col, death_col))
  death_df <- gf_prepare_frame(payload, c(iv_opyrs_col, death_time_col,
                                          death_col))
  if (!nrow(death_df))
    stop("No rows available to build the death follow-up plot.", call. = FALSE)
  death_data <- gf_build_death_frame(
    death_df, iv_opyrs_col, death_time_col, death_col,
    death_levels, origin_year, segment_drop
  )

  # --- Event panel (optional) -----------------------------------------------
  has_event  <- !is.null(event_col)
  event_data <- NULL
  if (has_event) {
    eff_death_col <- if (is.null(death_for_event_col)) death_col else
      death_for_event_col
    gf_require_columns(payload,
                       c(iv_opyrs_col, event_time_col, event_col,
                         eff_death_col))
    event_df <- gf_prepare_frame(
      payload,
      c(iv_opyrs_col, event_time_col, event_col, eff_death_col)
    )
    if (!nrow(event_df))
      stop("No rows available to build the event follow-up plot.", call. = FALSE)
    event_data <- gf_build_event_frame(
      event_df, iv_opyrs_col, event_time_col, event_col,
      eff_death_col, event_levels, origin_year, segment_drop
    )
  }

  tables <- list(diagonal = diag_df)
  if (has_event) tables$event_data <- event_data

  new_hv_data(
    data = death_data,
    meta = list(
      iv_opyrs_col        = iv_opyrs_col,
      death_col           = death_col,
      death_time_col      = death_time_col,
      event_col           = event_col,
      event_time_col      = event_time_col,
      death_for_event_col = death_for_event_col,
      origin_year         = origin_year,
      study_start         = study_start,
      study_end           = study_end,
      close_date          = close_date,
      death_levels        = death_levels,
      event_levels        = event_levels,
      segment_drop        = segment_drop,
      has_event           = has_event,
      n_patients          = nrow(payload)
    ),
    tables   = tables,
    subclass = "hv_followup"
  )
}


#' Print an hv_followup object
#'
#' @param x   An \code{hv_followup} object from \code{\link{hv_followup}}.
#' @param ... Ignored.
#' @return \code{x}, invisibly.
#' @export
print.hv_followup <- function(x, ...) {
  m <- x$meta
  cat("<hv_followup>\n")
  cat(sprintf("  N patients  : %d\n", m$n_patients))
  cat(sprintf("  Study period: %s \u2013 %s (close: %s)\n",
              format(m$study_start), format(m$study_end),
              format(m$close_date)))
  cat(sprintf("  Death col   : %s / %s\n", m$death_col, m$death_time_col))
  if (m$has_event)
    cat(sprintf("  Event col   : %s / %s\n",
                m$event_col, m$event_time_col))
  cat(sprintf("  Panels      : followup%s\n",
              if (m$has_event) ", event" else ""))
  invisible(x)
}


#' Plot an hv_followup object
#'
#' Builds a bare goodness-of-follow-up \code{ggplot2} object from an
#' \code{\link{hv_followup}} data object.  Each patient appears as a point
#' at their operation year (x) and total follow-up time (y); a vertical
#' segment drops from the point to indicate their current state.  An orange
#' diagonal reference line shows the maximum possible follow-up for patients
#' enrolled at each year.
#'
#' @param x                  An \code{hv_followup} object.
#' @param type               Which panel to produce: \code{"followup"}
#'   (default, death states) or \code{"event"} (requires \code{event_col} to
#'   have been supplied to \code{\link{hv_followup}}).
#' @param alpha              Point/segment transparency in \eqn{[0,1]}.
#'   Default \code{0.8}.
#' @param diagonal_color     Colour of the diagonal reference line.
#'   Default \code{"orange"}.
#' @param diagonal_linetype  Linetype for the diagonal.  Default
#'   \code{"dashed"}.
#' @param diagonal_linewidth Linewidth for the diagonal.  Default \code{0.6}.
#' @param ...                Ignored; present for S3 consistency.
#'
#' @return A bare \code{\link[ggplot2]{ggplot}} object.
#'
#' @seealso \code{\link{hv_followup}}, \code{\link{theme_hv_manuscript}}
#'
#' @examples
#' dta <- sample_goodness_followup_data()
#' gf  <- hv_followup(dta, event_col = "ev_event",
#'                      event_time_col = "iv_event")
#'
#' # Death panel
#' plot(gf) +
#'   ggplot2::scale_color_manual(
#'     values = c("Alive" = "steelblue", "Dead" = "firebrick"),
#'     name = NULL
#'   ) +
#'   ggplot2::labs(x = "Operation Date", y = "Follow-up (years)") +
#'   theme_hv_poster()
#'
#' # Event panel
#' plot(gf, type = "event") +
#'   ggplot2::scale_color_manual(
#'     values = c("No event" = "blue", "Non-fatal event" = "green3",
#'                "Death" = "red"),
#'     name = NULL
#'   ) +
#'   ggplot2::labs(x = "Operation Date", y = "Follow-up (years)") +
#'   theme_hv_poster()
#'
#' @importFrom ggplot2 ggplot aes geom_point geom_segment geom_line
#' @export
plot.hv_followup <- function(x,
                               type               = c("followup", "event"),
                               alpha              = 0.8,
                               diagonal_color     = "orange",
                               diagonal_linetype  = "dashed",
                               diagonal_linewidth = 0.6,
                               ...) {
  type <- match.arg(type)
  .check_alpha(alpha)

  if (type == "event" && !x$meta$has_event)
    stop(
      'type = "event" requires event_col and event_time_col to be supplied ',
      "to hv_followup().",
      call. = FALSE
    )

  plot_data <- if (type == "followup") x$data else x$tables$event_data

  gf_build_followup_plot(
    plot_data,
    x$tables$diagonal,
    alpha,
    diagonal_color,
    diagonal_linetype,
    diagonal_linewidth
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
  ggplot2::ggplot(
    data,
    ggplot2::aes(.data[["operation_year"]], .data[["follow_up"]])
  ) +
    ggplot2::geom_point(
      ggplot2::aes(
        color = .data[["state"]],
        shape = .data[["state"]]
      ),
      alpha = alpha
    ) +
    ggplot2::geom_segment(
      ggplot2::aes(
        xend  = .data[["operation_year"]],
        yend  = .data[["segment_end"]],
        color = .data[["state"]]
      ),
      alpha = alpha
    ) +
    ggplot2::geom_line(
      data         = diagonal,
      ggplot2::aes(.data[["operation_year"]], .data[["follow_up"]]),
      inherit.aes  = FALSE,
      linewidth    = diagonal_linewidth,
      linetype     = diagonal_linetype,
      color        = diagonal_color
    )
}
