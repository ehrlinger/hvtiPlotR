###############################################################################
## kaplan-meier.R
##
## R port of the SAS macros:
##   %kaplan  (!MACROS/kaplan)  — product-limit survival analysis
##   %nelsont (!MACROS/nelsont) — Nelson-Aalen cumulative event analysis
## as called from:
##   /distributions/templates/tp.ac.dead.sas
##
## Produces five companion plots matching the SAS macro output flags
## (PLOTS, PLOTC, PLOTH, PLOTL) plus associated data frames (tidy KM data,
## numbers-at-risk table, and a report table at user-supplied time points).
##
## method = "kaplan-meier"  →  %kaplan  (product-limit, logit CI)
## method = "nelson-aalen"  →  %nelsont (Fleming-Harrington, log CI on H)
##
## Quick start
## -----------
##   dta <- sample_survival_data(n = 500, seed = 42)
##   km  <- hv_survival(dta)
##
##   p +
##     ggplot2::scale_y_continuous(breaks = seq(0, 100, 20),
##                                 labels = function(x) paste0(x, "%")) +
##     ggplot2::scale_x_continuous(breaks = seq(0, 20, 5)) +
##     ggplot2::coord_cartesian(xlim = c(0, 20), ylim = c(0, 100)) +
##     ggplot2::labs(x = "Years after Operation", y = "Survival (%)",
##                   title = "Freedom from Death") +
##     hv_theme("manuscript")
##
###############################################################################

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

##' Fit a Kaplan-Meier (survfit) model
##'
##' Wraps \code{survival::survfit} using renamed local variables to avoid
##' column-name clashes with the formula interface.
##'
##' @param data      A data frame.
##' @param time_col  Name of the time column.
##' @param event_col Name of the event indicator column.
##' @param group_col Name of an optional stratification column, or \code{NULL}.
##' @param conf_level Confidence level for the CI band (default 0.95).
##' @param method Method for survival curve estimation: `"kaplan-meier"` uses
##'   product-limit S(t) with logit CI (matches SAS `%kaplan`), or
##'   `"nelson-aalen"` uses Fleming-Harrington H(t) with log CI (matches
##'   SAS `%nelsont`).
##' @return A \code{survfit} object.
##' @importFrom survival Surv survfit
##' @keywords internal
km_fit <- function(data, time_col, event_col, group_col, conf_level, method) {
  t_ <- data[[time_col]]
  e_ <- data[[event_col]]

  # method → survfit type and CI transform
  # "kaplan-meier": product-limit S(t), logit CI  — matches SAS %kaplan
  # "nelson-aalen": Fleming-Harrington H(t), log CI — matches SAS %nelsont
  surv_type <- if (method == "kaplan-meier") "kaplan-meier" else "fleming-harrington"
  conf_type <- if (method == "kaplan-meier") "logit"        else "log"

  if (is.null(group_col)) {
    survival::survfit(
      survival::Surv(t_, e_) ~ 1,
      data      = data.frame(t_ = t_, e_ = e_),
      type      = surv_type,
      conf.int  = conf_level,
      conf.type = conf_type
    )
  } else {
    s_ <- data[[group_col]]
    survival::survfit(
      survival::Surv(t_, e_) ~ s_,
      data      = data.frame(t_ = t_, e_ = e_, s_ = s_),
      type      = surv_type,
      conf.int  = conf_level,
      conf.type = conf_type
    )
  }
}

