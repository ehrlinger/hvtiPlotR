###############################################################################
## Reusable mirrored histogram for propensity score distributions.
## Supports two modes:
##   Binary-match mode  (match_col): darkened bars = matched subset.
##   Weighted IPTW mode (weight_col): weighted bars = per-bin weight sums.
###############################################################################

# File-local constants (mirror-histogram score axis)
HVTI_SCORE_MIN              <- 0
HVTI_SCORE_MAX              <- 100
HVTI_SCORE_BREAK_STEP       <- 10
HVTI_SCORE_MARGIN_RATIO     <- 0.10
HVTI_SCORE_FILL_RATIO       <- 0.95
HVTI_SCORE_DEFAULT_MULTIPLIER <- 100

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

##' Calculate Standardized Mean Difference (SMD)
##'
##' Computes the standardized mean difference between two groups for a given score.
##'
##' @param score Numeric vector of scores.
##' @param group Vector indicating group membership (same length as score).
##' @param group_levels Length-2 vector specifying the two group values to compare.
##' @return Numeric value of the SMD, or NA/0 if not computable.
##' @keywords internal
calc_smd <- function(score, group, group_levels) {
  g0 <- score[group == group_levels[1]]
  g1 <- score[group == group_levels[2]]
  if (length(g0) < 2 || length(g1) < 2) {
    return(NA_real_)
  }
  pooled_sd <- sqrt((stats::var(g0) + stats::var(g1)) / 2)
  if (is.na(pooled_sd) || pooled_sd == 0) {
    return(0)
  }
  (mean(g1) - mean(g0)) / pooled_sd
}

##' Calculate Weighted Standardized Mean Difference (SMD)
##'
##' Computes the weighted SMD between two groups using IPTW weights.
##' Uses weighted means and weighted variances (frequency-weight convention).
##'
##' @param score Numeric vector of scores.
##' @param weights Numeric vector of non-negative weights (same length as score).
##' @param group Vector indicating group membership (same length as score).
##' @param group_levels Length-2 vector specifying the two group values to compare.
##' @return Numeric value of the weighted SMD, or NA if not computable.
##' @keywords internal
calc_weighted_smd <- function(score, weights, group, group_levels) {
  idx0 <- group == group_levels[1]
  idx1 <- group == group_levels[2]
  s0 <- score[idx0];   w0 <- weights[idx0]
  s1 <- score[idx1];   w1 <- weights[idx1]
  sw0 <- sum(w0);      sw1 <- sum(w1)
  if (sw0 == 0 || sw1 == 0 ||
      sum(w0 > 0) < 2 || sum(w1 > 0) < 2) {
    return(NA_real_)
  }
  mu0 <- sum(w0 * s0) / sw0
  mu1 <- sum(w1 * s1) / sw1
  var0 <- sum(w0 * (s0 - mu0)^2) / sw0
  var1 <- sum(w1 * (s1 - mu1)^2) / sw1
  pooled_sd <- sqrt((var0 + var1) / 2)
  if (is.na(pooled_sd) || pooled_sd == 0) return(0)
  (mu1 - mu0) / pooled_sd
}

##' Build Histogram Counts
##'
##' Helper function to compute histogram bin midpoints and counts for a numeric vector.
##'
##' @param x Numeric vector to bin.
##' @param breaks Numeric vector of break points for bins.
##' @return Data frame with columns `x` (bin midpoints) and `count` (counts per bin).
##' @keywords internal
##' @importFrom graphics hist
build_hist_counts <- function(x, breaks) {
  h <- hist(
    x,
    breaks = breaks,
    plot = FALSE,
    right = TRUE,
    include.lowest = TRUE
  )
  data.frame(x = h$mids, count = h$counts)
}

##' Build Weighted Histogram Counts
##'
##' Computes per-bin sums of \code{weights} for use in IPTW mirrored histograms.
##'
##' @param x Numeric vector of propensity scores (already scaled).
##' @param weights Numeric vector of non-negative weights (same length as \code{x}).
##' @param breaks Numeric vector of break points for bins.
##' @return Data frame with columns `x` (bin midpoints) and `count` (weight sums per bin).
##' @keywords internal
build_weighted_hist_counts <- function(x, weights, breaks) {
  bins <- cut(x, breaks = breaks, right = TRUE, include.lowest = TRUE)
  sums <- tapply(weights, bins, FUN = sum, simplify = TRUE)
  sums[is.na(sums)] <- 0
  mids <- (breaks[-length(breaks)] + breaks[-1]) / 2
  data.frame(x = mids, count = as.numeric(sums))
}

