# at-risk-table.R
# Numbers-at-risk table harness: a shared empirical count helper, a renderer
# that turns a risk table into a bare ggplot panel, and a composer that stacks
# a survival curve over the table with aligned x-axes.
#
# `n.risk`, `report_time`, and `strata` are columns in the tidy risk table;
# suppress R CMD check notes about undefined globals used in aes().
utils::globalVariables(c("n.risk", "report_time", "strata"))

# ---------------------------------------------------------------------------
# Internal: empirical numbers-at-risk from subject-level data.
# n.risk at time t = number of subjects whose follow-up time is >= t.
# `status` is accepted for signature symmetry / future per-time event counts;
# v1 uses only `time` and `group`.
# NA `time` values are excluded from counts (via na.rm = TRUE in sum()) — intentional.
.atrisk_table <- function(time, status = NULL, group = NULL, report_times) {
  if (!is.numeric(time) || length(time) == 0L)
    stop("`time` must be a non-empty numeric vector.", call. = FALSE)
  if (!(is.numeric(report_times) && length(report_times) > 0L))
    stop("`report_times` must be a non-empty numeric vector.", call. = FALSE)
  if (is.null(group)) group <- rep("Overall", length(time))
  if (length(group) != length(time))
    stop("`group` must be the same length as `time`.", call. = FALSE)
  grp_chr <- as.character(group)
  if (anyNA(grp_chr))
    stop("`group` contains missing values; drop or label them before ",
         "building the at-risk table.", call. = FALSE)
  strata_levels <- if (is.factor(group)) levels(droplevels(group)) else
    sort(unique(grp_chr))

  rows <- lapply(strata_levels, function(st) {
    t_st <- time[grp_chr == st]
    do.call(rbind, lapply(report_times, function(rt) {
      data.frame(strata = st, report_time = rt,
                 n.risk = sum(t_st >= rt, na.rm = TRUE),
                 stringsAsFactors = FALSE)
    }))
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

# ---------------------------------------------------------------------------
# Internal: resolve any accepted input into a tidy risk data frame with
# columns strata, report_time, n.risk.
# Internal: on the table-backed paths, `report_times` selects which of the
# table's existing times to show (it cannot recompute counts). Times not in
# the table are ignored with a warning; an empty selection errors.
.select_report_times <- function(rdf, report_times) {
  if (is.null(report_times)) return(rdf)
  avail   <- sort(unique(rdf$report_time))
  missing <- setdiff(report_times, avail)
  if (length(missing) > 0L)
    warning("`report_times` not in the risk table (ignored): ",
            paste(missing, collapse = ", "),
            ". Available: ", paste(avail, collapse = ", "), ".", call. = FALSE)
  out <- rdf[rdf$report_time %in% report_times, , drop = FALSE]
  if (nrow(out) == 0L)
    stop("None of the requested `report_times` are in the risk table. ",
         "Available: ", paste(avail, collapse = ", "), ".", call. = FALSE)
  out
}

.resolve_risk_df <- function(x, time, status, group, report_times) {
  # Mode 1: an hv_data object carrying $tables$risk (e.g. hv_survival).
  if (inherits(x, "hv_data")) {
    rdf <- x$tables$risk
    if (is.null(rdf))
      stop("This object has no `$tables$risk`. Pass subject-level data with ",
           "`time`/`status`/`group`, or a precomputed risk data frame.",
           call. = FALSE)
    return(.select_report_times(rdf, report_times))
  }

  if (!is.data.frame(x))
    stop("`x` must be an hv_data object, a precomputed risk data frame ",
         "(strata/time/n columns), or a subject-level data frame plus ",
         "`time` (and optional `status`/`group`).", call. = FALSE)

  # Mode 3: subject-level data frame + column names -> compute counts.
  if (!is.null(time)) {
    if (!(time %in% names(x)))
      stop("`time` column \"", time, "\" not found in `x`.", call. = FALSE)
    if (!is.null(group) && !(group %in% names(x)))
      stop("`group` column \"", group, "\" not found in `x`.", call. = FALSE)
    if (!is.null(status) && !(status %in% names(x)))
      stop("`status` column \"", status, "\" not found in `x`.", call. = FALSE)
    tv <- x[[time]]
    if (!is.numeric(tv) || !any(is.finite(tv)))
      stop("`time` column \"", time, "\" has no finite values.", call. = FALSE)
    gv <- if (!is.null(group)) x[[group]] else NULL
    sv <- if (!is.null(status)) x[[status]] else NULL
    rt <- report_times
    if (is.null(rt)) {
      rng <- range(tv, na.rm = TRUE)
      rt  <- pretty(rng, n = 5)
      rt  <- rt[rt >= rng[1] & rt <= rng[2]]
      if (length(rt) == 0L) rt <- rng
      rt  <- unique(rt)
    }
    return(.atrisk_table(time = tv, status = sv, group = gv,
                         report_times = rt))
  }

  # Mode 2: precomputed risk data frame. Normalise column aliases.
  nm <- names(x)
  time_col <- if ("report_time" %in% nm) "report_time" else
    if ("time" %in% nm) "time" else NULL
  n_col    <- if ("n.risk" %in% nm) "n.risk" else
    if ("n" %in% nm) "n" else NULL
  if (!("strata" %in% nm) || is.null(time_col) || is.null(n_col))
    stop("Precomputed risk data frame needs `strata`, ",
         "`report_time` (or `time`), and `n.risk` (or `n`) columns.",
         call. = FALSE)
  rdf <- data.frame(
    strata      = x[["strata"]],          # preserve type (factor order kept)
    report_time = x[[time_col]],
    n.risk      = x[[n_col]],
    stringsAsFactors = FALSE
  )
  .select_report_times(rdf, report_times)
}

#' Numbers-at-risk table panel
#'
#' Renders a numbers-at-risk table as a bare \pkg{ggplot2} panel, ready to
#' stack under a survival curve with \code{\link{hv_atrisk_compose}}.
#'
#' @param x One of: an \code{hv_data} object that carries \code{$tables$risk}
#'   (e.g. from \code{\link{hv_survival}}); a precomputed risk data frame with
#'   \code{strata}, \code{report_time} (or \code{time}), and \code{n.risk}
#'   (or \code{n}) columns; or a subject-level data frame supplied together
#'   with the \code{time} (and optional \code{status}/\code{group}) column
#'   names, from which counts are computed.
#' @param time,status,group Column names in \code{x} when \code{x} is a
#'   subject-level data frame. \code{time} triggers the raw-data path;
#'   \code{status} is reserved and currently unused; \code{group} splits the
#'   table into strata. Pass \code{group} as a factor to control the stratum
#'   row order (its levels set the order); a character column orders rows
#'   alphabetically. Default \code{NULL}.
#' @param report_times Numeric time points for the columns. \code{NULL}
#'   (default) uses the table's own points, or -- on the raw-data path -- an
#'   even spread derived from the observed time range. On the object and
#'   precomputed-table paths a non-\code{NULL} value \emph{selects} which of
#'   the table's existing times to show; the counts are not recomputed, and
#'   any requested time not in the table is ignored with a warning. To use
#'   arbitrary times for a Kaplan-Meier object, rebuild it with
#'   \code{hv_survival(..., report_times = )} or pass the subject-level data.
#' @param size Text size for the counts. Default \code{NULL} (3.5).
#' @param strata_labels Optional named character vector remapping stratum row
#'   labels. Default \code{NULL}.
#' @param ... Ignored; present for S3 consistency.
#'
#' @return A bare \code{\link[ggplot2]{ggplot}} object: one text label per
#'   stratum and report time, strata as y rows (first stratum on top), time on
#'   a continuous x with axis text blanked (the curve carries the axis).
#'
#' @seealso Worked recipe with rendered output:
#'   \url{https://ehrlinger.github.io/hvti_graphics/survival.html}.
#' @seealso \code{\link{hv_atrisk_compose}}, \code{\link{hv_survival}}
#'
#' @examples
#' km <- hv_survival(sample_survival_data(n = 200, seed = 1))
#' hv_atrisk(km)
#'
#' @importFrom ggplot2 ggplot aes geom_text scale_y_discrete theme_minimal theme element_blank
#' @importFrom rlang .data
#' @export
hv_atrisk <- function(x, time = NULL, status = NULL, group = NULL,
                      report_times = NULL, size = NULL,
                      strata_labels = NULL, ...) {
  rdf <- .resolve_risk_df(x, time, status, group, report_times)

  if (is.null(rdf))
    stop("Could not resolve `x` into a risk table. Supply an hv_data object ",
         "carrying `$tables$risk`, a precomputed risk data frame, or a ",
         "subject-level data frame with a `time` column.", call. = FALSE)

  if (anyNA(rdf$strata))
    stop("The risk table has missing `strata` values; label or drop them.",
         call. = FALSE)
  # First stratum on top: reverse the stratum order (ggplot puts level 1 at
  # the bottom). Respect a factor's own levels; else use first-seen order.
  lev <- if (is.factor(rdf$strata)) levels(droplevels(rdf$strata)) else
    unique(as.character(rdf$strata))
  rdf$strata <- factor(as.character(rdf$strata), levels = rev(lev))

  y_labels <- if (is.null(strata_labels)) ggplot2::waiver() else
    function(br) ifelse(br %in% names(strata_labels), strata_labels[br], br)

  ggplot2::ggplot(
    rdf, ggplot2::aes(x = .data$report_time, y = .data$strata)
  ) +
    ggplot2::geom_text(
      ggplot2::aes(label = .data$n.risk),
      size = if (is.null(size)) 3.5 else size
    ) +
    ggplot2::scale_y_discrete(labels = y_labels) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      panel.grid  = ggplot2::element_blank(),
      axis.title  = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_blank(),
      axis.ticks  = ggplot2::element_blank()
    )
}

#' Stack a survival curve over a numbers-at-risk table
#'
#' Composes a curve plot over a \code{\link{hv_atrisk}} panel, aligning the
#' table's x-range to the curve's so the counts sit under the matching times,
#' and stacks them with \pkg{patchwork}.
#'
#' @param curve A \pkg{ggplot2} survival curve, e.g. \code{plot(hv_survival(...))}.
#' @param table A \pkg{ggplot2} numbers-at-risk panel from \code{\link{hv_atrisk}}.
#' @param heights Numeric length-2 curve:table height ratio. Default
#'   \code{c(3, 1)}.
#'
#' @return A \pkg{patchwork} object (the curve above, the table below).
#'   Decorate both panels with patchwork's \code{&}, e.g.
#'   \code{& theme_hv_manuscript()}.
#'
#' @seealso \code{\link{hv_atrisk}}
#'
#' @examples
#' km <- hv_survival(sample_survival_data(n = 200, seed = 1))
#' hv_atrisk_compose(plot(km), hv_atrisk(km))
#'
#' @importFrom ggplot2 ggplot_build coord_cartesian
#' @importFrom patchwork wrap_plots plot_layout
#' @export
hv_atrisk_compose <- function(curve, table, heights = c(3, 1)) {
  if (!inherits(curve, "ggplot"))
    stop("`curve` must be a ggplot object.", call. = FALSE)
  if (!inherits(table, "ggplot"))
    stop("`table` must be a ggplot object (from hv_atrisk()).", call. = FALSE)
  if (!is.numeric(heights) || length(heights) != 2L || anyNA(heights))
    stop("`heights` must be a length-2 numeric vector.", call. = FALSE)

  # Use the curve's already-expanded x-range as the table's hard range so the
  # two panels share identical x limits (expand = FALSE avoids re-padding).
  xr    <- ggplot2::ggplot_build(curve)$layout$panel_params[[1]]$x.range
  if (is.null(xr) || length(xr) != 2L)
    stop("Could not read an x-range from `curve`; is it a rendered ggplot ",
         "with a continuous x-axis?", call. = FALSE)
  table <- table + ggplot2::coord_cartesian(xlim = xr, expand = FALSE)

  patchwork::wrap_plots(curve, table, ncol = 1) +
    patchwork::plot_layout(heights = heights)
}