##' Extract tidy data frame from a survfit object
##'
##' Converts the survfit object to a tidy data frame, prepends a time=0 row
##' per stratum, strips the \code{"s_="} prefix from stratum names, and
##' computes derived columns that match the SAS \code{\%kaplan} macro outputs:
##'
##' \describe{
##'   \item{\code{cumhaz}}{Cumulative hazard H(t) = -log S(t).}
##'   \item{\code{log_cumhaz}}{log H(t) — y-axis of the log-log survival
##'     plot used to assess the proportional-hazards assumption.}
##'   \item{\code{log_time}}{log(t) — x-axis of log-scale PLOTC plots.}
##'   \item{\code{hazard}}{Instantaneous hazard estimate:
##'     log(S(t_prev) / S(t)) / (t - t_prev).  Only defined at event times
##'     with \code{delta_t > 0}; \code{NA} at censoring times.}
##'   \item{\code{density}}{Probability density: (S(t_prev) - S(t)) / delta_t.}
##'   \item{\code{mid_time}}{Midpoint of the interval (t_prev, t], used as
##'     the x-axis of hazard-rate plots.}
##'   \item{\code{life}}{Cumulative integral of the survival function
##'     (restricted mean survival time) using the SAS trapezoidal rule:
##'     LIFE += delta_t * (3*S(t) - S(t_prev)) / 2.}
##'   \item{\code{proplife}}{LIFE / t — proportionate life length.}
##' }
##'
##' @param fit       A \code{survfit} object.
##' @param group_col Name of the original stratification column, or \code{NULL}.
##' @return A data frame.
##' @keywords internal
km_extract_tidy <- function(fit, group_col) {
  s <- summary(fit, censored = TRUE)

  if (is.null(group_col)) {
    strata_vec <- rep("All", length(s$time))
  } else {
    raw_strata <- as.character(s$strata)
    strata_vec <- sub("^[^=]+=", "", raw_strata)
  }

  cumhaz_vec <- if (!is.null(s$cumhaz)) s$cumhaz else -log(pmax(s$surv, .Machine$double.eps))

  df <- data.frame(
    time     = s$time,
    surv     = s$surv,
    lower    = s$lower,
    upper    = s$upper,
    n.risk   = s$n.risk,
    n.event  = s$n.event,
    n.censor = s$n.censor,
    cumhaz   = cumhaz_vec,
    strata   = strata_vec,
    stringsAsFactors = FALSE
  )

  # Prepend time=0 row per stratum
  strata_levels <- unique(df$strata)
  time0_rows <- lapply(strata_levels, function(st) {
    sub_df <- df[df$strata == st, ]
    n0 <- if (nrow(sub_df) > 0) sub_df$n.risk[1] else NA_integer_
    data.frame(
      time     = 0, surv = 1, lower = 1, upper = 1,
      n.risk   = n0, n.event = 0L, n.censor = 0L, cumhaz = 0,
      strata   = st, stringsAsFactors = FALSE
    )
  })

  out <- rbind(do.call(rbind, time0_rows), df)
  out <- out[order(out$strata, out$time), ]

  # --- Compute SAS-equivalent derived columns per stratum --------------------
  derived <- lapply(strata_levels, function(st) {
    sub  <- out[out$strata == st, ]
    n    <- nrow(sub)
    haz  <- rep(NA_real_, n)
    dens <- rep(NA_real_, n)
    mid  <- rep(NA_real_, n)
    life <- rep(NA_real_, n)
    prop <- rep(NA_real_, n)
    cum_life <- 0

    for (i in seq_len(n)) {
      if (i == 1L) next          # time=0 anchor row
      delta_t  <- sub$time[i] - sub$time[i - 1L]
      lag_surv <- sub$surv[i - 1L]
      cur_surv <- sub$surv[i]

      # SAS: HAZARD only computed when EVENT > 0
      if (sub$n.event[i] > 0L && delta_t > 0 && cur_surv > 0) {
        haz[i]  <- log(lag_surv / cur_surv) / delta_t
        dens[i] <- (lag_surv - cur_surv) / delta_t
        mid[i]  <- (sub$time[i - 1L] + sub$time[i]) / 2
      }
      # SAS: LIFE += delta_t * (3*CUM_SURV - LAG_SURV) / 2
      cum_life <- cum_life + delta_t * (3 * cur_surv - lag_surv) / 2
      life[i]  <- cum_life
      prop[i]  <- if (sub$time[i] > 0) cum_life / sub$time[i] else NA_real_
    }

    sub$hazard   <- haz
    sub$density  <- dens
    sub$mid_time <- mid
    sub$life     <- life
    sub$proplife <- prop
    sub$log_cumhaz <- ifelse(sub$cumhaz > 0, log(sub$cumhaz), NA_real_)
    sub$log_time   <- ifelse(sub$time   > 0, log(sub$time),   NA_real_)
    sub
  })

  row.names(out) <- NULL
  do.call(rbind, derived)
}

