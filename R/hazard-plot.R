# hazard-plot.R
#
# PORT of:
#   tp.hp.dead.sas                               (basic survival + hazard)
#   tp.hp.dead.age_on_horizontal_axis.sas        (age as x-axis)
#   tp.hp.dead.age_with_population_life_table.sas (life table overlay)
#   tp.hp.dead.ideal_multivariable_time_depiction.sas (risk group profiles)
#   tp.hp.dead.life-gained.sas                   (survival difference)
#   tp.hp.dead.tkdn.stratified.sas               (stratified groups)
#   tp.hp.dead.uslife.stratifed.sas              (age-stratified life table)
#   tp.hp.dead.uslife.stratify_uses.sas          (population overlay)
#   tp.hp.event.weighted.sas                     (weighted 1st event)
#   tp.hp.repeated.event.weighted.sas            (weighted repeated events)
#   tp.hp.repeated_events.sas                    (repeated cardioversion)
#   tp.hp.dead.number_risk.R                     (survival + at-risk table)
#   tp.hp.dead.stratify_different_hazards.sas    (per-group hazard models)
#   tp.hp.dead.matching_weight.sas               (propensity-matched)
#   tp.hp.dead.limited_FET.mtwt.sas              (propensity-weighted)
#   tp.hp.mcs.mod.dead.devseq_nlvlv12.scallop.sas (device sequencing)
#   tp.hp.numtreat.survdiff.matched.sas          (NNT + survival difference)
#
# SAS EQUIVALENT:
#   Parametric predictions from the hp.dead.sas macro output dataset `predict`
#   (columns: years, ssurviv, scllsurv, sclusurv, [group_var]).
#   KM empirical points from the KM macro output dataset `plout`
#   (columns: iv_dead, cum_surv, cl_lower, cl_upper, [group_var]).
#   Life table from uslife datasets (columns: time, smatched, hmatched).
#
# MIGRATION GUIDE FOR SAS USERS:
#   1. Export predict  -> read.csv("predict.csv")   -> curve_data
#   2. Export plout    -> read.csv("plout.csv")      -> empirical
#   3. Export uslife   -> read.csv("uslife.csv")     -> reference
#   4. Call hazard_plot(curve_data, ..., empirical = empirical,
#                       reference = reference)
#   5. For survival difference: export diffout      -> survival_difference_plot()
#   6. For NNT:                 export nntout        -> nnt_plot()
# ---------------------------------------------------------------------------

# ============================================================================
# INTERNAL HELPERS
# ============================================================================

# Weibull parametric predictions on a time grid.
# S(t) = exp(-(t/scale)^shape); h(t) = (shape/scale)*(t/scale)^(shape-1)
.hp_weibull_pred <- function(t_grid, shape, scale) {
  surv   <- exp(-(t_grid / scale)^shape) * 100          # % survival
  hazard <- (shape / scale) * (t_grid / scale)^(shape - 1) * 100  # %/year
  cumhaz <- (t_grid / scale)^shape * 100                # cumulative hazard %
  list(surv = surv, hazard = hazard, cumhaz = cumhaz)
}

# CI band for a survival curve (normal approximation on survival scale).
.hp_surv_ci <- function(surv_pct, n, z_score) {
  s     <- pmax(surv_pct / 100, 1e-6)
  n_eff <- pmax(n * s, 1)
  se    <- sqrt(s * (1 - s) / n_eff)
  list(lower = pmax((s - z_score * se) * 100, 0),
       upper = pmin((s + z_score * se) * 100, 100))
}

# CI band for a hazard rate (log-scale approximation).
.hp_haz_ci <- function(haz_pct, n, z_score) {
  h      <- pmax(haz_pct, 0.01)
  se_log <- 1 / sqrt(pmax(n * 0.03, 1))
  list(lower = exp(log(h) - z_score * se_log),
       upper = exp(log(h) + z_score * se_log))
}

# Simulate patient survival times and return KM estimates at binned time points.
.hp_km_binned <- function(n, shape, scale, time_max, n_bins, ci_level, seed) {
  set.seed(seed)
  u        <- stats::runif(n)
  t_event  <- scale * (-log(pmax(u, 1e-9)))^(1 / shape)
  t_censor <- stats::runif(n, time_max * 0.2, time_max * 1.5)
  t_obs    <- pmin(t_event, t_censor, time_max * 1.2)
  status   <- as.integer(t_event <= t_censor & t_event <= time_max * 1.2)

  km_fit <- survival::survfit(
    survival::Surv(t_obs, status) ~ 1,
    conf.int  = ci_level,
    conf.type = "log-log"
  )
  bin_times <- seq(time_max / n_bins, time_max, length.out = n_bins)
  km_sum    <- summary(km_fit, times = bin_times, extend = TRUE)

  data.frame(
    time     = bin_times,
    estimate = km_sum$surv  * 100,
    lower    = km_sum$lower * 100,
    upper    = km_sum$upper * 100
  )
}

# ============================================================================

