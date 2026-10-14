###############################################################################
## Covariate balance plot for propensity score matching / IPTW analyses.
## Adapted from the tp.lp.propen.cov_balance.R template.
###############################################################################

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

cb_validate_input <- function(data, variable_col, group_col, std_diff_col) {
  .check_df(data)
  .check_cols(data, c(variable_col, group_col, std_diff_col))
  .check_numeric_col(data, std_diff_col)
}

cb_validate_params <- function(threshold, point_size, hline_linewidth,
                               vline_linewidth) {
  .check_scalar_nonneg(threshold,       "threshold")
  .check_scalar_positive(point_size,    "point_size")
  .check_scalar_positive(hline_linewidth, "hline_linewidth")
  .check_scalar_positive(vline_linewidth, "vline_linewidth")
}

cb_stat_labels <- c(
  smd            = "Standardized difference (%)",
  variance_ratio = "Variance ratio",
  ks             = "KS statistic"
)

cb_validate_stat_args <- function(vr_threshold, ks_threshold, group_labels) {
  if (!is.numeric(vr_threshold) || !length(vr_threshold) %in% 1:2 ||
      anyNA(vr_threshold) || any(vr_threshold <= 0))
    stop("`vr_threshold` must be one or two positive numbers.", call. = FALSE)
  if (!is.null(ks_threshold) &&
      (!is.numeric(ks_threshold) || length(ks_threshold) != 1L ||
       is.na(ks_threshold) || ks_threshold < 0 || ks_threshold > 1))
    stop("`ks_threshold` must be NULL or a single number in [0, 1].", call. = FALSE)
  if (!is.character(group_labels) || length(group_labels) != 2L || anyNA(group_labels))
    stop("`group_labels` must be a length-2 character vector.", call. = FALSE)
}

# Add the canonical statistic and pair columns, keep only the requested stats
# and fix factor levels so facets follow `stats` and first-appearance order.
# A caller's own `stat` / `pair` column is never touched: when one exists that
# is not the source column, the canonical values go in `.cb_stat` / `.cb_pair`.
# Returns the data plus the column names actually used.
cb_add_stat_pair <- function(working, stat_col, pair_col, stats) {
  # The fallback name must itself be unused, or it would overwrite a caller column.
  own <- function(nm, src) {
    if (!nm %in% names(working) || identical(src, nm)) return(nm)
    taken <- make.unique(c(names(working), paste0(".cb_", nm)))
    taken[length(taken)]
  }
  stat_var <- own("stat", stat_col)
  pair_var <- own("pair", pair_col)

  working[[stat_var]] <- if (is.null(stat_col)) "smd" else as.character(working[[stat_col]])
  working[[pair_var]] <- if (is.null(pair_col)) NA_character_ else as.character(working[[pair_col]])

  unknown <- setdiff(unique(working[[stat_var]]), names(cb_stat_labels))
  if (length(unknown))
    stop(sprintf(
      "`stat_col` holds unknown statistic(s): %s. Expected smd, variance_ratio or ks.",
      paste(unknown, collapse = ", ")), call. = FALSE)
  absent <- setdiff(stats, working[[stat_var]])
  if (length(absent))
    stop(sprintf("`stats` asks for %s, but `data` has no rows for it.",
                 paste(absent, collapse = " and ")), call. = FALSE)

  working <- working[working[[stat_var]] %in% stats, , drop = FALSE]
  working[[stat_var]] <- factor(working[[stat_var]], levels = stats)
  if (!is.null(pair_col))
    working[[pair_var]] <- factor(working[[pair_var]], levels = unique(working[[pair_var]]))
  list(data = working, stat_var = stat_var, pair_var = pair_var)
}

# Solid and dotted reference lines, one row per line, tagged with the stat
# column so each lands only in its own facet. With no stat facet the extra
# column is ignored.
cb_ref_lines <- function(stats, stat_var, threshold, vr_threshold, ks_threshold) {
  solid_x <- c(smd = 0, variance_ratio = 1, ks = 0)
  dotted  <- list(smd = c(-threshold, threshold), variance_ratio = vr_threshold,
                  ks = ks_threshold)
  lvl <- function(s) factor(s, levels = stats)
  tag <- function(s, x) {
    out <- data.frame(x = x)
    out[[stat_var]] <- lvl(s)
    out
  }
  list(
    solid  = tag(stats, unname(solid_x[stats])),
    dotted = do.call(rbind, lapply(stats, function(s) {
      if (length(dotted[[s]])) tag(s, dotted[[s]])
    }))
  )
}