##' Build numbers-at-risk table
##'
##' For each stratum, finds the last observed \code{n.risk} at or before each
##' report time.
##'
##' @param km_df        Tidy KM data frame from \code{km_extract_tidy}.
##' @param report_times Numeric vector of time points.
##' @return A data frame with columns \code{strata}, \code{report_time},
##'   \code{n.risk}.
##' @keywords internal
km_risk_table <- function(km_df, report_times) {
  strata_levels <- unique(km_df$strata)

  rows <- lapply(strata_levels, function(st) {
    sub_df <- km_df[km_df$strata == st, ]
    lapply(report_times, function(t) {
      idx <- which(sub_df$time <= t)
      if (length(idx) == 0L) {
        nr <- sub_df$n.risk[1]
      } else {
        nr <- sub_df$n.risk[max(idx)]
      }
      data.frame(strata = st, report_time = t, n.risk = nr,
                 stringsAsFactors = FALSE)
    })
  })

  do.call(rbind, do.call(c, rows))
}

##' Build report table at specified time points
##'
##' For each stratum and report time, extracts the survival estimate (and CI
##' bounds, n.risk, and n.event) at the last observed time \eqn{\le} the
##' report time.
##'
##' @param km_df        Tidy KM data frame from \code{km_extract_tidy}.
##' @param report_times Numeric vector of time points.
##' @return A data frame with columns \code{strata}, \code{report_time},
##'   \code{surv}, \code{lower}, \code{upper}, \code{n.risk}, \code{n.event}.
##' @keywords internal
km_report_table <- function(km_df, report_times) {
  strata_levels <- unique(km_df$strata)

  rows <- lapply(strata_levels, function(st) {
    sub_df <- km_df[km_df$strata == st, ]
    lapply(report_times, function(t) {
      idx <- which(sub_df$time <= t)
      if (length(idx) == 0L) {
        row <- sub_df[1L, ]
      } else {
        row <- sub_df[max(idx), ]
      }
      data.frame(
        strata      = st,
        report_time = t,
        surv        = row$surv,
        lower       = row$lower,
        upper       = row$upper,
        n.risk      = row$n.risk,
        n.event     = row$n.event,
        stringsAsFactors = FALSE
      )
    })
  })

  do.call(rbind, do.call(c, rows))
}

##' Build bare survival curve ggplot
##'
##' Returns a \code{ggplot} with a \code{geom_step()} for the KM estimate,
##' an optional \code{geom_ribbon()} for the CI, and a \code{geom_hline} at
##' zero.  The y-axis is expressed as 0–100 (i.e., \code{surv * 100}).
##' Color and fill are mapped to \code{strata} so single-group plots display
##' "All" as the group name; callers can suppress the legend if desired.
##'
##' @param km_df   Tidy KM data frame.
##' @param conf_int Logical; draw CI ribbon when \code{TRUE}.
##' @return A bare \code{ggplot} object.
##' @importFrom ggplot2 ggplot aes geom_step geom_ribbon geom_hline scale_y_continuous
##' @importFrom rlang .data
##' @keywords internal
km_build_survival_plot <- function(km_df, conf_int, alpha) {
  p <- ggplot2::ggplot(
    km_df,
    ggplot2::aes(
      x     = .data[["time"]],
      y     = .data[["surv"]] * 100,
      color = .data[["strata"]],
      fill  = .data[["strata"]]
    )
  ) +
    ggplot2::geom_hline(yintercept = 0) +
    ggplot2::scale_y_continuous(limits = c(0, 100))

  if (conf_int) {
    p <- p +
      ggplot2::geom_ribbon(
        ggplot2::aes(
          ymin = .data[["lower"]] * 100,
          ymax = .data[["upper"]] * 100
        ),
        alpha = 0.2,
        color = NA
      )
  }

  p + ggplot2::geom_step(alpha = alpha)
}

##' Build bare cumulative hazard ggplot
##'
##' @param km_df Tidy KM data frame.
##' @return A bare \code{ggplot} object.
##' @importFrom ggplot2 ggplot aes geom_step
##' @importFrom rlang .data
##' @keywords internal
km_build_cumhaz_plot <- function(km_df, alpha) {
  ggplot2::ggplot(
    km_df,
    ggplot2::aes(
      x     = .data[["time"]],
      y     = .data[["cumhaz"]],
      color = .data[["strata"]]
    )
  ) +
    ggplot2::geom_step(alpha = alpha)
}

