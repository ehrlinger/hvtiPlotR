# nonparametric-curve-plot.R
#
# PORT of tp.np.*.avrg_curv.*, tp.np.*.u.trend.*, tp.np.*.double.*,
#         tp.np.*.mult.*, tp.np.*.phases.*, tp.np.z0axdpo.*.
#
# SAS EQUIVALENT: After running %decompos() and averaging patient-specific
# profiles with PROC SUMMARY, the resulting `mean_curv` dataset (columns:
# iv_echo/iv_wristm, prev/est, [cll_p68/clu_p68]) is the direct input to
# hvti_nonparametric().
#
# MIGRATION GUIDE FOR SAS USERS:
#   1. Export mean_curv  -> read.csv("mean_curv.csv")  -> curve_data
#   2. Export boots_ci   -> read.csv("boots_ci.csv")   -> same curve_data, lower/upper cols
#   3. Export means      -> read.csv("means.csv")      -> data_points
#   4. Call hvti_nonparametric(curve_data, ..., data_points = ...)
#   5. Compose with scale_colour_*, labs(), hvti_theme() using + operator
#      (replaces the `color=` and axis options inside %plot())
#
# Internal two-phase helper (not exported):
#   .np_two_phase() replicates the shape of the SAS %decompos() output
#   for use in sample data generation only.
# ---------------------------------------------------------------------------

# Internal helper: two-phase temporal trend
# Early phase (incomplete): bell-shaped; Late phase (complete): Weibull CDF.
# Returns a vector of eta values on the log-odds / linear-predictor scale.
.np_two_phase <- function(t, e0 = 0, thalf1 = 2, thalf2 = 8) {
  t_norm1 <- pmax(t, 1e-9) / thalf1
  g1      <- t_norm1 * exp(1 - t_norm1)          # early: peaks at thalf1
  g2      <- 1 - exp(-(t / thalf2)^2)            # late: Weibull CDF, shape=2
  exp(e0) * g1 + g2
}

# Simulation tuning constants — single source of truth for all np-curve
# simulation functions.  Change here to update every code path.
.NP_SIM <- list(
  eta_intercept = -0.5,   # log-odds shift; centres baseline P(event) ≈ 18 %
  logit_shift   = -1.2,   # additional logit shift; P(event) ≈ 12 % at t = 0
  cont_baseline =  40,    # continuous outcome baseline (e.g. AV gradient, mmHg)
  cont_scale    =   8,    # eta → mmHg scaling factor
  cont_sigma    =   6,    # residual SD (mmHg measurement noise)
  eff_frac_prob =   0.1,  # effective-patient fraction per time point (probability)
  eff_frac_cont =   0.05  # effective-patient fraction per time point (continuous)
)

# ============================================================================

