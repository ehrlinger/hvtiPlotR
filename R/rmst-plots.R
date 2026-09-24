###############################################################################
## Restricted mean survival time (RMST) plots: per-estimator contrasts and
## weighted Kaplan-Meier curves. Consume the tables of hvtiRpropensity::ps_rmst()
## as plain data frames (or the ps_rmst object itself); no hard dependency.
###############################################################################

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

# A data frame is used as is. A list with a `$tables` element (a ps_rmst
# object, or anything shaped like one) is unwrapped to `$tables[[name]]`.
rmst_pull_table <- function(x, name, arg) {
  if (is.data.frame(x)) return(x)
  if (is.list(x) && is.list(x$tables)) {
    tbl <- x$tables[[name]]
    if (is.data.frame(tbl)) return(tbl)
    stop(sprintf("`%s` has no `tables$%s` data frame.", arg, name), call. = FALSE)
  }
  stop(sprintf("`%s` must be a data frame or a ps_rmst-like object with `$tables$%s`.", arg, name),
       call. = FALSE)
}

# Display order: factor levels when the column is a factor, otherwise first
# appearance.
rmst_levels <- function(x) {
  if (is.factor(x)) levels(droplevels(x)) else unique(as.character(x))
}

# Step polygon under a right-continuous survival curve, from its first time to
# `tau`. Each knot (t_i, s_i) holds until the next knot (or tau), so the ribbon
# is drawn as a staircase: points (t_i, s_i) and (t_{i+1}, s_i) for every i.
rmst_step_area <- function(time, surv, tau) {
  ord  <- order(time)
  time <- time[ord]
  surv <- surv[ord]
  keep <- time <= tau
  time <- time[keep]
  surv <- surv[keep]
  if (!length(time)) return(NULL)
  data.frame(
    time = as.vector(rbind(time, c(time[-1L], tau))),
    surv = rep(surv, each = 2L)
  )
}

rmst_shade_table <- function(curves, facet_col, arm_col, time_col, surv_col, tau) {
  groups <- split(curves, list(curves[[facet_col]], curves[[arm_col]]), drop = TRUE)
  pieces <- lapply(groups, function(g) {
    area <- rmst_step_area(g[[time_col]], g[[surv_col]], tau)
    if (is.null(area)) return(NULL)
    out <- data.frame(
      facet = rep(g[[facet_col]][1L], nrow(area)),
      arm   = rep(g[[arm_col]][1L], nrow(area)),
      time  = area$time,
      surv  = area$surv
    )
    names(out) <- c(facet_col, arm_col, time_col, surv_col)
    out
  })
  pieces <- pieces[!vapply(pieces, is.null, logical(1))]
  if (!length(pieces)) return(curves[0L, c(facet_col, arm_col, time_col, surv_col), drop = FALSE])
  do.call(rbind, unname(pieces))
}

# ---------------------------------------------------------------------------
# hv_rmst_contrast
# ---------------------------------------------------------------------------