##' Build bare hazard rate ggplot
##'
##' Plots the instantaneous hazard estimates computed using the SAS
##' \code{\%kaplan} formula: \eqn{h(t) = \log(S(t_{prev}) / S(t)) / \Delta t},
##' plotted at the interval midpoint.  Only event times with
##' \eqn{\Delta t > 0} and \eqn{S(t) > 0} are shown; censoring rows are
##' excluded.  A smoother (e.g., \code{geom_smooth}) is typically added by
##' the caller.
##'
##' @param km_df Tidy KM data frame from \code{km_extract_tidy}.
##' @return A bare \code{ggplot} object.
##' @importFrom ggplot2 ggplot aes geom_point
##' @importFrom rlang .data
##' @keywords internal
km_build_hazard_plot <- function(km_df, alpha) {
  hz_df <- km_df[!is.na(km_df$hazard) & !is.na(km_df$mid_time), ]

  ggplot2::ggplot(
    hz_df,
    ggplot2::aes(
      x     = .data[["mid_time"]],
      y     = .data[["hazard"]],
      color = .data[["strata"]]
    )
  ) +
    ggplot2::geom_point(alpha = alpha)
}

##' Build bare log-log survival ggplot (PLOTC extension)
##'
##' Plots \eqn{\log H(t) = \log(-\log S(t))} against \eqn{\log t}, which
##' linearises a Weibull survival model and is used to assess the
##' proportional-hazards assumption — parallel lines indicate proportional
##' hazards.  Corresponds to the SAS \code{LN_CUMHZ * LN_INT} plot produced
##' when \code{PLOTC=1}.
##'
##' @param km_df Tidy KM data frame from \code{km_extract_tidy}.
##' @return A bare \code{ggplot} object.
##' @importFrom ggplot2 ggplot aes geom_step
##' @importFrom rlang .data
##' @keywords internal
km_build_loglog_plot <- function(km_df, alpha) {
  ll_df <- km_df[!is.na(km_df$log_cumhaz) & !is.na(km_df$log_time), ]

  ggplot2::ggplot(
    ll_df,
    ggplot2::aes(
      x     = .data[["log_time"]],
      y     = .data[["log_cumhaz"]],
      color = .data[["strata"]]
    )
  ) +
    ggplot2::geom_step(alpha = alpha)
}

##' Build bare integrated survivorship ggplot (PLOTL)
##'
##' Plots the cumulative integral of the survival function (restricted mean
##' survival time, LIFE) against time, matching the SAS \code{\%kaplan}
##' \code{PLOTL=1} output.  The proportionate life length
##' (\code{proplife = LIFE / t}) is also available in \code{km_data} for
##' a secondary plot.
##'
##' @param km_df Tidy KM data frame from \code{km_extract_tidy}.
##' @return A bare \code{ggplot} object.
##' @importFrom ggplot2 ggplot aes geom_step
##' @importFrom rlang .data
##' @keywords internal
km_build_life_plot <- function(km_df, alpha) {
  life_df <- km_df[!is.na(km_df$life), ]

  ggplot2::ggplot(
    life_df,
    ggplot2::aes(
      x     = .data[["time"]],
      y     = .data[["life"]],
      color = .data[["strata"]]
    )
  ) +
    ggplot2::geom_step(alpha = alpha)
}

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

