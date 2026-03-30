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
# the direct input to hvti_ordinal().
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
#     hvti_ordinal(long, data_points = dp_long)
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
#'   in ascending order. Default
#'   `c("Grade 0", "Grade 1", "Grade 2", "Grade 3")`.
#' @param n_bins       Number of equal-sized bins for the data summary points.
#'   Default `10`.
#' @param seed         Random seed. Default `42`.
#'
#' @return A long-format data frame: `time`, `estimate`, `grade` (factor).
#'   Individual grade probabilities sum to 1 at each time point.
#'
#' @seealso [hvti_ordinal()], [sample_nonparametric_curve_data()],
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

  a_first       <- 0.5
  a_step        <- 1.2
  eta_intercept <- -0.2

  t_grid <- exp(seq(log(0.01), log(max(time_max, 0.1)), length.out = n_points))

  a_raw <- cumsum(c(a_first, rep(a_step, n_grades - 2)))

  thalf1 <- time_max * 0.20
  thalf2 <- time_max * 0.60
  eta    <- .np_two_phase(t_grid, e0 = eta_intercept, thalf1 = thalf1, thalf2 = thalf2)

  cp <- matrix(NA_real_, nrow = n_points, ncol = n_grades - 1L)
  for (k in seq_len(n_grades - 1L)) {
    cp[, k] <- stats::plogis(a_raw[k] + eta)
  }

  prob <- matrix(NA_real_, nrow = n_points, ncol = n_grades)
  prob[, 1L] <- cp[, 1L]
  for (k in seq(2L, n_grades - 1L)) {
    prob[, k] <- cp[, k] - cp[, k - 1L]
  }
  prob[, n_grades] <- 1 - cp[, n_grades - 1L]
  prob <- pmax(prob, 0)

  curve_df <- do.call(rbind, lapply(seq_len(n_grades), function(k) {
    data.frame(time     = t_grid,
               estimate = prob[, k],
               grade    = grade_labels[k])
  }))
  curve_df$grade <- factor(curve_df$grade, levels = grade_labels)

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
#' @seealso [sample_nonparametric_ordinal_data()], [hvti_ordinal()]
#'
#' @examples
#' # Default: four grade levels
#' pts <- sample_nonparametric_ordinal_points(n = 800, time_max = 5)
#' head(pts)
#' levels(pts$grade)
#'
#' # Clinical AR grade labels
#' pts2 <- sample_nonparametric_ordinal_points(
#'   n            = 600,
#'   time_max     = 7,
#'   grade_labels = c("None", "Mild", "Moderate", "Severe")
#' )
#' table(pts2$grade)
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

  a_first       <- 0.5
  a_step        <- 1.2
  eta_intercept <- -0.2

  a_raw <- cumsum(c(a_first, rep(a_step, n_grades - 2)))

  thalf1 <- time_max * 0.20
  thalf2 <- time_max * 0.60

  t_pat   <- stats::runif(n, 0.01, time_max)
  eta_pat <- .np_two_phase(t_pat, e0 = eta_intercept, thalf1 = thalf1, thalf2 = thalf2)
  cp_pat  <- matrix(NA_real_, nrow = n, ncol = n_grades - 1L)
  for (k in seq_len(n_grades - 1L)) {
    cp_pat[, k] <- stats::plogis(a_raw[k] + eta_pat)
  }
  u_pat     <- stats::runif(n)
  grade_obs <- rowSums(u_pat > cbind(cp_pat, 1)) + 1L

  ord      <- order(t_pat)
  t_s      <- t_pat[ord]
  g_s      <- grade_obs[ord]
  bin      <- cut(seq_along(t_s), breaks = n_bins, labels = FALSE)
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
# Public API
# ============================================================================