#' Sample Nonparametric Curve Data
#'
#' Simulates pre-computed curve output matching what SAS produces after fitting
#' a two-phase nonparametric temporal trend model and averaging patient-specific
#' profiles with `PROC SUMMARY`. The output is suitable for direct use with
#' [hvti_nonparametric()].
#'
#' **SAS context:** In the SAS templates this dataset corresponds to
#' `mean_curv` (estimate column) plus `boots_ci` (lower/upper columns).
#' Export those datasets to CSV and read them with [read.csv()] to use your
#' own model output instead of this sample function.
#'
#' @param n           Number of simulated patients (used for binned data
#'   points and CI width). Default `500`.
#' @param time_max    Upper end of the time axis (same units as the SAS
#'   `iv_echo` / `iv_wristm` variable). Default `12`.
#' @param n_points    Number of time points on the fine prediction grid.
#'   Default `500` (matches the SAS `inc=(max-min)/499.9` loop).
#' @param groups      `NULL` for a single average curve, or a named numeric
#'   vector of group-specific hazard multipliers,
#'   e.g. `c("Ozaki" = 0.8, "CE-Pericardial" = 1.2)`.
#' @param outcome_type `"probability"` (binary outcome, 0-1 scale) or
#'   `"continuous"`. Default `"probability"`.
#' @param ci_level    Confidence level for bootstrap-style CI bands.
#'   Default `0.68`.
#' @param n_bins      Number of equal-sized data-summary bins. Default `10`.
#' @param seed        Random seed. Default `42`.
#'
#' @return A data frame with columns `time`, `estimate`, `lower`, `upper`,
#'   and (if `groups` is not `NULL`) `group`.
#'
#' @seealso [hvti_nonparametric()], [sample_nonparametric_curve_points()]
#'
#' @examples
#' # Single average curve
#' dat <- sample_nonparametric_curve_data(n = 500, time_max = 12)
#' head(dat)
#'
#' # Two-group comparison
#' dat2 <- sample_nonparametric_curve_data(
#'   n = 400, time_max = 7,
#'   groups = c("Ozaki" = 0.7, "CE-Pericardial" = 1.3),
#'   outcome_type = "continuous"
#' )
#' head(dat2)
#' @export
sample_nonparametric_curve_data <- function(n            = 500,
                                            time_max     = 12,
                                            n_points     = 500,
                                            groups       = NULL,
                                            outcome_type = c("probability",
                                                             "continuous"),
                                            ci_level     = 0.68,
                                            n_bins       = 10,
                                            seed         = 42L) {
  outcome_type <- match.arg(outcome_type)
  set.seed(seed)

  z_score <- stats::qnorm(1 - (1 - ci_level) / 2)

  eta_intercept <- .NP_SIM$eta_intercept
  logit_shift   <- .NP_SIM$logit_shift
  cont_baseline <- .NP_SIM$cont_baseline
  cont_scale    <- .NP_SIM$cont_scale
  cont_sigma    <- .NP_SIM$cont_sigma
  eff_frac_prob <- .NP_SIM$eff_frac_prob
  eff_frac_cont <- .NP_SIM$eff_frac_cont

  t_grid <- exp(seq(log(0.05), log(max(time_max, 0.1)), length.out = n_points))

  thalf1 <- time_max * 0.15
  thalf2 <- time_max * 0.55

  if (is.null(groups)) {
    eta  <- .np_two_phase(t_grid, e0 = eta_intercept,
                          thalf1 = thalf1, thalf2 = thalf2)

    if (outcome_type == "probability") {
      est  <- stats::plogis(eta + logit_shift)
      se   <- sqrt(pmax(est * (1 - est), 1e-4) / (n * eff_frac_prob))
      lo   <- stats::plogis(stats::qlogis(pmax(est, 1e-4)) - z_score * se /
                              sqrt(est * (1 - est) + 1e-4))
      hi   <- stats::plogis(stats::qlogis(pmax(est, 1e-4)) + z_score * se /
                              sqrt(est * (1 - est) + 1e-4))
    } else {
      est   <- cont_baseline + cont_scale * eta
      sigma <- cont_sigma
      lo    <- est - z_score * sigma / sqrt(n * eff_frac_cont)
      hi    <- est + z_score * sigma / sqrt(n * eff_frac_cont)
    }

    curve_df <- data.frame(time     = t_grid,
                           estimate = est,
                           lower    = pmax(lo, 0),
                           upper    = hi)

  } else {
    grp_names  <- names(groups)
    curve_list <- lapply(seq_along(groups), function(i) {
      eta <- .np_two_phase(t_grid, e0 = log(groups[[i]]) + eta_intercept,
                           thalf1 = thalf1, thalf2 = thalf2)
      if (outcome_type == "probability") {
        est <- stats::plogis(eta + logit_shift)
        se  <- sqrt(pmax(est * (1 - est), 1e-4) / (n * eff_frac_prob))
        lo  <- stats::plogis(stats::qlogis(pmax(est, 1e-4)) - z_score * se /
                               sqrt(est * (1 - est) + 1e-4))
        hi  <- stats::plogis(stats::qlogis(pmax(est, 1e-4)) + z_score * se /
                               sqrt(est * (1 - est) + 1e-4))
      } else {
        est <- cont_baseline + cont_scale * eta
        se  <- cont_sigma
        lo  <- est - z_score * se / sqrt(n * eff_frac_cont)
        hi  <- est + z_score * se / sqrt(n * eff_frac_cont)
      }
      data.frame(time     = t_grid,
                 estimate = est,
                 lower    = pmax(lo, 0),
                 upper    = hi,
                 group    = grp_names[[i]])
    })
    curve_df       <- do.call(rbind, curve_list)
    curve_df$group <- factor(curve_df$group, levels = grp_names)
  }

  curve_df
}