#' Prepare survival data for plotting
#'
#' Fits a Kaplan-Meier (product-limit) or Nelson-Aalen (Fleming-Harrington)
#' survival model to patient-level data and returns an \code{hv_survival}
#' object containing the tidy model output and accessory tables.  No plot is
#' built at this stage; call \code{\link{plot.hv_survival}} on the result to
#' obtain a bare \code{ggplot2} object that you can decorate with scales,
#' labels, and \code{\link{hv_theme}}.
#'
#' @param data         A data frame with one row per patient.
#' @param time_col     Name of the numeric column holding follow-up time (in
#'   years). Default \code{"iv_dead"}.
#' @param event_col    Name of the 0/1 or logical event-indicator column.
#'   Default \code{"dead"}.
#' @param group_col    Optional name of a character or factor column used to
#'   stratify the analysis.  \code{NULL} (default) produces an unstratified
#'   estimate labelled \code{"All"}.
#' @param method       Estimator: \code{"kaplan-meier"} (default, logit CI —
#'   mirrors SAS \code{\%kaplan}) or \code{"nelson-aalen"} (Fleming-Harrington
#'   cumulative hazard with log CI — mirrors SAS \code{\%nelsont}, preferred
#'   when \eqn{S(t)} approaches zero).
#' @param conf_level   Confidence level for the CI band.  Default \code{0.95}.
#' @param report_times Numeric vector of time points at which survival
#'   estimates and numbers-at-risk are tabulated.
#'   Default \code{c(1, 5, 10, 15, 20, 25)}.
#'
#' @return An object of class \code{c("hv_survival", "hv_data")} (a list);
#'   call \code{plot()} on the result to render the figure — see
#'   \code{\link{plot.hv_survival}}. The list has three elements:
#' \describe{
#'   \item{\code{$data}}{Tidy data frame with one row per (time, strata) pair.
#'     Columns: \code{time}, \code{surv}, \code{lower}, \code{upper},
#'     \code{n.risk}, \code{n.event}, \code{n.censor}, \code{cumhaz},
#'     \code{strata}, \code{hazard}, \code{density}, \code{mid_time},
#'     \code{life}, \code{proplife}, \code{log_cumhaz}, \code{log_time}.}
#'   \item{\code{$meta}}{Named list: \code{time_col}, \code{event_col},
#'     \code{group_col}, \code{method}, \code{conf_level},
#'     \code{report_times}, \code{n_obs}, \code{n_events}.}
#'   \item{\code{$tables}}{Named list with two data frames:
#'     \code{risk} (\code{strata}, \code{report_time}, \code{n.risk}) and
#'     \code{report} (\code{strata}, \code{report_time}, \code{surv},
#'     \code{lower}, \code{upper}, \code{n.risk}, \code{n.event}).}
#' }
#'
#' @seealso \code{\link{plot.hv_survival}} to render as a ggplot2 figure,
#'   \code{\link{hv_theme}} for the publication theme,
#'   \code{\link{sample_survival_data}} for example data.
#'
#' @family Kaplan-Meier survival
#'
#' @references SAS templates: \code{tp.ac.dead.sas} (\code{\%kaplan},
#'   \code{\%nelsont}).
#'
#' @examples
#' dta <- sample_survival_data(n = 500, seed = 42)
#'
#' # --- Build the data object ---
#' km <- hv_survival(dta)
#' km                          # print method shows key metadata
#' km$tables$report            # survival estimates at report_times
#' km$tables$risk              # numbers at risk
#'
#' # --- Plot (bare ggplot2 — add decorators with +) ---
#' plot(km) +
#'   ggplot2::scale_y_continuous(breaks = seq(0, 100, 20),
#'                               labels = function(x) paste0(x, "%")) +
#'   ggplot2::scale_x_continuous(breaks = seq(0, 20, 5)) +
#'   ggplot2::coord_cartesian(xlim = c(0, 20), ylim = c(0, 100)) +
#'   ggplot2::labs(x = "Years after Operation", y = "Survival (%)",
#'                 title = "Freedom from Death") +
#'   hv_theme("manuscript")
#'
#' # --- Other plot types ---
#' plot(km, type = "cumhaz") +
#'   ggplot2::labs(x = "Years", y = "Cumulative Hazard") +
#'   hv_theme("manuscript")
#'
#' plot(km, type = "loglog") +
#'   ggplot2::labs(x = "log(Years)", y = "log(-log S(t))",
#'                 title = "PH Assumption Check") +
#'   hv_theme("manuscript")
#'
#' # --- Stratified ---
#' dta_s <- sample_survival_data(
#'   n = 500, strata_levels = c("Type A", "Type B"),
#'   hazard_ratios = c(1, 1.4), seed = 42
#' )
#' km_s <- hv_survival(dta_s, group_col = "valve_type")
#' plot(km_s) +
#'   ggplot2::scale_color_manual(
#'     values = c("Type A" = "steelblue", "Type B" = "firebrick"),
#'     name   = "Valve Type"
#'   ) +
#'   ggplot2::labs(x = "Years after Operation", y = "Survival (%)") +
#'   hv_theme("manuscript")
#'
#' # --- Nelson-Aalen (when S(t) may reach zero) ---
#' km_na <- hv_survival(dta, method = "nelson-aalen")
#' plot(km_na) + hv_theme("manuscript")
#'
#' # --- Global theme + RColorBrewer (set once per session) ------------------
#' \dontrun{
#' # Apply manuscript theme globally — subsequent plots need no
#' # + hv_theme("manuscript").  Restore the previous theme when done.
#' old <- ggplot2::theme_set(hv_theme_manuscript())
#' plot(km_s) +
#'   ggplot2::scale_colour_brewer(palette = "Set1", name = "Valve Type") +
#'   ggplot2::labs(x = "Years after Operation", y = "Survival (%)")
#' ggplot2::theme_set(old)
#' }
#'
#' # See vignette("plot-decorators", package = "hvtiPlotR") for theming,
#' # colour scales, annotation labels, and saving plots.
#'
#' @importFrom survival Surv survfit
#' @importFrom rlang .data
#' @export
hv_survival <- function(data,
                          time_col     = "iv_dead",
                          event_col    = "dead",
                          group_col    = NULL,
                          method       = c("kaplan-meier", "nelson-aalen"),
                          conf_level   = 0.95,
                          report_times = c(1, 5, 10, 15, 20, 25)) {

  method <- match.arg(method)

  # --- Validation -----------------------------------------------------------
  .check_df(data)
  required_cols <- c(time_col, event_col)
  if (!is.null(group_col)) required_cols <- c(required_cols, group_col)
  .check_cols(data, required_cols)

  if (!is.numeric(data[[time_col]]))
    stop(sprintf("`%s` must be numeric. Got: %s",
                 time_col, class(data[[time_col]])[1L]), call. = FALSE)
  if (!all(data[[event_col]] %in% c(0, 1, NA)))
    stop(sprintf("`%s` must be 0/1 or logical. Got values: %s",
                 event_col,
                 paste(sort(unique(data[[event_col]])), collapse = ", ")),
         call. = FALSE)
  if (!is.numeric(conf_level) || length(conf_level) != 1L ||
      !(conf_level > 0 && conf_level < 1))
    stop("`conf_level` must be a single number in (0, 1).", call. = FALSE)
  if (!(is.numeric(report_times) && length(report_times) > 0L))
    stop("`report_times` must be a non-empty numeric vector.", call. = FALSE)

  # --- Fit ------------------------------------------------------------------
  fit   <- km_fit(data, time_col, event_col, group_col, conf_level, method)
  km_df <- km_extract_tidy(fit, group_col)

  # --- Tables ---------------------------------------------------------------
  risk_tbl   <- km_risk_table(km_df, report_times)
  report_tbl <- km_report_table(km_df, report_times)

  # --- Assemble -------------------------------------------------------------
  new_hv_data(
    data = km_df,
    meta = list(
      time_col     = time_col,
      event_col    = event_col,
      group_col    = group_col,
      method       = method,
      conf_level   = conf_level,
      report_times = report_times,
      n_obs        = nrow(data),
      n_events     = sum(as.integer(data[[event_col]]), na.rm = TRUE)
    ),
    tables = list(
      risk   = risk_tbl,
      report = report_tbl
    ),
    subclass = "hv_survival"
  )
}