# Internal: Validate inputs for mirrored histogram
validate_mirror_histogram_input <- function(data, score_col, group_col, match_col,
                                            group_levels, group_labels, binwidth,
                                            weight_col = NULL) {
  if (!(is.data.frame(data)))
    stop("`data` must be a data.frame.")
  # When weight_col is provided, match_col presence is not required
  required_cols <- if (is.null(weight_col)) {
    c(score_col, group_col, match_col)
  } else {
    c(score_col, group_col, weight_col)
  }
  missing_cols <- setdiff(required_cols, names(data))
  if (!(length(missing_cols) == 0))
    stop(sprintf("Missing required columns: %s",
                 paste(missing_cols, collapse = ", ")))
  if (!(length(group_levels) == 2))
    stop("`group_levels` must contain exactly 2 values.")
  if (!(length(group_labels) == 2))
    stop("`group_labels` must contain exactly 2 values.")
  if (!(is.numeric(data[[score_col]])))
    stop(sprintf("`%s` must be numeric.", score_col))
  if (!is.numeric(binwidth) || length(binwidth) != 1L || !(binwidth > 0))
    stop("`binwidth` must be a positive numeric scalar.")
  if (!is.null(weight_col)) {
    if (!(is.numeric(data[[weight_col]])))
      stop(sprintf("`%s` must be numeric.", weight_col))
    if (!(all(data[[weight_col]] >= 0, na.rm = TRUE)))
      stop(sprintf("`%s` must contain non-negative values.", weight_col))
  }
}

# Internal: Prepare and filter data
prepare_mirror_histogram_data <- function(data, score_col, group_col, match_col,
                                          group_levels, score_multiplier,
                                          weight_col = NULL) {
  if (is.null(weight_col)) {
    working <- data.frame(
      score_raw = data[[score_col]],
      group     = data[[group_col]],
      matched   = data[[match_col]]
    )
  } else {
    working <- data.frame(
      score_raw = data[[score_col]],
      group     = data[[group_col]],
      weight    = data[[weight_col]]
    )
  }
  n_input <- nrow(working)
  working <- working[stats::complete.cases(working), ]
  n_dropped <- n_input - nrow(working)
  working <- working[working$group %in% group_levels, ]
  if (!(nrow(working) > 0))
    stop("No rows remain after filtering to `group_levels` and complete cases.")
  if (!(all(group_levels %in% unique(working$group))))
    stop("Not all `group_levels` are present in the filtered data.")
  working$score <- working$score_raw * score_multiplier
  if (any(working$score < HVTI_SCORE_MIN | working$score > HVTI_SCORE_MAX)) {
    stop(
      sprintf(
        "Scaled propensity scores must lie in [%d, %d]. Check `score_multiplier`.",
        HVTI_SCORE_MIN, HVTI_SCORE_MAX
      ),
      call. = FALSE
    )
  }
  list(working = working, n_input = n_input, n_dropped = n_dropped)
}

# Internal: Assemble binary-match histogram plot data
assemble_binary_mirror_plot_df <- function(working, group_levels, group_labels,
                                           matched_value, breaks) {
  g0 <- working$group == group_levels[1]
  g1 <- working$group == group_levels[2]
  matched_idx <- working$matched == matched_value
  b0 <- build_hist_counts(working$score[g0], breaks)
  b1 <- build_hist_counts(working$score[g1], breaks)
  a0 <- build_hist_counts(working$score[g0 & matched_idx], breaks)
  a1 <- build_hist_counts(working$score[g1 & matched_idx], breaks)
  plot_df <- rbind(
    data.frame(x = b0$x, y =  b0$count, group = group_labels[1],
               layer = "Before",  fill_key = "before_g0"),
    data.frame(x = a0$x, y =  a0$count, group = group_labels[1],
               layer = "Matched", fill_key = "matched_g0"),
    data.frame(x = b1$x, y = -b1$count, group = group_labels[2],
               layer = "Before",  fill_key = "before_g1"),
    data.frame(x = a1$x, y = -a1$count, group = group_labels[2],
               layer = "Matched", fill_key = "matched_g1")
  )
  list(plot_df = plot_df, matched_idx = matched_idx)
}