#' Sample Nonparametric Curve Data Points
#'
#' Returns only the binned patient-level data summary points from
#' [sample_nonparametric_curve_data()]. Accepts the same parameters
#' and returns a plain `data.frame`.
#'
#' @inheritParams sample_nonparametric_curve_data
#'
#' @return A data frame with columns `time`, `value`, and (if `groups` is not
#'   `NULL`) `group`.
#'
#' @seealso [sample_nonparametric_curve_data()], [hvti_nonparametric()]
#'
#' @examples
#' # Single-group data summary points
#' pts <- sample_nonparametric_curve_points(n = 500, time_max = 12)
#' head(pts)
#' names(pts)           # "time", "value"
#'
#' # Two-group points
#' pts2 <- sample_nonparametric_curve_points(
#'   n            = 400,
#'   time_max     = 7,
#'   groups       = c("Ozaki" = 0.7, "CE-Pericardial" = 1.3),
#'   outcome_type = "continuous"
#' )
#' levels(pts2$group)
#' @export
sample_nonparametric_curve_points <- function(n            = 500,
                                              time_max     = 12,
                                              n_points     = 500,
                                              groups       = NULL,
                                              outcome_type = c("probability",
                                                               "continuous"),
                                              ci_level     = 0.68,
                                              n_bins       = 10,
                                              seed         = 42L) {
  outcome_type <- match.arg(outcome_type)
  set.seed(seed)

  thalf1 <- time_max * 0.15
  thalf2 <- time_max * 0.55

  if (is.null(groups)) {
    dp_df <- .np_sample_bins(n, time_max, thalf1, thalf2, outcome_type, n_bins)
  } else {
    grp_names <- names(groups)
    dp_list <- lapply(seq_along(groups), function(i) {
      df         <- .np_sample_bins(n, time_max, thalf1 * groups[[i]],
                                    thalf2 * groups[[i]], outcome_type, n_bins)
      df$group   <- grp_names[[i]]
      df
    })
    dp_df       <- do.call(rbind, dp_list)
    dp_df$group <- factor(dp_df$group, levels = grp_names)
  }

  dp_df
}

# Internal: generate binned patient-level data summary
.np_sample_bins <- function(n, time_max, thalf1, thalf2, outcome_type, n_bins,
                            eta_intercept  = .NP_SIM$eta_intercept,
                            logit_shift    = .NP_SIM$logit_shift,
                            cont_baseline  = .NP_SIM$cont_baseline,
                            cont_scale     = .NP_SIM$cont_scale,
                            cont_sigma     = .NP_SIM$cont_sigma) {
  t_pat <- stats::runif(n, 0.05, time_max)
  eta   <- .np_two_phase(t_pat, e0 = eta_intercept, thalf1 = thalf1, thalf2 = thalf2)
  if (outcome_type == "probability") {
    mu  <- stats::plogis(eta + logit_shift)
    obs <- stats::rbinom(n, 1, mu)
  } else {
    mu  <- cont_baseline + cont_scale * eta
    obs <- stats::rnorm(n, mu, cont_sigma)
  }
  ord  <- order(t_pat)
  t_s  <- t_pat[ord]
  o_s  <- obs[ord]
  bin  <- cut(seq_along(t_s), breaks = n_bins, labels = FALSE)
  data.frame(
    time  = tapply(t_s, bin, mean),
    value = tapply(o_s, bin, mean)
  )
}

# ============================================================================
# Public API
# ============================================================================