#' @importFrom rlang .data
#' @importFrom ggplot2 ggplot aes geom_vline geom_hline geom_point scale_y_continuous
#' @importFrom ggplot2 facet_grid vars labeller as_labeller
cb_build_plot <- function(data, std_diff_col, group_col, var_levels,
                          threshold, stats, pairs, stat_var, pair_var,
                          vr_threshold, ks_threshold,
                          point_size, alpha,
                          hline_linetype, hline_linewidth,
                          vline_linewidth, threshold_linetype) {
  n_vars <- length(var_levels)
  # Extra vertical space (in "covariate rows") above the top row to ensure
  # room for point glyphs and potential multi-line labels/annotations.
  y_padding <- 1.75
  refs <- cb_ref_lines(stats, stat_var, threshold, vr_threshold, ks_threshold)

  p <- ggplot2::ggplot(data) +
    # Solid center reference: 0 for SMD and KS, 1 for the variance ratio
    ggplot2::geom_vline(
      data = refs$solid, ggplot2::aes(xintercept = .data[["x"]]),
      linewidth = vline_linewidth, color = "black"
    )
  if (!is.null(refs$dotted))
    # Dotted threshold reference lines
    p <- p + ggplot2::geom_vline(
      data = refs$dotted, ggplot2::aes(xintercept = .data[["x"]]),
      linetype = threshold_linetype, color = "black"
    )

  p <- p +
    # Dashed horizontal guides, one per covariate row
    ggplot2::geom_hline(
      yintercept = seq_len(n_vars),
      linetype   = hline_linetype,
      linewidth  = hline_linewidth,
      color      = "black"
    ) +
    # Points: shape and color mapped to group; no defaults applied
    ggplot2::geom_point(
      ggplot2::aes(
        x      = .data[[std_diff_col]],
        y      = .data[["cb_index"]],
        shape  = .data[[group_col]],
        color  = .data[[group_col]]
      ),
      size  = point_size,
      alpha = alpha
    ) +
    # Y-axis: integer positions labeled with covariate names
    ggplot2::scale_y_continuous(
      limits = c(0, n_vars + y_padding),
      breaks = seq_len(n_vars),
      labels = var_levels
    )

  # Named vars() keep the facet variable called `stat`, which the labeller
  # looks up by name, whatever column holds it.
  facet_rows <- if (length(pairs) > 1L) ggplot2::vars(pair = .data[[pair_var]])
  facet_cols <- if (length(stats) > 1L) ggplot2::vars(stat = .data[[stat_var]])
  if (!is.null(facet_rows) || !is.null(facet_cols))
    p <- p + ggplot2::facet_grid(
      rows     = facet_rows,
      cols     = facet_cols,
      scales   = "free_x",
      labeller = ggplot2::labeller(stat = ggplot2::as_labeller(cb_stat_labels))
    )
  p
}

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