#' Print an hv_survival object
#'
#' @param x   An \code{hv_survival} object from \code{\link{hv_survival}}.
#' @param ... Ignored.
#' @return \code{x}, invisibly.
#' @export
print.hv_survival <- function(x, ...) {
  m <- x$meta
  cat("<hv_survival>\n")
  cat(sprintf("  Method      : %s\n", m$method))
  cat(sprintf("  Time col    : %s\n", m$time_col))
  cat(sprintf("  Event col   : %s\n", m$event_col))
  if (!is.null(m$group_col))
    cat(sprintf("  Group col   : %s\n", m$group_col))
  cat(sprintf("  N obs       : %d  (events: %d, %.1f%%)\n",
              m$n_obs, m$n_events,
              100 * m$n_events / max(m$n_obs, 1L)))
  cat(sprintf("  Conf level  : %.0f%%\n", m$conf_level * 100))
  cat(sprintf("  Report times: %s\n",
              paste(m$report_times, collapse = ", ")))
  cat(sprintf("  $data       : %d rows \u00d7 %d cols\n",
              nrow(x$data), ncol(x$data)))
  cat(sprintf("  $tables     : risk, report\n"))
  invisible(x)
}


#' Plot an hv_survival object
#'
#' Builds a bare \code{ggplot2} object from an \code{\link{hv_survival}}
#' data object.  The plot contains the correct aesthetics and geometries but
#' no scale, label, or theme modifications — add those with \code{+} as you
#' would with any \code{ggplot2} object.
#'
#' @param x        An \code{hv_survival} object.
#' @param type     Which plot variant to produce.  One of:
#'   \describe{
#'     \item{\code{"survival"}}{(default, \code{PLOTS=1}) KM step function with
#'       optional CI ribbon; y-axis on the 0–100 percent scale.}
#'     \item{\code{"cumhaz"}}{(\code{PLOTC=1}) Nelson-Aalen cumulative hazard
#'       \eqn{H(t) = -\log S(t)}.}
#'     \item{\code{"hazard"}}{(\code{PLOTH=1}) Instantaneous hazard
#'       \eqn{h(t)}; add \code{geom_smooth(method="loess")} for a smoothed
#'       publication curve.}
#'     \item{\code{"loglog"}}{Log-log diagnostic: \eqn{\log H(t)} vs
#'       \eqn{\log t}.  Parallel lines across strata support proportional
#'       hazards.}
#'     \item{\code{"life"}}{(\code{PLOTL=1}) Restricted mean survival time
#'       (integral of \eqn{S(t)}) vs time.}
#'   }
#' @param conf_int Logical; draw a CI ribbon on the \code{"survival"} plot.
#'   Default \code{TRUE}.  Ignored for other \code{type} values.
#' @param alpha    Line/point transparency in \eqn{[0,1]}.  Default \code{0.8}.
#' @param ...      Ignored; present for S3 consistency.
#'
#' @return A bare \code{\link[ggplot2]{ggplot}} object; compose with \code{+}
#'   to add scales, axis limits, labels, and \code{\link{hv_theme}}.
#'
#' @seealso \code{\link{hv_survival}} to build the data object,
#'   \code{\link{hv_theme}} for the publication theme.
#'
#' @family Kaplan-Meier survival
#'
#' @examples
#' dta <- sample_survival_data(n = 500, seed = 42)
#' km  <- hv_survival(dta)
#'
#' # Default survival curve
#' plot(km) +
#'   ggplot2::labs(x = "Years after Operation", y = "Survival (%)") +
#'   hv_theme("manuscript")
#'
#' # Cumulative hazard
#' plot(km, type = "cumhaz") +
#'   ggplot2::labs(x = "Years", y = "Cumulative Hazard") +
#'   hv_theme("manuscript")
#'
#' # Hazard rate with loess smoother
#' plot(km, type = "hazard") +
#'   ggplot2::geom_smooth(
#'     ggplot2::aes(x = .data[["mid_time"]], y = .data[["hazard"]]),
#'     method = "loess", se = FALSE, span = 0.5
#'   ) +
#'   ggplot2::labs(x = "Years", y = "Instantaneous Hazard") +
#'   hv_theme("manuscript")
#'
#' @importFrom ggplot2 ggplot aes geom_step geom_ribbon geom_hline
#'   scale_y_continuous geom_point
#' @export
plot.hv_survival <- function(x,
                               type     = c("survival", "cumhaz",
                                            "hazard", "loglog", "life"),
                               conf_int = TRUE,
                               alpha    = 0.8,
                               ...) {
  type <- match.arg(type)
  .check_alpha(alpha)
  km_df <- x$data

  switch(type,
    survival = km_build_survival_plot(km_df, conf_int = conf_int,
                                      alpha = alpha),
    cumhaz   = km_build_cumhaz_plot(km_df, alpha = alpha),
    hazard   = km_build_hazard_plot(km_df, alpha = alpha),
    loglog   = km_build_loglog_plot(km_df, alpha = alpha),
    life     = km_build_life_plot(km_df, alpha = alpha)
  )
}