#' Prepare nonparametric ordinal outcome curve data for plotting
#'
#' Validates pre-computed grade-specific probability curves (and optional
#' binned data summary points) and returns an \code{hvti_ordinal} object.
#' Call \code{\link{plot.hvti_ordinal}} on the result to obtain a bare
#' \code{ggplot2} multi-grade line plot that you can decorate with
#' colour scales and \code{\link{hvti_theme}}.
#'
#' **SAS column mapping (\code{predict} dataset after averaging):**
#' - \code{time} ← \code{iv_echo} (or \code{iv_wristm})
#' - \code{estimate} ← one of \code{p0}, \code{p1}, \code{p2}, \code{p3}
#'   (individual grade probs, after wide-to-long reshape)
#' - \code{grade} ← a new column created during the reshape
#'
#' @param curve_data  Long-format data frame: one row per (time, grade)
#'   combination. Columns: \code{x_col}, \code{estimate_col}, \code{grade_col}.
#' @param x_col       Name of the time column. Default \code{"time"}.
#' @param estimate_col Name of the predicted probability column.
#'   Default \code{"estimate"}.
#' @param grade_col   Name of the grade/category column. Default \code{"grade"}.
#' @param data_points Optional long-format data frame of binned data summary
#'   points. Must have columns matching \code{x_col}, \code{"value"}, and
#'   \code{grade_col}. Default \code{NULL}.
#'
#' @return An object of class \code{c("hvti_ordinal", "hvti_data")}:
#' \describe{
#'   \item{\code{$data}}{The \code{curve_data} data frame.}
#'   \item{\code{$meta}}{Named list: \code{x_col}, \code{estimate_col},
#'     \code{grade_col}, \code{n_obs}, \code{n_grades},
#'     \code{has_data_points}.}
#'   \item{\code{$tables}}{List; contains \code{data_points} when supplied.}
#' }
#'
#' @seealso \code{\link{plot.hvti_ordinal}},
#'   \code{\link{sample_nonparametric_ordinal_data}}
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
#' ord <- hvti_ordinal(dat, data_points = dat_pts)
#' ord  # prints grade count and data-point flag
#'
#' plot(ord) +
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
#' @importFrom rlang .data
#' @export
hvti_ordinal <- function(curve_data,
                          x_col        = "time",
                          estimate_col = "estimate",
                          grade_col    = "grade",
                          data_points  = NULL) {
  .check_df(curve_data, "curve_data")
  .check_cols(curve_data, c(x_col, estimate_col, grade_col), "curve_data")

  has_data_points <- !is.null(data_points)
  if (has_data_points) {
    .check_df(data_points, "data_points")
    .check_cols(data_points, c(x_col, "value", grade_col), "data_points")
  }

  n_grades <- length(unique(curve_data[[grade_col]]))
  tables   <- if (has_data_points) list(data_points = data_points) else list()

  new_hvti_data(
    data = as.data.frame(curve_data),
    meta = list(
      x_col           = x_col,
      estimate_col    = estimate_col,
      grade_col       = grade_col,
      n_obs           = nrow(curve_data),
      n_grades        = n_grades,
      has_data_points = has_data_points
    ),
    tables   = tables,
    subclass = "hvti_ordinal"
  )
}


#' Print an hvti_ordinal object
#'
#' @param x   An \code{hvti_ordinal} object from \code{\link{hvti_ordinal}}.
#' @param ... Ignored.
#' @return \code{x}, invisibly.
#' @export
print.hvti_ordinal <- function(x, ...) {
  m <- x$meta
  cat("<hvti_ordinal>\n")
  cat(sprintf("  N curve pts : %d  (%d grades)\n", m$n_obs, m$n_grades))
  cat(sprintf("  x / estimate / grade : %s / %s / %s\n",
              m$x_col, m$estimate_col, m$grade_col))
  cat(sprintf("  Data points : %s\n", if (m$has_data_points) "yes" else "no"))
  invisible(x)
}


#' Plot an hvti_ordinal object
#'
#' Draws grade-specific probability curves with an optional binned data
#' summary point overlay.
#'
#' @param x            An \code{hvti_ordinal} object.
#' @param line_width   Width of grade-specific curve lines. Default \code{1.0}.
#' @param point_size   Size of binned data summary points. Default \code{2.5}.
#' @param point_shape  Integer shape for summary points. Default \code{20}.
#' @param ...          Ignored; present for S3 consistency.
#'
#' @return A bare \code{\link[ggplot2]{ggplot}} object.
#'
#' @seealso \code{\link{hvti_ordinal}}, \code{\link{hvti_theme}}
#'
#' @examples
#' dat <- sample_nonparametric_ordinal_data(
#'   n = 800, time_max = 5,
#'   grade_labels = c("None", "Mild", "Moderate", "Severe")
#' )
#'
#' # Curves only, with RColorBrewer palette
#' plot(hvti_ordinal(dat)) +
#'   ggplot2::scale_colour_brewer(palette = "RdYlGn", direction = -1,
#'                                name = "AR Grade") +
#'   ggplot2::scale_x_continuous(breaks = 0:5) +
#'   ggplot2::scale_y_continuous(labels = scales::percent) +
#'   ggplot2::labs(x = "Years after Surgery", y = "Prevalence") +
#'   hvti_theme("manuscript")
#'
#' # Subset: show only severe grade
#' plot(hvti_ordinal(dat[dat$grade == "Severe", ])) +
#'   ggplot2::scale_colour_manual(values = c(Severe = "firebrick"),
#'                                guide  = "none") +
#'   ggplot2::scale_y_continuous(limits = c(0, 0.25),
#'                               labels = scales::percent) +
#'   ggplot2::labs(x = "Years", y = "P(Severe TR grade)") +
#'   hvti_theme("manuscript")
#'
#' @importFrom ggplot2 ggplot aes geom_line geom_point
#' @importFrom rlang .data
#' @export
plot.hvti_ordinal <- function(x,
                               line_width  = 1.0,
                               point_size  = 2.5,
                               point_shape = 20L,
                               ...) {
  curve_data   <- x$data
  m            <- x$meta
  x_col        <- m$x_col
  estimate_col <- m$estimate_col
  grade_col    <- m$grade_col

  p <- ggplot2::ggplot(
    curve_data,
    ggplot2::aes(x      = .data[[x_col]],
                 y      = .data[[estimate_col]],
                 colour = .data[[grade_col]],
                 group  = .data[[grade_col]])
  ) +
    ggplot2::geom_line(linewidth = line_width)

  if (m$has_data_points) {
    data_points <- x$tables$data_points
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
