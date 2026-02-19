###############################################################################
## Reusable mirrored histogram for propensity score distributions.
## Darkened bars represent matched patients.
###############################################################################
## created using data in:
## /studies/cardiac/valves/aortic/replacement/partner_publication_office/partner_12s3/all/stroke/tavr_savr/
##
##############################################################################
## To run this...
## Read your data....
# dta <- haven::read_xpt("../datasets/tav_mtch.xpt")
#
## make all columns lower case, because R is case sensitive.
# names(dta) <- tolower(names(dta))
#
## Create and save the plot... arguments depend on your data.
# result <- plot_mirror_propensity_histogram(
#   data = dta,
#   score_col = "prob_t",
#   group_col = "tavr",
#   match_col = "match",
#   group_levels = c(0, 1),
#   group_labels = c("SAVR", "TF-TAVR"),
#   matched_value = 1,
#   output_file = "../graphs/lp_mirror-hist-SAVR_TF-TAVR.pdf"
# )
#
# print(result$plot)
# print(result$diagnostics)
# }
###############################################################################

library(ggplot2)

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
  
  # Check for sufficient data in both groups
  if (length(g0) < 2 || length(g1) < 2) {
    return(NA_real_)
  }
  
  # Calculate pooled standard deviation
  pooled_sd <- sqrt((stats::var(g0) + stats::var(g1)) / 2)
  
  # Handle edge cases for pooled_sd
  if (is.na(pooled_sd) || pooled_sd == 0) {
    return(0)
  }
  
  # Return standardized mean difference
  (mean(g1) - mean(g0)) / pooled_sd
}

##' Build Histogram Counts
##'
##' Helper function to compute histogram bin midpoints and counts for a numeric vector.
##'
##' @param x Numeric vector to bin.
##' @param breaks Numeric vector of break points for bins.
##' @return Data frame with columns `x` (bin midpoints) and `count` (counts per bin).
##' @keywords internal
build_hist_counts <- function(x, breaks) {
  # Compute histogram without plotting
  h <- hist(
    x,
    breaks = breaks,
    plot = FALSE,
    right = FALSE,
    include.lowest = TRUE
  )
  # Return data frame of bin midpoints and counts
  data.frame(x = h$mids, count = h$counts)
}

# Internal: Validate input for mirrored histogram
validate_mirror_histogram_input <- function(data, score_col, group_col, match_col, group_levels, group_labels, binwidth) {
  if (!is.data.frame(data)) {
    stop("`data` must be a data.frame.")
  }
  required_cols <- c(score_col, group_col, match_col)
  missing_cols <- setdiff(required_cols, names(data))
  if (length(missing_cols) > 0) {
    stop(sprintf(
      "Missing required columns: %s",
      paste(missing_cols, collapse = ", ")
    ))
  }
  if (length(group_levels) != 2 || length(group_labels) != 2) {
    stop("`group_levels` and `group_labels` must each contain exactly 2 values.")
  }
  if (!is.numeric(data[[score_col]])) {
    stop(sprintf("`%s` must be numeric.", score_col))
  }
  if (!is.numeric(binwidth) || length(binwidth) != 1 || binwidth <= 0) {
    stop("`binwidth` must be a positive numeric scalar.")
  }
}

# Internal: Prepare and filter data for mirrored histogram
prepare_mirror_histogram_data <- function(data, score_col, group_col, match_col, group_levels, score_multiplier) {
  working <- data.frame(score_raw = data[[score_col]],
                        group = data[[group_col]],
                        matched = data[[match_col]])
  n_input <- nrow(working)
  working <- working[stats::complete.cases(working), ]
  n_dropped <- n_input - nrow(working)
  working <- working[working$group %in% group_levels, ]
  if (nrow(working) == 0) {
    stop("No rows remain after filtering to `group_levels` and complete cases.")
  }
  if (!all(group_levels %in% unique(working$group))) {
    stop("Not all `group_levels` are present in the filtered data.")
  }
  working$score <- working$score_raw * score_multiplier
  if (any(working$score < HVTI_SCORE_MIN | working$score > HVTI_SCORE_MAX)) {
    stop(
      sprintf(
        "Scaled propensity scores must lie in [%d, %d]. Check `score_multiplier` and score values.",
        HVTI_SCORE_MIN,
        HVTI_SCORE_MAX
      )
    )
  }
  list(working = working, n_input = n_input, n_dropped = n_dropped)
}