# Internal: Assemble weighted-IPTW histogram plot data
assemble_weighted_mirror_plot_df <- function(working, group_levels, group_labels,
                                             breaks) {
  g0 <- working$group == group_levels[1]
  g1 <- working$group == group_levels[2]
  b0  <- build_hist_counts(working$score[g0], breaks)
  b1  <- build_hist_counts(working$score[g1], breaks)
  wt0 <- build_weighted_hist_counts(working$score[g0], working$weight[g0], breaks)
  wt1 <- build_weighted_hist_counts(working$score[g1], working$weight[g1], breaks)
  plot_df <- rbind(
    data.frame(x = b0$x,  y =  b0$count,  group = group_labels[1],
               layer = "Before",   fill_key = "before_g0"),
    data.frame(x = wt0$x, y =  wt0$count, group = group_labels[1],
               layer = "Weighted", fill_key = "weighted_g0"),
    data.frame(x = b1$x,  y = -b1$count,  group = group_labels[2],
               layer = "Before",   fill_key = "before_g1"),
    data.frame(x = wt1$x, y = -wt1$count, group = group_labels[2],
               layer = "Weighted", fill_key = "weighted_g1")
  )
  list(plot_df = plot_df, matched_idx = NULL)
}

# Internal: Route to binary or weighted assembly
assemble_mirror_histogram_plot_df <- function(working, group_levels, group_labels,
                                              matched_value, breaks,
                                              weight_col = NULL) {
  if (is.null(weight_col)) {
    assemble_binary_mirror_plot_df(working, group_levels, group_labels,
                                   matched_value, breaks)
  } else {
    assemble_weighted_mirror_plot_df(working, group_levels, group_labels, breaks)
  }
}

# Internal: Build ggplot object for mirrored histogram
#' @importFrom ggplot2 ggplot geom_hline geom_col scale_fill_manual scale_x_continuous scale_y_continuous labs annotate coord_cartesian aes theme_minimal
build_mirror_histogram_plot <- function(plot_df, group_labels, binwidth,
                                        lower, upper, y_breaks, alpha) {
  ggplot2::ggplot() +
    ggplot2::geom_hline(yintercept = 0, linewidth = 0.7, color = "black") +
    ggplot2::geom_col(
      data = plot_df[plot_df$layer == "Before", ],
      ggplot2::aes(x = .data[["x"]], y = .data[["y"]],
                   fill = .data[["fill_key"]]),
      width = binwidth * HVTI_SCORE_FILL_RATIO,
      color = "black",
      alpha = alpha
    ) +
    ggplot2::geom_col(
      data = plot_df[plot_df$layer != "Before", ],
      ggplot2::aes(x = .data[["x"]], y = .data[["y"]],
                   fill = .data[["fill_key"]]),
      width = binwidth * HVTI_SCORE_FILL_RATIO,
      color = "black",
      alpha = alpha
    ) +
    ggplot2::scale_x_continuous(
      limits = c(HVTI_SCORE_MIN, HVTI_SCORE_MAX),
      breaks = seq(HVTI_SCORE_MIN, HVTI_SCORE_MAX, HVTI_SCORE_BREAK_STEP)
    ) +
    ggplot2::scale_y_continuous(
      limits = c(lower, upper),
      breaks = y_breaks,
      labels = abs(y_breaks)
    ) +
    ggplot2::labs(x = "Propensity Score (%)",
                  y = "Number of patients / sum of weights") +
    ggplot2::coord_cartesian(clip = "off") +
    ggplot2::theme_minimal(base_size = 12)
}

# Internal: Safely persist mirrored histogram to disk
save_mirror_histogram_plot <- function(plot_obj, output_file, width, height) {
  if (!(is.character(output_file) && length(output_file) == 1L &&
        nzchar(output_file)))
    stop("`output_file` must be a non-empty string.")
  target_dir <- dirname(output_file)
  if (target_dir %in% c("", ".")) target_dir <- "."
  if (!(dir.exists(target_dir)))
    stop(sprintf("Directory for `output_file` (%s) does not exist.",
                 target_dir))
  tryCatch(
    ggplot2::ggsave(filename = output_file, plot = plot_obj,
                    width = width, height = height),
    error = function(e) {
      stop(sprintf("Failed to save mirrored histogram to '%s': %s",
                   output_file, e$message), call. = FALSE)
    }
  )
}

