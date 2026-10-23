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
#' Follow-up is deliberately imperfect, so the plot shows what real data
#' look like rather than the ideal. Patients lost to follow-up are censored
#' before `close_date`, the date the dataset was frozen, and fall below the
#' diagonal. No patient has follow-up past `close_date`. Set `loss_rate = 0`
#' for complete follow-up, with every survivor censored at `close_date`.
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
#' @param loss_rate Annual hazard of loss to active follow-up (exponential
#'   model). Default `0.03`. `0` means nobody is lost.
#'
#' @return A data frame with columns:
#'   \describe{
#'     \item{`iv_opyrs`}{Years from `origin_year` to operation date.}
#'     \item{`iv_dead`}{Follow-up years to death or censoring.}
#'     \item{`dead`}{Logical all-source death indicator.}
#'     \item{`iv_event`}{Follow-up years to non-fatal event or censoring.}
#'     \item{`ev_event`}{Logical non-fatal event indicator.}
#'     \item{`deads`}{Logical active/systematic death indicator (subset of
#'       `dead`).}
#'   }
#'
#' @seealso [hv_followup()]
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
  seed        = 42L,
  loss_rate   = 0.03
) {
  if (!(is.numeric(n) && length(n) == 1L && n >= 1L && n %% 1 == 0))
    stop("`n` must be a positive integer scalar.", call. = FALSE)
  if (!is.numeric(death_rate) || death_rate <= 0)
    stop("`death_rate` must be a positive number.", call. = FALSE)
  if (!is.numeric(event_rate) || event_rate <= 0)
    stop("`event_rate` must be a positive number.", call. = FALSE)
  if (!(is.numeric(loss_rate) && length(loss_rate) == 1L && loss_rate >= 0))
    stop("`loss_rate` must be a non-negative number.", call. = FALSE)

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

  withr::local_seed(seed)

  # Operation dates: uniform over the study period
  study_span <- as.integer(study_end - study_start)
  op_dates   <- study_start + sample.int(study_span + 1, n, replace = TRUE) - 1

  # iv_opyrs: years from origin_year Jan-1 to each operation date
  origin_date <- as.Date(paste0(origin_year, "-01-01"))
  iv_opyrs    <- round(as.numeric(op_dates - origin_date) / 365.2425, 4)

  # Potential follow-up: years from operation to close_date
  pfup <- as.numeric(close_date - op_dates) / 365.2425

  # Latent times. Drawn before loss to follow-up so a given seed keeps the
  # same operation dates, death times and event times.
  death_time <- stats::rexp(n, rate = death_rate)
  event_time <- stats::rexp(n, rate = event_rate)

  # Follow-up ends at loss to follow-up or at close_date, whichever is first
  loss_time <- if (loss_rate > 0) stats::rexp(n, rate = loss_rate) else
    rep(Inf, n)
  fup <- pmin(pfup, loss_time)

  # Death: exponential, censored at follow-up
  dead    <- death_time <= fup
  iv_dead <- round(pmin(death_time, fup), 4)

  # Non-fatal event: exponential, competing with death and censored at
  # follow-up. For the event panel, follow-up time is the minimum of event
  # time, death time, and follow-up. An event is only recorded if it occurs
  # before death and before censoring.
  iv_event_time <- pmin(event_time, death_time, fup)
  ev_event      <- (event_time < death_time) & (event_time <= fup)
  iv_event      <- round(iv_event_time, 4)

  # Active/systematic death: restrict to 90% of potential follow-up.
  # This approximates the shorter active ascertainment window vs. passive
  # surveillance; mirrors the dead/deads distinction in the template.
  deads <- death_time <= pmin(pfup * 0.90, fup)

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
#' @param event_col          Name of the non-fatal event indicator column, or
#'   a vector of names for competing non-fatal events drawn in one panel.
#'   Required to compute the event panel (\code{type = "event"}).
#'   Default \code{NULL} (event panel unavailable).  The flag alone does not
#'   decide the state: each event time is compared against
#'   \code{death_time_col}, and a flagged event is only counted as non-fatal
#'   when it strictly precedes death.  Ties go to death.  Among the events
#'   that qualify, the earliest sets the state, and a tie between two goes to
#'   the one listed first.
#' @param event_time_col     Name of the time-to-event column, or a vector the
#'   same length as \code{event_col}, one interval per event.  Required when
#'   \code{event_col} is supplied.  Default \code{NULL}.  A patient is drawn at
#'   the winning event's interval; with no qualifying event, at the first
#'   event's interval.
#' @param death_for_event_col Name of the death column to use specifically in
#'   the event panel (defaults to \code{death_col} when \code{NULL}).
#' @param origin_year        Integer; calendar year used as the y-axis origin.
#'   Default \code{1990}.
#' @param study_start        Start of study period.  Default
#'   \code{as.Date("1990-01-01")}.
#' @param study_end          End of study enrollment.  Default
#'   \code{as.Date("2019-12-31")}.
#' @param close_date         Data close date.  Must be \eqn{\geq}
#'   \code{study_end}.  Default \code{as.Date("2021-08-06")}.
#' @param tolower_names      Logical; if TRUE, column names are lower-cased when
#'   materialising the data.  Default \code{TRUE}.
#' @param death_levels       Length-2 character vector labeling the two death
#'   states (alive first).  Default \code{c("Alive", "Dead")}.
#' @param event_levels       Character vector of distinct labels for the event
#'   panel: event-free, one per non-fatal event in the order of
#'   \code{event_col}, then death.  Its length is the number of events plus
#'   two.  Default \code{c("No event", "Non-fatal event", "Death")}.
#' @param segment_drop       Numeric; vertical offset (years) for the segment
#'   endpoint below the follow-up point.  Default \code{0} (no segment drawn).
#'   Set to a positive value to restore the legacy stem below each point.
#' @param echo               Optional data frame with one row per echo, for
#'   the echo layer.  Each row carries the operation interval
#'   (\code{echo_opyrs_col}) and the echo interval (\code{echo_time_col}), so
#'   no patient identifier is needed; a cohort column carried onto each joined
#'   echo row is enough.  Default \code{NULL}: with \code{echo_time_col} set,
#'   the echo is read from \code{data} instead, one per patient.
#' @param echo_time_col      Name of the echo interval column, in years since
#'   the operation.  Default \code{NULL}, which draws no echo layer.  With
#'   \code{echo = NULL} it names a column of \code{data}, the shape a join
#'   reduced to one echo per patient delivers.
#' @param echo_opyrs_col     Name of the operation interval column in
#'   \code{echo}.  Default \code{NULL}, meaning \code{iv_opyrs_col}.
#'
#' @section Echo layer:
#' The echo layer marks when each echo happened along a patient's follow-up: a
#' tick at the operation year (x) and the echo interval (y), drawn on both
#' panels.  It has two sources.  One echo per patient is a column of
#' \code{data}; a missing value there means no echo was recorded, so the
#' patient gets no tick, is still drawn in the panel, and nothing is warned.
#' \code{$meta$n_echo} and \code{$meta$n_no_echo} count the two.  Every echo is
#' a separate \code{echo} data frame; a row missing either column is an
#' incomplete record, excluded with a warning and counted in
#' \code{$meta$n_echo_excluded}.
#'
#' @section Missing data:
#' Patients with a missing value in any required column are excluded, with a
#' warning naming the columns responsible.  \code{$meta$n_patients} reports
#' the \emph{analyzed} cohort, alongside \code{$meta$n_input} and
#' \code{$meta$n_excluded}, so the reported N always describes the plotted
#' points.
#'
#' The event panel requires more columns than the death panel, so the two can
#' have different cohorts: a patient with a complete death record but a
#' missing event time appears in one panel and not the other.  Each panel is
#' therefore filtered and warned about separately, and the event panel's
#' counts are reported as \code{$meta$n_event_patients} and
#' \code{$meta$n_event_excluded}.
#'
#' @return An object of class \code{c("hv_followup", "hv_data")}:
#' \describe{
#'   \item{\code{$data}}{Per-patient data frame for the death panel.}
#'   \item{\code{$meta}}{Column names, date parameters, state levels,
#'     \code{has_event} flag, and the cohort counts \code{n_patients}
#'     (analyzed), \code{n_input}, and \code{n_excluded}.}
#'   \item{\code{$tables}}{Named list with \code{diagonal} (the study-period
#'     reference diagonal), \code{event_data} when event columns are
#'     supplied, and \code{echo_data} (\code{operation_year},
#'     \code{follow_up}) when \code{echo_time_col} is.}
#' }
#'
#' @seealso Worked recipe with rendered output:
#'   \url{https://ehrlinger.github.io/hvtiGraphics/balance.html}.
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
#' # 3. Decorate: color palette, axis labels, theme
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
#' # Two competing non-fatal events in one panel: the first to happen wins
#' dta$ev_stroke <- !dta$ev_event & seq_len(nrow(dta)) %% 4 == 0
#' gf3 <- hv_followup(dta, event_col = c("ev_event", "ev_stroke"),
#'                    event_time_col = c("iv_event", "iv_event"),
#'                    event_levels = c("No event", "Reoperation", "Stroke", "Death"))
#' table(gf3$tables$event_data$state)
#' plot(gf3, type = "event")
#'
#' # Echo layer, one echo per patient: a column of the patient data
#' dta$iv_echo <- dta$iv_dead * 0.6
#' plot(hv_followup(dta, echo_time_col = "iv_echo"))
#'
#' # Echo layer, every echo: one row per echo, placed by the operation interval
#' echoes <- data.frame(iv_opyrs = rep(dta$iv_opyrs[1:40], each = 3),
#'                      iv_echo  = rep(dta$iv_dead[1:40], each = 3) * c(0.1, 0.5, 0.9))
#' plot(hv_followup(dta, echo = echoes, echo_time_col = "iv_echo"))
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
  segment_drop         = 0,
  echo                 = NULL,
  echo_time_col        = NULL,
  echo_opyrs_col       = NULL
) {
  if (length(death_levels) != 2L)
    stop("`death_levels` must contain exactly two labels.", call. = FALSE)
  if (!is.numeric(segment_drop) || segment_drop < 0)
    stop("`segment_drop` must be a non-negative numeric value.", call. = FALSE)
  if (!is.null(event_col) && is.null(event_time_col))
    stop("Supply `event_time_col` when `event_col` is provided.", call. = FALSE)
  event_col      <- unname(event_col)
  event_time_col <- unname(event_time_col)
  if (length(event_col) != length(event_time_col))
    stop("`event_col` and `event_time_col` must be the same length, one interval per event.",
         call. = FALSE)
  # No event, each non-fatal event in the order given, then death.
  n_levels <- if (is.null(event_col)) 3L else length(event_col) + 2L
  if (length(event_levels) != n_levels)
    stop(sprintf("`event_levels` must contain exactly %s labels: no event, %s, then death.",
                 gf_count_word(n_levels),
                 if (n_levels == 3L) "the event" else "each event in order"),
         call. = FALSE)
  if (anyDuplicated(event_levels))
    stop("`event_levels` must be distinct.", call. = FALSE)
  if (!is.null(echo) && is.null(echo_time_col))
    stop("Supply `echo_time_col` when `echo` is provided.", call. = FALSE)

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
  death_excl <- .exclude_incomplete(payload, c(iv_opyrs_col, death_time_col,
                                               death_col),
                                    context = "death panel")
  death_df   <- death_excl$data[, c(iv_opyrs_col, death_time_col, death_col),
                                drop = FALSE]
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
    # death_time_col is required here, not just for the death panel: without
    # it the event panel cannot tell whether death preceded the flagged event.
    event_cols <- c(iv_opyrs_col, event_time_col, event_col, eff_death_col,
                    death_time_col)
    gf_require_columns(payload, event_cols)
    # The event panel needs more columns than the death panel, so it has its
    # own cohort. Reporting only the death panel's counts would describe a
    # different set of patients than event_data actually contains.
    event_excl <- .exclude_incomplete(payload, event_cols,
                                      context = "event panel")
    event_df   <- event_excl$data[, event_cols, drop = FALSE]
    if (!nrow(event_df))
      stop("No rows available to build the event follow-up plot.", call. = FALSE)
    event_data <- gf_build_event_frame(
      event_df, iv_opyrs_col, event_time_col, event_col,
      eff_death_col, death_time_col, event_levels, origin_year, segment_drop
    )
  }

  # --- Echo layer (optional) ------------------------------------------------
  echo_out <- NULL
  if (!is.null(echo_time_col))
    echo_out <- gf_build_echo_frame(
      payload, echo, iv_opyrs_col,
      if (is.null(echo_opyrs_col)) iv_opyrs_col else echo_opyrs_col,
      echo_time_col, origin_year, tolower_names
    )

  tables <- list(diagonal = diag_df)
  if (has_event) tables$event_data <- event_data
  if (!is.null(echo_out)) tables$echo_data <- echo_out$data

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
      n_patients          = death_excl$n_analyzed,
      n_input             = death_excl$n_input,
      n_excluded          = death_excl$n_excluded,
      n_event_patients    = if (has_event) event_excl$n_analyzed else NULL,
      n_event_excluded    = if (has_event) event_excl$n_excluded else NULL,
      echo_time_col       = echo_time_col,
      echo_source         = echo_out$source,
      n_echo              = echo_out$n_echo,
      n_no_echo           = echo_out$n_no_echo,
      n_echo_excluded     = echo_out$n_excluded
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
  if (isTRUE(m$n_excluded > 0L))
    cat(sprintf(
      "                %d analyzed of %d input; %d excluded for missing values\n",
      m$n_patients, m$n_input, m$n_excluded))
  if (isTRUE(m$n_event_excluded > 0L))
    cat(sprintf(
      "  Event panel : %d analyzed; %d excluded for missing values\n",
      m$n_event_patients, m$n_event_excluded))
  cat(sprintf("  Study period: %s \u2013 %s (close: %s)\n",
              format(m$study_start), format(m$study_end),
              format(m$close_date)))
  cat(sprintf("  Death col   : %s / %s\n", m$death_col, m$death_time_col))
  if (m$has_event)
    cat(sprintf("  Event col   : %s\n",
                paste(m$event_col, m$event_time_col, sep = " / ", collapse = ", ")))
  if (!is.null(m$echo_time_col))
    cat(sprintf("  Echo        : %s, %d echo(es) drawn (%s)\n", m$echo_time_col, m$n_echo,
                if (identical(m$echo_source, "patient")) "one per patient" else "every echo"))
  cat(sprintf("  Panels      : followup%s\n",
              if (m$has_event) ", event" else ""))
  invisible(x)
}


