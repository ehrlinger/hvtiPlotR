# spaghetti-plot.R
#
# Profile / spaghetti plot of repeated measurements per subject.
# Ports the pattern from tp.dp.spaghetti.echo.R (template graph library) to
# hvtiPlotR, replacing hard-coded colours with scale_ composition and
# explicit theme calls with hvtiPlotR themes.
#
# Key differences from the template:
#  - id_col / colour_col parameters replace hard-coded group = CCFID and
#    colour = factor(MALE) in every geom_line() call
#  - No hard-coded colour values; examples demonstrate scale_colour_manual()
#    and scale_colour_brewer()
#  - Optional LOESS/mean smooth overlay replaces a separate geom_smooth() call
#  - Ordinal y-axis labelling (plot_9 pattern) supported via y_labels parameter
#  - Theme applied via + hvti_theme("manuscript") in examples
# ---------------------------------------------------------------------------

#' Sample Spaghetti / Profile Plot Data
#'
#' Generates a realistic repeated-measures longitudinal data set for
#' demonstrating [hvti_spaghetti()]. Each row is one observation for one
#' patient at one time point, mimicking serial echocardiographic measurements
#' after cardiac surgery (AV mean gradient trajectory over follow-up).
#' Patients have an irregular number of follow-up measurements and a group
#' indicator (e.g. sex), matching the `b_echo.xpt` structure in the template.
#'
#' @param n_patients  Number of unique patients. Default `150`.
#' @param max_obs     Maximum number of observations per patient. Default `6`.
#' @param groups      Named character vector of group labels and their
#'   sampling probabilities (summing to 1). Default
#'   `c(Female = 0.45, Male = 0.55)`.
#' @param seed        Random seed for reproducibility. Default `42`.
#'
#' @return A data frame with columns:
#'   - `id`    — patient identifier (integer)
#'   - `time`  — years from index procedure (numeric)
#'   - `value` — continuous outcome (numeric; AV mean gradient in mmHg)
#'   - `group` — group label (factor)
#'
#' @seealso [hvti_spaghetti()]
#'
#' @examples
#' dta <- sample_spaghetti_data(n_patients = 100, seed = 42)
#' head(dta)
#' table(dta$group)
#' @export
sample_spaghetti_data <- function(n_patients = 150,
                                  max_obs    = 6,
                                  groups     = c(Female = 0.45, Male = 0.55),
                                  seed       = 42L) {
  set.seed(seed)

  group_labels <- names(groups)
  group_probs  <- unname(groups)

  patient_group <- sample(group_labels, n_patients, replace = TRUE,
                          prob = group_probs)

  # Baseline gradient higher for females in this simulation
  baseline_mu <- ifelse(patient_group == "Female", 18, 14)
  baseline    <- stats::rnorm(n_patients, mean = baseline_mu, sd = 6)
  # Patient-specific linear drift (most improve, some worsen)
  drift       <- stats::rnorm(n_patients, mean = 0.8, sd = 1.5)

  rows <- vector("list", n_patients)
  for (i in seq_len(n_patients)) {
    n_obs  <- sample(2L:max_obs, 1L)
    times  <- sort(round(stats::runif(n_obs, min = 0, max = 5), 2))
    values <- pmax(0, baseline[i] + drift[i] * times +
                     stats::rnorm(n_obs, sd = 3))
    rows[[i]] <- data.frame(
      id    = i,
      time  = times,
      value = round(values, 2),
      group = patient_group[i]
    )
  }

  dta       <- do.call(rbind, rows)
  dta$group <- factor(dta$group, levels = group_labels)
  dta
}

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

