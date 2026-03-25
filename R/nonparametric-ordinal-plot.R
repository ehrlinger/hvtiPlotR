# nonparametric-ordinal-plot.R
#
# PORT of tp.np.tr.ivecho.average_curv.ordinal.sas
#         tp.np.po_ar.u_multi.ordinal.sas
#         tp.np.tr.ivecho.independence.sas
#         tp.np.tr.ivecho.u.phases.sas
#
# SAS EQUIVALENT: After running %decompos() with ordinal intercepts (a0, a1,
# a2), computing cp0/cp1/cp2 (cumulative probabilities) and p0/p1/p2/p3
# (individual grade probabilities), then averaging patient-specific curves with
# PROC SUMMARY by iv_echo, the resulting `predict` dataset in LONG format is
# the direct input to nonparametric_ordinal_plot().
#
# MIGRATION GUIDE FOR SAS USERS:
#   SAS keeps one column per grade: p0, p1, p2, p3.
#   R / ggplot2 prefers LONG format: one row per (time, grade) combination.
#
#   Reshape step (replaces the wide `predict` dataset):
#     library(tidyr)
#     long <- pivot_longer(
#       predict_wide,
#       cols      = c(p0, p1, p2, p3),
#       names_to  = "grade",
#       values_to = "estimate"
#     )
#
#   Same reshape for the binned data summary (SAS `means` dataset with
#   smntr0, smntr1, smntr2, smntr3 columns):
#     dp_long <- pivot_longer(
#       means,
#       cols      = c(smntr0, smntr1, smntr2, smntr3),
#       names_to  = "grade",
#       values_to = "value"
#     )
#     dp_long$time <- means$mtime   # or mmtime
#
#   Then call:
#     nonparametric_ordinal_plot(long, data_points = dp_long)
# ---------------------------------------------------------------------------

