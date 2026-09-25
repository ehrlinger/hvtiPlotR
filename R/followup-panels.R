# followup-panels.R
#
# A set of goodness-of-follow-up panels over one study window: one
# hv_followup() per death indicator and per non-fatal event, all sharing the
# origin, the study window and the close date. The dp-gfup template and the
# EDA-report template in hvtiRtemplates both draw through this, so a panel in
# the combined report is the same figure as the standalone job. The checks and
# the window used to live in the template, where a second template would have
# had to copy them.
#
# Design: hvtiRtemplates dev/specs/2026-09-25-eda-composite-design.md, section 4.
# ---------------------------------------------------------------------------

#' Prepare a set of goodness-of-follow-up panels
#'
#' Checks a set of death and event panels against the data, works out the
#' study window they share, and prepares one [hv_followup()] object per panel.
#' Call [plot.hv_followup_panels()] on the result for the figures.
#'
#' **The study window starts on 1 January of `origin_year`**, because
#' [hv_followup()] draws its potential-follow-up diagonal from `origin_year`
#' whatever `study_start` is. It ends at the latest operation in the data.
#'
#' **The close date** is `close_date` when given. When `NULL` it is estimated
#' as the latest operation plus follow-up in the data: the date follow-up is
#' known to reach, which is not necessarily the date it was closed.
#' `meta$close_source` says which, so a report can too.
#'
#' Every check runs before any panel is built. Every column named anywhere is
#' checked at once, and the error lists all that are missing. A panel name is
#' also its figure's name, so a name used twice, within `panels` or across
#' `panels` and `events`, is an error. The origin is checked for plausibility:
#' an operation before the origin, or operation years outside 1900 to next
#' year, is the wrong-origin mistake, which otherwise slides every point
#' along the x-axis without any other symptom.
#'
#' @param data Data frame; one row per patient.
#' @param opyrs_col Name of the years-since-origin interval to the operation.
#'   Default `"iv_opyrs"`.
#' @param origin_year The calendar year `opyrs_col` counts from, a whole
#'   number.
#' @param panels Named list of death panels. Each entry is a list with
#'   `status`, the 1/0 death indicator, `time`, its follow-up in years, and
#'   optionally `title`.
#' @param events Named list of non-fatal event panels, possibly empty. Each
#'   entry is a list with `event` and `time`, the event's indicator and
#'   interval, `death` and `death_time`, the death it competes with, and
#'   optionally `label`. A flagged event counts only when it strictly precedes
#'   death.
#' @param close_date `NULL` to estimate, or one date (a `Date` or a string
#'   `as.Date()` reads), on or after the last operation.
#'
#' @return An object of class `c("hv_followup_panels", "hv_data")`:
#' \describe{
#'   \item{`$data`}{One row per panel, in order, death panels first:
#'     `panel`, `type` (`"followup"` or `"event"`), `title`, `n_drawn` and
#'     `n_excluded`.}
#'   \item{`$meta`}{Named list: `opyrs_col`, `origin_year`, `study_start`,
#'     `study_end`, `first_operation`, `close_date`, `close_source`,
#'     `n_obs` and `n_opyrs_missing`.}
#'   \item{`$tables`}{`panels`, a named list of [hv_followup()] objects.}
#' }
#'
#' @seealso [plot.hv_followup_panels()], [hv_followup()]
#'
#' @examples
#' dta <- sample_goodness_followup_data()
#' fp <- hv_followup_panels(
#'   dta, origin_year = 1990,
#'   panels = list(all = list(status = "dead", time = "iv_dead", title = "All deaths")),
#'   events = list(ev = list(event = "ev_event", time = "iv_event", death = "deads",
#'                           death_time = "iv_dead", label = "Non-fatal event"))
#' )
#' fp
#' fp$meta$close_source
#' @export
hv_followup_panels <- function(data,
                               opyrs_col   = "iv_opyrs",
                               origin_year,
                               panels,
                               events      = list(),
                               close_date  = NULL) {
  .check_df(data)
  is_name <- function(x) is.character(x) && length(x) == 1L && !is.na(x) && nzchar(x)
  if (!is_name(opyrs_col)) stop("`opyrs_col` must name one column.", call. = FALSE)
  if (!is.numeric(origin_year) || length(origin_year) != 1L || is.na(origin_year) ||
        origin_year != round(origin_year)) {
    stop("`origin_year` must be one whole calendar year.", call. = FALSE)
  }
  if (!is.list(panels) || !length(panels) || is.null(names(panels)) || any(!nzchar(names(panels)))) {
    stop("`panels` must be a named list with at least one entry.", call. = FALSE)
  }
  if (!is.list(events) || (length(events) && (is.null(names(events)) || any(!nzchar(names(events)))))) {
    stop("`events` must be a named list, or list() for none.", call. = FALSE)
  }
  # Each name is also a figure's name, so a name used twice, within a list or
  # across both, would overwrite the first figure without a word.
  all_names <- c(names(panels), names(events))
  dup <- unique(all_names[duplicated(all_names)])
  if (length(dup)) {
    stop("`panels` and `events` names must be distinct across both lists: ",
         paste(dup, collapse = ", "), " is used twice.", call. = FALSE)
  }
  # An entry must be a list before its fields are read: `NULL[c("event", ...)]`
  # is NULL, and all() of nothing is TRUE, so a NULL entry would pass a field
  # check and fail later inside hv_followup().
  is_text <- function(x) is.null(x) || is_name(x)
  for (nm in names(panels)) {
    p <- panels[[nm]]
    if (!is.list(p) || !is_name(p$status) || !is_name(p$time)) {
      stop("`panels` entry `", nm, "` needs one `status` and one `time` column.", call. = FALSE)
    }
    if (!is_text(p$title)) stop("`panels` entry `", nm, "`: `title` must be one non-empty string.", call. = FALSE)
  }
  for (nm in names(events)) {
    e <- events[[nm]]
    if (!is.list(e) || !all(vapply(c("event", "time", "death", "death_time"), function(k) is_name(e[[k]]),
                                   logical(1L)))) {
      stop("`events` entry `", nm, "` needs one `event`, `time`, `death` and `death_time` column.",
           call. = FALSE)
    }
    # The label becomes the middle of three state levels, so it must not repeat
    # either of the other two.
    if (!is_text(e$label) || (!is.null(e$label) && e$label %in% c("No event", "Death"))) {
      stop("`events` entry `", nm, "`: `label` must be one non-empty string other than ",
           "\"No event\" and \"Death\".", call. = FALSE)
    }
  }

  # Every column named anywhere, checked at once, so three misspellings are
  # reported in one error rather than three.
  status_cols <- unique(c(vapply(panels, `[[`, "", "status"),
                          unlist(lapply(events, `[`, c("event", "death")), use.names = FALSE)))
  time_cols <- unique(c(vapply(panels, `[[`, "", "time"),
                        unlist(lapply(events, `[`, c("time", "death_time")), use.names = FALSE)))
  unknown <- setdiff(c(opyrs_col, status_cols, time_cols), names(data))
  if (length(unknown)) {
    stop("Column(s) not in the data: ", paste(unknown, collapse = ", "), ".", call. = FALSE)
  }
  not_numeric <- Filter(function(v) !is.numeric(data[[v]]), c(opyrs_col, time_cols))
  if (length(not_numeric)) {
    stop("Interval column(s) must be numeric years: ", paste(not_numeric, collapse = ", "), ".",
         call. = FALSE)
  }
  not_binary <- Filter(function(v) {
    x <- data[[v]]
    (!is.numeric(x) && !is.logical(x)) || any(!is.na(x) & !x %in% c(0, 1))
  }, status_cols)
  if (length(not_binary)) {
    stop("Indicator column(s) must be 1/0 or logical: ", paste(not_binary, collapse = ", "), ".",
         call. = FALSE)
  }

  opyrs <- data[[opyrs_col]]
  if (all(is.na(opyrs))) stop("`", opyrs_col, "` is missing for every patient.", call. = FALSE)
  if (any(opyrs < 0, na.rm = TRUE)) {
    stop(sum(opyrs < 0, na.rm = TRUE), " patient(s) have a negative `", opyrs_col, "`, an ",
         "operation before origin_year = ", origin_year, ". Check `origin_year`.", call. = FALSE)
  }
  # A plausible window, not a precise one: it catches the wrong-origin mistake,
  # which lands decades out.
  this_year <- as.integer(format(Sys.Date(), "%Y"))
  op_year <- origin_year + opyrs
  if (origin_year < 1900 || any(op_year > this_year + 1, na.rm = TRUE)) {
    stop("Operations fall outside 1900 to ", this_year + 1, " (", floor(min(op_year, na.rm = TRUE)),
         " to ", floor(max(op_year, na.rm = TRUE)), "). Check `origin_year`.", call. = FALSE)
  }

  year_days <- 365.2425
  study_start <- as.Date(paste0(origin_year, "-01-01"))
  study_end <- study_start + round(max(opyrs, na.rm = TRUE) * year_days)
  if (is.null(close_date)) {
    reach <- max(vapply(time_cols, function(v) max(opyrs + data[[v]], na.rm = TRUE), numeric(1L)))
    close <- max(study_end, study_start + round(reach * year_days))
    close_source <- "estimated: the latest operation plus follow-up in the data"
  } else {
    close <- tryCatch(as.Date(close_date), error = function(e) as.Date(NA))
    if (length(close) != 1L || is.na(close)) {
      stop("`close_date` must be NULL or one date, as.Date(\"YYYY-MM-DD\").", call. = FALSE)
    }
    if (close < study_end) {
      stop("`close_date` (", close, ") is before the last operation (", study_end, ").", call. = FALSE)
    }
    close_source <- "set in close_date"
  }

  common <- list(data = data, iv_opyrs_col = opyrs_col, origin_year = origin_year,
                 study_start = study_start, study_end = study_end,
                 close_date = close, tolower_names = FALSE)
  built <- list()
  rows <- list()
  for (nm in names(panels)) {
    p <- panels[[nm]]
    gf <- do.call(hv_followup, c(common, list(death_col = p$status, death_time_col = p$time,
                                              death_levels = c("Alive", "Dead"))))
    built[[nm]] <- gf
    rows[[nm]] <- data.frame(panel = nm, type = "followup", title = if (is.null(p$title)) nm else p$title,
                             n_drawn = gf$meta$n_patients, n_excluded = gf$meta$n_excluded)
  }
  for (nm in names(events)) {
    e <- events[[nm]]
    label <- if (is.null(e$label)) nm else e$label
    gf <- do.call(hv_followup, c(common, list(death_col = e$death, death_time_col = e$death_time,
                                              event_col = e$event, event_time_col = e$time,
                                              event_levels = c("No event", label, "Death"))))
    built[[nm]] <- gf
    rows[[nm]] <- data.frame(panel = nm, type = "event", title = label,
                             n_drawn = gf$meta$n_event_patients, n_excluded = gf$meta$n_event_excluded)
  }
  summary <- do.call(rbind, unname(rows))
  rownames(summary) <- NULL

  new_hv_data(
    data = summary,
    meta = list(
      opyrs_col       = opyrs_col,
      origin_year     = origin_year,
      study_start     = study_start,
      study_end       = study_end,
      first_operation = study_start + round(min(opyrs, na.rm = TRUE) * year_days),
      close_date      = close,
      close_source    = close_source,
      n_obs           = nrow(data),
      n_opyrs_missing = sum(is.na(opyrs))
    ),
    tables   = list(panels = built),
    subclass = "hv_followup_panels"
  )
}