#' Prepare nonparametric temporal trend curve data for plotting
#'
#' Validates pre-computed curve data (and optional CI bounds and binned data
#' summary points) and returns an \code{hvti_nonparametric} object.  Call
#' \code{\link{plot.hvti_nonparametric}} to obtain a bare \code{ggplot2}
#' curve plot that you can decorate with colour/fill scales, axis limits, and
#' \code{\link{hvti_theme}}.
#'
#' Covers the full range of \code{tp.np.*} SAS templates:
#'
#' | SAS template pattern | R usage |
#' |---|---|
#' | Single average curve (`avrg_curv`, `u.trend`) | \code{hvti_nonparametric(dat)} |
#' | Curve + 68\% CI (`avrg_curv.ci`) | \code{+ lower_col + upper_col} |
#' | Curve + CI + data points | \code{+ data_points = ...} |
#' | Two-group comparison (`double`, `ozak`) | \code{+ group_col = "group"} |
#' | Multi-scenario / covariate-adjusted (`mult`) | \code{+ group_col = "group"} |
#' | Phase decomposition (`phases`, `independence`) | \code{+ group_col = "phase"} |
#'
#' **SAS column mapping:**
#' - \code{estimate_col} ← \code{prev}, \code{mnprev}, \code{_p_},
#'   \code{est_fev}, \code{est_z0d}
#' - \code{lower_col} ← \code{cll_p68} or \code{cll_p95}
#' - \code{upper_col} ← \code{clu_p68} or \code{clu_p95}
#' - \code{group_col} ← indicator added after wide-to-long reshape
#'
#' @param curve_data  Data frame; one row per (time, group) combination.
#' @param x_col       Name of the x-axis column. Default \code{"time"}.
#' @param estimate_col Name of the predicted value column. Default
#'   \code{"estimate"}.
#' @param lower_col   Name of the lower CI bound column, or \code{NULL}.
#'   Default \code{NULL}.
#' @param upper_col   Name of the upper CI bound column, or \code{NULL}.
#'   Default \code{NULL}.
#' @param group_col   Name of the stratification column, or \code{NULL}.
#'   Default \code{NULL}.
#' @param data_points Optional data frame of binned data summary points.
#'   Must have columns matching \code{x_col} and \code{"value"}, plus
#'   \code{group_col} when stratified. Default \code{NULL}.
#'
#' @return An object of class \code{c("hvti_nonparametric", "hvti_data")}:
#' \describe{
#'   \item{\code{$data}}{The \code{curve_data} data frame.}
#'   \item{\code{$meta}}{Named list: \code{x_col}, \code{estimate_col},
#'     \code{lower_col}, \code{upper_col}, \code{group_col},
#'     \code{has_ci}, \code{has_data_points}, \code{n_obs}.}
#'   \item{\code{$tables}}{List; contains \code{data_points} when supplied.}
#' }
#'
#' @seealso \code{\link{plot.hvti_nonparametric}},
#'   \code{\link{sample_nonparametric_curve_data}}
#'
#' @examples
#' dat     <- sample_nonparametric_curve_data(n = 500, time_max = 12)
#' dat_pts <- sample_nonparametric_curve_points(n = 500, time_max = 12)
#' np <- hvti_nonparametric(dat, lower_col = "lower", upper_col = "upper",
#'                           data_points = dat_pts)
#' np   # prints CI / data-point flags
#'
#' plot(np) +
#'   ggplot2::scale_colour_manual(values = c("steelblue"), guide = "none") +
#'   ggplot2::scale_fill_manual(values = c("steelblue"), guide = "none") +
#'   ggplot2::scale_x_continuous(limits = c(0, 12), breaks = 0:12) +
#'   ggplot2::scale_y_continuous(limits = c(0, 0.40),
#'                               breaks = seq(0, 0.40, 0.10),
#'                               labels = scales::percent) +
#'   ggplot2::labs(x = "Months", y = "Prevalence of AF") +
#'   hvti_theme("manuscript")
#'
#' @importFrom rlang .data
#' @export
hvti_nonparametric <- function(curve_data,
                                x_col        = "time",
                                estimate_col = "estimate",
                                lower_col    = NULL,
                                upper_col    = NULL,
                                group_col    = NULL,
                                data_points  = NULL) {
  .check_df(curve_data, "curve_data")
  .check_cols(curve_data, c(x_col, estimate_col), "curve_data")
  .check_col(curve_data, lower_col, "curve_data")
  .check_col(curve_data, upper_col, "curve_data")
  .check_col(curve_data, group_col, "curve_data")

  has_ci          <- !is.null(lower_col) && !is.null(upper_col)
  has_data_points <- !is.null(data_points)

  if (has_data_points) {
    .check_df(data_points, "data_points")
    .check_cols(data_points, c(x_col, "value"), "data_points")
    if (!is.null(group_col))
      .check_cols(data_points, group_col, "data_points")
  }

  tables <- if (has_data_points) list(data_points = data_points) else list()

  new_hvti_data(
    data = as.data.frame(curve_data),
    meta = list(
      x_col           = x_col,
      estimate_col    = estimate_col,
      lower_col       = lower_col,
      upper_col       = upper_col,
      group_col       = group_col,
      has_ci          = has_ci,
      has_data_points = has_data_points,
      n_obs           = nrow(curve_data)
    ),
    tables   = tables,
    subclass = "hvti_nonparametric"
  )
}


#' Print an hvti_nonparametric object
#'
#' @param x   An \code{hvti_nonparametric} object.
#' @param ... Ignored.
#' @return \code{x}, invisibly.
#' @export
print.hvti_nonparametric <- function(x, ...) {
  m <- x$meta
  cat("<hvti_nonparametric>\n")
  cat(sprintf("  N curve pts : %d\n", m$n_obs))
  cat(sprintf("  x / estimate: %s / %s\n", m$x_col, m$estimate_col))
  if (!is.null(m$group_col))
    cat(sprintf("  Group col   : %s\n", m$group_col))
  cat(sprintf("  CI ribbon   : %s\n", if (m$has_ci)
    paste(m$lower_col, "/", m$upper_col) else "none"))
  cat(sprintf("  Data points : %s\n", if (m$has_data_points) "yes" else "no"))
  invisible(x)
}


