###############################################################################
## Covariate balance plot for propensity score matching / IPTW analyses.
## Adapted from the tp.lp.propen.cov_balance.R template.
###############################################################################

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

cb_validate_input <- function(data, variable_col, group_col, std_diff_col) {
  if (!is.data.frame(data))
    stop("`data` must be a data.frame.", call. = FALSE)
  missing_cols <- setdiff(
    c(variable_col, group_col, std_diff_col), names(data)
  )
  if (length(missing_cols))
    stop(
      sprintf("Missing required column(s): %s",
              paste(missing_cols, collapse = ", ")),
      call. = FALSE
    )
  if (!is.numeric(data[[std_diff_col]]))
    stop(sprintf("`%s` must be numeric.", std_diff_col), call. = FALSE)
}

#' @importFrom rlang .data
#' @importFrom ggplot2 ggplot aes geom_vline geom_hline geom_point
#'   scale_y_continuous
cb_build_plot <- function(data, std_diff_col, group_col, var_levels,
                          threshold, point_size,
                          hline_linetype, hline_linewidth,
                          vline_linewidth, threshold_linetype) {
  n_vars <- length(var_levels)

  ggplot2::ggplot(data) +
    # Solid centre reference at zero
    ggplot2::geom_vline(
      xintercept = 0,
      linewidth = vline_linewidth, color = "black"
    ) +
    # Dotted threshold reference lines
    ggplot2::geom_vline(
      xintercept = threshold,
      linetype = threshold_linetype, color = "black"
    ) +
    ggplot2::geom_vline(
      xintercept = -threshold,
      linetype = threshold_linetype, color = "black"
    ) +
    # Dashed horizontal guides, one per covariate row
    ggplot2::geom_hline(
      yintercept = seq_len(n_vars),
      linetype   = hline_linetype,
      linewidth  = hline_linewidth,
      color      = "black"
    ) +
    # Points — shape and colour mapped to group; no defaults applied
    ggplot2::geom_point(
      ggplot2::aes(
        x      = .data[[std_diff_col]],
        y      = .data[["cb_index"]],
        shape  = .data[[group_col]],
        colour = .data[[group_col]]
      ),
      size = point_size
    ) +
    # Y-axis: integer positions labelled with covariate names
    ggplot2::scale_y_continuous(
      limits = c(0, n_vars + 1.75),
      breaks = seq_len(n_vars),
      labels = var_levels
    )
}

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