#' Prepare RMST contrast data for plotting
#'
#' Validates a table of restricted mean survival time (RMST) differences, one
#' row per weighting estimator, and returns an `hv_rmst_contrast` object.
#' Call [plot.hv_rmst_contrast()] on the result for a bare dot-and-whisker
#' `ggplot2` object: one point per estimator, a whisker for its interval, and a
#' vertical reference line at zero.
#'
#' The input follows the `tables$estimates` contract of
#' `hvtiRpropensity::ps_rmst()`: columns `estimator`, `subset`, `weighting`,
#' `n`, `ess_treated`, `ess_control`, `rmst_treated`, `rmst_control`, `diff`,
#' `diff_days`, `lo_days`, `hi_days` and `n_failed`, where a positive `diff`
#' favours the treated arm. Only the estimator, difference and interval
#' columns are used here. hvtiRpropensity is not required: pass a plain data
#' frame, or the `ps_rmst` object itself and its `$tables$estimates` is read.
#'
#' @param data      A data frame with one row per estimator, or a `ps_rmst`
#'   object (any list whose `$tables$estimates` is a data frame).
#' @param estimator Name of the column holding estimator labels. Default
#'   `"estimator"`. If it is a factor, its levels set the display order;
#'   otherwise the order of first appearance is used.
#' @param diff      Name of the numeric column with the RMST difference (in
#'   days). Default `"diff_days"`.
#' @param lo,hi     Names of the numeric columns with the lower and upper
#'   interval limits (in days). Defaults `"lo_days"` and `"hi_days"`.
#' @param ...       Ignored; present for S3 consistency.
#'
#' @return An object of class `c("hv_rmst_contrast", "hv_data")`: a list with
#' \describe{
#'   \item{`$data`}{The estimates data frame, with the estimator column
#'     as supplied.}
#'   \item{`$meta`}{Named list: `estimator`, `diff`, `lo`, `hi` (column
#'     names), `estimator_levels`, `n_estimators`, `n_missing`.}
#'   \item{`$tables`}{Empty list.}
#' }
#'
#' @seealso [plot.hv_rmst_contrast()], [hv_rmst_curves()]
#' @family Propensity Score & Matching
#'
#' @examples
#' est <- data.frame(
#'   estimator = factor(c("IPTW", "Overlap", "Matching"),
#'                      levels = c("IPTW", "Overlap", "Matching")),
#'   diff_days = c(41, 35, 28),
#'   lo_days   = c(-5, 2, -14),
#'   hi_days   = c(87, 68, 70)
#' )
#' rc <- hv_rmst_contrast(est)
#' rc
#'
#' plot(rc) +
#'   ggplot2::labs(y = NULL) +
#'   theme_hv_manuscript()
#'
#' @export
hv_rmst_contrast <- function(data,
                             estimator = "estimator",
                             diff      = "diff_days",
                             lo        = "lo_days",
                             hi        = "hi_days",
                             ...) {
  data <- rmst_pull_table(data, "estimates", "data")
  .check_df(data)
  .check_cols(data, c(estimator, diff, lo, hi))
  for (cl in c(diff, lo, hi)) .check_numeric_col(data, cl)
  .check_complete_labels(data, estimator)
  incomplete <- .count_incomplete(data, c(diff, lo, hi))

  working <- as.data.frame(data)
  lvls    <- rmst_levels(working[[estimator]])

  new_hv_data(
    data = working,
    meta = list(
      estimator        = estimator,
      diff             = diff,
      lo               = lo,
      hi               = hi,
      estimator_levels = lvls,
      n_estimators     = length(lvls),
      n_missing        = incomplete$n_missing
    ),
    tables   = list(),
    subclass = "hv_rmst_contrast"
  )
}

#' Print an hv_rmst_contrast object
#'
#' @param x   An `hv_rmst_contrast` object from [hv_rmst_contrast()].
#' @param ... Ignored.
#' @return `x`, invisibly.
#' @export
print.hv_rmst_contrast <- function(x, ...) {
  m <- x$meta
  cat("<hv_rmst_contrast>\n")
  cat(sprintf("  Estimators : %d (%s)%s\n", m$n_estimators,
              paste(m$estimator_levels, collapse = ", "),
              if (isTRUE(m$n_missing > 0L))
                sprintf("  [%d row(s) not drawn: missing values]", m$n_missing)
              else ""))
  cat(sprintf("  Difference : %s [%s, %s]\n", m$diff, m$lo, m$hi))
  invisible(x)
}