#' Sample Parametric Hazard Model Predictions
#'
#' Simulates parametric survival, hazard, and cumulative-hazard predictions on
#' a fine time grid, matching the structure of the SAS `predict` dataset
#' produced by `tp.hp.dead.sas` and its variants after fitting a Weibull model
#' with `PROC LIFEREG`.
#'
#' **SAS column mapping:**
#' - `time`         ← `YEARS` / `iv_dead` (prediction grid)
#' - `survival`     ← `SSURVIV` (predicted survival, 0–100 %)
#' - `surv_lower`   ← `SCLLSURV` (lower confidence limit on survival)
#' - `surv_upper`   ← `SCLUSURV` (upper confidence limit on survival)
#' - `hazard`       ← predicted hazard rate (%/year)
#' - `haz_lower`    ← lower confidence limit on hazard
#' - `haz_upper`    ← upper confidence limit on hazard
#' - `cumhaz`       ← cumulative hazard (%; corresponds to `-log(S)*100`)
#' - `group`        ← group stratification variable (when `groups` is not `NULL`)
#'
#' @param n        Number of patients used to scale confidence-limit width.
#'   Default `500`.
#' @param time_max Upper end of the time axis (years). Default `10`.
#' @param n_points Number of time points in the prediction grid. Default `500`.
#' @param groups   `NULL` for a single curve, or a named numeric vector of
#'   hazard multipliers, e.g. `c("Control" = 1.0, "Treatment" = 0.7)`.
#'   A multiplier < 1 means lower hazard (better survival). Analogous to the
#'   group indicator in `tp.hp.dead.tkdn.stratified.sas`.
#' @param shape    Weibull shape parameter. `shape > 1` gives increasing hazard
#'   (late mortality); `shape < 1` gives decreasing hazard (early operative
#'   mortality). Default `1.5`.
#' @param scale    Weibull scale parameter (characteristic time in years, i.e.
#'   the time at which `S = exp(-1) ≈ 37%`). Default `8.0`.
#' @param ci_level Confidence level for the CI bands. Default `0.95`.
#' @param seed     Random seed (unused for deterministic Weibull predictions;
#'   kept for API consistency with other sample functions). Default `42`.
#'
#' @return A data frame with columns `time`, `survival`, `surv_lower`,
#'   `surv_upper`, `hazard`, `haz_lower`, `haz_upper`, `cumhaz`, and
#'   (when `groups` is not `NULL`) `group`.
#'
#' @seealso [hazard_plot()], [sample_hazard_empirical()], [sample_life_table()]
#'
#' @examples
#' # Single-group predictions (tp.hp.dead.sas)
#' dat <- sample_hazard_data(n = 500, time_max = 10)
#' head(dat)
#'
#' # Two-group predictions (tp.hp.dead.tkdn.stratified.sas)
#' dat2 <- sample_hazard_data(
#'   n = 400, time_max = 10,
#'   groups = c("No Takedown" = 1.0, "Takedown" = 0.65)
#' )
#' head(dat2)
#' @importFrom stats runif qnorm
#' @export
sample_hazard_data <- function(n        = 500,
                                time_max = 10,
                                n_points = 500,
                                groups   = NULL,
                                shape    = 1.5,
                                scale    = 8.0,
                                ci_level = 0.95,
                                seed     = 42L) {
  z_score <- stats::qnorm(1 - (1 - ci_level) / 2)
  t_grid  <- seq(0.01, time_max, length.out = n_points)

  .make_row <- function(grp_scale, grp_n) {
    pred <- .hp_weibull_pred(t_grid, shape, grp_scale)
    ci_s <- .hp_surv_ci(pred$surv, grp_n, z_score)
    ci_h <- .hp_haz_ci(pred$hazard, grp_n, z_score)
    data.frame(
      time         = t_grid,
      survival     = pred$surv,
      surv_lower   = ci_s$lower,
      surv_upper   = ci_s$upper,
      hazard       = pred$hazard,
      haz_lower    = ci_h$lower,
      haz_upper    = ci_h$upper,
      cumhaz       = pred$cumhaz,
      cumhaz_lower = pmax(pred$cumhaz - z_score * sqrt(pmax(pred$cumhaz, 0) / grp_n) * 100, 0),
      cumhaz_upper = pred$cumhaz + z_score * sqrt(pmax(pred$cumhaz, 0) / grp_n) * 100
    )
  }

  if (is.null(groups)) {
    .make_row(scale, n)
  } else {
    grp_names  <- names(groups)
    curve_list <- lapply(seq_along(groups), function(i) {
      df        <- .make_row(scale / groups[[i]], n)
      df$group  <- grp_names[[i]]
      df
    })
    out       <- do.call(rbind, curve_list)
    out$group <- factor(out$group, levels = grp_names)
    out
  }
}

# ============================================================================

#' Sample Kaplan-Meier Empirical Points for Hazard Plot Overlay
#'
#' Simulates patient-level survival data from a Weibull distribution and
#' returns Kaplan-Meier estimates at a small number of binned time points,
#' matching the structure of the SAS `plout` dataset used as an empirical
#' overlay in `tp.hp.dead.sas` and related templates.
#'
#' **SAS column mapping:**
#' - `time`     ← `IV_DEAD` / `iv_dead` (evaluation time points)
#' - `estimate` ← `CUM_SURV` (KM survival estimate, 0–100 %)
#' - `lower`    ← `CL_LOWER` (lower 95 % CI)
#' - `upper`    ← `CL_UPPER` (upper 95 % CI)
#' - `group`    ← stratification variable (when `groups` is not `NULL`)
#'
#' @param n        Number of simulated patients. Default `500`.
#' @param time_max Upper end of the follow-up window (years). Default `10`.
#' @param n_bins   Number of time points at which KM is evaluated. Analogous
#'   to the discrete annotation points in the SAS templates. Default `6`.
#' @param groups   `NULL` for a single group, or a named numeric vector of
#'   hazard multipliers matching those passed to [sample_hazard_data()].
#' @param shape    Weibull shape parameter. Default `1.5`.
#' @param scale    Weibull scale parameter (years). Default `8.0`.
#' @param ci_level Confidence level. Default `0.95`.
#' @param seed     Random seed. Default `42`.
#'
#' @return A data frame with columns `time`, `estimate`, `lower`, `upper`, and
#'   (when `groups` is not `NULL`) `group`.
#'
#' @seealso [hazard_plot()], [sample_hazard_data()]
#'
#' @examples
#' emp <- sample_hazard_empirical(n = 500, time_max = 10, n_bins = 6)
#' head(emp)
#'
#' emp2 <- sample_hazard_empirical(
#'   n = 400, time_max = 10,
#'   groups = c("No Takedown" = 1.0, "Takedown" = 0.65)
#' )
#' head(emp2)
#' @importFrom survival survfit Surv
#' @export
sample_hazard_empirical <- function(n        = 500,
                                    time_max = 10,
                                    n_bins   = 6,
                                    groups   = NULL,
                                    shape    = 1.5,
                                    scale    = 8.0,
                                    ci_level = 0.95,
                                    seed     = 42L) {
  if (is.null(groups)) {
    .hp_km_binned(n, shape, scale, time_max, n_bins, ci_level, seed)
  } else {
    grp_names <- names(groups)
    emp_list  <- lapply(seq_along(groups), function(i) {
      df        <- .hp_km_binned(n, shape, scale / groups[[i]],
                                 time_max, n_bins, ci_level, seed + i * 100L)
      df$group  <- grp_names[[i]]
      df
    })
    out       <- do.call(rbind, emp_list)
    out$group <- factor(out$group, levels = grp_names)
    out
  }
}

# ============================================================================

#' Sample Population Life Table Data
#'
#' Generates age-group-specific population survival curves using Gompertz
#' mortality, matching the US population life table overlays used in
#' `tp.hp.dead.age_with_population_life_table.sas` and
#' `tp.hp.dead.uslife.stratifed.sas`.
#'
#' **SAS column mapping:**
#' - `time`     ← prediction time grid (years)
#' - `survival` ← `SMATCHED` (age-group-specific survivorship, 0–100 %)
#' - `group`    ← age group label (e.g. `"<65"`, `"65-80"`, `"\u226580"`)
#'
#' @param age_groups Character vector of age group labels. Default
#'   `c("<65", "65-80", "\u226580")`.
#' @param age_mids  Numeric vector of representative ages (years) for each
#'   group, same length as `age_groups`. Default `c(55, 72, 85)`.
#' @param time_max  Upper end of the time axis (years). Default `10`.
#' @param n_points  Number of time points. Default `100`.
#'
#' @return A data frame with columns `time`, `survival`, and `group`.
#'
#' @seealso [hazard_plot()], [sample_hazard_data()]
#'
#' @examples
#' lt <- sample_life_table(time_max = 10)
#' head(lt)
#' @export
sample_life_table <- function(age_groups = c("<65", "65-80", "\u226580"),
                               age_mids   = c(55, 72, 85),
                               time_max   = 10,
                               n_points   = 100) {
  if (length(age_groups) != length(age_mids))
    stop("`age_groups` and `age_mids` must have the same length.")

  # Gompertz: h(age) = alpha * exp(beta * age)
  # Conditional S(t | baseline age) = exp(-alpha/beta*(exp(beta*(age+t))-exp(beta*age)))
  alpha  <- 5e-5
  beta   <- 0.085
  t_grid <- seq(0, time_max, length.out = n_points)

  df_list <- lapply(seq_along(age_groups), function(i) {
    age      <- age_mids[[i]]
    log_surv <- -(alpha / beta) * (exp(beta * (age + t_grid)) - exp(beta * age))
    data.frame(
      time     = t_grid,
      survival = pmax(exp(log_surv) * 100, 0),
      group    = age_groups[[i]]
    )
  })

  out       <- do.call(rbind, df_list)
  out$group <- factor(out$group, levels = age_groups)
  out
}