#' Sample Nonparametric Ordinal Curve Data
#'
#' Simulates pre-computed grade-specific probability curves matching what SAS
#' produces after fitting a cumulative proportional-odds nonparametric temporal
#' trend model. Covers the ordinal TR / AR grade patterns from:
#' - `tp.np.tr.ivecho.average_curv.ordinal.sas` (p0, p1, p2, p3 individual probs)
#' - `tp.np.po_ar.u_multi.ordinal.sas` (multi-scenario ordinal, p34 = p3+p4)
#'
#' **SAS context:** The SAS `predict` dataset has one column per grade
#' (`p0`, `p1`, `p2`, `p3`) after computing individual probabilities from
#' cumulative probabilities (`cp0 = co0/(1+co0)`, etc.). Export it to CSV
#' and reshape to long format to use your own model output.
#'
#' @param n            Number of simulated patients (controls CI width and
#'   data-point variability). Default `1000`.
#' @param time_max     Upper end of the time axis (years). Default `5`.
#' @param n_points     Number of time points on the prediction grid. Default
#'   `500`.
#' @param grade_labels Character vector of grade labels, one per grade level
#'   in ascending order. Corresponds to the SAS grade levels (e.g.
#'   `c("None", "Mild", "Moderate", "Severe")` for AR grade, or
#'   `c("0", "1", "2", "3+")` for TR grade). Default
#'   `c("Grade 0", "Grade 1", "Grade 2", "Grade 3")`.
#' @param n_bins       Number of equal-sized bins for the data summary points
#'   (analogous to SAS `decile = _nobs_/10`). Default `10`.
#' @param seed         Random seed. Default `42`.
#'
#' @return A long-format data frame: `time`, `estimate`, `grade` (factor).
#'   Individual grade probabilities sum to 1 at each time point.
#'
#' @seealso [nonparametric_ordinal_plot()], [sample_nonparametric_curve_data()],
#'   [sample_nonparametric_ordinal_points()]
#'
#' @examples
#' dat <- sample_nonparametric_ordinal_data(n = 800, time_max = 5)
#' head(dat)
#' # verify probabilities sum to 1 at each time point
#' tapply(dat$estimate[dat$time == dat$time[1]],
#'        dat$grade[dat$time == dat$time[1]], sum)
#' @export
sample_nonparametric_ordinal_data <- function(n            = 1000,
                                              time_max     = 5,
                                              n_points     = 500,
                                              grade_labels = c("Grade 0",
                                                               "Grade 1",
                                                               "Grade 2",
                                                               "Grade 3"),
                                              n_bins       = 10,
                                              seed         = 42L) {
  set.seed(seed)
  n_grades <- length(grade_labels)

  # ----------- Simulation tuning constants -----------------------------------
  a_first       <- 0.5   # first ordinal intercept (cumulative cut-point 1)
  a_step        <- 1.2   # spacing between successive intercepts
  eta_intercept <- -0.2  # two-phase trend at baseline (centred near 0)

  # Log-spaced time grid (matches SAS min=-5;max=log(t);inc=... loop)
  t_grid <- exp(seq(log(0.01), log(max(time_max, 0.1)), length.out = n_points))

  # Ordinal intercepts (a0, a1, a2 in SAS) — define cumulative cut-points
  # Increasing: a[1] < a[1]+a[2] < a[1]+a[2]+a[3] etc.
  a_raw <- cumsum(c(a_first, rep(a_step, n_grades - 2)))   # n_cuts = n_grades - 1

  # Common temporal trend (two-phase, centred near 0 at baseline)
  thalf1 <- time_max * 0.20
  thalf2 <- time_max * 0.60
  eta    <- .np_two_phase(t_grid, e0 = eta_intercept, thalf1 = thalf1, thalf2 = thalf2)

  # Cumulative probabilities (proportional odds):
  # P(grade >= k | t) = plogis(a[k] + eta(t))
  cp <- matrix(NA_real_, nrow = n_points, ncol = n_grades - 1L)
  for (k in seq_len(n_grades - 1L)) {
    cp[, k] <- stats::plogis(a_raw[k] + eta)
  }

  # Individual grade probabilities
  prob <- matrix(NA_real_, nrow = n_points, ncol = n_grades)
  prob[, 1L] <- cp[, 1L]
  for (k in seq(2L, n_grades - 1L)) {
    prob[, k] <- cp[, k] - cp[, k - 1L]
  }
  prob[, n_grades] <- 1 - cp[, n_grades - 1L]
  prob <- pmax(prob, 0)

  # Assemble long format
  curve_df <- do.call(rbind, lapply(seq_len(n_grades), function(k) {
    data.frame(time     = t_grid,
               estimate = prob[, k],
               grade    = grade_labels[k])
  }))
  curve_df$grade <- factor(curve_df$grade, levels = grade_labels)

  # ----------- Binned data summary -----------------------------------------
  # Simulate individual ordinal observations and bin by time decile
  t_pat   <- stats::runif(n, 0.01, time_max)
  eta_pat <- .np_two_phase(t_pat, e0 = eta_intercept, thalf1 = thalf1, thalf2 = thalf2)
  cp_pat  <- matrix(NA_real_, nrow = n, ncol = n_grades - 1L)
  for (k in seq_len(n_grades - 1L)) {
    cp_pat[, k] <- stats::plogis(a_raw[k] + eta_pat)
  }
  # Simulate ordinal grade via cumulative model
  u_pat <- stats::runif(n)
  grade_obs <- rowSums(u_pat > cbind(cp_pat, 1)) + 1L  # grade index 1..n_grades

  ord  <- order(t_pat)
  t_s  <- t_pat[ord]
  g_s  <- grade_obs[ord]
  bin  <- cut(seq_along(t_s), breaks = n_bins, labels = FALSE)
  bin_time <- tapply(t_s, bin, mean)

  curve_df
}