#' Prepare spaghetti / profile data for plotting
#'
#' Validates a long-format repeated-measures data frame and returns an
#' \code{hvti_spaghetti} object.  Call \code{\link{plot.hvti_spaghetti}} on
#' the result to obtain a bare \code{ggplot2} trajectory plot that you can
#' decorate with colour scales, axis labels, and \code{\link{hvti_theme}}.
#'
#' @param data       Data frame; one row per observation per subject.
#' @param x_col      Name of the time column. Default \code{"time"}.
#' @param y_col      Name of the outcome column. Default \code{"value"}.
#' @param id_col     Name of the subject-identifier column (used as the
#'   \code{group} aesthetic for line continuity). Default \code{"id"}.
#' @param colour_col Name of the column to map to line colour, or \code{NULL}
#'   for a single uniform colour. Default \code{NULL}.
#'
#' @return An object of class \code{c("hvti_spaghetti", "hvti_data")}:
#' \describe{
#'   \item{\code{$data}}{The validated input data frame.}
#'   \item{\code{$meta}}{Named list: \code{x_col}, \code{y_col},
#'     \code{id_col}, \code{colour_col}, \code{n_subjects},
#'     \code{n_obs}.}
#'   \item{\code{$tables}}{Empty list.}
#' }
#'
#' @seealso \code{\link{plot.hvti_spaghetti}},
#'   \code{\link{sample_spaghetti_data}}
#'
#' @examples
#' dta <- sample_spaghetti_data(n_patients = 150, seed = 42)
#' sp  <- hvti_spaghetti(dta, colour_col = "group")
#' sp   # prints subject count, observation count, column mapping
#'
#' plot(sp) +
#'   ggplot2::scale_colour_manual(
#'     values = c(Female = "firebrick", Male = "steelblue"), name = NULL
#'   ) +
#'   ggplot2::labs(x = "Years after Operation",
#'                 y = "AV Mean Gradient (mmHg)") +
#'   hvti_theme("manuscript")
#'
#' @importFrom rlang .data
#' @export
hvti_spaghetti <- function(data,
                           x_col      = "time",
                           y_col      = "value",
                           id_col     = "id",
                           colour_col = NULL) {
  .check_df(data)
  .check_cols(data, c(x_col, y_col, id_col))
  if (!is.null(colour_col))
    .check_col(data, colour_col)

  new_hvti_data(
    data = as.data.frame(data),
    meta = list(
      x_col      = x_col,
      y_col      = y_col,
      id_col     = id_col,
      colour_col = colour_col,
      n_subjects = length(unique(data[[id_col]])),
      n_obs      = nrow(data)
    ),
    tables   = list(),
    subclass = "hvti_spaghetti"
  )
}


#' Print an hvti_spaghetti object
#'
#' @param x   An \code{hvti_spaghetti} object from \code{\link{hvti_spaghetti}}.
#' @param ... Ignored.
#' @return \code{x}, invisibly.
#' @export
print.hvti_spaghetti <- function(x, ...) {
  m <- x$meta
  cat("<hvti_spaghetti>\n")
  cat(sprintf("  N subjects  : %d  (%d observations)\n",
              m$n_subjects, m$n_obs))
  cat(sprintf("  x / y / id  : %s / %s / %s\n",
              m$x_col, m$y_col, m$id_col))
  if (!is.null(m$colour_col))
    cat(sprintf("  Colour col  : %s\n", m$colour_col))
  invisible(x)
}