# ============================================================================

#' Sample Survival Difference (Life-Gained) Data
#'
#' Computes a group-vs-group survival difference curve and confidence interval,
#' matching the output of the `HAZDIFL` macro used in
#' `tp.hp.dead.life-gained.sas`.
#'
#' **SAS column mapping:**
#' - `time`        ← prediction grid
#' - `difference`  ← survival(group 2) - survival(group 1) (percentage points)
#' - `diff_lower`  ← lower CI on difference
#' - `diff_upper`  ← upper CI on difference
#' - `group1_surv` ← survival curve for group 1
#' - `group2_surv` ← survival curve for group 2
#'
#' @param n        Number of patients per group (used for CI width). Default `500`.
#' @param time_max Upper end of the time axis (years). Default `10`.
#' @param n_points Number of prediction grid points. Default `500`.
#' @param groups   Named numeric vector of length 2; hazard multipliers for
#'   groups 1 and 2. The group with the smaller multiplier has better survival.
#'   Default `c("Control" = 1.0, "Treatment" = 0.7)`.
#' @param shape    Weibull shape. Default `1.5`.
#' @param scale    Weibull scale (years). Default `8.0`.
#' @param ci_level Confidence level. Default `0.95`.
#' @param seed     Random seed. Default `42`.
#'
#' @return A data frame with columns `time`, `difference`, `diff_lower`,
#'   `diff_upper`, `group1_surv`, `group2_surv`.
#'
#' @seealso [survival_difference_plot()], [sample_hazard_data()]
#'
#' @examples
#' diff_dat <- sample_survival_difference_data(
#'   groups = c("Control" = 1.0, "Treatment" = 0.7)
#' )
#' head(diff_dat)
#' @importFrom stats qnorm
#' @export
sample_survival_difference_data <- function(n        = 500,
                                             time_max = 10,
                                             n_points = 500,
                                             groups   = c("Control"   = 1.0,
                                                          "Treatment" = 0.7),
                                             shape    = 1.5,
                                             scale    = 8.0,
                                             ci_level = 0.95,
                                             seed     = 42L) {
  if (length(groups) != 2L)
    stop("`groups` must be a named numeric vector of length 2.")

  curves    <- sample_hazard_data(n = n, time_max = time_max,
                                  n_points = n_points, groups = groups,
                                  shape = shape, scale = scale,
                                  ci_level = ci_level, seed = seed)
  grp_names <- names(groups)
  s1  <- curves$survival[curves$group == grp_names[[1]]]
  s2  <- curves$survival[curves$group == grp_names[[2]]]
  t   <- curves$time[curves$group == grp_names[[1]]]

  # SE from CI width (CI = estimate ± z * SE)
  z_score <- stats::qnorm(1 - (1 - ci_level) / 2)
  se1     <- (curves$surv_upper[curves$group == grp_names[[1]]] -
              curves$surv_lower[curves$group == grp_names[[1]]]) / (2 * z_score)
  se2     <- (curves$surv_upper[curves$group == grp_names[[2]]] -
              curves$surv_lower[curves$group == grp_names[[2]]]) / (2 * z_score)
  se_diff <- sqrt(se1^2 + se2^2)
  diff    <- s2 - s1    # positive when group 2 (treatment) survives better

  data.frame(
    time        = t,
    difference  = diff,
    diff_lower  = diff - z_score * se_diff,
    diff_upper  = diff + z_score * se_diff,
    group1_surv = s1,
    group2_surv = s2
  )
}

# ============================================================================

#' Sample Number Needed to Treat Data
#'
#' Computes the number needed to treat (NNT) and absolute risk reduction (ARR)
#' over time from a two-group survival difference, matching the output
#' of `tp.hp.numtreat.survdiff.matched.sas`.
#'
#' **SAS column mapping:**
#' - `time`      ← prediction grid (years)
#' - `arr`       ← absolute risk reduction (survival difference, %)
#' - `arr_lower` / `arr_upper` ← CI on ARR
#' - `nnt`       ← number needed to treat (= 100 / ARR)
#' - `nnt_lower` / `nnt_upper` ← CI on NNT (inverted from ARR CI)
#'
#' @inheritParams sample_survival_difference_data
#'
#' @return A data frame with columns `time`, `arr`, `arr_lower`, `arr_upper`,
#'   `nnt`, `nnt_lower`, `nnt_upper`.
#'
#' @seealso [nnt_plot()], [survival_difference_plot()]
#'
#' @examples
#' nnt_dat <- sample_nnt_data(
#'   groups = c("Control" = 1.0, "Treatment" = 0.7)
#' )
#' head(nnt_dat)
#' @export
sample_nnt_data <- function(n        = 500,
                             time_max = 10,
                             n_points = 500,
                             groups   = c("Control"   = 1.0,
                                          "Treatment" = 0.7),
                             shape    = 1.5,
                             scale    = 8.0,
                             ci_level = 0.95,
                             seed     = 42L) {
  dif <- sample_survival_difference_data(
    n = n, time_max = time_max, n_points = n_points,
    groups = groups, shape = shape, scale = scale,
    ci_level = ci_level, seed = seed
  )

  arr     <- dif$difference       # percentage points
  arr_lo  <- dif$diff_lower
  arr_hi  <- dif$diff_upper

  # NNT = 100 / ARR (treating ARR as %). Undefined / unstable near zero.
  nnt     <- ifelse(arr > 0.1,  100 / arr,    NA_real_)
  nnt_lo  <- ifelse(arr_hi > 0.1, 100 / arr_hi, NA_real_)  # inverted
  nnt_hi  <- ifelse(arr_lo > 0.1, 100 / arr_lo, NA_real_)

  data.frame(
    time      = dif$time,
    arr       = arr,
    arr_lower = arr_lo,
    arr_upper = arr_hi,
    nnt       = nnt,
    nnt_lower = nnt_lo,
    nnt_upper = nnt_hi
  )
}

# ============================================================================