#' Plot an hv_rmst_contrast object
#'
#' Builds a bare dot-and-whisker `ggplot2` object from an
#' [hv_rmst_contrast()] object. Estimators run down the y axis with the first
#' level at the top, so the plot reads in the order supplied. A solid vertical
#' line marks zero (no difference). Add colours, scales and a theme with `+`.
#'
#' @param x              An `hv_rmst_contrast` object.
#' @param point_size     Point size passed to `geom_pointrange()`. Default `3`.
#' @param linewidth      Whisker line width. Default `0.6`.
#' @param zero_linetype  Linetype of the zero reference line. Default
#'   `"solid"`.
#' @param zero_linewidth Line width of the zero reference line. Default `0.3`.
#' @param x_label        X axis label. Default `"RMST difference (days)"`.
#' @param ...            Ignored; present for S3 consistency.
#'
#' @return A bare [ggplot2::ggplot()] object.
#'
#' @seealso [hv_rmst_contrast()]
#' @family Propensity Score & Matching
#'
#' @examples
#' est <- data.frame(
#'   estimator = c("IPTW", "Overlap", "Matching"),
#'   diff_days = c(41, 35, 28),
#'   lo_days   = c(-5, 2, -14),
#'   hi_days   = c(87, 68, 70)
#' )
#' plot(hv_rmst_contrast(est), x_label = "RMST difference at 5 years (days)")
#'
#' @importFrom rlang .data
#' @importFrom ggplot2 ggplot aes geom_vline geom_pointrange scale_y_discrete labs
#' @export
plot.hv_rmst_contrast <- function(x,
                                  point_size     = 3,
                                  linewidth      = 0.6,
                                  zero_linetype  = "solid",
                                  zero_linewidth = 0.3,
                                  x_label        = "RMST difference (days)",
                                  ...) {
  .check_scalar_positive(point_size, "point_size")
  .check_scalar_positive(linewidth, "linewidth")
  .check_scalar_positive(zero_linewidth, "zero_linewidth")
  m <- x$meta

  ggplot2::ggplot(x$data) +
    ggplot2::geom_vline(xintercept = 0, linetype = zero_linetype, linewidth = zero_linewidth) +
    ggplot2::geom_pointrange(
      ggplot2::aes(
        x    = .data[[m$diff]],
        xmin = .data[[m$lo]],
        xmax = .data[[m$hi]],
        y    = .data[[m$estimator]]
      ),
      size      = point_size / 3,
      linewidth = linewidth,
      orientation = "y"
    ) +
    ggplot2::scale_y_discrete(limits = rev(m$estimator_levels)) +
    ggplot2::labs(x = x_label, y = m$estimator)
}

# ---------------------------------------------------------------------------
# hv_rmst_curves
# ---------------------------------------------------------------------------