#' Print an hv_followup_panels object
#'
#' @param x   An `hv_followup_panels` object from [hv_followup_panels()].
#' @param ... Ignored.
#' @return `x`, invisibly.
#' @export
print.hv_followup_panels <- function(x, ...) {
  m <- x$meta
  cat("<hv_followup_panels>\n")
  cat(sprintf("  Panels      : %s\n", paste(x$data$panel, collapse = ", ")))
  cat(sprintf("  Operations  : %s to %s (origin %d)\n", format(m$first_operation), format(m$study_end),
              as.integer(m$origin_year)))
  cat(sprintf("  Close date  : %s (%s)\n", format(m$close_date), m$close_source))
  cat(sprintf("  N obs       : %d\n", m$n_obs))
  invisible(x)
}


#' Plot an hv_followup_panels object
#'
#' Draws one bare goodness-of-follow-up figure per panel, through
#' [plot.hv_followup()]. Colours, shapes, labels and themes are left to the
#' caller, as everywhere in this package; the state levels are `"Alive"` and
#' `"Dead"` for a death panel, and `"No event"`, the event's label and
#' `"Death"` for an event panel.
#'
#' @param x An `hv_followup_panels` object.
#' @param alpha Point transparency. Default `0.5`, which keeps a dense cohort
#'   readable as a distribution.
#' @param ... Passed to [plot.hv_followup()], for example `diagonal_color`.
#'
#' @return A named list of bare `ggplot` objects, one per panel, in the order
#'   of `x$data`.
#'
#' @seealso [hv_followup_panels()], [plot.hv_followup()]
#'
#' @examples
#' dta <- sample_goodness_followup_data()
#' fp <- hv_followup_panels(dta, origin_year = 1990,
#'                          panels = list(all = list(status = "dead", time = "iv_dead")))
#' plots <- plot(fp)
#' plots$all +
#'   ggplot2::scale_colour_manual(values = c(Alive = "#377EB8", Dead = "#E41A1C")) +
#'   ggplot2::labs(x = "Year of operation", y = "Follow-up (years)")
#' @export
plot.hv_followup_panels <- function(x, alpha = 0.5, ...) {
  .check_alpha(alpha)
  types <- stats::setNames(x$data$type, x$data$panel)
  lapply(stats::setNames(names(types), names(types)), function(nm) {
    plot(x$tables$panels[[nm]], type = types[[nm]], alpha = alpha, ...)
  })
}
