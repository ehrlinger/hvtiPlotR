# nonparametric-curve-plot.R
#
# PORT of tp.np.*.avrg_curv.*, tp.np.*.u.trend.*, tp.np.*.double.*,
#         tp.np.*.mult.*, tp.np.*.phases.*, tp.np.z0axdpo.*.
#
# SAS EQUIVALENT: After running %decompos() and averaging patient-specific
# profiles with PROC SUMMARY, the resulting `mean_curv` dataset (columns:
# iv_echo/iv_wristm, prev/est, [cll_p68/clu_p68]) is the direct input to
# nonparametric_curve_plot().
#
# MIGRATION GUIDE FOR SAS USERS:
#   1. Export mean_curv  -> read.csv("mean_curv.csv")  -> curve_data
#   2. Export boots_ci   -> read.csv("boots_ci.csv")   -> same curve_data, lower/upper cols
#   3. Export means      -> read.csv("means.csv")      -> data_points
#   4. Call nonparametric_curve_plot(curve_data, ..., data_points = ...)
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

# ============================================================================

#' Sample Nonparametric Curve Data
#'
#' Simulates pre-computed curve output matching what SAS produces after fitting
#' a two-phase nonparametric temporal trend model and averaging patient-specific
#' profiles with `PROC SUMMARY`. The output is suitable for direct use with
#' [nonparametric_curve_plot()].
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
#'   e.g. `c("Ozaki" = 0.8, "CE-Pericardial" = 1.2)` — analogous to the
#'   indicator variable effect in `tp.np.avpkgrad_ozak_ind_mtwt.sas`.
#' @param outcome_type `"probability"` (binary outcome, 0-1 scale; e.g.
#'   AF prevalence, TR grade prevalence) or `"continuous"` (e.g. FEV1, AV
#'   peak gradient). Default `"probability"`.
#' @param ci_level    Confidence level for bootstrap-style CI bands.
#'   Use `0.68` for the 68% CI shown in the SAS templates (one standard
#'   error), or `0.95` for the 95% CI. Default `0.68`.
#' @param n_bins      Number of equal-sized data-summary bins (analogous to
#'   the SAS `quint = _nobs_/12` / `decile = _nobs_/10` grouping). Default
#'   `10`.
#' @param seed        Random seed. Default `42`.
#'
#' @return A data frame with columns `time`, `estimate`, `lower`, `upper`,
#'   and (if `groups` is not `NULL`) `group`.
#'
#' @seealso [nonparametric_curve_plot()], [sample_nonparametric_curve_points()]
#'
#' @examples
#' # Single average curve (like tp.np.afib.ivwristm.avrg_curv.binary.sas)
#' dat <- sample_nonparametric_curve_data(n = 500, time_max = 12)
#' head(dat)
#'
#' # Two-group comparison (like tp.np.avpkgrad_ozak_ind_mtwt.sas)
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

  # Fine time grid (log-spaced like SAS min=-5;max=log(t);inc=...)
  t_grid <- exp(seq(log(0.05), log(max(time_max, 0.1)), length.out = n_points))

  # ----------- Simulation parameters (analogous to model estimates) ----------
  thalf1 <- time_max * 0.15    # early half-life
  thalf2 <- time_max * 0.55    # late half-life

  if (is.null(groups)) {
    # Single curve --------------------------------------------------------
    eta  <- .np_two_phase(t_grid, e0 = -0.5, thalf1 = thalf1, thalf2 = thalf2)

    if (outcome_type == "probability") {
      est  <- stats::plogis(eta - 1.2)
      se   <- sqrt(pmax(est * (1 - est), 1e-4) / (n * 0.1))
      lo   <- stats::plogis(stats::qlogis(pmax(est, 1e-4)) - z_score * se /
                              sqrt(est * (1 - est) + 1e-4))
      hi   <- stats::plogis(stats::qlogis(pmax(est, 1e-4)) + z_score * se /
                              sqrt(est * (1 - est) + 1e-4))
    } else {
      est  <- 40 + 8 * eta         # e.g. AV peak gradient in mmHg
      sigma <- 6
      lo   <- est - z_score * sigma / sqrt(n * 0.05)
      hi   <- est + z_score * sigma / sqrt(n * 0.05)
    }

    curve_df <- data.frame(time     = t_grid,
                           estimate = est,
                           lower    = pmax(lo, 0),
                           upper    = hi)

  } else {
    # Multi-group curves --------------------------------------------------
    grp_names <- names(groups)
    curve_list <- lapply(seq_along(groups), function(i) {
      eta <- .np_two_phase(t_grid, e0 = log(groups[[i]]) - 0.5,
                           thalf1 = thalf1, thalf2 = thalf2)
      if (outcome_type == "probability") {
        est <- stats::plogis(eta - 1.2)
        se  <- sqrt(pmax(est * (1 - est), 1e-4) / (n * 0.1))
        lo  <- stats::plogis(stats::qlogis(pmax(est, 1e-4)) - z_score * se /
                               sqrt(est * (1 - est) + 1e-4))
        hi  <- stats::plogis(stats::qlogis(pmax(est, 1e-4)) + z_score * se /
                               sqrt(est * (1 - est) + 1e-4))
      } else {
        est <- 40 + 8 * eta
        se  <- 6
        lo  <- est - z_score * se / sqrt(n * 0.05)
        hi  <- est + z_score * se / sqrt(n * 0.05)
      }
      data.frame(time     = t_grid,
                 estimate = est,
                 lower    = pmax(lo, 0),
                 upper    = hi,
                 group    = grp_names[[i]])
    })
    curve_df <- do.call(rbind, curve_list)
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
#' @seealso [sample_nonparametric_curve_data()], [nonparametric_curve_plot()]
#'
#' @examples
#' pts <- sample_nonparametric_curve_points(n = 500, time_max = 12)
#' head(pts)
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
    dp_df <- do.call(rbind, dp_list)
    dp_df$group <- factor(dp_df$group, levels = grp_names)
  }

  dp_df
}