#' Generate Sample Survival Data
#'
#' Simulates exponential survival times with administrative censoring at
#' \code{study_years}.  The default \code{hazard_rate = 0.05} yields roughly
#' 63\% 20-year mortality — a realistic range for cardiac surgery cohorts.
#'
#' @param n             Number of observations. Must be a positive integer.
#'   Defaults to \code{500}.
#' @param hazard_rate   Base annual hazard rate (exponential distribution
#'   parameter). Defaults to \code{0.05}.
#' @param strata_levels Optional character vector of stratum labels (e.g.
#'   \code{c("Type A", "Type B")}).  When \code{NULL} (the default) a single
#'   unstratified cohort is generated.
#' @param hazard_ratios Numeric vector of hazard multipliers — one per element
#'   of \code{strata_levels} — relative to \code{hazard_rate}.  Defaults to
#'   all 1 (equal hazard across strata).  Ignored when \code{strata_levels}
#'   is \code{NULL}.
#' @param study_years   Length of administrative follow-up in years.  Subjects
#'   event-free beyond this point are censored. Defaults to \code{20}.
#' @param seed          Integer random seed for reproducibility.
#'   Defaults to \code{42}.
#'
#' @return A data frame with columns:
#' \describe{
#'   \item{\code{iv_dead}}{Follow-up time in years (numeric), truncated at
#'     \code{study_years}.}
#'   \item{\code{dead}}{Logical event indicator; \code{TRUE} if the subject
#'     experienced the event before administrative censoring.}
#'   \item{\code{iv_opyrs}}{Operation year offset — uniform over
#'     \code{[1990, 1990 + study_years]}.}
#'   \item{\code{age_at_op}}{Age at operation (years); drawn from
#'     \eqn{N(65, 10)}, capped to \code{[30, 90]}.}
#'   \item{\code{valve_type}}{(Only when \code{strata_levels} is not
#'     \code{NULL}) Character stratum label.}
#' }
#'
#' @examples
#' # Unstratified
#' dta <- sample_survival_data(n = 500, seed = 42)
#' head(dta)
#'
#' # Stratified with differential hazard
#' dta_s <- sample_survival_data(
#'   n             = 500,
#'   strata_levels = c("Type A", "Type B"),
#'   hazard_ratios = c(1, 1.4),
#'   seed          = 42
#' )
#' table(dta_s$valve_type)
#'
#' @importFrom stats rnorm rexp runif
#' @export
sample_survival_data <- function(n             = 500,
                                 hazard_rate   = 0.05,
                                 strata_levels = NULL,
                                 hazard_ratios = NULL,
                                 study_years   = 20,
                                 seed          = 42) {

  # --- Validation -----------------------------------------------------------
  if (!is.numeric(n) || length(n) != 1L || n < 1L || n %% 1 != 0)
    stop("`n` must be a positive integer.", call. = FALSE)
  if (!is.numeric(hazard_rate) || length(hazard_rate) != 1L ||
      !(hazard_rate > 0))
    stop("`hazard_rate` must be a positive number.", call. = FALSE)
  if (!is.numeric(study_years) || length(study_years) != 1L ||
      !(study_years > 0))
    stop("`study_years` must be a positive number.", call. = FALSE)

  if (!is.null(strata_levels)) {
    if (!(is.character(strata_levels) && length(strata_levels) >= 1L))
      stop("`strata_levels` must be a non-empty character vector.", call. = FALSE)
    if (!is.null(hazard_ratios)) {
      if (!(is.numeric(hazard_ratios) &&
              length(hazard_ratios) == length(strata_levels)))
        stop(paste("`hazard_ratios` must be a numeric vector of the same",
                   "length as `strata_levels`."), call. = FALSE)
      if (!(all(hazard_ratios > 0)))
        stop("All elements of `hazard_ratios` must be positive.", call. = FALSE)
    } else {
      hazard_ratios <- rep(1, length(strata_levels))
    }
  }

  # --- Simulation -----------------------------------------------------------
  set.seed(seed)

  simulate_group <- function(n_grp, rate) {
    surv_times  <- stats::rexp(n_grp, rate = rate)
    admin_cens  <- rep(study_years, n_grp)
    iv_dead     <- pmin(surv_times, admin_cens)
    dead        <- surv_times <= admin_cens
    iv_opyrs    <- stats::runif(n_grp, min = 1990, max = 1990 + study_years)
    age_at_op   <- pmin(pmax(stats::rnorm(n_grp, mean = 65, sd = 10), 30), 90)
    data.frame(
      iv_dead   = iv_dead,
      dead      = dead,
      iv_opyrs  = iv_opyrs,
      age_at_op = age_at_op,
      stringsAsFactors = FALSE
    )
  }

  if (is.null(strata_levels)) {
    simulate_group(n, hazard_rate)
  } else {
    n_strata  <- length(strata_levels)
    n_each    <- rep(n %/% n_strata, n_strata)
    n_each[n_strata] <- n_each[n_strata] + (n %% n_strata)

    parts <- mapply(
      function(n_grp, ratio, label) {
        grp_df <- simulate_group(n_grp, hazard_rate * ratio)
        grp_df$valve_type <- label
        grp_df
      },
      n_each, hazard_ratios, strata_levels,
      SIMPLIFY = FALSE
    )

    do.call(rbind, parts)
  }
}