# Internal: Compute diagnostics — routes on matched_idx being NULL (weighted) or not
mirror_histogram_diagnostics <- function(working, matched_idx, group_levels,
                                         n_input, n_dropped) {
  base <- list(
    n_input                          = n_input,
    n_analyzed                       = nrow(working),
    n_dropped_missing_or_other_group = n_dropped +
      (n_input - n_dropped - nrow(working)),
    group_counts_before              = table(working$group),
    score_summary_before             = by(working$score, working$group, summary),
    smd_before                       = calc_smd(working$score, working$group,
                                                group_levels)
  )
  if (is.null(matched_idx)) {
    # Weighted IPTW mode
    c(base, list(
      effective_n_by_group = tapply(working$weight, working$group, sum),
      smd_weighted         = calc_weighted_smd(working$score, working$weight,
                                               working$group, group_levels)
    ))
  } else {
    # Binary match mode
    c(base, list(
      group_counts_matched  = table(working$group[matched_idx]),
      matched_rate_by_group = tapply(matched_idx, working$group, mean),
      score_summary_matched = by(working$score[matched_idx],
                                 working$group[matched_idx], summary),
      smd_matched           = calc_smd(working$score[matched_idx],
                                       working$group[matched_idx], group_levels)
    ))
  }
}

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

