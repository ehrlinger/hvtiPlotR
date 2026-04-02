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
  .check_df(data)
  # When weight_col is provided, match_col presence is not required
  required_cols <- if (is.null(weight_col)) {
    c(score_col, group_col, match_col)
  } else {
    c(score_col, group_col, weight_col)
  }
  .check_cols(data, required_cols)
  if (length(group_levels) != 2L)
    stop("`group_levels` must contain exactly 2 values.", call. = FALSE)
  if (length(group_labels) != 2L)
    stop("`group_labels` must contain exactly 2 values.", call. = FALSE)
  .check_numeric_col(data, score_col)
  if (!is.numeric(binwidth) || length(binwidth) != 1L || !(binwidth > 0))
    stop("`binwidth` must be a positive numeric scalar.", call. = FALSE)
  if (!is.null(weight_col)) {
    .check_numeric_col(data, weight_col)
    if (!all(data[[weight_col]] >= 0, na.rm = TRUE))
      stop(sprintf("`%s` must contain non-negative values.", weight_col),
           call. = FALSE)
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
    stop("No rows remain after filtering to `group_levels` and complete cases.",
         call. = FALSE)
  if (!(all(group_levels %in% unique(working$group))))
    stop("Not all `group_levels` are present in the filtered data.",
         call. = FALSE)
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
    stop("`output_file` must be a non-empty string.", call. = FALSE)
  target_dir <- dirname(output_file)
  if (target_dir %in% c("", ".")) target_dir <- "."
  if (!(dir.exists(target_dir)))
    stop(sprintf("Directory for `output_file` (%s) does not exist.",
                 target_dir), call. = FALSE)
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

#' Prepare mirror-histogram data for plotting
#'
#' Validates and assembles propensity-score distributions for a mirrored
#' histogram comparing a treated group (bars above the axis) and a control
#' group (bars below the axis), with optional matched and unmatched shading.
#' Returns an \code{hv_mirror_hist} object; call \code{\link{plot.hv_mirror_hist}}
#' on the result to obtain a bare \code{ggplot2} object.
#'
#' @param data             A data frame with one row per patient.
#' @param score_col        Name of the propensity-score column (0–1 scale
#'   before multiplier is applied). Default \code{"prob_t"}.
#' @param group_col        Name of the binary group-indicator column.
#'   Default \code{"tavr"}.
#' @param match_col        Name of the binary match-indicator column
#'   (1 = matched). Default \code{"match"}.
#' @param group_levels     Length-2 vector of the two values in
#'   \code{group_col} (control first, treated second).
#'   Default \code{c(0, 1)}.
#' @param group_labels     Length-2 character vector of display labels
#'   corresponding to \code{group_levels}.
#'   Default \code{c("SAVR", "TF-TAVR")}.
#' @param matched_value    Value in \code{match_col} that flags a matched
#'   patient.  Default \code{1}.
#' @param score_multiplier Scalar applied to \code{score_col} to convert to
#'   the 0–100 display scale.  Default \code{100}.
#' @param binwidth         Histogram bin width on the 0–100 scale. Default \code{5}.
#' @param weight_col       Optional name of an IPTW weight column.  When
#'   supplied, bar heights reflect weighted counts instead of raw counts.
#'
#' @return An object of class \code{c("hv_mirror_hist", "hv_data")}; call
#'   \code{plot()} on the result to render the figure — see
#'   \code{\link{plot.hv_mirror_hist}}.  The list contains:
#' \describe{
#'   \item{\code{$data}}{Tidy data frame of histogram bar coordinates for
#'     \code{\link{plot.hv_mirror_hist}}.}
#'   \item{\code{$meta}}{Named list: \code{score_col}, \code{group_col},
#'     \code{match_col}, \code{group_labels}, \code{binwidth}, \code{lower},
#'     \code{upper}, \code{y_breaks}, \code{n_obs}, \code{n_dropped}.}
#'   \item{\code{$tables}}{Named list with two elements:
#'     \describe{
#'       \item{\code{diagnostics}}{A named list of diagnostic summaries.
#'         Always contains \code{n_input}, \code{n_analyzed},
#'         \code{n_dropped_missing_or_other_group},
#'         \code{group_counts_before} (table), \code{score_summary_before}
#'         (\code{by} object), and \code{smd_before} (numeric SMD).
#'         In binary-match mode, additionally contains
#'         \code{group_counts_matched}, \code{matched_rate_by_group},
#'         \code{score_summary_matched}, and \code{smd_matched}.
#'         In weighted IPTW mode, additionally contains
#'         \code{effective_n_by_group} and \code{smd_weighted}.}
#'       \item{\code{working}}{The per-patient data frame after score
#'         rescaling and complete-case filtering, used for custom
#'         downstream diagnostics.}
#'     }
#'   }
#' }
#'
#' @seealso \code{\link{plot.hv_mirror_hist}} to render as a ggplot2 figure,
#'   \code{\link{hv_theme}} for the publication theme,
#'   \code{\link{sample_mirror_histogram_data}} for example data.
#'
#' @family Propensity Score & Matching
#'
#' @concept mirrored histogram propensity score overlap matching IPTW weighting mirror_histogram
#'
#' @examples
#' dta <- sample_mirror_histogram_data(n = 500, separation = 1.5)
#'
#' # 1. Build data object
#' mh <- hv_mirror_hist(dta)
#' mh                    # print diagnostics summary
#' mh$tables$diagnostics # full diagnostics list
#'
#' # 2. Bare plot -- undecorated ggplot returned by plot.hv_mirror_hist
#' p <- plot(mh)
#'
#' # 3. Decorate: axis labels and theme
#' p +
#'   ggplot2::labs(x = "Propensity Score (%)", y = "Count") +
#'   hv_theme("poster")
#'
#' @importFrom rlang .data
#' @export
hv_mirror_hist <- function(data,
                        score_col        = "prob_t",
                        group_col        = "tavr",
                        match_col        = "match",
                        group_levels     = c(0, 1),
                        group_labels     = c("SAVR", "TF-TAVR"),
                        matched_value    = 1,
                        score_multiplier = HVTI_SCORE_DEFAULT_MULTIPLIER,
                        binwidth         = 5,
                        weight_col       = NULL) {

  validate_mirror_histogram_input(data, score_col, group_col, match_col,
                                  group_levels, group_labels, binwidth,
                                  weight_col = weight_col)

  # --- Data preparation -----------------------------------------------------
  prep      <- prepare_mirror_histogram_data(data, score_col, group_col,
                                             match_col, group_levels,
                                             score_multiplier,
                                             weight_col = weight_col)
  working   <- prep$working
  n_input   <- prep$n_input
  n_dropped <- prep$n_dropped

  # --- Build plot data frame ------------------------------------------------
  breaks <- seq(HVTI_SCORE_MIN, HVTI_SCORE_MAX, by = binwidth)
  if (utils::tail(breaks, 1L) < HVTI_SCORE_MAX)
    breaks <- c(breaks, HVTI_SCORE_MAX)

  plot_info   <- assemble_mirror_histogram_plot_df(working, group_levels,
                                                   group_labels, matched_value,
                                                   breaks,
                                                   weight_col = weight_col)
  plot_df     <- plot_info$plot_df
  matched_idx <- plot_info$matched_idx

  # --- Y-axis bounds (stored so plot() can use them without recomputing) ----
  ymax     <- max(plot_df$y[plot_df$y >= 0], 0)
  ymin     <- min(plot_df$y[plot_df$y <= 0], 0)
  upper    <- ymax + max(1, ceiling(HVTI_SCORE_MARGIN_RATIO * ymax))
  lower    <- ymin - max(1, ceiling(HVTI_SCORE_MARGIN_RATIO * abs(ymin)))
  y_breaks <- pretty(c(lower, upper), n = 8)

  # --- Diagnostics ----------------------------------------------------------
  diagnostics <- mirror_histogram_diagnostics(working, matched_idx,
                                              group_levels, n_input, n_dropped)

  message(sprintf(
    "mirror_histogram diagnostics: n=%d  dropped=%d  [see $tables$diagnostics]",
    n_input, n_dropped
  ))

  new_hv_data(
    data = plot_df,
    meta = list(
      score_col    = score_col,
      group_col    = group_col,
      match_col    = match_col,
      group_levels = group_levels,
      group_labels = group_labels,
      binwidth     = binwidth,
      lower        = lower,
      upper        = upper,
      y_breaks     = y_breaks,
      n_obs        = n_input,
      n_dropped    = n_dropped
    ),
    tables = list(
      diagnostics = diagnostics,
      working     = working
    ),
    subclass = "hv_mirror_hist"
  )
}


#' Print an hv_mirror_hist object
#'
#' @param x   An \code{hv_mirror_hist} object from \code{\link{hv_mirror_hist}}.
#' @param ... Ignored.
#' @return \code{x}, invisibly.
#' @export
print.hv_mirror_hist <- function(x, ...) {
  m <- x$meta
  cat("<hv_mirror_hist>\n")
  cat(sprintf("  Groups      : %s (control) vs %s (treated)\n",
              m$group_labels[1L], m$group_labels[2L]))
  cat(sprintf("  Score col   : %s\n", m$score_col))
  cat(sprintf("  Match col   : %s\n", m$match_col))
  cat(sprintf("  N obs       : %d  (dropped: %d)\n", m$n_obs, m$n_dropped))
  cat(sprintf("  Bin width   : %g\n", m$binwidth))
  cat(sprintf("  Y range     : [%g, %g]\n", m$lower, m$upper))
  cat("  $tables     : diagnostics, working\n")
  invisible(x)
}


#' Plot an hv_mirror_hist object
#'
#' Builds a bare mirrored-histogram \code{ggplot2} object from an
#' \code{\link{hv_mirror_hist}} data object.  Bars for the treated group
#' appear above the x-axis; bars for the control group appear below.  Matched
#' or weighted patients are shown in a contrasting shade.  Compose with
#' \code{+} to add colour scales, axis labels, and \code{\link{hv_theme}}.
#'
#' @param x     An \code{hv_mirror_hist} object from
#'   \code{\link{hv_mirror_hist}}.
#' @param alpha Bar transparency in \eqn{[0,1]}.  Default \code{0.8}.
#' @param ...   Ignored; present for S3 consistency.
#'
#' @return A bare \code{\link[ggplot2]{ggplot}} object; compose with \code{+}
#'   to add colour scales, axis limits, labels, and
#'   \code{\link{hv_theme}}.
#'
#' @seealso \code{\link{hv_mirror_hist}} to build the data object,
#'   \code{\link{hv_theme}} for the publication theme,
#'   \code{\link{sample_mirror_histogram_data}} for example data.
#'
#' @family Propensity Score & Matching
#'
#' @examples
#' dta <- sample_mirror_histogram_data(n = 500)
#' mh  <- hv_mirror_hist(dta)
#'
#' plot(mh) +
#'   ggplot2::labs(x = "Propensity Score (%)", y = "Count") +
#'   hv_theme("poster")
#'
#' @importFrom ggplot2 ggplot aes geom_bar scale_x_continuous scale_y_continuous
#' @export
plot.hv_mirror_hist <- function(x, alpha = 0.8, ...) {
  .check_alpha(alpha)
  build_mirror_histogram_plot(
    x$data,
    x$meta$group_labels,
    x$meta$binwidth,
    x$meta$lower,
    x$meta$upper,
    x$meta$y_breaks,
    alpha
  )
}

# ---------------------------------------------------------------------------
# Sample data
# ---------------------------------------------------------------------------

#' Generate Sample Data for Mirrored Histogram
#'
#' Creates a reproducible data frame for testing [hv_mirror_hist()]
#' in either binary-match or weighted IPTW mode.  Propensity scores are
#' simulated via a logistic model: control subjects draw their linear predictor
#' from \eqn{N(-\text{sep}/2, 1)} and treated subjects from
#' \eqn{N(+\text{sep}/2, 1)}, so the two score distributions overlap in the
#' centre while accumulating mass at opposite extremes.  Patients at those
#' extremes cannot find a matching partner within the caliper, which naturally
#' reproduces the "many unmatched at the tails" pattern seen in real studies.
#'
#' @param n Number of observations **per group** (default 500).
#' @param separation Numeric. Distance between the two group means on the
#'   log-odds scale.  Larger values push the score distributions further apart
#'   and increase the proportion of unmatched patients at the extremes
#'   (default 1.5).
#' @param caliper Matching caliper width expressed in propensity-score units
#'   (0–1 scale, default 0.05).  Treated patients without a control partner
#'   within this distance are left unmatched.
#' @param seed Integer random seed for reproducibility (default 42L).
#' @param add_weights Logical. When `TRUE` an `mt_wt` column of
#'   ATE-style IPTW weights derived from the simulated propensity scores is
#'   appended and normalised to mean 1 within each group (default `FALSE`).
#'
#' @return Data frame with columns:
#'   \describe{
#'     \item{`prob_t`}{Propensity score on the 0–1 scale.}
#'     \item{`tavr`}{Group indicator (0 = control, 1 = treated).}
#'     \item{`match`}{Binary match indicator produced by greedy
#'       nearest-neighbour matching within `caliper` (1 = matched).}
#'     \item{`mt_wt`}{(Only when `add_weights = TRUE`) ATE IPTW
#'       weights normalised to mean 1 within each group.}
#'   }
#'
#' @seealso [hv_mirror_hist()]
#'
#' @examples
#' # Binary-match mode sample data (default)
#' dta <- sample_mirror_histogram_data(n = 500, separation = 1.5)
#' head(dta)
#' table(dta$tavr, dta$match)   # matched vs unmatched counts per group
#'
#' # IPTW weighted mode — adds mt_wt column
#' dta_wt <- sample_mirror_histogram_data(n = 500, add_weights = TRUE)
#' head(dta_wt)
#' tapply(dta_wt$mt_wt, dta_wt$tavr, mean)  # should be ~1 in each group
#'
#' @importFrom stats rnorm plogis
#' @export
sample_mirror_histogram_data <- function(n          = 500,
                                         separation = 1.5,
                                         caliper    = 0.05,
                                         seed       = 42L,
                                         add_weights = FALSE) {
  if (!is.numeric(n) || length(n) != 1L || n < 1L || n %% 1 != 0)
    stop("`n` must be a positive integer.", call. = FALSE)
  if (!is.numeric(separation) || length(separation) != 1L ||
      !(separation > 0))
    stop("`separation` must be a positive number.", call. = FALSE)
  if (!is.numeric(caliper) || length(caliper) != 1L ||
      !(caliper > 0 && caliper <= 1))
    stop("`caliper` must be a number in (0, 1].", call. = FALSE)
  if (!is.logical(add_weights) || length(add_weights) != 1L)
    stop("`add_weights` must be TRUE or FALSE.", call. = FALSE)

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