#' Plot an hvti_nonparametric object
#'
#' Draws a smooth predicted curve with optional CI ribbon and binned data
#' summary point overlay.
#'
#' @param x            An \code{hvti_nonparametric} object.
#' @param ci_alpha     Transparency of the confidence ribbon. Default \code{0.2}.
#' @param line_width   Width of the predicted curve line. Default \code{1.0}.
#' @param point_size   Size of binned data summary points. Default \code{2.5}.
#' @param point_shape  Integer shape code for data summary points.
#'   Default \code{20} (filled circle).
#' @param ...          Ignored; present for S3 consistency.
#'
#' @return A bare \code{\link[ggplot2]{ggplot}} object.
#'
#' @seealso \code{\link{hvti_nonparametric}}, \code{\link{hvti_theme}}
#'
#' @examples
#' dat_two <- sample_nonparametric_curve_data(
#'   n = 400, time_max = 7,
#'   groups = c("Ozaki" = 0.7, "CE-Pericardial" = 1.3),
#'   outcome_type = "continuous"
#' )
#' dat_two_pts <- sample_nonparametric_curve_points(
#'   n = 400, time_max = 7,
#'   groups = c("Ozaki" = 0.7, "CE-Pericardial" = 1.3),
#'   outcome_type = "continuous"
#' )
#' np <- hvti_nonparametric(dat_two, group_col = "group",
#'                           lower_col = "lower", upper_col = "upper",
#'                           data_points = dat_two_pts)
#' plot(np) +
#'   ggplot2::scale_colour_manual(
#'     values = c("Ozaki" = "steelblue", "CE-Pericardial" = "firebrick"),
#'     name = "Procedure"
#'   ) +
#'   ggplot2::scale_fill_manual(
#'     values = c("Ozaki" = "steelblue", "CE-Pericardial" = "firebrick"),
#'     guide  = "none"
#'   ) +
#'   ggplot2::labs(x = "Years", y = "AV Peak Gradient (mmHg)") +
#'   hvti_theme("manuscript")
#'
#' @importFrom ggplot2 ggplot aes geom_line geom_ribbon geom_point
#' @importFrom rlang .data
#' @export
plot.hvti_nonparametric <- function(x,
                                     ci_alpha    = 0.2,
                                     line_width  = 1.0,
                                     point_size  = 2.5,
                                     point_shape = 20L,
                                     ...) {
  curve_data   <- x$data
  m            <- x$meta
  x_col        <- m$x_col
  estimate_col <- m$estimate_col
  lower_col    <- m$lower_col
  upper_col    <- m$upper_col
  group_col    <- m$group_col

  if (!is.null(group_col)) {
    base_aes <- ggplot2::aes(x      = .data[[x_col]],
                             y      = .data[[estimate_col]],
                             colour = .data[[group_col]],
                             group  = .data[[group_col]])
  } else {
    base_aes <- ggplot2::aes(x = .data[[x_col]], y = .data[[estimate_col]])
  }

  p <- ggplot2::ggplot(curve_data, base_aes)

  if (m$has_ci) {
    if (!is.null(group_col)) {
      ribbon_aes <- ggplot2::aes(x      = .data[[x_col]],
                                 ymin   = .data[[lower_col]],
                                 ymax   = .data[[upper_col]],
                                 fill   = .data[[group_col]],
                                 group  = .data[[group_col]])
    } else {
      ribbon_aes <- ggplot2::aes(x    = .data[[x_col]],
                                 ymin = .data[[lower_col]],
                                 ymax = .data[[upper_col]])
    }
    p <- p + ggplot2::geom_ribbon(mapping     = ribbon_aes,
                                  alpha       = ci_alpha,
                                  colour      = NA,
                                  inherit.aes = FALSE,
                                  data        = curve_data)
  }

  p <- p + ggplot2::geom_line(linewidth = line_width)

  if (m$has_data_points) {
    data_points <- x$tables$data_points
    if (!is.null(group_col)) {
      dp_aes <- ggplot2::aes(x      = .data[[x_col]],
                             y      = .data[["value"]],
                             colour = .data[[group_col]])
    } else {
      dp_aes <- ggplot2::aes(x = .data[[x_col]], y = .data[["value"]])
    }
    p <- p + ggplot2::geom_point(mapping     = dp_aes,
                                 data        = data_points,
                                 size        = point_size,
                                 shape       = point_shape,
                                 inherit.aes = FALSE)
  }

  p
}