#' Prepare covariate balance data for plotting
#'
#' Validates and orders a long-format standardized-mean-difference data frame
#' for a covariate balance plot, and returns an \code{hv_balance} object.
#' Call \code{\link{plot.hv_balance}} on the result to obtain a bare
#' \code{ggplot2} object that you can decorate with color, shape, axis scales,
#' and \code{\link{theme_hv_manuscript}}.
#'
#' Instead of a long data frame, \code{data} may be a \code{cobalt::bal.tab()}
#' result, a multi-category \code{bal.tab} (one facet row per pair), an
#' hvtiRpropensity \code{ps_match()} / \code{ps_weight()} object, or a list of
#' any one of those, one per imputation. In those cases the SMD is multiplied
#' by 100 and the \code{*_col} arguments are ignored.
#'
#' A \code{bal.tab()} result must be built with \code{binary = "std"} and
#' \code{continuous = "std"} (the default), so every difference is
#' standardized, and with \code{un = TRUE} to draw the Before group: cobalt
#' leaves the unadjusted columns empty otherwise, and \code{hv_balance()} then
#' says so in a message and draws the After group only. Ask for the variance
#' ratio and KS statistic with \code{stats = c("m", "v", "ks")}; the variance
#' ratio is undefined for binary covariates, so those rows are left out of its
#' panel. A distance or \code{prop.score} row (\code{Type} "Distance") is drawn
#' as a covariate row, as in \code{cobalt::love.plot()}. \code{ps_*} objects
#' carry standardized differences only.
#'
#' A list is pooled across imputations: SMD and KS statistic are averaged,
#' the variance ratio takes the geometric mean, and an \code{NA} in any
#' imputation makes the pooled value \code{NA} (counted in
#' \code{$meta$n_missing}). Every imputation must have the same rows.
#'
#' @param data         A data frame in \strong{long format} with one row per
#'   covariate \eqn{\times} group combination.  Wide-format data must be
#'   reshaped first (e.g. with \code{tidyr::pivot_longer()}).  It may instead
#'   be a \code{cobalt::bal.tab()} result (built with \code{un = TRUE} to draw
#'   the Before group), an hvtiRpropensity \code{ps_*} object, or a list of
#'   those, one per imputation; see Details.
#' @param variable_col Name of the column containing covariate labels.
#'   Default \code{"variable"}.
#' @param group_col    Name of the column identifying the comparison group
#'   (e.g. \code{"Before match"} / \code{"After match"}).
#'   Default \code{"group"}.
#' @param std_diff_col Name of the numeric column holding standardized mean
#'   difference values.  Default \code{"std_diff"}.
#' @param var_levels   Character vector controlling the display order of
#'   covariates on the y-axis.  The first element appears at the bottom.
#'   Defaults to the order of first appearance in \code{data[[variable_col]]}.
#' @param threshold    Numeric; absolute SMD value at which dotted reference
#'   lines are drawn (\eqn{\pm}\code{threshold}).  Default \code{10}.
#' @param stat_col     Optional name of a column holding the statistic each row
#'   reports: \code{"smd"}, \code{"variance_ratio"} or \code{"ks"}.  When
#'   \code{NULL} (default) every row is treated as \code{"smd"}.
#' @param pair_col     Optional name of a column identifying the comparison
#'   (e.g. \code{"B vs. A"}) when more than two groups were compared.  Default
#'   \code{NULL} (a single comparison).
#' @param stats        Character vector of statistics to keep, in panel order;
#'   any of \code{"smd"}, \code{"variance_ratio"}, \code{"ks"}.  Default
#'   \code{"smd"}.  An error is raised if a requested statistic has no rows.
#' @param vr_threshold One or two positive numbers; reference lines for the
#'   variance-ratio panel.  Default \code{c(0.5, 2)}.
#' @param ks_threshold \code{NULL} (no line, default) or a single number in
#'   \eqn{[0,1]}; reference line for the KS panel.
#' @param group_labels Length-2 character vector naming the before and after
#'   groups.  Default \code{c("Before", "After")}.
#'
#' @return An object of class \code{c("hv_balance", "hv_data")}: a list
#'   with three elements:
#' \describe{
#'   \item{\code{$data}}{The input data frame with a \code{cb_index} column
#'     added for y-axis positioning, a \code{stat} factor (levels =
#'     \code{stats}) and a \code{pair} column (\code{NA} when there are no
#'     comparisons, otherwise a factor in order of first appearance). If
#'     \code{data} already has its own \code{stat} or \code{pair} column it is
#'     left untouched and these values go in \code{.cb_stat} / \code{.cb_pair}.}
#'   \item{\code{$meta}}{Named list: \code{variable_col}, \code{group_col},
#'     \code{std_diff_col}, \code{var_levels}, \code{threshold},
#'     \code{n_vars}, \code{n_groups}, \code{stats}, \code{pairs},
#'     \code{stat_var} and \code{pair_var} (the names of the columns holding
#'     the statistic and the comparison), \code{n_imputations},
#'     \code{vr_threshold}, \code{ks_threshold}, \code{suggested_height}.}
#'   \item{\code{$tables}}{Empty list (no accessory tables).}
#' }
#'
#' @seealso Worked recipe with rendered output:
#'   \url{https://ehrlinger.github.io/hvtiGraphics/balance.html}.
#' @seealso \code{\link{plot.hv_balance}},
#'   \code{\link{sample_covariate_balance_data}}
#'
#' @examples
#' library(ggplot2)
#' dta <- sample_covariate_balance_data()
#'
#' # 1. Build data object
#' cb <- hv_balance(dta)
#' cb  # prints variable count, group count, threshold
#'
#' # 2. Bare plot -- undecorated ggplot returned by plot.hv_balance
#' p <- plot(cb)
#'
#' # 3. Decorate: color/shape palettes, x-axis range, labels, theme
#' p +
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
#'   theme_hv_poster()
#'
#' # 4. From a cobalt::bal.tab() result: SMD, variance ratio and KS panels
#' if (requireNamespace("cobalt", quietly = TRUE)) {
#'   lal <- cobalt::lalonde
#'   ps  <- fitted(glm(treat ~ age + educ + race + married + nodegree + re74 + re75,
#'                     data = lal, family = binomial()))
#'   bt <- cobalt::bal.tab(
#'     treat ~ age + educ + race + married + nodegree + re74 + re75,
#'     data = lal, weights = ifelse(lal$treat == 1, 1 / ps, 1 / (1 - ps)),
#'     binary = "std", s.d.denom = "pooled", stats = c("m", "v", "ks"), un = TRUE
#'   )
#'   plot(hv_balance(bt, stats = c("smd", "variance_ratio", "ks")))
#' }
#'
#' @export
hv_balance <- function(
  data,
  variable_col = "variable",
  group_col    = "group",
  std_diff_col = "std_diff",
  var_levels   = NULL,
  threshold    = 10,
  stat_col     = NULL,
  pair_col     = NULL,
  stats        = "smd",
  vr_threshold = c(0.5, 2),
  ks_threshold = NULL,
  group_labels = c("Before", "After")
) {
  stats <- unique(match.arg(stats, names(cb_stat_labels), several.ok = TRUE))
  cb_validate_stat_args(vr_threshold, ks_threshold, group_labels)

  n_imputations <- 1L
  long <- .cb_as_long(data, stats, group_labels)
  if (!is.null(long)) {
    data          <- long$data
    n_imputations <- long$n_imputations
    variable_col  <- "variable"
    group_col     <- "group"
    std_diff_col  <- "std_diff"
    stat_col      <- "stat"
    pair_col      <- "pair"
    # Two-group input has no comparisons: drop the all-NA column so the
    # label-completeness check does not reject it.
    if (all(is.na(data[["pair"]]))) {
      data[["pair"]] <- NULL
      pair_col <- NULL
    }
  }

  cb_validate_input(data, variable_col, group_col, std_diff_col)
  .check_cols(data, c(stat_col, pair_col))
  cb_validate_params(threshold, point_size = 3, hline_linewidth = 0.25,
                     vline_linewidth = 0.2)

  .check_complete_labels(data, c(variable_col, group_col, stat_col, pair_col))
  prepared <- cb_add_stat_pair(as.data.frame(data), stat_col, pair_col, stats)
  working  <- prepared$data
  incomplete <- .count_incomplete(working, std_diff_col)

  if (is.null(var_levels))
    var_levels <- unique(as.character(working[[variable_col]]))

  working[["cb_index"]] <- as.integer(
    factor(working[[variable_col]], levels = var_levels)
  )

  pairs <- if (is.null(pair_col)) character(0) else levels(working[[prepared$pair_var]])

  new_hv_data(
    data = working,
    meta = list(
      variable_col     = variable_col,
      group_col        = group_col,
      std_diff_col     = std_diff_col,
      var_levels       = var_levels,
      threshold        = threshold,
      n_vars           = length(var_levels),
      n_missing        = incomplete$n_missing,
      n_groups         = length(unique(working[[group_col]])),
      stats            = stats,
      pairs            = pairs,
      stat_var         = prepared$stat_var,
      pair_var         = prepared$pair_var,
      n_imputations    = n_imputations,
      vr_threshold     = vr_threshold,
      ks_threshold     = ks_threshold,
      suggested_height = hv_balance_height(length(var_levels),
                                           n_pairs = max(1L, length(pairs)))
    ),
    tables   = list(),
    subclass = "hv_balance"
  )
}