# Internal: Assemble histogram data for plotting
assemble_mirror_histogram_plot_df <- function(working, group_levels, group_labels, matched_value, breaks) {
  g0 <- working$group == group_levels[1]
  g1 <- working$group == group_levels[2]
  matched_idx <- working$matched == matched_value
  before0 <- working$score[g0]
  before1 <- working$score[g1]
  after0 <- working$score[g0 & matched_idx]
  after1 <- working$score[g1 & matched_idx]
  b0 <- build_hist_counts(before0, breaks)
  b1 <- build_hist_counts(before1, breaks)
  a0 <- build_hist_counts(after0, breaks)
  a1 <- build_hist_counts(after1, breaks)
  plot_df <- rbind(
    data.frame(
      x = b0$x,
      y = b0$count,
      group = group_labels[1],
      layer = "Before",
      fill_key = "before_g0"
    ),
    data.frame(
      x = a0$x,
      y = a0$count,
      group = group_labels[1],
      layer = "Matched",
      fill_key = "matched_g0"
    ),
    data.frame(
      x = b1$x,
      y = -b1$count,
      group = group_labels[2],
      layer = "Before",
      fill_key = "before_g1"
    ),
    data.frame(
      x = a1$x,
      y = -a1$count,
      group = group_labels[2],
      layer = "Matched",
      fill_key = "matched_g1"
    )
  )
  list(plot_df = plot_df, matched_idx = matched_idx)
}

# Internal: Build ggplot object for mirrored histogram
build_mirror_histogram_plot <- function(plot_df, group_labels, binwidth, lower, upper, y_breaks) {
  ggplot() +
    geom_hline(yintercept = 0,
               linewidth = 0.7,
               color = "black") +
    geom_col(
      data = plot_df[plot_df$layer == "Before", ],
      aes(x = x, y = y, fill = fill_key),
      width = binwidth * HVTI_SCORE_FILL_RATIO,
      color = "black"
    ) +
    geom_col(
      data = plot_df[plot_df$layer == "Matched", ],
      aes(x = x, y = y, fill = fill_key),
      width = binwidth * HVTI_SCORE_FILL_RATIO,
      color = "black"
    ) +
    scale_fill_manual(
      values = c(
        before_g0 = "white",
        matched_g0 = "green1",
        before_g1 = "white",
        matched_g1 = "green4"
      ),
      guide = "none"
    ) +
    scale_x_continuous(
      limits = c(HVTI_SCORE_MIN, HVTI_SCORE_MAX),
      breaks = seq(HVTI_SCORE_MIN, HVTI_SCORE_MAX, HVTI_SCORE_BREAK_STEP)
    ) +
    scale_y_continuous(
      limits = c(lower, upper),
      breaks = y_breaks,
      labels = abs(y_breaks)
    ) +
    labs(x = "Propensity Score (%)", y = "Number of Patients") +
    annotate(
      "text",
      x = HVTI_ANNOTATION_X,
      y = upper * 0.80,
      label = group_labels[1],
      size = 6
    ) +
    annotate(
      "text",
      x = HVTI_ANNOTATION_X,
      y = lower * 0.80,
      label = group_labels[2],
      size = 6
    ) +
    coord_cartesian(clip = "off") +
    theme_minimal(base_size = 12)
}

