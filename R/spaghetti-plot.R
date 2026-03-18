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
#' demonstrating [spaghetti_plot()]. Each row is one observation for one
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
#' @seealso [spaghetti_plot()]
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

#' Spaghetti / Profile Plot of Repeated Measurements
#'
#' Draws one trajectory line per subject over time. Optionally stratifies line
#' colour by a grouping variable and overlays a LOESS smooth (or other
#' smoother) per group. Returns a bare ggplot object for composition with
#' `scale_colour_*`, `labs()`, `annotate()`, and [hvti_theme()].
#'
#' **Unstratified use** (`colour_col = NULL`): all lines share the same colour,
#' set via `line_colour`. Override with `scale_colour_identity()` or add a
#' single-value `scale_colour_manual()`.
#'
#' **Stratified use** (`colour_col = "group"`): lines are mapped to
#' `colour_col`; add `scale_colour_manual()` or `scale_colour_brewer()` to
#' control the palette.
#'
#' **Ordinal y-axis** (`y_labels`): supply a named numeric vector
#' (`c("None" = 0, "Mild" = 1, ...)`) to replace numeric tick marks with
#' category labels — matching `plot_9` in the template.
#'
#' @param data         Data frame; one row per observation per subject.
#' @param x_col        Name of the time column. Default `"time"`.
#' @param y_col        Name of the outcome column. Default `"value"`.
#' @param id_col       Name of the subject identifier column used as the
#'   `group` aesthetic for line continuity. Default `"id"`.
#' @param colour_col   Name of the column to map to line colour, or `NULL` for
#'   a single colour. Default `NULL`.
#' @param line_colour  Fixed line colour used when `colour_col = NULL`.
#'   Default `"grey50"`.
#' @param line_width   Line width for individual trajectories. Default `0.2`.
#' @param alpha        Transparency of individual lines. Default `0.6`.
#' @param add_smooth   Logical; overlay a smoother per group (or overall when
#'   `colour_col = NULL`)? Default `FALSE`.
#' @param smooth_method Smoothing method, e.g. `"loess"` (default) or `"lm"`.
#' @param smooth_se    Logical; show confidence ribbon around smooth?
#'   Default `FALSE`.
#' @param smooth_width Line width for the smooth overlay. Default `1.2`.
#' @param y_labels     Named numeric vector mapping category names to y
#'   positions for an ordinal axis, e.g.
#'   `c("None" = 0, "Mild" = 1, "Moderate" = 2, "Severe" = 3)`.
#'   When supplied, `scale_y_continuous()` uses these as breaks and labels.
#'   Default `NULL` (standard numeric axis).
#'
#' @return A [ggplot2::ggplot()] object.
#'
#' @seealso [sample_spaghetti_data()], [hvti_theme()]
#'
#' @examples
#' dta <- sample_spaghetti_data(n_patients = 150, seed = 42)
#'
#' # --- Unstratified (all lines grey) ---------------------------------------
#' spaghetti_plot(dta) +
#'   ggplot2::scale_x_continuous(breaks = seq(0, 5, 1)) +
#'   ggplot2::scale_y_continuous(breaks = seq(0, 40, 10)) +
#'   ggplot2::coord_cartesian(xlim = c(0, 5), ylim = c(0, 40)) +
#'   ggplot2::labs(x = "Years after Operation",
#'                 y = "AV Mean Gradient (mmHg)") +
#'   hvti_theme("manuscript")
#'
#' # --- Stratified by group with scale_colour_manual ------------------------
#' spaghetti_plot(dta, colour_col = "group") +
#'   ggplot2::scale_colour_manual(
#'     values = c(Female = "firebrick", Male = "steelblue"),
#'     name   = NULL
#'   ) +
#'   ggplot2::scale_x_continuous(breaks = seq(0, 5, 1)) +
#'   ggplot2::scale_y_continuous(breaks = seq(0, 40, 10)) +
#'   ggplot2::coord_cartesian(xlim = c(0, 5), ylim = c(0, 40)) +
#'   ggplot2::labs(x = "Years after Operation",
#'                 y = "AV Mean Gradient (mmHg)") +
#'   hvti_theme("manuscript")
#'
#' # --- With LOESS smooth overlay per group ---------------------------------
#' spaghetti_plot(dta, colour_col = "group", add_smooth = TRUE) +
#'   ggplot2::scale_colour_brewer(palette = "Set1", name = NULL) +
#'   ggplot2::scale_fill_brewer(palette = "Set1", guide = "none") +
#'   ggplot2::scale_x_continuous(breaks = seq(0, 5, 1)) +
#'   ggplot2::labs(x = "Years after Operation",
#'                 y = "AV Mean Gradient (mmHg)") +
#'   ggplot2::annotate(
#'     "text", x = 3, y = 35,
#'     label = "Individual patient trajectories",
#'     size = 3.5, colour = "grey40"
#'   ) +
#'   hvti_theme("manuscript")
#'
#' # --- Ordinal y-axis (MR grade) -------------------------------------------
#' # Simulate an ordinal outcome (0-3 scale)
#' dta_ord <- dta
#' dta_ord$value <- round(pmin(3, pmax(0, dta$value / 12)))
#' spaghetti_plot(
#'   dta_ord,
#'   colour_col = "group",
#'   y_labels   = c(None = 0, Mild = 1, Moderate = 2, Severe = 3)
#' ) +
#'   ggplot2::scale_colour_manual(
#'     values = c(Female = "firebrick", Male = "steelblue"),
#'     name   = NULL
#'   ) +
#'   ggplot2::coord_cartesian(xlim = c(0, 5), ylim = c(0, 3)) +
#'   ggplot2::labs(x = "Years after Procedure",
#'                 y = "MV Regurgitation Grade") +
#'   hvti_theme("manuscript")
#'
#' # --- Save ----------------------------------------------------------------
#' \dontrun{
#' p <- spaghetti_plot(dta, colour_col = "group") +
#'   ggplot2::scale_colour_manual(
#'     values = c(Female = "firebrick", Male = "steelblue"), name = NULL
#'   ) +
#'   ggplot2::labs(x = "Years", y = "AV Mean Gradient (mmHg)") +
#'   hvti_theme("manuscript")
#' ggplot2::ggsave("spaghetti.pdf", p, width = 11, height = 8.5)
#' }
#'
#' @importFrom ggplot2 ggplot aes geom_line geom_smooth scale_colour_identity
#'   scale_y_continuous
#' @importFrom rlang .data
#' @export
spaghetti_plot <- function(data,
                           x_col         = "time",
                           y_col         = "value",
                           id_col        = "id",
                           colour_col    = NULL,
                           line_colour   = "grey50",
                           line_width    = 0.2,
                           alpha         = 0.6,
                           add_smooth    = FALSE,
                           smooth_method = "loess",
                           smooth_se     = FALSE,
                           smooth_width  = 1.2,
                           y_labels      = NULL) {

  # --- Validation -----------------------------------------------------------
  if (!is.data.frame(data))
    stop("`data` must be a data frame.")
  for (col in c(x_col, y_col, id_col)) {
    if (!(col %in% names(data)))
      stop(paste0("Column '", col, "' not found in `data`."))
  }
  if (!is.null(colour_col)) {
    if (!(colour_col %in% names(data)))
      stop(paste0("`colour_col` '", colour_col, "' not found in `data`."))
  }
  if (!is.numeric(alpha) || length(alpha) != 1L ||
      !(alpha >= 0 && alpha <= 1))
    stop("`alpha` must be a number in [0, 1].")
  if (!(is.null(y_labels) ||
          (is.numeric(y_labels) && !is.null(names(y_labels)))))
    stop(paste0("`y_labels` must be NULL or a named numeric vector, ",
                "e.g. c(None = 0, Mild = 1, Moderate = 2, Severe = 3)."))

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
      mapping   = smooth_aes,
      method    = smooth_method,
      formula   = y ~ x,
      se        = smooth_se,
      linewidth = smooth_width,
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