#' Parametric Hazard / Survival Plot
#'
#' Plots a pre-computed parametric survival, hazard, or cumulative-hazard curve
#' from a Weibull (or other parametric) model, optionally overlaid with
#' Kaplan-Meier empirical estimates and a population life-table reference.
#' Covers the complete family of `tp.hp.dead.*` SAS templates.
#'
#' | SAS template | R usage |
#' |---|---|
#' | Basic survival (tp.hp.dead.sas) | `hazard_plot(dat, estimate_col="survival")` |
#' | Basic hazard (tp.hp.dead.sas) | `hazard_plot(dat, estimate_col="hazard")` |
#' | Cumulative hazard (tp.hp.event.weighted.sas) | `hazard_plot(dat, estimate_col="cumhaz")` |
#' | Stratified by group (tp.hp.dead.tkdn.stratified.sas) | `+ group_col="group"` |
#' | KM empirical overlay | `+ empirical=emp_data` |
#' | Life table overlay (tp.hp.dead.uslife.stratifed.sas) | `+ reference=lt_data` |
#' | Age as x-axis (tp.hp.dead.age_on_horizontal_axis.sas) | `x_col="age"` |
#'
#' **SAS column mapping:**
#' - `x_col`          ← `YEARS` / `iv_dead`
#' - `estimate_col`   ← `SSURVIV` (survival), `hazard` (%/yr), or `cumhaz`
#' - `lower_col`      ← `SCLLSURV` / `cll_p95`
#' - `upper_col`      ← `SCLUSURV` / `clu_p95`
#' - `group_col`      ← treatment/group indicator variable
#' - `empirical`      ← the `plout` / `acpdms` KM output dataset
#' - `reference`      ← the `smatched` life-table dataset
#'
#' Returns a **bare ggplot object**; compose with `scale_colour_*`,
#' `scale_y_continuous()`, `labs()`, [hvti_theme()].
#'
#' @param curve_data   Data frame of parametric predictions (fine grid).
#'   Typical source: SAS `predict` dataset exported to CSV, or
#'   [sample_hazard_data()].
#' @param x_col        Name of the time (or age) column. Corresponds to `YEARS`
#'   / `iv_dead` in SAS. Default `"time"`.
#' @param estimate_col Name of the predicted-value column. Use `"survival"` for
#'   a survival plot, `"hazard"` for a hazard-rate plot, or `"cumhaz"` for a
#'   cumulative-hazard plot. Corresponds to `SSURVIV`, `hazard`, or `cumhaz`
#'   in the SAS output. Default `"survival"`.
#' @param lower_col    Name of the lower CI column in `curve_data`, or `NULL`
#'   for no ribbon. Corresponds to `SCLLSURV` / `cll_p95`. Default `NULL`.
#' @param upper_col    Name of the upper CI column in `curve_data`, or `NULL`.
#'   Corresponds to `SCLUSURV` / `clu_p95`. Default `NULL`.
#' @param group_col    Name of the stratification column in `curve_data`, or
#'   `NULL` for a single curve. Default `NULL`.
#' @param empirical    Optional data frame of Kaplan-Meier empirical estimates
#'   (discrete time points). Corresponds to the SAS `plout` / `acpdms`
#'   dataset. See [sample_hazard_empirical()]. Default `NULL`.
#' @param emp_x_col    Column name for x in `empirical`. Default: same as
#'   `x_col`.
#' @param emp_estimate_col Column name for y in `empirical`. Default: same as
#'   `estimate_col`.
#' @param emp_lower_col Column name for error-bar lower bound in `empirical`,
#'   or `NULL` for no error bars. Default `NULL`.
#' @param emp_upper_col Column name for error-bar upper bound in `empirical`,
#'   or `NULL`. Default `NULL`.
#' @param emp_group_col Column name for grouping in `empirical`. Default: same
#'   as `group_col`.
#' @param reference    Optional data frame of population life-table survival
#'   curves. Corresponds to the SAS `smatched` / `hmatched` datasets. See
#'   [sample_life_table()]. Rendered as dashed lines. Default `NULL`.
#' @param ref_x_col    Column name for x in `reference`. Default: same as
#'   `x_col`.
#' @param ref_estimate_col Column name for y in `reference`. Default: same as
#'   `estimate_col`.
#' @param ref_group_col Column name used to vary the linetype of the reference
#'   curves (e.g. age group). Default `NULL`.
#' @param ci_alpha     Transparency of the parametric CI ribbon (`[0, 1]`).
#'   Default `0.20`.
#' @param line_width   Width of the parametric curve line. SAS `width=3`
#'   corresponds roughly to `1.2`. Default `1.0`.
#' @param point_size   Size of empirical overlay points. Default `2.0`.
#' @param point_shape  Shape code for empirical points. `1` = open circle
#'   (SAS `symbol=circle`); `0` = open square (SAS `symbol=square`).
#'   Default `1`.
#' @param errorbar_width Width of the error bars on empirical points.
#'   Default `0.25`.
#'
#' @return A [ggplot2::ggplot()] object.
#'
#' @seealso [sample_hazard_data()], [sample_hazard_empirical()],
#'   [sample_life_table()], [survival_difference_plot()], [nnt_plot()],
#'   [hvti_theme()]
#'
#' @references SAS templates: \code{tp.hp.dead.sas},
#'   \code{tp.hp.dead.tkdn.stratified.sas},
#'   \code{tp.hp.dead.age_with_population_life_table.sas},
#'   \code{tp.hp.dead.uslife.stratifed.sas},
#'   \code{tp.hp.dead.matching_weight.sas},
#'   \code{tp.hp.dead.limited_FET.mtwt.sas},
#'   \code{tp.hp.event.weighted.sas},
#'   \code{tp.hp.repeated.event.weighted.sas},
#'   \code{tp.hp.repeated_events.sas},
#'   \code{tp.hp.mcs.mod.dead.devseq_nlvlv12.scallop.sas}.
#'
#' @examples
#' library(ggplot2)
#'
#' dat <- sample_hazard_data(n = 500, time_max = 10)
#' emp <- sample_hazard_empirical(n = 500, time_max = 10, n_bins = 6)
#'
#' # --- (1) Basic survival curve + KM overlay -------------------------------
#' # Matches tp.hp.dead.sas (survival panel).
#' # SAS: SSURVIV on y-axis, SCLLSURV/SCLUSURV for CI, plout circles + bars.
#' hazard_plot(
#'   dat,
#'   estimate_col  = "survival",
#'   lower_col     = "surv_lower",
#'   upper_col     = "surv_upper",
#'   empirical     = emp,
#'   emp_lower_col = "lower",
#'   emp_upper_col = "upper"
#' ) +
#'   scale_colour_manual(values = c("steelblue"), guide = "none") +
#'   scale_fill_manual(values = c("steelblue"), guide = "none") +
#'   scale_x_continuous(limits = c(0, 10), breaks = 0:10) +
#'   scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 20),
#'                      labels = function(x) paste0(x, "%")) +
#'   labs(x = "Years", y = "Survival (%)") +
#'   hvti_theme("manuscript")
#'
#' # --- (2) Hazard rate curve + KM overlay ----------------------------------
#' # Matches tp.hp.dead.sas (hazard panel).
#' # SAS: hazard on y-axis (%/year). KM empirical hazard not shown here
#' # (the empirical overlay in SAS is the survival-based dot plot; for hazard,
#' # only the parametric curve is typically shown).
#' hazard_plot(
#'   dat,
#'   estimate_col = "hazard",
#'   lower_col    = "haz_lower",
#'   upper_col    = "haz_upper"
#' ) +
#'   scale_colour_manual(values = c("firebrick"), guide = "none") +
#'   scale_fill_manual(values = c("firebrick"), guide = "none") +
#'   scale_x_continuous(limits = c(0, 10), breaks = 0:10) +
#'   scale_y_continuous(limits = c(0, 30),
#'                      labels = function(x) paste0(x, "%/yr")) +
#'   labs(x = "Years", y = "Hazard (%/year)") +
#'   hvti_theme("manuscript")
#'
#' # --- (3) Cumulative hazard (tp.hp.event.weighted.sas) --------------------
#' # For readmission / repeated-event analyses: cumhaz = -log(S)*100.
#' # SAS: Nelson-Aalen cumulative hazard. R: use cumhaz column from predict.
#' hazard_plot(
#'   dat,
#'   estimate_col  = "cumhaz",
#'   lower_col     = "cumhaz_lower",
#'   upper_col     = "cumhaz_upper"
#' ) +
#'   scale_colour_manual(values = c("darkorange"), guide = "none") +
#'   scale_fill_manual(values = c("darkorange"), guide = "none") +
#'   scale_x_continuous(limits = c(0, 10), breaks = 0:10) +
#'   labs(x = "Years", y = "Cumulative Hazard (%)") +
#'   hvti_theme("manuscript")
#'
#' # --- (4) Stratified survival (tp.hp.dead.tkdn.stratified.sas) ------------
#' # Two groups (e.g. Takedown vs No Takedown) with different colours and
#' # linetypes. KM empirical overlay uses matching colours.
#' dat2 <- sample_hazard_data(
#'   n = 400, time_max = 10,
#'   groups = c("No Takedown" = 1.0, "Takedown" = 0.65)
#' )
#' emp2 <- sample_hazard_empirical(
#'   n = 400, time_max = 10, n_bins = 6,
#'   groups = c("No Takedown" = 1.0, "Takedown" = 0.65)
#' )
#' hazard_plot(
#'   dat2,
#'   estimate_col  = "survival",
#'   lower_col     = "surv_lower",
#'   upper_col     = "surv_upper",
#'   group_col     = "group",
#'   empirical     = emp2,
#'   emp_lower_col = "lower",
#'   emp_upper_col = "upper"
#' ) +
#'   scale_colour_manual(
#'     values = c("No Takedown" = "steelblue", "Takedown" = "firebrick"),
#'     name   = NULL
#'   ) +
#'   scale_fill_manual(
#'     values = c("No Takedown" = "steelblue", "Takedown" = "firebrick"),
#'     guide  = "none"
#'   ) +
#'   scale_x_continuous(limits = c(0, 10), breaks = 0:10) +
#'   scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 20),
#'                      labels = function(x) paste0(x, "%")) +
#'   labs(x = "Years after Esophagostomy", y = "Survival (%)") +
#'   hvti_theme("manuscript")
#'
#' # --- (5) Life table overlay (tp.hp.dead.age_with_population_life_table) ---
#' # Age-stratified study curves + US population life table reference (dashed).
#' # SAS: smatched as dashed overlay; different symbols per age group.
#' dat3 <- sample_hazard_data(
#'   n = 600, time_max = 12,
#'   groups = c("<65" = 0.5, "65-80" = 1.0, "\u226580" = 1.8)
#' )
#' emp3 <- sample_hazard_empirical(
#'   n = 600, time_max = 12, n_bins = 6,
#'   groups = c("<65" = 0.5, "65-80" = 1.0, "\u226580" = 1.8)
#' )
#' lt <- sample_life_table(time_max = 12)
#'
#' hazard_plot(
#'   dat3,
#'   estimate_col     = "survival",
#'   lower_col        = "surv_lower",
#'   upper_col        = "surv_upper",
#'   group_col        = "group",
#'   empirical        = emp3,
#'   emp_lower_col    = "lower",
#'   emp_upper_col    = "upper",
#'   reference        = lt,
#'   ref_estimate_col = "survival",
#'   ref_group_col    = "group"
#' ) +
#'   scale_colour_manual(
#'     values = c("<65" = "steelblue", "65-80" = "forestgreen",
#'                "\u226580" = "firebrick"),
#'     name = "Age Group"
#'   ) +
#'   scale_fill_manual(
#'     values = c("<65" = "steelblue", "65-80" = "forestgreen",
#'                "\u226580" = "firebrick"),
#'     guide  = "none"
#'   ) +
#'   scale_x_continuous(limits = c(0, 12), breaks = seq(0, 12, 2)) +
#'   scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 20),
#'                      labels = function(x) paste0(x, "%")) +
#'   labs(x = "Years", y = "Survival (%)",
#'        caption = "Dashed lines: US population life table") +
#'   hvti_theme("manuscript")
#'
#' # --- (6) Multivariable risk profiles (tp.hp.dead.ideal_multivariable) -----
#' # Patient profiles with distinct covariate combinations (good vs poor risk).
#' dat_risk <- sample_hazard_data(
#'   n = 500, time_max = 8,
#'   groups = c("Ideal (young, stage IIIA)" = 0.4,
#'              "Poor (elderly, stage IIIB, palliation)" = 1.8)
#' )
#' hazard_plot(
#'   dat_risk,
#'   estimate_col = "survival",
#'   lower_col    = "surv_lower",
#'   upper_col    = "surv_upper",
#'   group_col    = "group"
#' ) +
#'   scale_colour_manual(
#'     values = c("Ideal (young, stage IIIA)"              = "steelblue",
#'                "Poor (elderly, stage IIIB, palliation)" = "firebrick"),
#'     name   = "Patient profile"
#'   ) +
#'   scale_fill_manual(
#'     values = c("Ideal (young, stage IIIA)"              = "steelblue",
#'                "Poor (elderly, stage IIIB, palliation)" = "firebrick"),
#'     guide  = "none"
#'   ) +
#'   scale_x_continuous(limits = c(0, 8), breaks = 0:8) +
#'   scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 20),
#'                      labels = function(x) paste0(x, "%")) +
#'   labs(x = "Years after Brain Metastases",
#'        y = "Survival (%)") +
#'   hvti_theme("manuscript")
#'
#' # --- (7) Propensity-weighted / matched groups -----------------------------
#' # tp.hp.dead.matching_weight.sas / tp.hp.dead.limited_FET.mtwt.sas.
#' # Propensity weighting is applied upstream (before plotting); the plot call
#' # is identical to the basic stratified survival plot above.
#' dat_match <- sample_hazard_data(
#'   n = 300, time_max = 7,
#'   groups = c("Limited FET" = 1.0, "Extended FET" = 0.72)
#' )
#' emp_match <- sample_hazard_empirical(
#'   n = 300, time_max = 7, n_bins = 5,
#'   groups = c("Limited FET" = 1.0, "Extended FET" = 0.72)
#' )
#' hazard_plot(
#'   dat_match,
#'   estimate_col  = "survival",
#'   lower_col     = "surv_lower",
#'   upper_col     = "surv_upper",
#'   group_col     = "group",
#'   empirical     = emp_match,
#'   emp_lower_col = "lower",
#'   emp_upper_col = "upper"
#' ) +
#'   scale_colour_manual(
#'     values = c("Limited FET" = "steelblue", "Extended FET" = "#8B4513"),
#'     name   = NULL
#'   ) +
#'   scale_fill_manual(
#'     values = c("Limited FET" = "steelblue", "Extended FET" = "#8B4513"),
#'     guide  = "none"
#'   ) +
#'   scale_x_continuous(limits = c(0, 7), breaks = 0:7) +
#'   scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 20),
#'                      labels = function(x) paste0(x, "%")) +
#'   labs(x = "Years after Repair", y = "Survival (%)") +
#'   hvti_theme("manuscript")
#'
#' # --- (8) Device sequencing (tp.hp.mcs.mod.dead.devseq) -------------------
#' # Survival conditioned on surviving the non-LVAD phase, then the LVAD phase.
#' # In R: generate two separate prediction segments and rbind them.
#' dat_dev1 <- sample_hazard_data(n = 200, time_max = 0.038,
#'                                 shape = 0.5, scale = 0.5)
#' dat_dev1$device <- "Non-LVAD (first 2 weeks)"
#' dat_dev2 <- sample_hazard_data(n = 200, time_max = 0.25,
#'                                 shape = 1.0, scale = 1.5)
#' dat_dev2$time   <- dat_dev2$time + 0.038
#' dat_dev2$device <- "LVAD"
#' dat_dev  <- rbind(dat_dev1, dat_dev2)
#' hazard_plot(
#'   dat_dev,
#'   estimate_col = "survival",
#'   group_col    = "device"
#' ) +
#'   scale_colour_manual(
#'     values = c("Non-LVAD (first 2 weeks)" = "steelblue", "LVAD" = "firebrick"),
#'     name   = NULL
#'   ) +
#'   scale_x_continuous(limits = c(0, 0.29),
#'                       breaks = c(0, 0.038, 0.08, 0.13, 0.19, 0.25),
#'                       labels = c("0", "2w", "1m", "6w", "2m", "3m")) +
#'   scale_y_continuous(limits = c(0, 100),
#'                       labels = function(x) paste0(x, "%")) +
#'   labs(x = "Time on Device", y = "Survival (%)") +
#'   hvti_theme("manuscript")
#'
#' # --- (9) Save (dontrun) --------------------------------------------------
#' \dontrun{
#' p <- hazard_plot(dat, estimate_col = "survival",
#'                  lower_col = "surv_lower", upper_col = "surv_upper",
#'                  empirical = emp,
#'                  emp_lower_col = "lower", emp_upper_col = "upper") +
#'   scale_colour_manual(values = c("steelblue"), guide = "none") +
#'   scale_fill_manual(values = c("steelblue"), guide = "none") +
#'   labs(x = "Years", y = "Survival (%)") +
#'   hvti_theme("manuscript")
#' ggplot2::ggsave("survival.pdf", p, width = 11.5, height = 8)
#' }
#'
#' @importFrom ggplot2 ggplot aes geom_line geom_ribbon geom_point geom_errorbar
#' @importFrom rlang .data
#' @export
hazard_plot <- function(curve_data,
                         x_col            = "time",
                         estimate_col     = "survival",
                         lower_col        = NULL,
                         upper_col        = NULL,
                         group_col        = NULL,
                         empirical        = NULL,
                         emp_x_col        = x_col,
                         emp_estimate_col = estimate_col,
                         emp_lower_col    = NULL,
                         emp_upper_col    = NULL,
                         emp_group_col    = group_col,
                         reference        = NULL,
                         ref_x_col        = x_col,
                         ref_estimate_col = estimate_col,
                         ref_group_col    = NULL,
                         ci_alpha         = 0.20,
                         line_width       = 1.0,
                         point_size       = 2.0,
                         point_shape      = 1L,
                         errorbar_width   = 0.25) {

  # --- Validate curve_data --------------------------------------------------
  if (!is.data.frame(curve_data))
    stop("`curve_data` must be a data frame.")
  for (col in c(x_col, estimate_col)) {
    if (!(col %in% names(curve_data)))
      stop(sprintf("Column '%s' not found in `curve_data`.", col))
  }
  for (col in c(lower_col, upper_col, group_col)) {
    if (!is.null(col) && !(col %in% names(curve_data)))
      stop(sprintf("Column '%s' not found in `curve_data`.", col))
  }

  # --- Validate empirical ---------------------------------------------------
  if (!is.null(empirical)) {
    if (!is.data.frame(empirical))
      stop("`empirical` must be a data frame.")
    for (col in c(emp_x_col, emp_estimate_col, emp_lower_col,
                  emp_upper_col, emp_group_col)) {
      if (!is.null(col) && !(col %in% names(empirical)))
        stop(sprintf("Column '%s' not found in `empirical`.", col))
    }
  }

  # --- Validate reference ---------------------------------------------------
  if (!is.null(reference)) {
    if (!is.data.frame(reference))
      stop("`reference` must be a data frame.")
    for (col in c(ref_x_col, ref_estimate_col, ref_group_col)) {
      if (!is.null(col) && !(col %in% names(reference)))
        stop(sprintf("Column '%s' not found in `reference`.", col))
    }
  }

  # --- Base aesthetics for parametric curves --------------------------------
  if (!is.null(group_col)) {
    base_aes <- ggplot2::aes(x      = .data[[x_col]],
                             y      = .data[[estimate_col]],
                             colour = .data[[group_col]],
                             group  = .data[[group_col]])
  } else {
    base_aes <- ggplot2::aes(x = .data[[x_col]],
                             y = .data[[estimate_col]])
  }

  p <- ggplot2::ggplot(curve_data, base_aes)

  # --- CI ribbon on parametric curve ----------------------------------------
  if (!is.null(lower_col) && !is.null(upper_col)) {
    if (!is.null(group_col)) {
      rib_aes <- ggplot2::aes(x      = .data[[x_col]],
                              ymin   = .data[[lower_col]],
                              ymax   = .data[[upper_col]],
                              fill   = .data[[group_col]],
                              group  = .data[[group_col]])
    } else {
      rib_aes <- ggplot2::aes(x    = .data[[x_col]],
                              ymin = .data[[lower_col]],
                              ymax = .data[[upper_col]])
    }
    p <- p + ggplot2::geom_ribbon(mapping     = rib_aes,
                                  data        = curve_data,
                                  alpha       = ci_alpha,
                                  colour      = NA,
                                  inherit.aes = FALSE)
  }

  # --- Parametric curve lines -----------------------------------------------
  p <- p + ggplot2::geom_line(linewidth = line_width)

  # --- Reference (life table) overlay ---------------------------------------
  if (!is.null(reference)) {
    if (!is.null(ref_group_col)) {
      ref_aes <- ggplot2::aes(x        = .data[[ref_x_col]],
                              y        = .data[[ref_estimate_col]],
                              group    = .data[[ref_group_col]],
                              linetype = .data[[ref_group_col]])
      p <- p + ggplot2::geom_line(mapping     = ref_aes,
                                  data        = reference,
                                  linewidth   = line_width * 0.7,
                                  inherit.aes = FALSE)
    } else {
      ref_aes <- ggplot2::aes(x = .data[[ref_x_col]],
                              y = .data[[ref_estimate_col]])
      p <- p + ggplot2::geom_line(mapping     = ref_aes,
                                  data        = reference,
                                  linetype    = "dashed",
                                  linewidth   = line_width * 0.7,
                                  inherit.aes = FALSE)
    }
  }

  # --- KM empirical points --------------------------------------------------
  if (!is.null(empirical)) {
    if (!is.null(emp_group_col)) {
      emp_aes <- ggplot2::aes(x      = .data[[emp_x_col]],
                              y      = .data[[emp_estimate_col]],
                              colour = .data[[emp_group_col]])
    } else {
      emp_aes <- ggplot2::aes(x = .data[[emp_x_col]],
                              y = .data[[emp_estimate_col]])
    }
    p <- p + ggplot2::geom_point(mapping     = emp_aes,
                                 data        = empirical,
                                 size        = point_size,
                                 shape       = point_shape,
                                 inherit.aes = FALSE)

    # --- Error bars on empirical points -------------------------------------
    if (!is.null(emp_lower_col) && !is.null(emp_upper_col)) {
      if (!is.null(emp_group_col)) {
        err_aes <- ggplot2::aes(x      = .data[[emp_x_col]],
                                y      = .data[[emp_estimate_col]],
                                ymin   = .data[[emp_lower_col]],
                                ymax   = .data[[emp_upper_col]],
                                colour = .data[[emp_group_col]])
      } else {
        err_aes <- ggplot2::aes(x    = .data[[emp_x_col]],
                                y    = .data[[emp_estimate_col]],
                                ymin = .data[[emp_lower_col]],
                                ymax = .data[[emp_upper_col]])
      }
      p <- p + ggplot2::geom_errorbar(mapping     = err_aes,
                                      data        = empirical,
                                      width       = errorbar_width,
                                      inherit.aes = FALSE)
    }
  }

  p
}