# Internal: Compute diagnostics for mirrored histogram
mirror_histogram_diagnostics <- function(working, matched_idx, group_levels, n_input, n_dropped) {
  list(
    n_input = n_input,
    n_analyzed = nrow(working),
    n_dropped_missing_or_other_group = n_dropped +
      (n_input - n_dropped - nrow(working)),
    group_counts_before = table(working$group),
    group_counts_matched = table(working$group[matched_idx]),
    matched_rate_by_group = tapply(matched_idx, working$group, mean),
    score_summary_before = by(working$score, working$group, summary),
    score_summary_matched = by(working$score[matched_idx], working$group[matched_idx], summary),
    smd_before = calc_smd(working$score, working$group, group_levels),
    smd_matched = calc_smd(working$score[matched_idx], working$group[matched_idx], group_levels)
  )
}

#' Plot Mirrored Propensity Score Histogram
#' (Refactored for modularity)
#' @inheritParams plot_mirror_histogram
#' @export
plot_mirror_histogram <- function(data,
                                  score_col = "prob_t",
                                  group_col = "tavr",
                                  match_col = "match",
                                  group_levels = c(0, 1),
                                  group_labels = c("SAVR", "TF-TAVR"),
                                  matched_value = 1,
                                  score_multiplier = HVTI_SCORE_DEFAULT_MULTIPLIER,
                                  binwidth = 5,
                                  output_file = NULL,
                                  width = 8,
                                  height = 6) {
  validate_mirror_histogram_input(data, score_col, group_col, match_col, group_levels, group_labels, binwidth)
  prep <- prepare_mirror_histogram_data(data, score_col, group_col, match_col, group_levels, score_multiplier)
  working <- prep$working
  n_input <- prep$n_input
  n_dropped <- prep$n_dropped
  breaks <- seq(HVTI_SCORE_MIN, HVTI_SCORE_MAX, by = binwidth)
  if (utils::tail(breaks, 1) < HVTI_SCORE_MAX) {
    breaks <- c(breaks, HVTI_SCORE_MAX)
  }
  plot_info <- assemble_mirror_histogram_plot_df(working, group_levels, group_labels, matched_value, breaks)
  plot_df <- plot_info$plot_df
  matched_idx <- plot_info$matched_idx
  ymax <- max(plot_df$y[plot_df$y >= 0], 0)
  ymin <- min(plot_df$y[plot_df$y <= 0], 0)
  upper <- ymax + max(1, ceiling(HVTI_SCORE_MARGIN_RATIO * ymax))
  lower <- ymin - max(1, ceiling(HVTI_SCORE_MARGIN_RATIO * abs(ymin)))
  y_breaks <- pretty(c(lower, upper), n = 8)
  p <- build_mirror_histogram_plot(plot_df, group_labels, binwidth, lower, upper, y_breaks)
  diagnostics <- mirror_histogram_diagnostics(working, matched_idx, group_levels, n_input, n_dropped)
  if (!is.null(output_file)) {
    ggsave(
      filename = output_file,
      plot = p,
      width = width,
      height = height
    )
  }
  list(plot = p,
       diagnostics = diagnostics,
       data = working)
}

##' Generate Sample Data for Mirrored Histogram
##'
##' Creates a sample data frame suitable for testing plot_mirror_histogram.
##'
##' @param n Number of samples per group (default 100).
##' @return Data frame with columns: prob_t (numeric score), tavr (group), match (matched status)
##' @export
sample_mirror_histogram_data <- function(n = 100) {
  set.seed(123)
  # Generate scores for two groups
  group0_scores <- rbeta(n, 2, 5)
  group1_scores <- rbeta(n, 5, 2)
  # Assign group labels
  group <- c(rep(0, n), rep(1, n))
  prob_t <- c(group0_scores, group1_scores)
  # Simulate matched status (randomly assign ~60% matched)
  match <- rbinom(2 * n, 1, prob = HVTI_MATCH_PROBABILITY)
  data.frame(
    prob_t = prob_t,
    tavr = group,
    match = match
  )
}

utils::globalVariables(c("x", "y", "fill_key"))