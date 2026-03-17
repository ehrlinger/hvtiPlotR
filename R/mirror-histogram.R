###############################################################################
## Reusable mirrored histogram for propensity score distributions.
## Supports two modes:
##   Binary-match mode  (match_col): darkened bars = matched subset.
##   Weighted IPTW mode (weight_col): weighted bars = per-bin weight sums.
###############################################################################

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
  assertthat::assert_that(is.data.frame(data), msg = "`data` must be a data.frame.")
  # When weight_col is provided, match_col presence is not required
  required_cols <- if (is.null(weight_col)) {
    c(score_col, group_col, match_col)
  } else {
    c(score_col, group_col, weight_col)
  }
  missing_cols <- setdiff(required_cols, names(data))
  assertthat::assert_that(
    length(missing_cols) == 0,
    msg = sprintf("Missing required columns: %s", paste(missing_cols, collapse = ", "))
  )
  assertthat::assert_that(
    length(group_levels) == 2,
    msg = "`group_levels` must contain exactly 2 values."
  )
  assertthat::assert_that(
    length(group_labels) == 2,
    msg = "`group_labels` must contain exactly 2 values."
  )
  assertthat::assert_that(
    is.numeric(data[[score_col]]),
    msg = sprintf("`%s` must be numeric.", score_col)
  )
  assertthat::assert_that(
    assertthat::is.number(binwidth),
    binwidth > 0,
    msg = "`binwidth` must be a positive numeric scalar."
  )
  if (!is.null(weight_col)) {
    assertthat::assert_that(
      is.numeric(data[[weight_col]]),
      msg = sprintf("`%s` must be numeric.", weight_col)
    )
    assertthat::assert_that(
      all(data[[weight_col]] >= 0, na.rm = TRUE),
      msg = sprintf("`%s` must contain non-negative values.", weight_col)
    )
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
  assertthat::assert_that(
    nrow(working) > 0,
    msg = "No rows remain after filtering to `group_levels` and complete cases."
  )
  assertthat::assert_that(
    all(group_levels %in% unique(working$group)),
    msg = "Not all `group_levels` are present in the filtered data."
  )
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
                                        lower, upper, y_breaks) {
  ggplot2::ggplot() +
    ggplot2::geom_hline(yintercept = 0, linewidth = 0.7, color = "black") +
    ggplot2::geom_col(
      data = plot_df[plot_df$layer == "Before", ],
      ggplot2::aes(x = x, y = y, fill = fill_key),
      width = binwidth * HVTI_SCORE_FILL_RATIO,
      color = "black"
    ) +
    ggplot2::geom_col(
      data = plot_df[plot_df$layer != "Before", ],
      ggplot2::aes(x = x, y = y, fill = fill_key),
      width = binwidth * HVTI_SCORE_FILL_RATIO,
      color = "black"
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
    ggplot2::labs(x = "Propensity Score (%)", y = "Number of Patients") +
    ggplot2::coord_cartesian(clip = "off") +
    ggplot2::theme_minimal(base_size = 12)
}

# Internal: Safely persist mirrored histogram to disk
save_mirror_histogram_plot <- function(plot_obj, output_file, width, height) {
  assertthat::assert_that(
    assertthat::is.string(output_file), nzchar(output_file),
    msg = "`output_file` must be a non-empty string."
  )
  target_dir <- dirname(output_file)
  if (target_dir %in% c("", ".")) target_dir <- "."
  assertthat::assert_that(
    dir.exists(target_dir),
    msg = sprintf("Directory for `output_file` (%s) does not exist.", target_dir)
  )
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
#' @param match_col Column name of the binary match indicator. Required in
#'   binary-match mode; ignored when \code{weight_col} is supplied.
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
#' mirror_dta <- sample_mirror_histogram_data(n = 4000)
#' mhist <- mirror_histogram(mirror_dta)
#' mhist$plot
#' mhist$diagnostics$smd_before
#' mhist$diagnostics$smd_matched
#'
#' # Customise fill colours
#' mhist$plot +
#'   ggplot2::scale_fill_manual(
#'     values = c(before_g0 = "white",  matched_g0 = "steelblue",
#'                before_g1 = "white",  matched_g1 = "firebrick"),
#'     guide = "none"
#'   )
#'
#' # --- Weighted IPTW mode --------------------------------------------------
#' wt_dta <- sample_mirror_histogram_data(n = 500, add_weights = TRUE)
#' mhist_wt <- mirror_histogram(wt_dta, weight_col = "mt_wt")
#' mhist_wt$plot
#' mhist_wt$diagnostics$smd_weighted
#' mhist_wt$diagnostics$effective_n_by_group
#'
#' # Customise fill colours for weighted mode
#' mhist_wt$plot +
#'   ggplot2::scale_fill_manual(
#'     values = c(before_g0 = "white", weighted_g0 = "blue",
#'                before_g1 = "white", weighted_g1 = "red"),
#'     guide = "none"
#'   )
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
                             output_file     = NULL,
                             width           = 8,
                             height          = 6) {
  validate_mirror_histogram_input(data, score_col, group_col, match_col,
                                  group_levels, group_labels, binwidth,
                                  weight_col = weight_col)
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
                                   lower, upper, y_breaks)
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
##' Creates a reproducible data frame suitable for testing
##' \code{\link{mirror_histogram}} in either binary-match or weighted IPTW mode.
##'
##' @param n Number of samples per group (default 100).
##' @param add_weights Logical. When \code{TRUE} an \code{mt_wt} column of
##'   positive IPTW-style weights is appended (default \code{FALSE}).
##' @return Data frame with columns \code{prob_t}, \code{tavr}, \code{match},
##'   and optionally \code{mt_wt}.
##' @importFrom stats rbeta rbinom rexp
##' @export
sample_mirror_histogram_data <- function(n = 100, add_weights = FALSE) {
  assertthat::assert_that(assertthat::is.count(n),
                          msg = "`n` must be a positive integer.")
  assertthat::assert_that(assertthat::is.flag(add_weights),
                          msg = "`add_weights` must be TRUE or FALSE.")
  set.seed(123)
  group0_scores <- stats::rbeta(n, 2, 5)
  group1_scores <- stats::rbeta(n, 5, 2)
  group  <- c(rep(0, n), rep(1, n))
  prob_t <- c(group0_scores, group1_scores)
  match  <- stats::rbinom(2 * n, 1, prob = HVTI_MATCH_PROBABILITY)
  df <- data.frame(prob_t = prob_t, tavr = group, match = match)
  if (add_weights) {
    set.seed(456)
    df$mt_wt <- stats::rexp(2 * n, rate = 1)
  }
  df
}

utils::globalVariables(c("x", "y", "fill_key"))