# ============================================================================

#' Survival Difference (Life-Gained) Plot
#'
#' Plots the difference in survival between two groups over time, with an
#' optional confidence band. Covers `tp.hp.dead.life-gained.sas` and the
#' survival-difference component of `tp.hp.numtreat.survdiff.matched.sas`.
#'
#' **SAS context:** The `HAZDIFL` macro in `tp.hp.dead.life-gained.sas`
#' bootstraps the difference `S_2(t) - S_1(t)` (or `S_1(t) - S_2(t)`) and
#' stores the result in a `diffout` dataset. Export that dataset and pass it
#' here with the appropriate column names.
#'
#' @param diff_data    Data frame of pre-computed survival differences. See
#'   [sample_survival_difference_data()].
#' @param x_col        Name of the time column. Default `"time"`.
#' @param estimate_col Name of the difference column. Default `"difference"`.
#' @param lower_col    Name of the lower CI column, or `NULL`. Default `NULL`.
#' @param upper_col    Name of the upper CI column, or `NULL`. Default `NULL`.
#' @param group_col    Name of a grouping column for multiple comparisons, or
#'   `NULL`. Default `NULL`.
#' @param ci_alpha     Transparency of the CI ribbon. Default `0.20`.
#' @param line_width   Line width. Default `1.0`.
#'
#' @return A [ggplot2::ggplot()] object.
#'
#' @seealso [sample_survival_difference_data()], [nnt_plot()], [hazard_plot()]
#'
#' @references SAS templates: \code{tp.hp.dead.life-gained.sas},
#'   \code{tp.hp.numtreat.survdiff.matched.sas}.
#'
#' @examples
#' library(ggplot2)
#'
#' diff_dat <- sample_survival_difference_data(
#'   n = 500, time_max = 10,
#'   groups = c("Control" = 1.0, "Treatment" = 0.70)
#' )
#'
#' # --- (1) Single comparison: TF-TAVR vs TA-TAVR (tp.hp.dead.life-gained) --
#' survival_difference_plot(
#'   diff_dat,
#'   lower_col = "diff_lower",
#'   upper_col = "diff_upper"
#' ) +
#'   scale_colour_manual(values = c("steelblue"), guide = "none") +
#'   scale_fill_manual(values = c("steelblue"), guide = "none") +
#'   geom_hline(yintercept = 0, linetype = "dashed", colour = "grey50") +
#'   scale_x_continuous(limits = c(0, 10), breaks = 0:10) +
#'   scale_y_continuous(limits = c(-5, 30),
#'                      labels = function(x) paste0(x, "%")) +
#'   labs(x = "Years", y = "Survival Difference (%)") +
#'   hvti_theme("manuscript")
#'
#' # --- (2) Multiple treatment comparisons ----------------------------------
#' # Simulate three comparisons and combine (each row = one comparison)
#' d1 <- sample_survival_difference_data(
#'   groups = c("Medical Mgmt" = 1.0, "TF-TAVR" = 0.70), seed = 1
#' )
#' d1$comparison <- "TF-TAVR vs Medical Mgmt"
#'
#' d2 <- sample_survival_difference_data(
#'   groups = c("TA-TAVR" = 0.90, "TF-TAVR" = 0.70), seed = 2
#' )
#' d2$comparison <- "TF-TAVR vs TA-TAVR"
#'
#' d3 <- sample_survival_difference_data(
#'   groups = c("AVR" = 0.80, "TF-TAVR" = 0.70), seed = 3
#' )
#' d3$comparison <- "TF-TAVR vs AVR"
#'
#' dall <- rbind(d1, d2, d3)
#'
#' survival_difference_plot(dall, group_col = "comparison") +
#'   scale_colour_brewer(palette = "Set1", name = NULL) +
#'   scale_fill_brewer(palette = "Set1", guide = "none") +
#'   geom_hline(yintercept = 0, linetype = "dashed", colour = "grey50") +
#'   scale_x_continuous(limits = c(0, 10), breaks = 0:10) +
#'   labs(x = "Years", y = "Survival Difference (%)") +
#'   hvti_theme("manuscript")
#'
#' @importFrom ggplot2 ggplot aes geom_line geom_ribbon
#' @importFrom rlang .data
#' @export
survival_difference_plot <- function(diff_data,
                                     x_col        = "time",
                                     estimate_col = "difference",
                                     lower_col    = NULL,
                                     upper_col    = NULL,
                                     group_col    = NULL,
                                     ci_alpha     = 0.20,
                                     line_width   = 1.0) {
  if (!is.data.frame(diff_data))
    stop("`diff_data` must be a data frame.")
  for (col in c(x_col, estimate_col, lower_col, upper_col, group_col)) {
    if (!is.null(col) && !(col %in% names(diff_data)))
      stop(sprintf("Column '%s' not found in `diff_data`.", col))
  }

  if (!is.null(group_col)) {
    base_aes <- ggplot2::aes(x      = .data[[x_col]],
                             y      = .data[[estimate_col]],
                             colour = .data[[group_col]],
                             group  = .data[[group_col]])
  } else {
    base_aes <- ggplot2::aes(x = .data[[x_col]],
                             y = .data[[estimate_col]])
  }

  p <- ggplot2::ggplot(diff_data, base_aes)

  if (!is.null(lower_col) && !is.null(upper_col)) {
    if (!is.null(group_col)) {
      rib_aes <- ggplot2::aes(x     = .data[[x_col]],
                              ymin  = .data[[lower_col]],
                              ymax  = .data[[upper_col]],
                              fill  = .data[[group_col]],
                              group = .data[[group_col]])
    } else {
      rib_aes <- ggplot2::aes(x    = .data[[x_col]],
                              ymin = .data[[lower_col]],
                              ymax = .data[[upper_col]])
    }
    p <- p + ggplot2::geom_ribbon(mapping     = rib_aes,
                                  data        = diff_data,
                                  alpha       = ci_alpha,
                                  colour      = NA,
                                  inherit.aes = FALSE)
  }

  p + ggplot2::geom_line(linewidth = line_width)
}