#' Plot Mirrored Propensity Score Histogram
#'
#' Generates mirrored propensity score histograms for two treatment groups.
#' Supports two display modes selected by the arguments supplied:
#'
#' \describe{
#'   \item{Binary-match mode}{Supply \code{match_col}. Upper bars show all
#'     observations (before matching); overlaid bars show the matched subset.
#'     Fill keys: \code{before_g0}, \code{matched_g0}, \code{before_g1},
#'     \code{matched_g1}.}
#'   \item{Weighted IPTW mode}{Supply \code{weight_col}. Upper bars show raw
#'     counts (before weighting); overlaid bars show per-bin weight sums.
#'     \code{match_col} is ignored. Fill keys: \code{before_g0},
#'     \code{weighted_g0}, \code{before_g1}, \code{weighted_g1}.}
#' }
#'
#' @param data A data frame containing at least the score and group columns,
#'   plus either \code{match_col} or \code{weight_col}.
#' @param score_col Column name holding the numeric propensity score.
#' @param group_col Column name identifying the grouping/treatment indicator.
#' @param match_col Column name of the binary match indicator. Default
#'   \code{"match"}. Required in binary-match mode; ignored when
#'   \code{weight_col} is supplied.
#' @param group_levels Length-2 vector giving the values in \code{group_col}
#'   to plot (order determines panel orientation).
#' @param group_labels Length-2 character vector of human-readable group labels.
#' @param matched_value Value in \code{match_col} that denotes a matched
#'   observation (binary-match mode only).
#' @param score_multiplier Multiplier applied to \code{score_col} before
#'   plotting (default scales raw probabilities to percentages).
#' @param binwidth Bin width on the scaled score scale.
#' @param weight_col Optional column name holding IPTW weights. When supplied
#'   the function operates in weighted mode: "Before" bars show raw counts,
#'   "Weighted" bars show per-bin weight sums, and \code{match_col} is not
#'   required. The column must be numeric and non-negative.
#' @param alpha Transparency of the histogram bars, in \[0, 1\]. Default `0.8`.
#' @param output_file Optional file path; when provided the plot is saved via
#'   \code{ggsave()}.
#' @param width,height Dimensions (inches) when saving \code{output_file}.
#'
#' @return A list with elements \code{plot} (ggplot object), \code{diagnostics}
#'   (mode-dependent summary statistics), and \code{data} (filtered working
#'   data frame). Binary-match diagnostics include \code{smd_matched};
#'   weighted diagnostics include \code{smd_weighted} and
#'   \code{effective_n_by_group}.
#'
#' @examples
#' # --- Binary-match mode ---------------------------------------------------
#' # separation = 1.5 leaves many high/low-score patients unmatched at tails
#' mirror_dta <- sample_mirror_histogram_data(n = 500, separation = 1.5)
#' mhist <- mirror_histogram(mirror_dta, alpha = 0.8)
#' mhist$diagnostics$smd_before
#' mhist$diagnostics$smd_matched
#'
#' # Customise fill colours and apply manuscript theme
#' mhist$plot +
#'   ggplot2::scale_fill_manual(
#'     values = c(before_g0 = "white",  matched_g0 = "steelblue",
#'                before_g1 = "white",  matched_g1 = "firebrick"),
#'     guide = "none"
#'   ) +
#'   ggplot2::labs(x = "Propensity Score", y = "Count") +
#'   hvti_theme("manuscript")
#'
#' # --- Weighted IPTW mode --------------------------------------------------
#' wt_dta <- sample_mirror_histogram_data(n = 500, add_weights = TRUE)
#' mhist_wt <- mirror_histogram(wt_dta, weight_col = "mt_wt", alpha = 0.8)
#' mhist_wt$diagnostics$smd_weighted
#' mhist_wt$diagnostics$effective_n_by_group
#'
#' # Customise fill colours for weighted mode and apply manuscript theme
#' mhist_wt$plot +
#'   ggplot2::scale_fill_manual(
#'     values = c(before_g0 = "white", weighted_g0 = "blue",
#'                before_g1 = "white", weighted_g1 = "red"),
#'     guide = "none"
#'   ) +
#'   ggplot2::labs(x = "Propensity Score", y = "Weighted Count") +
#'   hvti_theme("manuscript")
#'
#' @importFrom ggplot2 ggplot geom_hline geom_col scale_fill_manual scale_x_continuous scale_y_continuous labs annotate coord_cartesian aes theme_minimal set_theme
#' @export
mirror_histogram <- function(data,
                             score_col       = "prob_t",
                             group_col       = "tavr",
                             match_col       = "match",
                             group_levels    = c(0, 1),
                             group_labels    = c("SAVR", "TF-TAVR"),
                             matched_value   = 1,
                             score_multiplier = HVTI_SCORE_DEFAULT_MULTIPLIER,
                             binwidth        = 5,
                             weight_col      = NULL,
                             alpha           = 0.8,
                             output_file     = NULL,
                             width           = 8,
                             height          = 6) {
  validate_mirror_histogram_input(data, score_col, group_col, match_col,
                                  group_levels, group_labels, binwidth,
                                  weight_col = weight_col)
  if (!is.numeric(alpha) || length(alpha) != 1L ||
      !(alpha > 0 && alpha <= 1))
    stop("`alpha` must be a number in (0, 1].")
  prep    <- prepare_mirror_histogram_data(data, score_col, group_col, match_col,
                                           group_levels, score_multiplier,
                                           weight_col = weight_col)
  working  <- prep$working
  n_input  <- prep$n_input
  n_dropped <- prep$n_dropped
  breaks <- seq(HVTI_SCORE_MIN, HVTI_SCORE_MAX, by = binwidth)
  if (utils::tail(breaks, 1) < HVTI_SCORE_MAX) breaks <- c(breaks, HVTI_SCORE_MAX)
  plot_info   <- assemble_mirror_histogram_plot_df(working, group_levels, group_labels,
                                                   matched_value, breaks,
                                                   weight_col = weight_col)
  plot_df     <- plot_info$plot_df
  matched_idx <- plot_info$matched_idx
  ymax  <- max(plot_df$y[plot_df$y >= 0], 0)
  ymin  <- min(plot_df$y[plot_df$y <= 0], 0)
  upper <- ymax + max(1, ceiling(HVTI_SCORE_MARGIN_RATIO * ymax))
  lower <- ymin - max(1, ceiling(HVTI_SCORE_MARGIN_RATIO * abs(ymin)))
  y_breaks <- pretty(c(lower, upper), n = 8)
  p <- build_mirror_histogram_plot(plot_df, group_labels, binwidth,
                                   lower, upper, y_breaks, alpha)
  diagnostics <- mirror_histogram_diagnostics(working, matched_idx, group_levels,
                                              n_input, n_dropped)
  if (!is.null(output_file)) {
    save_mirror_histogram_plot(p, output_file, width, height)
  }
  list(plot = p, diagnostics = diagnostics, data = working)
}

# ---------------------------------------------------------------------------
# Sample data
# ---------------------------------------------------------------------------