#' Prepare weighted Kaplan-Meier curves for an RMST figure
#'
#' Validates the step-function curves behind an RMST analysis and returns an
#' `hv_rmst_curves` object. Call [plot.hv_rmst_curves()] for a bare
#' `ggplot2` object with one facet per estimator and one step curve per arm.
#' With `tau`, the area under each arm's curve up to `tau` is shaded (that
#' area is the RMST) and a vertical line marks `tau`. With `estimates`, each
#' facet is annotated with its RMST difference and interval.
#'
#' The input follows the `tables$curves` contract of
#' `hvtiRpropensity::ps_rmst()`: columns `estimator`, `arm` (`"treated"` or
#' `"control"`), `time` and `surv`, as right-continuous steps that start at
#' time 0 with `surv` 1. hvtiRpropensity is not required: pass plain data
#' frames, or the `ps_rmst` object itself as `curves` and its
#' `$tables$curves` (and, when `estimates` is `NULL`, `$tables$estimates`) are
#' read.
#'
#' @param curves    A data frame of curve steps, or a `ps_rmst` object.
#' @param estimates Optional data frame with the `hv_rmst_contrast()` columns
#'   (`estimator`, `diff_days`, `lo_days`, `hi_days`), used for the facet
#'   annotations. If `NULL` and `curves` is a `ps_rmst`-like object, its
#'   `$tables$estimates` is used when present. `NULL` otherwise: no
#'   annotation.
#' @param tau       Optional single positive number: the RMST horizon, on the
#'   same scale as `time`.
#' @param facet     Name of the column defining facets. Default
#'   `"estimator"`. Factor levels set the facet order.
#' @param arm       Name of the arm column. Default `"arm"`. A character
#'   column is ordered `"treated"`, `"control"`, then any other value.
#' @param time,surv Names of the time and survival columns. Defaults
#'   `"time"` and `"surv"`.
#' @param ...       Ignored; present for S3 consistency.
#'
#' @return An object of class `c("hv_rmst_curves", "hv_data")`: a list with
#' \describe{
#'   \item{`$data`}{The curves data frame.}
#'   \item{`$meta`}{Named list: `facet`, `arm`, `time`, `surv` (column
#'     names), `tau`, `facet_levels`, `arm_levels`, `n_missing`.}
#'   \item{`$tables`}{`shade`: the staircase polygon under each curve up to
#'     `tau` (zero rows when `tau` is `NULL`); `labels`: one annotation per
#'     facet (zero rows when `estimates` is `NULL`).}
#' }
#'
#' @seealso [plot.hv_rmst_curves()], [hv_rmst_contrast()]
#' @family Propensity Score & Matching
#'
#' @examples
#' steps <- function(est, arm, rate) {
#'   t <- c(0, sort(round(stats::rexp(40, rate) * 365)))
#'   data.frame(estimator = est, arm = arm, time = t,
#'              surv = c(1, 1 - seq_len(40) / 41))
#' }
#' set.seed(1)
#' curves <- rbind(
#'   steps("IPTW", "treated", 1 / 3), steps("IPTW", "control", 1 / 2),
#'   steps("Overlap", "treated", 1 / 3), steps("Overlap", "control", 1 / 2)
#' )
#' est <- data.frame(estimator = c("IPTW", "Overlap"),
#'                   diff_days = c(41, 35), lo_days = c(-5, 2), hi_days = c(87, 68))
#'
#' rc <- hv_rmst_curves(curves, estimates = est, tau = 365)
#' rc
#'
#' plot(rc) +
#'   ggplot2::labs(x = "Days", y = "Survival") +
#'   theme_hv_manuscript()
#'
#' @export
hv_rmst_curves <- function(curves,
                           estimates = NULL,
                           tau       = NULL,
                           facet     = "estimator",
                           arm       = "arm",
                           time      = "time",
                           surv      = "surv",
                           ...) {
  if (is.null(estimates) && is.list(curves) && !is.data.frame(curves) && is.list(curves$tables) &&
        is.data.frame(curves$tables$estimates))
    estimates <- curves$tables$estimates
  curves <- rmst_pull_table(curves, "curves", "curves")
  .check_df(curves, "curves")
  .check_cols(curves, c(facet, arm, time, surv), data_arg = "curves")
  .check_numeric_col(curves, time)
  .check_numeric_col(curves, surv)
  .check_complete_labels(curves, c(facet, arm))
  if (!is.null(tau)) .check_scalar_positive(tau, "tau")
  incomplete <- .count_incomplete(curves, c(time, surv))

  working <- as.data.frame(curves)
  if (!is.factor(working[[arm]])) {
    present <- unique(as.character(working[[arm]]))
    lvls    <- c(intersect(c("treated", "control"), present),
                 setdiff(present, c("treated", "control")))
    working[[arm]] <- factor(working[[arm]], levels = lvls)
  }
  facet_levels <- rmst_levels(working[[facet]])
  if (!is.factor(working[[facet]]))
    working[[facet]] <- factor(working[[facet]], levels = facet_levels)

  shade <- if (is.null(tau)) {
    working[0L, c(facet, arm, time, surv), drop = FALSE]
  } else {
    # A group with a missing knot is not shaded: dropping the row first would
    # bridge the gap and report an RMST area the curve does not have.
    bad_group <- interaction(working[[facet]], working[[arm]], drop = TRUE)
    bad_group <- levels(bad_group)[unique(as.integer(
      bad_group[!stats::complete.cases(working[, c(time, surv)])]))]
    grp <- as.character(interaction(working[[facet]], working[[arm]]))
    rmst_shade_table(working[!grp %in% bad_group, , drop = FALSE], facet, arm, time, surv, tau)
  }

  labels <- NULL
  if (!is.null(estimates)) {
    estimates <- rmst_pull_table(estimates, "estimates", "estimates")
    .check_cols(estimates, c("estimator", "diff_days", "lo_days", "hi_days"), data_arg = "estimates")
    for (cl in c("diff_days", "lo_days", "hi_days")) .check_numeric_col(estimates, cl)
    est <- as.data.frame(estimates)
    est <- est[stats::complete.cases(est[, c("diff_days", "lo_days", "hi_days")]), , drop = FALSE]
    est <- est[as.character(est$estimator) %in% facet_levels, , drop = FALSE]
    labels <- data.frame(
      est$estimator,
      sprintf("%+.1f [%.1f, %.1f] days", est$diff_days, est$lo_days, est$hi_days)
    )
    names(labels) <- c(facet, "label")
    labels[[facet]] <- factor(as.character(labels[[facet]]), levels = facet_levels)
  } else {
    labels <- data.frame(facet = factor(character(), levels = facet_levels), label = character())
    names(labels)[1L] <- facet
  }

  new_hv_data(
    data = working,
    meta = list(
      facet        = facet,
      arm          = arm,
      time         = time,
      surv         = surv,
      tau          = tau,
      facet_levels = facet_levels,
      arm_levels   = levels(working[[arm]]),
      n_missing    = incomplete$n_missing
    ),
    tables   = list(shade = shade, labels = labels),
    subclass = "hv_rmst_curves"
  )
}