#' Covariate Balance Plot
#'
#' Draws the classic HVI covariate balance figure used to assess propensity
#' score matching or IPTW quality. Each covariate appears as a labelled row;
#' points display the standardized mean difference for each group (e.g. before
#' and after matching). A solid reference line marks zero; dotted reference
#' lines mark a user-supplied imbalance threshold (default +/-10\%).
#'
#' The function returns a bare `ggplot` object with no colour, shape, axis, or
#' theme applied. Callers are expected to add those with the usual `+`
#' operator, keeping the workflow flexible and consistent with the rest of
#' the package.
#'
#' @param data A data frame in **long format** with one row per
#'   covariate x group combination. Wide-format data (one column per group)
#'   must be reshaped before passing, e.g. with [tidyr::pivot_longer()] or
#'   [stats::reshape()].
#' @param variable_col Name of the column containing covariate labels.
#'   Default `"variable"`.
#' @param group_col Name of the column identifying the comparison group
#'   (e.g. `"Before match"` / `"After match"`). Default `"group"`.
#' @param std_diff_col Name of the numeric column holding the standardized
#'   mean difference values. Default `"std_diff"`.
#' @param var_levels Character vector controlling the **display order** of
#'   covariates on the y-axis. The first element appears at the bottom.
#'   Defaults to the order of first appearance in `data[[variable_col]]`.
#' @param threshold Numeric value (absolute) for the dotted imbalance
#'   reference lines drawn at `+/-threshold`. Default `10`.
#' @param point_size Passed to [ggplot2::geom_point()]. Default `3`.
#' @param hline_linetype Linetype for the horizontal covariate guide lines.
#'   Default `"dashed"`.
#' @param hline_linewidth Linewidth for the horizontal guide lines.
#'   Default `0.25`.
#' @param vline_linewidth Linewidth for the solid zero reference line.
#'   Default `0.2`.
#' @param threshold_linetype Linetype for the +/-threshold reference lines.
#'   Default `"dotted"`.
#'
#' @return A bare [ggplot2::ggplot()] object. Layer on
#'   [ggplot2::scale_color_manual()], [ggplot2::scale_shape_manual()],
#'   [ggplot2::scale_x_continuous()], [ggplot2::labs()],
#'   [ggplot2::annotate()], and a theme to complete the figure.
#'
#' @examples
#' library(ggplot2)
#'
#' dta <- sample_covariate_balance_data()
#'
#' # Bare plot
#' covariate_balance(dta)
#'
#' # Add colour, shape, and axis scales
#' covariate_balance(dta) +
#'   scale_color_manual(
#'     values = c("Before match" = "red4", "After match" = "blue3"),
#'     name   = NULL
#'   ) +
#'   scale_shape_manual(
#'     values = c("Before match" = 17L, "After match" = 15L),
#'     name   = NULL
#'   ) +
#'   scale_x_continuous(limits = c(-45, 35), breaks = seq(-40, 30, 10)) +
#'   labs(
#'     x = "Standardized difference: Group A vs Group B (%)",
#'     y = ""
#'   ) +
#'   theme(legend.position = c(0.20, 0.95))
#'
#' # Add directional annotations and theme
#' covariate_balance(dta) +
#'   scale_color_manual(
#'     values = c("Before match" = "red4", "After match" = "blue3"),
#'     name   = NULL
#'   ) +
#'   scale_shape_manual(
#'     values = c("Before match" = 17L, "After match" = 15L),
#'     name   = NULL
#'   ) +
#'   scale_x_continuous(limits = c(-45, 35), breaks = seq(-40, 30, 10)) +
#'   labs(x = "Standardized difference (%)", y = "") +
#'   annotate("text", x = -32, y =  0.5,
#'            label = "More likely Group B", size = 4) +
#'   annotate("text", x =  22, y = 13.5,
#'            label = "More likely Group A", size = 4) +
#'   hvtiPlotR::hvti_theme("manuscript")
#'
#' @export
covariate_balance <- function(
  data,
  variable_col       = "variable",
  group_col          = "group",
  std_diff_col       = "std_diff",
  var_levels         = NULL,
  threshold          = 10,
  point_size         = 3,
  hline_linetype     = "dashed",
  hline_linewidth    = 0.25,
  vline_linewidth    = 0.2,
  threshold_linetype = "dotted"
) {
  cb_validate_input(data, variable_col, group_col, std_diff_col)

  # Work on a local copy to avoid mutating inputs (e.g., data.table) by reference
  working <- as.data.frame(data)

  if (is.null(var_levels))
    var_levels <- unique(as.character(working[[variable_col]]))

  working[["cb_index"]] <- as.integer(
    factor(working[[variable_col]], levels = var_levels)
  )

  cb_build_plot(
    data               = working,
    std_diff_col       = std_diff_col,
    group_col          = group_col,
    var_levels         = var_levels,
    threshold          = threshold,
    point_size         = point_size,
    hline_linetype     = hline_linetype,
    hline_linewidth    = hline_linewidth,
    vline_linewidth    = vline_linewidth,
    threshold_linetype = threshold_linetype
  )
}

# ---------------------------------------------------------------------------
# Sample data generator
# ---------------------------------------------------------------------------