#' Print an hv_balance object
#'
#' @param x   An \code{hv_balance} object from \code{\link{hv_balance}}.
#' @param ... Ignored.
#' @return \code{x}, invisibly.
#' @export
print.hv_balance <- function(x, ...) {
  m <- x$meta
  cat("<hv_balance>\n")
  cat(sprintf("  Variables   : %d%s\n", m$n_vars,
              if (isTRUE(m$n_missing > 0L))
                sprintf("  [%d row(s) not drawn: missing values]", m$n_missing)
              else ""))
  cat(sprintf("  Groups      : %d (%s)\n", m$n_groups,
              paste(unique(x$data[[m$group_col]]), collapse = ", ")))
  cat(sprintf("  Value col   : %s\n", m$std_diff_col))
  cat(sprintf("  Threshold   : \u00b1%g\n", m$threshold))
  cat(sprintf("  Stats       : %s\n", paste(m$stats, collapse = ", ")))
  if (length(m$pairs))
    cat(sprintf("  Pairs       : %s\n", paste(m$pairs, collapse = ", ")))
  if (isTRUE(m$n_imputations > 1L))
    cat(sprintf("  Imputations : %d (mean)\n", m$n_imputations))
  cat(sprintf("  Height      : %.1f in at 12 pt (see hv_balance_height())\n",
              m$suggested_height))
  invisible(x)
}