# Internal: generate binned patient-level data summary
.np_sample_bins <- function(n, time_max, thalf1, thalf2, outcome_type, n_bins) {
  t_pat <- stats::runif(n, 0.05, time_max)
  eta   <- .np_two_phase(t_pat, e0 = -0.5, thalf1 = thalf1, thalf2 = thalf2)
  if (outcome_type == "probability") {
    mu  <- stats::plogis(eta - 1.2)
    obs <- stats::rbinom(n, 1, mu)
  } else {
    mu  <- 40 + 8 * eta
    obs <- stats::rnorm(n, mu, 6)
  }
  # Bin into n_bins equal-sized groups (like SAS quint / decile logic)
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

#' Nonparametric Temporal Trend Curve Plot
#'
#' Plots a pre-computed smooth predicted curve (and optional confidence band
#' and binned data summary points) from a nonparametric temporal trend model.
#' Covers the full range of `tp.np.*` SAS templates:
#'
#' | SAS template pattern | R usage |
#' |---|---|
#' | Single average curve (`avrg_curv`, `u.trend`) | `nonparametric_curve_plot(dat$curve)` |
#' | Curve + 68% CI (`avrg_curv.ci`) | `+ lower_col + upper_col` |
#' | Curve + CI + data points (`avrg_curv.ci.pts`) | `+ data_points = dat$data_points` |
#' | Two-group comparison (`double`, `ozak`) | `+ group_col = "group"` |
#' | Multi-scenario / covariate-adjusted (`mult`, `bmi_xaxis`) | `+ group_col = "group"` |
#' | Phase decomposition (`pt_spec_phases`, `independence`, `u.phases`) | `+ group_col = "phase"` |
#'
#' **SAS column mapping:**
#' - `estimate_col` ← `prev`, `mnprev`, `_p_`, `est_fev`, `est_z0d` (the predicted value)
#' - `lower_col` ← `cll_p68` or `cll_p95` from the bootstrap CI dataset
#' - `upper_col` ← `clu_p68` or `clu_p95`
#' - `group_col` ← a grouping indicator you add after reshaping from wide to long
#'   (use [tidyr::pivot_longer()] on the SAS `predict` dataset)
#'
#' **Reshaping from wide to long (SAS → R):**
#' SAS templates keep multiple curves as separate variables (`p0`, `p1`, `p2`)
#' in one dataset. In R, reshape to long format before calling this function:
#' ```r
#' library(tidyr)
#' long <- pivot_longer(predict_wide,
#'                      cols      = c(odd_e, odd_l),
#'                      names_to  = "phase",
#'                      values_to = "estimate")
#' nonparametric_curve_plot(long, group_col = "phase")
#' ```
#'
#' Returns a **bare ggplot object**. Compose with `scale_colour_*`,
#' `scale_x_continuous()`, `labs()`, [hvti_theme()]:
#' ```r
#' nonparametric_curve_plot(dat, ...) +
#'   scale_colour_manual(values = c(...)) +
#'   scale_x_continuous(breaks = 0:12) +
#'   labs(x = "Months", y = "Prevalence of AF (%)") +
#'   hvti_theme("manuscript")
#' ```
#'
#' @param curve_data  Data frame containing the fine-grid predicted curve.
#'   One row per time point (per group if stratified). Typical source: the
#'   SAS `mean_curv` or `boots_ci` datasets exported to CSV.
#' @param x_col       Name of the x-axis column (time or continuous covariate
#'   such as BMI). Corresponds to `iv_wristm`, `iv_echo`, `iv_fevpn`, or
#'   `bmi` in SAS. Default `"time"`.
#' @param estimate_col Name of the predicted value column. Corresponds to
#'   `prev`, `mnprev`, `_p_`, `est_fev`, `p0`–`p3` (one at a time) in SAS.
#'   Default `"estimate"`.
#' @param lower_col   Name of the lower CI bound column, or `NULL` for no
#'   ribbon. Corresponds to `cll_p68` / `cll_p95` in SAS. Default `NULL`.
#' @param upper_col   Name of the upper CI bound column, or `NULL` for no
#'   ribbon. Corresponds to `clu_p68` / `clu_p95` in SAS. Default `NULL`.
#' @param group_col   Name of the column used to stratify curves by colour
#'   and linetype, or `NULL` for a single curve. Use for group comparisons
#'   (e.g. Ozaki vs CE-Pericardial) or phase decomposition (Early vs Late).
#'   Default `NULL`.
#' @param data_points Optional data frame of binned data summary points to
#'   overlay as filled circles. Must have a column matching `x_col` for x,
#'   a column named `"value"` for y, and (when `group_col` is not `NULL`) a
#'   column matching `group_col`. Default `NULL`.
#' @param ci_alpha    Transparency of the confidence ribbon (`[0,1]`).
#'   Default `0.2`.
#' @param line_width  Width of the predicted curve line. SAS `width=3`
#'   corresponds roughly to `line_width = 1.2`. Default `1.0`.
#' @param point_size  Size of the binned data summary points. SAS `symbsize=3/4`
#'   corresponds roughly to `point_size = 2.0`. Default `2.5`.
#' @param point_shape Integer shape code for data summary points. Default `20`
#'   (filled circle; corresponds to SAS `symbol=dot`).
#'
#' @return A [ggplot2::ggplot()] object. Compose with `scale_colour_*`,
#'   `scale_x_continuous()`, `labs()`, `annotate()`, and [hvti_theme()].
#'
#' @seealso [sample_nonparametric_curve_data()], [nonparametric_ordinal_plot()],
#'   [hvti_theme()]
#'
#' @references SAS templates: \code{tp.np.*.avrg_curv.*},
#'   \code{tp.np.*.u.trend.*}, \code{tp.np.*.double.*},
#'   \code{tp.np.*.mult.*}, \code{tp.np.*.phases.*},
#'   \code{tp.np.z0axdpo.*}.
#'
#' @examples
#' # Sample data for examples below
#' dat_bin <- sample_nonparametric_curve_data(
#'   n = 500, time_max = 12, outcome_type = "probability"
#' )
#' dat_con <- sample_nonparametric_curve_data(
#'   n = 400, time_max = 7, outcome_type = "continuous"
#' )
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
#' dat_multi <- sample_nonparametric_curve_data(
#'   n = 600, time_max = 14,
#'   groups = c("CABG-" = 0.6, "CABG+" = 1.4),
#'   outcome_type = "probability"
#' )
#' dat_multi_pts <- sample_nonparametric_curve_points(
#'   n = 600, time_max = 14,
#'   groups = c("CABG-" = 0.6, "CABG+" = 1.4),
#'   outcome_type = "probability"
#' )
#'
#' # --- (1) Single average curve, no CI ------------------------------------
#' # Matches tp.np.afib.ivwristm.avrg_curv.binary.sas (mean_curv dataset,
#' # no confidence interval plotted).
#' nonparametric_curve_plot(dat_bin) +
#'   ggplot2::scale_colour_manual(values = c("steelblue"), guide = "none") +
#'   ggplot2::scale_x_continuous(limits = c(0, 12), breaks = 0:12,
#'                               minor_breaks = NULL) +
#'   ggplot2::scale_y_continuous(limits = c(0, 0.40),
#'                               breaks = seq(0, 0.40, 0.10),
#'                               labels = scales::percent) +
#'   ggplot2::labs(x = "Months", y = "Prevalence of AF") +
#'   hvti_theme("manuscript")
#'
#' # --- (2) Single curve + 68% CI ribbon ------------------------------------
#' # Matches the .ci.ps / .ci.cgm variants in tp.np.afib.ivwristm.avrg_curv.
#' # cll_p68 / clu_p68 from the SAS boots_ci dataset → lower / upper cols.
#' # The SAS boots_ci dataset also contains cll_p95 / clu_p95 (95% CI); swap
#' # lower_col / upper_col to those columns for a 95% interval.
#' nonparametric_curve_plot(
#'   dat_bin,
#'   lower_col = "lower",
#'   upper_col = "upper"
#' ) +
#'   ggplot2::scale_colour_manual(values = c("steelblue"), guide = "none") +
#'   ggplot2::scale_fill_manual(values = c("steelblue"), guide = "none") +
#'   ggplot2::scale_x_continuous(limits = c(0, 12), breaks = 0:12) +
#'   ggplot2::scale_y_continuous(limits = c(0, 0.40),
#'                               breaks = seq(0, 0.40, 0.10),
#'                               labels = scales::percent) +
#'   ggplot2::labs(x = "Months", y = "Prevalence of AF",
#'                 caption = "Shaded region: 68% bootstrap confidence interval") +
#'   hvti_theme("manuscript")
#'
#' # --- (3) Single curve + CI + binned data points --------------------------
#' # Matches the .ci.pts.ps variant. Data points come from the SAS `means`
#' # dataset (mmtime, safc). Point colour matches the curve colour.
#' dat_bin_pts <- sample_nonparametric_curve_points(
#'   n = 500, time_max = 12, outcome_type = "probability"
#' )
#' nonparametric_curve_plot(
#'   dat_bin,
#'   lower_col   = "lower",
#'   upper_col   = "upper",
#'   data_points = dat_bin_pts
#' ) +
#'   ggplot2::scale_colour_manual(values = c("steelblue"), guide = "none") +
#'   ggplot2::scale_fill_manual(values = c("steelblue"), guide = "none") +
#'   ggplot2::scale_x_continuous(limits = c(0, 12), breaks = 0:12) +
#'   ggplot2::scale_y_continuous(limits = c(0, 0.40),
#'                               breaks = seq(0, 0.40, 0.10),
#'                               labels = scales::percent) +
#'   ggplot2::labs(x = "Months", y = "Prevalence of AF") +
#'   hvti_theme("manuscript")
#'
#' # --- (4) Two-group comparison, continuous outcome ------------------------
#' # Matches tp.np.avpkgrad_ozak_ind_mtwt.sas and
#' # tp.np.fev.double.univariate.continuous.sas.
#' # CI ribbon fill matches group colour; use scale_fill_manual to suppress
#' # the legend for the ribbon.
#' # Note: the Ozaki SAS template uses different point shapes per group
#' # (dot vs trianglefilled); add scale_shape_manual() after to replicate this.
#' nonparametric_curve_plot(
#'   dat_two,
#'   group_col   = "group",
#'   lower_col   = "lower",
#'   upper_col   = "upper",
#'   data_points = dat_two_pts
#' ) +
#'   ggplot2::scale_colour_manual(
#'     values = c("Ozaki" = "steelblue", "CE-Pericardial" = "firebrick"),
#'     name   = "Procedure"
#'   ) +
#'   ggplot2::scale_fill_manual(
#'     values = c("Ozaki" = "steelblue", "CE-Pericardial" = "firebrick"),
#'     guide  = "none"
#'   ) +
#'   ggplot2::scale_x_continuous(limits = c(0, 7), breaks = 0:7) +
#'   ggplot2::scale_y_continuous(limits = c(25, 55),
#'                               breaks = seq(25, 55, 5)) +
#'   ggplot2::labs(x = "Years after Surgery",
#'                 y = "AV Peak Gradient (mmHg)") +
#'   ggplot2::annotate("text", x = 5, y = 52,
#'                     label = "68% bootstrap CI",
#'                     size = 3, colour = "grey40", fontface = "italic") +
#'   hvti_theme("manuscript")
#'
#' # --- (5) Two-group comparison, binary outcome ----------------------------
#' # Matches tp.np.afib.mult.avrg_curv.binary.sas (CABG vs no-CABG).
#' nonparametric_curve_plot(
#'   dat_multi,
#'   group_col   = "group",
#'   lower_col   = "lower",
#'   upper_col   = "upper",
#'   data_points = dat_multi_pts
#' ) +
#'   ggplot2::scale_colour_brewer(palette = "Set1", name = "CABG") +
#'   ggplot2::scale_fill_brewer(palette = "Set1", guide = "none") +
#'   ggplot2::scale_x_continuous(limits = c(0, 14),
#'                               breaks = seq(0, 14, 2)) +
#'   ggplot2::scale_y_continuous(limits = c(0, 0.30),
#'                               breaks = seq(0, 0.30, 0.10),
#'                               labels = scales::percent) +
#'   ggplot2::labs(x = "Months after Surgery",
#'                 y = "Prevalence of AF") +
#'   hvti_theme("manuscript")
#'
#' # --- (6) Phase decomposition (early vs late) -----------------------------
#' # Matches tp.np.afib.ivwristm.pt_spec_phases.binary.sas and
#' # tp.np.tr.ivecho.independence.sas / u.phases.sas.
#' # In SAS: odd_e and odd_l are separate columns in the predict dataset.
#' # In R: reshape to long format with a "phase" column before plotting.
#' dat_ph <- dat_bin
#' dat_long <- rbind(
#'   data.frame(time     = dat_ph$time,
#'              estimate = dat_ph$estimate * 0.45,
#'              phase    = "early"),
#'   data.frame(time     = dat_ph$time,
#'              estimate = dat_ph$estimate * 0.55,
#'              phase    = "late")
#' )
#' nonparametric_curve_plot(dat_long, group_col = "phase") +
#'   ggplot2::scale_colour_manual(
#'     values = c(early = "steelblue", late = "firebrick"),
#'     labels = c(early = "Early phase", late = "Late phase"),
#'     name   = NULL
#'   ) +
#'   ggplot2::scale_x_continuous(limits = c(0, 12), breaks = 0:12) +
#'   ggplot2::scale_y_continuous(labels = scales::percent) +
#'   ggplot2::labs(x = "Months", y = "Odds (decomposed)",
#'                 title = "Phase decomposition of temporal trend") +
#'   ggplot2::annotate("text", x = 3, y = 0.08,
#'                     label = "Early", colour = "steelblue",
#'                     size = 3.5, fontface = "bold") +
#'   ggplot2::annotate("text", x = 9, y = 0.12,
#'                     label = "Late", colour = "firebrick",
#'                     size = 3.5, fontface = "bold") +
#'   hvti_theme("manuscript")
#'
#' # --- (7) Multi-scenario / covariate-adjusted curves ----------------------
#' # Matches tp.np.fev.multivariate.continuous.sas and
#' # tp.np.afib.mult.pt_spec.binary.sas (multiple patient profiles).
#' dat_scen <- sample_nonparametric_curve_data(
#'   n = 600, time_max = 7,
#'   groups = c("Low risk"    = 0.60,
#'              "Medium risk" = 1.00,
#'              "High risk"   = 1.60),
#'   outcome_type = "probability",
#'   seed = 10
#' )
#' nonparametric_curve_plot(dat_scen, group_col = "group") +
#'   ggplot2::scale_colour_manual(
#'     values = c("Low risk" = "forestgreen",
#'                "Medium risk" = "goldenrod3",
#'                "High risk"   = "firebrick"),
#'     name = "Patient profile"
#'   ) +
#'   ggplot2::scale_x_continuous(limits = c(0, 7), breaks = 0:7) +
#'   ggplot2::scale_y_continuous(limits = c(0, 0.50),
#'                               breaks = seq(0, 0.50, 0.10),
#'                               labels = scales::percent) +
#'   ggplot2::labs(x = "Years", y = "Prevalence",
#'                 title = "Covariate-adjusted temporal profiles") +
#'   hvti_theme("manuscript")
#'
#' # --- (8) Non-time x-axis (BMI on x-axis) --------------------------------
#' # Matches tp.np.z0axdpo.continuous.bmi_xaxis.sas.
#' # In SAS the predict loop uses bmi as the x variable instead of time.
#' # Generate two fixed time-point curves over a BMI range:
#' bmi_grid <- seq(20, 45, length.out = 200)
#' dat_bmi  <- data.frame(
#'   bmi      = rep(bmi_grid, 2),
#'   diameter = c(30 + 0.30 * bmi_grid,       # 0.25-year curve
#'                30 + 0.30 * bmi_grid + 3),  # 5-year curve
#'   followup = rep(c("0.25 years", "5 years"), each = 200)
#' )
#' nonparametric_curve_plot(
#'   dat_bmi,
#'   x_col        = "bmi",
#'   estimate_col = "diameter",
#'   group_col    = "followup"
#' ) +
#'   ggplot2::scale_colour_manual(
#'     values = c("0.25 years" = "steelblue", "5 years" = "firebrick"),
#'     name   = "Follow-up"
#'   ) +
#'   ggplot2::scale_x_continuous(limits = c(20, 45),
#'                               breaks = seq(20, 45, 5)) +
#'   ggplot2::scale_y_continuous(limits = c(28, 50),
#'                               breaks = seq(28, 50, 4)) +
#'   ggplot2::labs(x = expression("BMI (kg/m"^2*")"),
#'                 y = "Aortic diameter (mm)") +
#'   ggplot2::annotate("text", x = 40, y = 32,
#'                     label = "Early", colour = "steelblue",
#'                     size = 3.5) +
#'   ggplot2::annotate("text", x = 40, y = 36,
#'                     label = "Late", colour = "firebrick",
#'                     size = 3.5) +
#'   hvti_theme("manuscript")
#'
#' # --- (9) PowerPoint dark theme (CGM output equivalent) -------------------
#' \dontrun{
#' nonparametric_curve_plot(dat_bin,
#'                          lower_col = "lower", upper_col = "upper") +
#'   ggplot2::scale_colour_manual(values = c("yellow"), guide = "none") +
#'   ggplot2::scale_fill_manual(values = c("yellow"), guide = "none") +
#'   ggplot2::labs(x = "Months", y = "Prevalence of AF (%)") +
#'   hvti_theme("dark_ppt")
#' }
#'
#' # --- (10) Dual-Y-axis overlay (tp.np_two_Yaxis_plots.R pattern) ----------
#' # Overlays two continuous outcomes on left and right y-axes using
#' # scale_y_continuous(sec.axis = ...). The R templates build this directly
#' # with ggplot2 rather than nonparametric_curve_plot(), as two independent
#' # geom_line layers on separate scales are needed.
#' \dontrun{
#' dat_y1 <- sample_nonparametric_curve_data(
#'   n = 400, time_max = 10, outcome_type = "continuous", seed = 20
#' )
#' dat_y2 <- sample_nonparametric_curve_data(
#'   n = 400, time_max = 10, outcome_type = "continuous", seed = 21
#' )
#' # Rescale dat_y2 onto the dat_y1 axis range for dual-axis rendering
#' scale_factor <- mean(dat_y1$estimate) / mean(dat_y2$estimate)
#' ggplot2::ggplot() +
#'   ggplot2::geom_line(
#'     data    = dat_y1,
#'     mapping = ggplot2::aes(x = time, y = estimate),
#'     colour  = "steelblue", linewidth = 1
#'   ) +
#'   ggplot2::geom_line(
#'     data    = dat_y2,
#'     mapping = ggplot2::aes(x = time, y = estimate * scale_factor),
#'     colour  = "firebrick", linewidth = 1
#'   ) +
#'   ggplot2::scale_y_continuous(
#'     name     = "Svensson's Index (mm)",
#'     sec.axis = ggplot2::sec_axis(
#'       transform = ~ . / scale_factor,
#'       name      = "Aortic Root Diameter (mm)"
#'     )
#'   ) +
#'   ggplot2::scale_x_continuous(breaks = seq(0, 10, 2)) +
#'   ggplot2::labs(x = "Years after Presentation") +
#'   hvti_theme("manuscript")
#' }
#'
#' # --- Save ----------------------------------------------------------------
#' \dontrun{
#' p <- nonparametric_curve_plot(
#'   dat_bin,
#'   lower_col   = "lower",
#'   upper_col   = "upper",
#'   data_points = dat_bin_pts
#' ) +
#'   ggplot2::scale_colour_manual(values = c("steelblue"), guide = "none") +
#'   ggplot2::scale_fill_manual(values = c("steelblue"), guide = "none") +
#'   ggplot2::labs(x = "Months", y = "Prevalence of AF") +
#'   hvti_theme("manuscript")
#' ggplot2::ggsave("np_curve.pdf", p, width = 11.5, height = 8)
#' }
#'
#' @importFrom ggplot2 ggplot aes geom_line geom_ribbon geom_point
#' @importFrom rlang .data
#' @export
nonparametric_curve_plot <- function(curve_data,
                                     x_col        = "time",
                                     estimate_col = "estimate",
                                     lower_col    = NULL,
                                     upper_col    = NULL,
                                     group_col    = NULL,
                                     data_points  = NULL,
                                     ci_alpha     = 0.2,
                                     line_width   = 1.0,
                                     point_size   = 2.5,
                                     point_shape  = 20L) {

  # --- Validation -----------------------------------------------------------
  if (!is.data.frame(curve_data))
    stop("`curve_data` must be a data frame.")
  for (col in c(x_col, estimate_col)) {
    if (!(col %in% names(curve_data)))
      stop(paste0("Column '", col, "' not found in `curve_data`."))
  }
  if (!is.null(lower_col))
    if (!(lower_col %in% names(curve_data)))
      stop(paste0("`lower_col` '", lower_col, "' not found in `curve_data`."))
  if (!is.null(upper_col))
    if (!(upper_col %in% names(curve_data)))
      stop(paste0("`upper_col` '", upper_col, "' not found in `curve_data`."))
  if (!is.null(group_col))
    if (!(group_col %in% names(curve_data)))
      stop(paste0("`group_col` '", group_col, "' not found in `curve_data`."))
  if (!is.null(data_points)) {
    if (!is.data.frame(data_points))
      stop("`data_points` must be a data frame.")
    if (!(x_col %in% names(data_points)))
      stop(paste0("`data_points` must have a column '", x_col,
                  "' (matching x_col)."))
    if (!("value" %in% names(data_points)))
      stop("`data_points` must have a column named 'value'.")
    if (!is.null(group_col) && !(group_col %in% names(data_points)))
      stop(paste0("`data_points` must have a column '", group_col,
                  "' (matching group_col)."))
  }

  # --- Base aesthetics ------------------------------------------------------
  if (!is.null(group_col)) {
    base_aes <- ggplot2::aes(x      = .data[[x_col]],
                             y      = .data[[estimate_col]],
                             colour = .data[[group_col]],
                             group  = .data[[group_col]])
  } else {
    base_aes <- ggplot2::aes(x = .data[[x_col]], y = .data[[estimate_col]])
  }

  p <- ggplot2::ggplot(curve_data, base_aes)

  # --- CI ribbon ------------------------------------------------------------
  if (!is.null(lower_col) && !is.null(upper_col)) {
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

  # --- Predicted curve line -------------------------------------------------
  p <- p + ggplot2::geom_line(linewidth = line_width)

  # --- Binned data summary points -------------------------------------------
  if (!is.null(data_points)) {
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