#' Sample Nonparametric Ordinal Data Points
#'
#' Returns only the binned patient-level data summary points from
#' [sample_nonparametric_ordinal_data()]. Accepts the same parameters
#' and returns a plain `data.frame`.
#'
#' @inheritParams sample_nonparametric_ordinal_data
#'
#' @return A data frame with columns `time`, `value`, `grade`.
#'
#' @seealso [sample_nonparametric_ordinal_data()],
#'   [nonparametric_ordinal_plot()]
#'
#' @examples
#' # Default: four grade levels
#' pts <- sample_nonparametric_ordinal_points(n = 800, time_max = 5)
#' head(pts)
#' levels(pts$grade)    # "Grade 0", "Grade 1", "Grade 2", "Grade 3"
#'
#' # Clinical AR grade labels
#' pts2 <- sample_nonparametric_ordinal_points(
#'   n            = 600,
#'   time_max     = 7,
#'   grade_labels = c("None", "Mild", "Moderate", "Severe")
#' )
#' table(pts2$grade)    # n_bins rows per grade
#' @export
sample_nonparametric_ordinal_points <- function(
  n            = 1000,
  time_max     = 5,
  n_points     = 500,
  grade_labels = c("Grade 0", "Grade 1", "Grade 2", "Grade 3"),
  n_bins       = 10,
  seed         = 42L
) {
  set.seed(seed)
  n_grades <- length(grade_labels)

  # ----------- Simulation tuning constants -----------------------------------
  a_first       <- 0.5   # first ordinal intercept (cumulative cut-point 1)
  a_step        <- 1.2   # spacing between successive intercepts
  eta_intercept <- -0.2  # two-phase trend at baseline (centred near 0)

  a_raw <- cumsum(c(a_first, rep(a_step, n_grades - 2)))

  thalf1 <- time_max * 0.20
  thalf2 <- time_max * 0.60

  t_pat   <- stats::runif(n, 0.01, time_max)
  eta_pat <- .np_two_phase(t_pat, e0 = eta_intercept, thalf1 = thalf1, thalf2 = thalf2)
  cp_pat  <- matrix(NA_real_, nrow = n, ncol = n_grades - 1L)
  for (k in seq_len(n_grades - 1L)) {
    cp_pat[, k] <- stats::plogis(a_raw[k] + eta_pat)
  }
  u_pat <- stats::runif(n)
  grade_obs <- rowSums(u_pat > cbind(cp_pat, 1)) + 1L

  ord  <- order(t_pat)
  t_s  <- t_pat[ord]
  g_s  <- grade_obs[ord]
  bin  <- cut(seq_along(t_s), breaks = n_bins, labels = FALSE)
  bin_time <- tapply(t_s, bin, mean)

  dp_list <- lapply(seq_len(n_grades), function(k) {
    prop <- tapply(g_s == k, bin, mean)
    data.frame(time  = as.numeric(bin_time),
               value = as.numeric(prop),
               grade = grade_labels[k])
  })
  dp_df       <- do.call(rbind, dp_list)
  dp_df$grade <- factor(dp_df$grade, levels = grade_labels)
  dp_df
}

# ============================================================================