#' Plot an hv_followup object
#'
#' Builds a bare goodness-of-follow-up \code{ggplot2} object from an
#' \code{\link{hv_followup}} data object.  Each patient appears as a point
#' at their operation year (x) and total follow-up time (y), shaped and
#' colored by their state.  An orange diagonal reference line shows the
#' maximum possible follow-up for patients enrolled at each year.  A vertical
#' stem below each point is drawn only when \code{hv_followup()} was called
#' with a positive \code{segment_drop}.
#'
#' @param x                  An \code{hv_followup} object.
#' @param type               Which panel to produce: \code{"followup"}
#'   (default, death states) or \code{"event"} (requires \code{event_col} to
#'   have been supplied to \code{\link{hv_followup}}).
#' @param alpha              Point/segment transparency in \eqn{[0,1]}.
#'   Default \code{0.8}.
#' @param diagonal_color     Color of the diagonal reference line.
#'   Default \code{"orange"}.
#' @param diagonal_linetype  Linetype for the diagonal.  Default
#'   \code{"dashed"}.
#' @param diagonal_linewidth Linewidth for the diagonal.  Default \code{0.6}.
#' @param echo               Logical; draw the echo layer when
#'   \code{hv_followup()} was given \code{echo_time_col}.  Default \code{TRUE};
#'   \code{FALSE} leaves it off.
#' @param echo_shape         Point shape for the echo ticks.  Default \code{95},
#'   a short horizontal dash.
#' @param echo_size          Size of the echo ticks.  Default \code{4}.
#' @param echo_color         Color of the echo ticks.  Default
#'   \code{"gray40"}.  The echo layer is drawn with fixed settings, like the
#'   diagonal, so it stays out of the state color scale and its legend.
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
#' # Legacy stem below each point -- restored with a positive segment_drop
#' plot(hv_followup(dta, segment_drop = 0.2))
#'
#' @importFrom ggplot2 ggplot aes geom_point geom_segment geom_line
#' @export
plot.hv_followup <- function(x,
                               type               = c("followup", "event"),
                               alpha              = 0.8,
                               diagonal_color     = "orange",
                               diagonal_linetype  = "dashed",
                               diagonal_linewidth = 0.6,
                               echo               = TRUE,
                               echo_shape         = 95,
                               echo_size          = 4,
                               echo_color         = "gray40",
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
    diagonal_linewidth,
    segment_drop = x$meta$segment_drop,
    echo_data    = if (isTRUE(echo)) x$tables$echo_data,
    echo_shape   = echo_shape,
    echo_size    = echo_size,
    echo_color   = echo_color
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

# Encapsulates event-panel transformations. Produces the state levels
#   levels[1]       = no event (alive and event-free at censoring)
#   levels[1 + i]   = non-fatal event i occurred first
#   levels[N + 2]   = death before any non-fatal event
# With one event this mirrors the ev_evnt coding in the legacy tp.dp.gfup.R
# template.
#
# The event flag alone cannot distinguish an event from death: a patient who
# died at year 1 with an event recorded at year 2 would be labeled with the
# event, contradicting the state definitions above. Each event time is
# therefore compared against the death time, and an event only qualifies when
# it strictly precedes death. Ties go to death, since an event recorded at the
# moment of death is not a non-fatal one.
#
# Among qualifying events the earliest wins, and a tie between two goes to the
# one listed first (which.min() returns the first minimum). y is the winning
# event's interval; with no qualifying event it is the first event's interval,
# which is what a single event has always drawn.
gf_build_event_frame <- function(df, iv_col, follow_cols, event_cols,
                                 death_col, death_time_col, levels,
                                 origin_year, segment_drop) {
  n              <- nrow(df)
  operation_year <- origin_year + as.numeric(df[[iv_col]])
  death_flag     <- as.logical(df[[death_col]])
  death_time     <- as.numeric(df[[death_time_col]])
  times <- matrix(unlist(lapply(follow_cols, function(v) as.numeric(df[[v]]))), nrow = n)
  flags <- matrix(unlist(lapply(event_cols, function(v) as.logical(df[[v]]))), nrow = n)

  qualifies <- flags & (!death_flag | times < death_time)
  candidate <- ifelse(qualifies, times, Inf)
  winner    <- apply(candidate, 1L, function(t) if (all(is.infinite(t))) 0L else which.min(t))

  follow_up <- ifelse(winner > 0L, times[cbind(seq_len(n), pmax(winner, 1L))], times[, 1L])
  state <- ifelse(winner > 0L, levels[winner + 1L],
                  ifelse(death_flag, levels[length(levels)], levels[1L]))
  data.frame(
    operation_year = operation_year,
    follow_up      = follow_up,
    segment_end    = pmax(follow_up - segment_drop, 0),
    state          = factor(state, levels = levels)
  )
}

# Builds the echo layer's points from either source. With `echo = NULL` the
# echo interval is a column of the patient data, one echo per patient (what a
# JOIN reduced to one row per patient delivers); a missing value there means no
# echo was recorded, so that patient gets no tick and nothing is warned. With
# `echo` a data frame, it holds one row per echo, and a row missing either
# column is an incomplete record, excluded with a warning.
gf_build_echo_frame <- function(payload, echo, iv_opyrs_col, echo_opyrs_col,
                                echo_time_col, origin_year, tolower_names) {
  as_points <- function(d, opyrs_col) {
    data.frame(operation_year = origin_year + as.numeric(d[[opyrs_col]]),
               follow_up      = as.numeric(d[[echo_time_col]]))
  }
  if (is.null(echo)) {
    gf_require_columns(payload, echo_time_col)
    has_opyrs <- !is.na(payload[[iv_opyrs_col]])
    has_echo  <- has_opyrs & !is.na(payload[[echo_time_col]])
    return(list(data = as_points(payload[has_echo, , drop = FALSE], iv_opyrs_col),
                source = "patient", n_echo = sum(has_echo),
                n_no_echo = sum(has_opyrs & !has_echo), n_excluded = NULL))
  }
  echo <- gf_materialize_followup_data(echo, tolower_names)
  cols <- c(echo_opyrs_col, echo_time_col)
  gf_require_columns(echo, cols)
  excl <- .exclude_incomplete(echo, cols, context = "echo layer")
  list(data = as_points(excl$data, echo_opyrs_col), source = "echo",
       n_echo = excl$n_analyzed, n_no_echo = NULL, n_excluded = excl$n_excluded)
}

gf_count_word <- function(n) {
  words <- c("three", "four", "five", "six", "seven", "eight", "nine", "ten")
  if (n >= 3L && n <= 10L) words[n - 2L] else as.character(n)
}

# Shared plotting scaffold — works for both the binary death panel and the
# three-level event panel because both use the same column names.
#
# The stem segment is omitted when `segment_drop` is zero. Drawing a
# zero-length segment would be invisible in the panel but would still add a
# line to every legend key, striking through the point glyph.
gf_build_followup_plot <- function(data, diagonal, alpha,
                                   diagonal_color, diagonal_linetype,
                                   diagonal_linewidth, segment_drop,
                                   echo_data = NULL, echo_shape = 95,
                                   echo_size = 4, echo_color = "gray40") {
  p <- ggplot2::ggplot(
    data,
    ggplot2::aes(.data[["operation_year"]], .data[["follow_up"]])
  ) +
    ggplot2::geom_point(
      ggplot2::aes(
        color = .data[["state"]],
        shape = .data[["state"]]
      ),
      alpha = alpha
    )

  if (segment_drop > 0)
    p <- p + ggplot2::geom_segment(
      ggplot2::aes(
        xend  = .data[["operation_year"]],
        yend  = .data[["segment_end"]],
        color = .data[["state"]]
      ),
      alpha = alpha
    )

  p <- p +
    ggplot2::geom_line(
      data         = diagonal,
      ggplot2::aes(.data[["operation_year"]], .data[["follow_up"]]),
      inherit.aes  = FALSE,
      linewidth    = diagonal_linewidth,
      linetype     = diagonal_linetype,
      color        = diagonal_color
    )

  # Drawn last, with fixed settings rather than a mapped aesthetic, so the
  # echo ticks stay out of the state color scale and its legend.
  if (!is.null(echo_data))
    p <- p + ggplot2::geom_point(
      data        = echo_data,
      ggplot2::aes(.data[["operation_year"]], .data[["follow_up"]]),
      inherit.aes = FALSE,
      shape       = echo_shape,
      size        = echo_size,
      color       = echo_color
    )
  p
}