#' Plot an hvti_spaghetti object
#'
#' Draws one trajectory line per subject over time, optionally stratified by
#' colour and with a LOESS (or other) smooth overlay.
#'
#' @param x             An \code{hvti_spaghetti} object.
#' @param line_colour   Fixed line colour used when \code{colour_col = NULL}.
#'   Default \code{"grey50"}.
#' @param line_width    Line width for individual trajectories. Default \code{0.2}.
#' @param alpha         Transparency of plot elements in \eqn{[0,1]}.
#'   Default \code{0.8}.
#' @param add_smooth    Logical; overlay a smoother? Default \code{FALSE}.
#' @param smooth_method Smoothing method passed to
#'   \code{geom_smooth()}.  Default \code{"loess"}.
#' @param smooth_se     Logical; show CI ribbon around smooth?
#'   Default \code{FALSE}.
#' @param smooth_width  Line width for the smooth overlay. Default \code{1.2}.
#' @param y_labels      Named numeric vector for an ordinal y-axis, e.g.
#'   \code{c(None = 0, Mild = 1, Moderate = 2, Severe = 3)}.
#'   Default \code{NULL} (standard numeric axis).
#' @param ...           Ignored; present for S3 consistency.
#'
#' @return A bare \code{\link[ggplot2]{ggplot}} object.
#'
#' @seealso \code{\link{hvti_spaghetti}}, \code{\link{hvti_theme}}
#'
#' @examples
#' dta <- sample_spaghetti_data(n_patients = 150, seed = 42)
#' sp  <- hvti_spaghetti(dta, colour_col = "group")
#'
#' # With LOESS smooth overlay
#' plot(sp, add_smooth = TRUE) +
#'   ggplot2::scale_colour_brewer(palette = "Set1", name = NULL) +
#'   ggplot2::labs(x = "Years", y = "AV Mean Gradient (mmHg)") +
#'   hvti_theme("manuscript")
#'
#' # Ordinal y-axis
#' dta_ord <- dta
#' dta_ord$value <- round(pmin(3, pmax(0, dta$value / 12)))
#' plot(hvti_spaghetti(dta_ord, colour_col = "group"),
#'      y_labels = c(None = 0, Mild = 1, Moderate = 2, Severe = 3)) +
#'   ggplot2::labs(x = "Years", y = "MR Grade") +
#'   hvti_theme("manuscript")
#'
#' @importFrom ggplot2 ggplot aes geom_line geom_smooth scale_colour_identity
#'   scale_y_continuous
#' @importFrom rlang .data
#' @export
plot.hvti_spaghetti <- function(x,
                                line_colour   = "grey50",
                                line_width    = 0.2,
                                alpha         = 0.8,
                                add_smooth    = FALSE,
                                smooth_method = "loess",
                                smooth_se     = FALSE,
                                smooth_width  = 1.2,
                                y_labels      = NULL,
                                ...) {
  .check_alpha(alpha)
  if (!(is.null(y_labels) ||
          (is.numeric(y_labels) && !is.null(names(y_labels)))))
    stop(paste0("`y_labels` must be NULL or a named numeric vector, ",
                "e.g. c(None = 0, Mild = 1, Moderate = 2, Severe = 3)."),
         call. = FALSE)

  data       <- x$data
  x_col      <- x$meta$x_col
  y_col      <- x$meta$y_col
  id_col     <- x$meta$id_col
  colour_col <- x$meta$colour_col

  # --- Line layer -----------------------------------------------------------
  if (!is.null(colour_col)) {
    line_aes <- ggplot2::aes(
      x      = .data[[x_col]],
      y      = .data[[y_col]],
      group  = .data[[id_col]],
      colour = .data[[colour_col]]
    )
  } else {
    line_aes <- ggplot2::aes(
      x     = .data[[x_col]],
      y     = .data[[y_col]],
      group = .data[[id_col]]
    )
  }

  p <- ggplot2::ggplot(data) +
    ggplot2::geom_line(
      mapping   = line_aes,
      linewidth = line_width,
      alpha     = alpha,
      colour    = if (is.null(colour_col)) line_colour else NULL
    )

  # --- Optional smooth overlay ----------------------------------------------
  if (add_smooth) {
    if (!is.null(colour_col)) {
      smooth_aes <- ggplot2::aes(
        x      = .data[[x_col]],
        y      = .data[[y_col]],
        colour = .data[[colour_col]],
        fill   = .data[[colour_col]],
        group  = .data[[colour_col]]
      )
    } else {
      smooth_aes <- ggplot2::aes(x = .data[[x_col]], y = .data[[y_col]])
    }
    p <- p + ggplot2::geom_smooth(
      mapping     = smooth_aes,
      method      = smooth_method,
      formula     = y ~ x,
      se          = smooth_se,
      linewidth   = smooth_width,
      inherit.aes = FALSE
    )
  }

  # --- Ordinal y-axis -------------------------------------------------------
  if (!is.null(y_labels)) {
    p <- p + ggplot2::scale_y_continuous(
      breaks = unname(y_labels),
      labels = names(y_labels)
    )
  }

  # When unstratified, suppress the spurious colour legend
  if (is.null(colour_col)) {
    p <- p + ggplot2::scale_colour_identity()
  }

  p
}