# ============================================================================

#' Number Needed to Treat (NNT) Plot
#'
#' Plots the number needed to treat (NNT) and/or absolute risk reduction (ARR)
#' over time, with optional confidence bands. Covers the NNT component of
#' `tp.hp.numtreat.survdiff.matched.sas`.
#'
#' **SAS context:** The SAS template computes NNT at discrete time points
#' (1, 5, 10, 15, 20 years) from the HAZDIFL macro output, then connects them
#' as a curve. Export the NNT dataset and pass it directly, or use
#' [sample_nnt_data()] for examples.
#'
#' @param nnt_data     Data frame of pre-computed NNT estimates. See
#'   [sample_nnt_data()].
#' @param x_col        Name of the time column. Default `"time"`.
#' @param estimate_col Name of the NNT column. Default `"nnt"`.
#' @param lower_col    Name of the lower CI column, or `NULL`. Default `NULL`.
#' @param upper_col    Name of the upper CI column, or `NULL`. Default `NULL`.
#' @param na_rm        Remove `NA` NNT values (undefined when ARR ≈ 0) before
#'   plotting. Default `TRUE`.
#' @param ci_alpha     Transparency of the CI ribbon. Default `0.20`.
#' @param line_width   Line width. Default `1.0`.
#'
#' @return A [ggplot2::ggplot()] object.
#'
#' @seealso [sample_nnt_data()], [survival_difference_plot()], [hazard_plot()]
#'
#' @references SAS template: \code{tp.hp.numtreat.survdiff.matched.sas}.
#'
#' @examples
#' library(ggplot2)
#'
#' nnt_dat <- sample_nnt_data(
#'   n = 500, time_max = 20,
#'   groups = c("SVG" = 1.0, "ITA" = 0.75)
#' )
#'
#' # --- (1) NNT curve over time --------------------------------------------
#' # Matches tp.hp.numtreat.survdiff.matched.sas (NNT panel).
#' # NNT decreases as the treatment benefit accumulates over time.
#' nnt_plot(
#'   nnt_dat,
#'   lower_col = "nnt_lower",
#'   upper_col = "nnt_upper"
#' ) +
#'   scale_colour_manual(values = c("steelblue"), guide = "none") +
#'   scale_fill_manual(values = c("steelblue"), guide = "none") +
#'   scale_x_continuous(limits = c(0, 20), breaks = seq(0, 20, 5)) +
#'   scale_y_continuous(limits = c(0, 50), breaks = seq(0, 50, 10)) +
#'   labs(x = "Years", y = "Number Needed to Treat (NNT)") +
#'   hvti_theme("manuscript")
#'
#' # --- (2) ARR curve over time (same data, different column) ---------------
#' # Absolute risk reduction (%) increases over time as survival curves diverge.
#' nnt_plot(
#'   nnt_dat,
#'   estimate_col = "arr",
#'   lower_col    = "arr_lower",
#'   upper_col    = "arr_upper"
#' ) +
#'   scale_colour_manual(values = c("firebrick"), guide = "none") +
#'   scale_fill_manual(values = c("firebrick"), guide = "none") +
#'   scale_x_continuous(limits = c(0, 20), breaks = seq(0, 20, 5)) +
#'   scale_y_continuous(limits = c(0, 50),
#'                      labels = function(x) paste0(x, "%")) +
#'   labs(x = "Years", y = "Absolute Risk Reduction (%)") +
#'   hvti_theme("manuscript")
#'
#' @importFrom ggplot2 ggplot aes geom_line geom_ribbon
#' @importFrom rlang .data
#' @export
nnt_plot <- function(nnt_data,
                     x_col        = "time",
                     estimate_col = "nnt",
                     lower_col    = NULL,
                     upper_col    = NULL,
                     na_rm        = TRUE,
                     ci_alpha     = 0.20,
                     line_width   = 1.0) {
  if (!is.data.frame(nnt_data))
    stop("`nnt_data` must be a data frame.")
  for (col in c(x_col, estimate_col, lower_col, upper_col)) {
    if (!is.null(col) && !(col %in% names(nnt_data)))
      stop(sprintf("Column '%s' not found in `nnt_data`.", col))
  }

  if (na_rm) {
    nnt_data <- nnt_data[!is.na(nnt_data[[estimate_col]]), , drop = FALSE]
  }

  p <- ggplot2::ggplot(nnt_data,
                       ggplot2::aes(x = .data[[x_col]],
                                    y = .data[[estimate_col]]))

  if (!is.null(lower_col) && !is.null(upper_col)) {
    p <- p + ggplot2::geom_ribbon(
      ggplot2::aes(ymin = .data[[lower_col]], ymax = .data[[upper_col]]),
      alpha  = ci_alpha,
      colour = NA
    )
  }

  p + ggplot2::geom_line(linewidth = line_width)
}