#' Plot an hv_balance object
#'
#' Builds a bare covariate balance \code{ggplot2} object from an
#' \code{\link{hv_balance}} data object.  Each covariate appears as a
#' labeled row; points show the standardized mean difference per group.
#' A solid line marks zero; dotted lines mark \eqn{\pm}\code{threshold}.
#' Add color, shape, axis scales, and a theme with \code{+}.
#'
#' With more than one statistic, panels sit side by side (free x scales,
#' labeled strips); with more than one pair, each pair gets a facet row. The
#' variance ratio panel has a solid line at 1 and dotted lines at
#' \code{vr_threshold}, and the KS panel has a solid line at 0 plus
#' \code{ks_threshold} when given.
#'
#' @param x                  An \code{hv_balance} object.
#' @param point_size         Passed to \code{geom_point()}. Default \code{3}.
#' @param alpha              Point transparency in \eqn{[0,1]}. Default \code{0.8}.
#' @param hline_linetype     Linetype for horizontal covariate guides.
#'   Default \code{"dashed"}.
#' @param hline_linewidth    Linewidth for horizontal guides. Default \code{0.25}.
#' @param vline_linewidth    Linewidth for the zero reference line.
#'   Default \code{0.2}.
#' @param threshold_linetype Linetype for the \eqn{\pm}threshold lines.
#'   Default \code{"dotted"}.
#' @param ...                Ignored; present for S3 consistency.
#'
#' @return A bare \code{\link[ggplot2]{ggplot}} object.
#'
#' @seealso \code{\link{hv_balance}}, \code{\link{theme_hv_manuscript}}
#'
#' @examples
#' dta <- sample_covariate_balance_data()
#' cb  <- hv_balance(dta)
#'
#' plot(cb) +
#'   ggplot2::scale_color_manual(
#'     values = c("Before match" = "red4", "After match" = "blue3"),
#'     name   = NULL
#'   ) +
#'   ggplot2::labs(x = "Standardized difference (%)", y = "") +
#'   theme_hv_poster()
#'
#' @importFrom ggplot2 ggplot aes geom_vline geom_hline geom_point scale_y_continuous
#' @export
plot.hv_balance <- function(x,
                              point_size         = 3,
                              alpha              = 0.8,
                              hline_linetype     = "dashed",
                              hline_linewidth    = 0.25,
                              vline_linewidth    = 0.2,
                              threshold_linetype = "dotted",
                              ...) {
  .check_alpha(alpha)
  cb_validate_params(x$meta$threshold, point_size, hline_linewidth,
                     vline_linewidth)
  cb_build_plot(
    data               = x$data,
    std_diff_col       = x$meta$std_diff_col,
    group_col          = x$meta$group_col,
    var_levels         = x$meta$var_levels,
    threshold          = x$meta$threshold,
    stats              = x$meta$stats,
    pairs              = x$meta$pairs,
    stat_var           = x$meta$stat_var,
    pair_var           = x$meta$pair_var,
    vr_threshold       = x$meta$vr_threshold,
    ks_threshold       = x$meta$ks_threshold,
    point_size         = point_size,
    alpha              = alpha,
    hline_linetype     = hline_linetype,
    hline_linewidth    = hline_linewidth,
    vline_linewidth    = vline_linewidth,
    threshold_linetype = threshold_linetype
  )
}