#' Nonparametric Ordinal Outcome Curve Plot
#'
#' Plots pre-computed grade-specific probability curves from a cumulative
#' proportional-odds nonparametric temporal trend model. Each grade level is
#' rendered as a distinct coloured line. Returns a bare ggplot object for
#' composition with `scale_colour_*`, `labs()`, and [hvti_theme()].
#'
#' **SAS column mapping (`predict` dataset after averaging):**
#' - `time` ← `iv_echo` (or `iv_wristm`)
#' - `estimate` ← one of `p0`, `p1`, `p2`, `p3` (individual grade probs)
#' - `grade` ← a new column created during the wide-to-long reshape
#'
#' **Reshape step required (SAS wide → R long):**
#' ```r
#' library(tidyr)
#' long <- pivot_longer(predict_wide,
#'                      cols      = c(p0, p1, p2, p3),
#'                      names_to  = "grade",
#'                      values_to = "estimate")
#' dp_long <- pivot_longer(means,
#'                         cols      = c(smntr0, smntr1, smntr2, smntr3),
#'                         names_to  = "grade",
#'                         values_to = "value")
#' dp_long$time <- rep(means$mtime, 4)
#' nonparametric_ordinal_plot(long, data_points = dp_long)
#' ```
#'
#' @param curve_data  Long-format data frame: one row per (time, grade)
#'   combination. Columns: `x_col`, `estimate_col`, `grade_col`.
#' @param x_col       Name of the time (or continuous x) column.
#'   Corresponds to `iv_echo` or `iv_wristm` in SAS. Default `"time"`.
#' @param estimate_col Name of the predicted probability column. In SAS this
#'   is `p0`, `p1`, `p2`, or `p3` (one per grade after reshaping).
#'   Default `"estimate"`.
#' @param grade_col   Name of the grade/category column created during the
#'   wide-to-long reshape. Default `"grade"`.
#' @param data_points Optional long-format data frame of binned data summary
#'   points. Must have columns matching `x_col`, `"value"`, and `grade_col`.
#'   Corresponds to the SAS `means` dataset after reshaping. Default `NULL`.
#' @param line_width  Width of grade-specific curve lines. Default `1.0`.
#' @param point_size  Size of binned data summary points. Default `2.5`.
#' @param point_shape Integer shape for summary points (SAS `symbol=dot`).
#'   Default `20` (filled circle).
#'
#' @return A [ggplot2::ggplot()] object. Compose with `scale_colour_manual()`,
#'   `scale_x_continuous()`, `labs()`, `annotate()`, and [hvti_theme()].
#'
#' @seealso [sample_nonparametric_ordinal_data()],
#'   [nonparametric_curve_plot()], [hvti_theme()]
#'
#' @references SAS templates: \code{tp.np.tr.ivecho.average_curv.ordinal.sas},
#'   \code{tp.np.po_ar.u_multi.ordinal.sas},
#'   \code{tp.np.tr.ivecho.independence.sas},
#'   \code{tp.np.tr.ivecho.u.phases.sas}.
#'
#' @examples
#' dat <- sample_nonparametric_ordinal_data(
#'   n = 800, time_max = 5,
#'   grade_labels = c("None", "Mild", "Moderate", "Severe")
#' )
#' dat_pts <- sample_nonparametric_ordinal_points(
#'   n = 800, time_max = 5,
#'   grade_labels = c("None", "Mild", "Moderate", "Severe")
#' )
#'
#' # --- All grades, manuscript theme (tp.np.tr.ivecho.avg_curv.ps) ----------
#' nonparametric_ordinal_plot(dat) +
#'   ggplot2::scale_colour_manual(
#'     values = c(None     = "steelblue",
#'                Mild     = "firebrick",
#'                Moderate = "forestgreen",
#'                Severe   = "goldenrod3"),
#'     name = "TR Grade"
#'   ) +
#'   ggplot2::scale_x_continuous(breaks = 0:5) +
#'   ggplot2::scale_y_continuous(limits = c(0, 0.50),
#'                               breaks = seq(0, 0.50, 0.10),
#'                               labels = scales::percent) +
#'   ggplot2::labs(x = "Years", y = "Percent in each TR grade") +
#'   hvti_theme("manuscript")
#'
#' # --- With RColorBrewer palette -------------------------------------------
#' nonparametric_ordinal_plot(dat) +
#'   ggplot2::scale_colour_brewer(palette = "RdYlGn", direction = -1,
#'                                name = "AR Grade") +
#'   ggplot2::scale_x_continuous(breaks = 0:5) +
#'   ggplot2::scale_y_continuous(labels = scales::percent) +
#'   ggplot2::labs(x = "Years after Surgery",
#'                 y = "Prevalence") +
#'   hvti_theme("manuscript")
#'
#' # --- Curves + binned data points (tp.np.tr.ivecho.avg_curv.pts.ps) -------
#' nonparametric_ordinal_plot(
#'   dat,
#'   data_points = dat_pts
#' ) +
#'   ggplot2::scale_colour_manual(
#'     values = c(None     = "steelblue",
#'                Mild     = "firebrick",
#'                Moderate = "forestgreen",
#'                Severe   = "goldenrod3"),
#'     name = "TR Grade"
#'   ) +
#'   ggplot2::scale_x_continuous(breaks = 0:5) +
#'   ggplot2::scale_y_continuous(limits = c(0, 0.50),
#'                               breaks = seq(0, 0.50, 0.10),
#'                               labels = scales::percent) +
#'   ggplot2::labs(x = "Years", y = "Percent in each TR grade") +
#'   ggplot2::annotate("text", x = 3, y = 0.45,
#'                     label = "Grade None most prevalent",
#'                     size = 3.5, fontface = "italic") +
#'   hvti_theme("manuscript")
#'
#' # --- Subset: show only severe grade for nomogram comparison --------------
#' dat_sev <- dat[dat$grade == "Severe", ]
#' nonparametric_ordinal_plot(dat_sev) +
#'   ggplot2::scale_colour_manual(values = c(Severe = "firebrick"),
#'                                guide  = "none") +
#'   ggplot2::scale_y_continuous(limits = c(0, 0.25),
#'                               labels = scales::percent) +
#'   ggplot2::labs(x = "Years", y = "P(Severe TR grade)") +
#'   hvti_theme("manuscript")
#'
#' # --- Two-covariate ordinal comparison (tp.np.po_ar.u_multi pattern) ------
#' # Generate two scenarios and stack into one long data frame
#' dat_tric <- sample_nonparametric_ordinal_data(
#'   n = 800, time_max = 13,
#'   grade_labels = c("0", "1+", "2+", "3+"), seed = 1
#' )
#' dat_bic <- sample_nonparametric_ordinal_data(
#'   n = 800, time_max = 13,
#'   grade_labels = c("0", "1+", "2+", "3+"), seed = 2
#' )
#' dat_tric$morphology <- "Tricuspid"
#' dat_bic$morphology  <- "Bicuspid"
#' dat_comb <- rbind(dat_tric, dat_bic)
#' dat_comb$morphology <- factor(dat_comb$morphology,
#'                               levels = c("Tricuspid", "Bicuspid"))
#' # Plot one grade at a time, coloured by morphology:
#' dat_3plus <- dat_comb[dat_comb$grade == "3+", ]
#' nonparametric_curve_plot(
#'   dat_3plus,
#'   estimate_col = "estimate",
#'   group_col    = "morphology"
#' ) +
#'   ggplot2::scale_colour_manual(
#'     values = c(Tricuspid = "steelblue", Bicuspid = "firebrick"),
#'     name   = "Morphology"
#'   ) +
#'   ggplot2::scale_x_continuous(breaks = seq(0, 13, 2)) +
#'   ggplot2::scale_y_continuous(limits = c(0, 0.15),
#'                               labels = scales::percent) +
#'   ggplot2::labs(x = "Years", y = "P(AR grade \u2265 3)") +
#'   hvti_theme("manuscript")
#'
#' # --- Pre-op severity comparison (tp.np.po_ar.u_multi preop_ar pattern) ---
#' # Three covariate levels (mild / moderate / severe preop AR severity),
#' # plotted for one grade at a time via nonparametric_curve_plot().
#' # Matches avrgsev = 2 / 3 / 4 subgroups in tp.np.po_ar.u_multi.ordinal.sas.
#' dat_mild <- sample_nonparametric_ordinal_data(
#'   n = 800, time_max = 13,
#'   grade_labels = c("0", "1+", "2+", "3+"), seed = 3
#' )
#' dat_mod <- sample_nonparametric_ordinal_data(
#'   n = 800, time_max = 13,
#'   grade_labels = c("0", "1+", "2+", "3+"), seed = 4
#' )
#' dat_sev3 <- sample_nonparametric_ordinal_data(
#'   n = 800, time_max = 13,
#'   grade_labels = c("0", "1+", "2+", "3+"), seed = 5
#' )
#' dat_mild$preop_ar  <- "Mild"
#' dat_mod$preop_ar   <- "Moderate"
#' dat_sev3$preop_ar  <- "Severe"
#' dat_preop <- rbind(dat_mild, dat_mod, dat_sev3)
#' dat_preop$preop_ar <- factor(dat_preop$preop_ar,
#'                              levels = c("Mild", "Moderate", "Severe"))
#' dat_34 <- dat_preop[dat_preop$grade == "3+", ]
#' nonparametric_curve_plot(dat_34, estimate_col = "estimate",
#'                          group_col = "preop_ar") +
#'   ggplot2::scale_colour_manual(
#'     values = c(Mild = "steelblue", Moderate = "goldenrod3",
#'                Severe = "firebrick"),
#'     name = "Pre-op AR"
#'   ) +
#'   ggplot2::scale_x_continuous(breaks = seq(0, 13, 2)) +
#'   ggplot2::scale_y_continuous(limits = c(0, 0.60),
#'                               labels = scales::percent) +
#'   ggplot2::labs(x = "Years", y = "P(AR grade \u2265 3+)") +
#'   hvti_theme("manuscript")
#'
#' # --- Save ----------------------------------------------------------------
#' \dontrun{
#' p <- nonparametric_ordinal_plot(dat, data_points = dat_pts) +
#'   ggplot2::scale_colour_brewer(palette = "Set1", name = "Grade") +
#'   ggplot2::labs(x = "Years", y = "Prevalence") +
#'   hvti_theme("manuscript")
#' ggplot2::ggsave("np_ordinal.pdf", p, width = 11.5, height = 8)
#' }
#'
#' @importFrom ggplot2 ggplot aes geom_line geom_point
#' @importFrom rlang .data
#' @export
nonparametric_ordinal_plot <- function(curve_data,
                                       x_col        = "time",
                                       estimate_col = "estimate",
                                       grade_col    = "grade",
                                       data_points  = NULL,
                                       line_width   = 1.0,
                                       point_size   = 2.5,
                                       point_shape  = 20L) {

  # --- Validation -----------------------------------------------------------
  .check_df(curve_data, "curve_data")
  .check_cols(curve_data, c(x_col, estimate_col, grade_col), "curve_data")
  if (!is.null(data_points)) {
    .check_df(data_points, "data_points")
    .check_cols(data_points, c(x_col, "value", grade_col), "data_points")
  }

  p <- ggplot2::ggplot(
    curve_data,
    ggplot2::aes(x      = .data[[x_col]],
                 y      = .data[[estimate_col]],
                 colour = .data[[grade_col]],
                 group  = .data[[grade_col]])
  ) +
    ggplot2::geom_line(linewidth = line_width)

  if (!is.null(data_points)) {
    p <- p + ggplot2::geom_point(
      data        = data_points,
      mapping     = ggplot2::aes(x      = .data[[x_col]],
                                 y      = .data[["value"]],
                                 colour = .data[[grade_col]]),
      size        = point_size,
      shape       = point_shape,
      inherit.aes = FALSE
    )
  }

  p
}