#' Print an hv_rmst_curves object
#'
#' @param x   An `hv_rmst_curves` object from [hv_rmst_curves()].
#' @param ... Ignored.
#' @return `x`, invisibly.
#' @export
print.hv_rmst_curves <- function(x, ...) {
  m <- x$meta
  cat("<hv_rmst_curves>\n")
  cat(sprintf("  Facets  : %d (%s)%s\n", length(m$facet_levels),
              paste(m$facet_levels, collapse = ", "),
              if (isTRUE(m$n_missing > 0L))
                sprintf("  [%d row(s) not drawn: missing values]", m$n_missing)
              else ""))
  cat(sprintf("  Arms    : %s\n", paste(m$arm_levels, collapse = ", ")))
  cat(sprintf("  Tau     : %s\n", if (is.null(m$tau)) "none" else format(m$tau)))
  cat(sprintf("  Labels  : %s\n", if (nrow(x$tables$labels)) "RMST difference" else "none"))
  invisible(x)
}

#' Plot an hv_rmst_curves object
#'
#' Builds a bare `ggplot2` object from an [hv_rmst_curves()] object: weighted
#' Kaplan-Meier step curves, one facet per estimator, coloured by arm. When
#' `tau` was supplied, the area under each curve up to `tau` is shaded
#' (`geom_ribbon()` over a staircase polygon, so the shading follows the steps
#' exactly) and a vertical line marks `tau`. When `estimates` was supplied, the
#' top right of each facet carries the RMST difference and interval. Colour and
#' fill both map to arm: set them together with `scale_colour_*()` and
#' `scale_fill_*()`.
#'
#' @param x          An `hv_rmst_curves` object.
#' @param shade_alpha Transparency of the shaded area. Default `0.2`.
#' @param linewidth  Step line width. Default `0.6`.
#' @param tau_linetype Linetype of the vertical `tau` line. Default
#'   `"dashed"`.
#' @param label_size Text size of the facet annotations. Default `3`.
#' @param ...        Ignored; present for S3 consistency.
#'
#' @return A bare [ggplot2::ggplot()] object.
#'
#' @seealso [hv_rmst_curves()]
#' @family Propensity Score & Matching
#'
#' @examples
#' curves <- data.frame(
#'   estimator = rep(c("IPTW", "Overlap"), each = 6),
#'   arm       = rep(rep(c("treated", "control"), each = 3), 2),
#'   time      = rep(c(0, 200, 500), 4),
#'   surv      = c(1, .9, .7, 1, .8, .5, 1, .92, .75, 1, .85, .6)
#' )
#' plot(hv_rmst_curves(curves, tau = 365), shade_alpha = 0.3)
#'
#' @importFrom rlang .data
#' @importFrom ggplot2 ggplot aes geom_step geom_ribbon geom_vline geom_text facet_wrap
#' @export
plot.hv_rmst_curves <- function(x,
                                shade_alpha  = 0.2,
                                linewidth    = 0.6,
                                tau_linetype = "dashed",
                                label_size   = 3,
                                ...) {
  .check_alpha(shade_alpha)
  .check_scalar_positive(linewidth, "linewidth")
  .check_scalar_positive(label_size, "label_size")
  m <- x$meta

  p <- ggplot2::ggplot()
  if (!is.null(m$tau) && nrow(x$tables$shade)) {
    p <- p + ggplot2::geom_ribbon(
      data = x$tables$shade,
      ggplot2::aes(
        x     = .data[[m$time]],
        ymin  = 0,
        ymax  = .data[[m$surv]],
        fill  = .data[[m$arm]],
        group = .data[[m$arm]]
      ),
      alpha = shade_alpha
    )
  }
  p <- p + ggplot2::geom_step(
    data = x$data,
    ggplot2::aes(x = .data[[m$time]], y = .data[[m$surv]], colour = .data[[m$arm]]),
    linewidth = linewidth
  )
  if (!is.null(m$tau)) {
    p <- p + ggplot2::geom_vline(xintercept = m$tau, linetype = tau_linetype)
  }
  if (nrow(x$tables$labels)) {
    p <- p + ggplot2::geom_text(
      data = x$tables$labels,
      ggplot2::aes(label = .data[["label"]]),
      x = Inf, y = Inf, hjust = 1.05, vjust = 1.5, size = label_size,
      inherit.aes = FALSE
    )
  }
  p + ggplot2::facet_wrap(m$facet)
}