#' Suggested figure height for a covariate balance plot
#'
#' Covariate labels overprint when a balance plot is drawn too short. This
#' returns a height that leaves about 0.17 in per covariate row at 12 pt,
#' plus room for the x axis, its title and a legend, scaled by `base_size`.
#'
#' @param n_rows    Number of covariate rows (`length(var_levels)`).
#' @param base_size Theme base font size in points. Default `12`.
#' @param n_pairs   Number of pairwise-comparison facet rows. Default `1`.
#'
#' @return Height in inches, a numeric scalar.
#'
#' @seealso [hv_balance()], whose `$meta$suggested_height` holds this value
#'   at `base_size = 12`.
#'
#' @examples
#' hv_balance_height(38)                 # about 8 in
#' hv_balance_height(38, base_size = 16)
#' hv_balance_height(12, n_pairs = 3)    # three-group design
#'
#' @export
hv_balance_height <- function(n_rows, base_size = 12, n_pairs = 1) {
  .check_scalar_positive(n_rows,    "n_rows")
  .check_scalar_positive(base_size, "base_size")
  .check_scalar_positive(n_pairs,   "n_pairs")
  s <- base_size / 12
  s * (0.17 * n_rows * n_pairs + 0.3 * (n_pairs - 1) + 1.5)
}

# ---------------------------------------------------------------------------
# Sample data generator
# ---------------------------------------------------------------------------

#' Generate Sample Covariate Balance Data
#'
#' Produces a reproducible long-format data frame suitable for testing and
#' demonstrating [hv_balance()].  Rather than drawing SMDs from
#' independent normals, this generator simulates patient-level covariates
#' through a logistic propensity score model, computes group standardized mean
#' differences before matching, then performs greedy 1:1 nearest-neighbor
#' caliper matching and computes residual differences in the matched cohort.
#'
#' The result captures the pattern seen in real studies: covariates that drive
#' treatment selection show large imbalance before matching; matching
#' substantially reduces imbalance, but patients at the propensity score
#' extremes cannot be matched, leaving small residual differences for the
#' strongest confounders.
#'
#' @param n_vars Integer; number of covariates to generate. Default `12`.
#' @param n Integer; total number of simulated patients before matching.
#'   Default `600` (roughly 300 per group at `separation = 1.5`).
#' @param separation Numeric; distance between the two group means on the
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
#' @family Propensity Score & Matching
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
  seed         = 42L
) {
  if (!is.numeric(n_vars) || length(n_vars) != 1L || n_vars < 1L ||
      n_vars %% 1 != 0)
    stop("`n_vars` must be a positive integer scalar.", call. = FALSE)
  if (!is.numeric(n) || length(n) != 1L || n < 2L || n %% 1 != 0)
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

  withr::local_seed(seed)

  # --- Patient-level simulation ----------------------------------------------
  # Covariate matrix: each column ~ N(0,1).
  # Beta coefficients ~ N(0, separation/sqrt(n_vars)) so total PS variance ~ 1.
  x_mat <- matrix(stats::rnorm(n * n_vars), nrow = n, ncol = n_vars)
  betas <- stats::rnorm(n_vars, mean = 0, sd = separation / sqrt(n_vars))

  # Center the linear predictor so ~50% of patients are treated.
  lp    <- drop(x_mat %*% betas)
  lp    <- lp - stats::median(lp)
  ps    <- stats::plogis(lp)
  treat <- stats::rbinom(n, 1L, ps)

  # --- SMDs before matching --------------------------------------------------
  smds_before <- vapply(seq_len(n_vars), function(j) {
    x0 <- x_mat[treat == 0, j]
    x1 <- x_mat[treat == 1, j]
    if (length(x0) < 2 || length(x1) < 2) return(NA_real_)
    pooled_sd <- sqrt((stats::var(x0) + stats::var(x1)) / 2)
    if (is.na(pooled_sd) || pooled_sd == 0) return(0)
    (mean(x1) - mean(x0)) / pooled_sd * 100
  }, numeric(1))

  # --- Greedy 1:1 nearest-neighbor caliper matching -------------------------
  # Patients with extreme PSs (far from 0.5) cannot find a partner within the
  # caliper, so they are excluded from the matched cohort.  This leaves
  # residual imbalance on the covariates most responsible for their extremity.
  idx0      <- which(treat == 0)
  idx1      <- which(treat == 1)

  if (!length(idx0) || !length(idx1)) {
    stop(
      "`treat` must contain at least one control (0) and one treated (1) ",
      "observation for matching.",
      call. = FALSE
    )
  }

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
  x_mc <- x_mat[idx0[m_ctrl], , drop = FALSE]
  x_mt <- x_mat[idx1[m_trt],  , drop = FALSE]

  smds_after <- vapply(seq_len(n_vars), function(j) {
    x0 <- x_mc[, j]
    x1 <- x_mt[, j]
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