#' Generate Sample Covariate Balance Data
#'
#' Produces a reproducible long-format data frame suitable for testing and
#' demonstrating [covariate_balance()].  Rather than drawing SMDs from
#' independent normals, this generator simulates patient-level covariates
#' through a logistic propensity score model, computes group standardized mean
#' differences before matching, then performs greedy 1:1 nearest-neighbour
#' caliper matching and computes residual differences in the matched cohort.
#'
#' The result captures the pattern seen in real studies: covariates that drive
#' treatment selection show large imbalance before matching; matching
#' substantially reduces imbalance, but patients at the propensity score
#' extremes cannot be matched, leaving small residual differences for the
#' strongest confounders.
#'
#' @param n_vars Integer. Number of covariates to generate. Default `12`.
#' @param n Integer. Total number of simulated patients before matching.
#'   Default `600` (roughly 300 per group at `separation = 1.5`).
#' @param separation Numeric. Distance between the two group means on the
#'   log-odds scale.  Larger values push propensity score distributions
#'   further apart, increasing the proportion of unmatched extreme-score
#'   patients and residual imbalance after matching.  Default `1.5`.
#' @param caliper Matching caliper expressed in propensity-score units (0–1
#'   scale).  Patients without a partner within this distance are left
#'   unmatched.  Default `0.05`.
#' @param group_levels Length-2 character vector of group labels. Default
#'   `c("Before match", "After match")`.
#' @param seed Integer random seed for reproducibility. Default `42`.
#'
#' @return A data frame with `2 * n_vars` rows and columns `variable`, `group`,
#'   and `std_diff` (standardized mean difference as a percentage).
#'
#' @examples
#' dta <- sample_covariate_balance_data()
#' head(dta)
#'
#' # Higher separation -> more unmatched extremes -> more residual imbalance
#' dta2 <- sample_covariate_balance_data(
#'   n_vars       = 8,
#'   separation   = 2.0,
#'   group_levels = c("Unweighted", "IPTW weighted")
#' )
#'
#' @importFrom stats rnorm plogis rbinom var median
#' @export
sample_covariate_balance_data <- function(
  n_vars       = 12,
  n            = 600,
  separation   = 1.5,
  caliper      = 0.05,
  group_levels = c("Before match", "After match"),
  seed         = 42
) {
  if (!assertthat::is.count(n_vars) || n_vars < 1L)
    stop("`n_vars` must be a positive integer scalar.", call. = FALSE)
  if (!assertthat::is.count(n) || n < 2L)
    stop("`n` must be a positive integer >= 2.", call. = FALSE)
  if (!is.numeric(separation) || length(separation) != 1L || separation <= 0)
    stop("`separation` must be a positive number.", call. = FALSE)
  if (!is.numeric(caliper) || length(caliper) != 1L ||
      caliper <= 0 || caliper > 1)
    stop("`caliper` must be a number in (0, 1].", call. = FALSE)
  if (length(group_levels) != 2L)
    stop("`group_levels` must be a length-2 character vector.", call. = FALSE)

  default_vars <- c(
    "Age", "Female sex", "Hypertension", "Diabetes mellitus",
    "COPD", "Creatinine", "NYHA Class III/IV", "Ejection fraction",
    "Coronary artery disease", "Prior cardiac surgery",
    "Body mass index", "Current smoker"
  )
  var_names <- if (n_vars <= length(default_vars)) {
    default_vars[seq_len(n_vars)]
  } else {
    c(default_vars,
      paste("Covariate", seq_len(n_vars - length(default_vars))))
  }

  set.seed(seed)

  # --- Patient-level simulation ----------------------------------------------
  # Covariate matrix: each column ~ N(0,1).
  # Beta coefficients ~ N(0, separation/sqrt(n_vars)) so total PS variance ~ 1.
  X     <- matrix(stats::rnorm(n * n_vars), nrow = n, ncol = n_vars)
  betas <- stats::rnorm(n_vars, mean = 0, sd = separation / sqrt(n_vars))

  # Centre the linear predictor so ~50% of patients are treated.
  lp    <- drop(X %*% betas)
  lp    <- lp - stats::median(lp)
  ps    <- stats::plogis(lp)
  treat <- stats::rbinom(n, 1L, ps)

  # --- SMDs before matching --------------------------------------------------
  smds_before <- vapply(seq_len(n_vars), function(j) {
    x0 <- X[treat == 0, j]
    x1 <- X[treat == 1, j]
    if (length(x0) < 2 || length(x1) < 2) return(NA_real_)
    pooled_sd <- sqrt((stats::var(x0) + stats::var(x1)) / 2)
    if (is.na(pooled_sd) || pooled_sd == 0) return(0)
    (mean(x1) - mean(x0)) / pooled_sd * 100
  }, numeric(1))

  # --- Greedy 1:1 nearest-neighbour caliper matching -------------------------
  # Patients with extreme PSs (far from 0.5) cannot find a partner within the
  # caliper, so they are excluded from the matched cohort.  This leaves
  # residual imbalance on the covariates most responsible for their extremity.
  idx0      <- which(treat == 0)
  idx1      <- which(treat == 1)
  ps0       <- ps[idx0]
  ps1       <- ps[idx1]
  used_ctrl <- rep(FALSE, length(idx0))
  m_trt     <- rep(FALSE, length(idx1))
  m_ctrl    <- rep(FALSE, length(idx0))

  for (i in sample.int(length(idx1))) {
    diffs            <- abs(ps0 - ps1[i])
    diffs[used_ctrl] <- Inf
    best             <- which.min(diffs)
    if (diffs[best] <= caliper) {
      m_trt[i]        <- TRUE
      m_ctrl[best]    <- TRUE
      used_ctrl[best] <- TRUE
    }
  }

  # --- SMDs after matching ---------------------------------------------------
  X_mc <- X[idx0[m_ctrl], , drop = FALSE]
  X_mt <- X[idx1[m_trt],  , drop = FALSE]

  smds_after <- vapply(seq_len(n_vars), function(j) {
    x0 <- X_mc[, j]
    x1 <- X_mt[, j]
    if (length(x0) < 2 || length(x1) < 2) return(NA_real_)
    pooled_sd <- sqrt((stats::var(x0) + stats::var(x1)) / 2)
    if (is.na(pooled_sd) || pooled_sd == 0) return(0)
    (mean(x1) - mean(x0)) / pooled_sd * 100
  }, numeric(1))

  rbind(
    data.frame(variable = var_names, group = group_levels[1],
               std_diff = round(smds_before, 1), stringsAsFactors = FALSE),
    data.frame(variable = var_names, group = group_levels[2],
               std_diff = round(smds_after,  1), stringsAsFactors = FALSE)
  )
}