##' Generate Sample Data for Mirrored Histogram
##'
##' Creates a reproducible data frame for testing \code{\link{mirror_histogram}}
##' in either binary-match or weighted IPTW mode.  Propensity scores are
##' simulated via a logistic model: control subjects draw their linear predictor
##' from \eqn{N(-\text{sep}/2, 1)} and treated subjects from
##' \eqn{N(+\text{sep}/2, 1)}, so the two score distributions overlap in the
##' centre while accumulating mass at opposite extremes.  Patients at those
##' extremes cannot find a matching partner within the caliper, which naturally
##' reproduces the "many unmatched at the tails" pattern seen in real studies.
##'
##' @param n Number of observations **per group** (default 500).
##' @param separation Numeric. Distance between the two group means on the
##'   log-odds scale.  Larger values push the score distributions further apart
##'   and increase the proportion of unmatched patients at the extremes
##'   (default 1.5).
##' @param caliper Matching caliper width expressed in propensity-score units
##'   (0–1 scale, default 0.05).  Treated patients without a control partner
##'   within this distance are left unmatched.
##' @param seed Integer random seed for reproducibility (default 42L).
##' @param add_weights Logical. When \code{TRUE} an \code{mt_wt} column of
##'   ATE-style IPTW weights derived from the simulated propensity scores is
##'   appended and normalised to mean 1 within each group (default \code{FALSE}).
##' @return Data frame with columns:
##'   \describe{
##'     \item{\code{prob_t}}{Propensity score on the 0–1 scale.}
##'     \item{\code{tavr}}{Group indicator (0 = control, 1 = treated).}
##'     \item{\code{match}}{Binary match indicator produced by greedy
##'       nearest-neighbour matching within \code{caliper} (1 = matched).}
##'     \item{\code{mt_wt}}{(Only when \code{add_weights = TRUE}) ATE IPTW
##'       weights normalised to mean 1 within each group.}
##'   }
##' @importFrom stats rnorm plogis
##' @export
sample_mirror_histogram_data <- function(n          = 500,
                                         separation = 1.5,
                                         caliper    = 0.05,
                                         seed       = 42L,
                                         add_weights = FALSE) {
  if (!is.numeric(n) || length(n) != 1L || n < 1L || n %% 1 != 0)
    stop("`n` must be a positive integer.")
  if (!is.numeric(separation) || length(separation) != 1L ||
      !(separation > 0))
    stop("`separation` must be a positive number.")
  if (!is.numeric(caliper) || length(caliper) != 1L ||
      !(caliper > 0 && caliper <= 1))
    stop("`caliper` must be a number in (0, 1].")
  if (!is.logical(add_weights) || length(add_weights) != 1L)
    stop("`add_weights` must be TRUE or FALSE.")

  set.seed(seed)

  # Logistic propensity score model.
  # Control LP ~ N(-sep/2, 1) → scores cluster below 0.5.
  # Treated LP ~ N(+sep/2, 1) → scores cluster above 0.5.
  # The further a patient sits from 0.5, the fewer matching partners exist.
  ps_ctrl <- stats::plogis(stats::rnorm(n, mean = -separation / 2, sd = 1))
  ps_trt  <- stats::plogis(stats::rnorm(n, mean =  separation / 2, sd = 1))

  prob_t <- c(ps_ctrl, ps_trt)
  group  <- c(rep(0L, n), rep(1L, n))

  # Greedy 1:1 nearest-neighbour matching within caliper.
  # Treated patients are visited in random order; each control can match once.
  match_flag <- rep(0L, 2L * n)
  used_ctrl  <- rep(FALSE, n)

  for (i in sample.int(n)) {
    diffs            <- abs(ps_ctrl - ps_trt[i])
    diffs[used_ctrl] <- Inf
    best             <- which.min(diffs)
    if (diffs[best] <= caliper) {
      match_flag[n + i] <- 1L
      match_flag[best]  <- 1L
      used_ctrl[best]   <- TRUE
    }
  }

  df <- data.frame(prob_t = prob_t, tavr = group, match = match_flag)

  if (add_weights) {
    # ATE IPTW: w = 1/PS (treated) or 1/(1-PS) (control).
    # Trim extreme scores to avoid runaway weights, then normalise within group.
    ps_trim <- pmax(pmin(prob_t, 0.99), 0.01)
    wts     <- ifelse(group == 1L, 1 / ps_trim, 1 / (1 - ps_trim))
    wts[group == 0L] <- wts[group == 0L] / mean(wts[group == 0L])
    wts[group == 1L] <- wts[group == 1L] / mean(wts[group == 1L])
    df$mt_wt <- wts
  }

  df
}

