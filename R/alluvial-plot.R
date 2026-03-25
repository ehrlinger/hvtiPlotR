# alluvial-plot.R
#
# Alluvial diagram wrapper (formerly sankey-plot.R).
# Ports the pattern from tp.dp.female_bicus_preAR_sankey.R (template graph
# library) to hvtiPlotR, replacing hard-coded colours with scale_ composition
# and explicit theme calls with hvtiPlotR themes.
#
# Key differences from raw ggalluvial::geom_alluvium():
#  - Dynamic axis aes() constructed from a character vector — no need to
#    hard-code axis1 = col1, axis2 = col2, etc.
#  - No hard-coded fill/colour values; examples demonstrate scale_fill_manual()
#    and scale_fill_brewer()
#  - stratum_fill exposed as a parameter (default "grey80") for the vertical
#    bars, keeping flow colours independent of stratum bars
#  - Theme applied via + hvti_theme("manuscript") in examples
# ---------------------------------------------------------------------------

#' Sample Sankey / Alluvial Data
#'
#' Generates a realistic cardiac-surgery data set suitable for demonstrating
#' [alluvial_plot()]. Each row represents a unique combination of pre-operative
#' AV regurgitation grade, surgical procedure type, and post-operative AV
#' regurgitation grade, together with the patient count (`freq`) for that
#' combination. The co-occurrence structure reflects realistic clinical
#' patterns: more severe pre-operative disease is more likely to improve
#' post-operatively following valve surgery.
#'
#' @param n    Total number of simulated patients before aggregation.
#'   Default `300`.
#' @param seed Random seed for reproducibility. Default `42`.
#'
#' @return A data frame with columns:
#'   `pre_ar` (factor), `procedure` (factor), `post_ar` (factor), `freq`
#'   (integer count). Rows with `freq == 0` are excluded.
#'
#' @seealso [alluvial_plot()]
#'
#' @examples
#' dta <- sample_alluvial_data(n = 300, seed = 42)
#' head(dta)
#' # Axes in order: pre-op grade → procedure → post-op grade
#' with(dta, tapply(freq, list(pre_ar, post_ar), sum, default = 0))
#' @export
sample_alluvial_data <- function(n = 300, seed = 42L) {
  set.seed(seed)

  grade_levels <- c("None", "Mild", "Moderate", "Severe")
  proc_levels  <- c("TAVR", "Repair", "Replacement")

  pre_ar <- sample(
    grade_levels, n, replace = TRUE,
    prob = c(0.25, 0.35, 0.28, 0.12)
  )

  # Procedure type: open surgery more likely for higher-grade disease
  severe <- pre_ar %in% c("Moderate", "Severe")
  procedure <- ifelse(
    severe,
    sample(proc_levels, n, replace = TRUE, prob = c(0.10, 0.30, 0.60)),
    sample(proc_levels, n, replace = TRUE, prob = c(0.25, 0.40, 0.35))
  )

  # Post-AR: improvement modelled as ordinal reduction
  pre_num      <- match(pre_ar, grade_levels)
  improvement  <- stats::rbinom(n, size = 2, prob = 0.70)
  post_num     <- pmax(1L, pre_num - improvement)
  post_ar      <- grade_levels[post_num]

  dta <- data.frame(pre_ar = pre_ar, procedure = procedure, post_ar = post_ar)
  agg <- as.data.frame(table(dta), stringsAsFactors = FALSE)
  names(agg)[names(agg) == "Freq"] <- "freq"

  agg$pre_ar    <- factor(agg$pre_ar,    levels = grade_levels)
  agg$procedure <- factor(agg$procedure, levels = proc_levels)
  agg$post_ar   <- factor(agg$post_ar,   levels = grade_levels)
  agg$freq      <- as.integer(agg$freq)

  agg[agg$freq > 0L, ]
}

# ---------------------------------------------------------------------------

#' Sankey / Alluvial Plot
#'
#' Produces a Sankey (alluvial) diagram using [ggalluvial::geom_alluvium()] and
#' [ggalluvial::geom_stratum()]. Axes are specified as a character vector so
#' the number of stages is not hard-coded. Returns a bare ggplot object for
#' composition with `scale_*`, `labs()`, and [hvti_theme()].
#'
#' **Data format:** one row per unique combination of axis values, with a
#' numeric weight column (`y_col`). This matches the frequency / summary table
#' format used in the SAS template (`ardat` with `percent` as `y`).
#'
#' **Colours:** flows are unfilled by default. Map a column to `fill_col` and
#' add `scale_fill_manual()` or `scale_fill_brewer()` to the returned object.
#' Stratum bars use `stratum_fill` (default `"grey80"`) and are independent of
#' the flow fill scale.
#'
#' @param data          A data frame in wide alluvial format: one row per
#'   axis-value combination, a numeric weight column, and one column per axis.
#' @param axes          Character vector of column names to use as axes, in
#'   left-to-right display order. Minimum two columns.
#' @param y_col         Name of the numeric weight column (counts or
#'   proportions). Default `"freq"`.
#' @param fill_col      Name of the column to map to the flow fill and colour
#'   aesthetics, or `NULL` for a single fill. Default `NULL`.
#' @param axis_labels   Character vector of axis labels for the x-axis, the
#'   same length as `axes`. Defaults to `axes` (column names).
#' @param stratum_fill  Fill colour for the stratum bars. Default `"grey80"`.
#' @param stratum_width Width of the stratum bars as a fraction of axis
#'   spacing. Default `1/4`.
#' @param flow_width    Width of the alluvium flows. Default `1/6`.
#' @param alpha         Transparency of the flows, `[0, 1]`. Default `0.8`.
#' @param knot_pos      Curvature of the flow ribbons, `[0, 1]`. Default `0.4`.
#' @param show_labels   Logical; whether to label each stratum with its value.
#'   Default `TRUE`.
#'
#' @return A [ggplot2::ggplot()] object. Compose with `scale_fill_*`,
#'   `scale_colour_*`, `labs()`, `annotate()`, and [hvti_theme()].
#'
#' @seealso [ggalluvial::geom_alluvium()], [ggalluvial::geom_stratum()],
#'   [sample_alluvial_data()], [hvti_theme()]
#'
#' @examples
#' dta  <- sample_alluvial_data(n = 300, seed = 42)
#' axes <- c("pre_ar", "procedure", "post_ar")
#'
#' # --- Bare plot -----------------------------------------------------------
#' alluvial_plot(dta, axes = axes, y_col = "freq")
#'
#' # --- Fill flows by pre-operative AR grade + manuscript theme -------------
#' alluvial_plot(dta, axes = axes, y_col = "freq", fill_col = "pre_ar") +
#'   ggplot2::scale_fill_manual(
#'     values = c(None     = "steelblue",
#'                Mild     = "goldenrod",
#'                Moderate = "darkorange",
#'                Severe   = "firebrick"),
#'     name = "Pre-op AR"
#'   ) +
#'   ggplot2::scale_colour_manual(
#'     values = c(None     = "steelblue",
#'                Mild     = "goldenrod",
#'                Moderate = "darkorange",
#'                Severe   = "firebrick"),
#'     guide = "none"
#'   ) +
#'   ggplot2::scale_x_continuous(
#'     breaks = 1:3,
#'     labels = c("Pre-op AR", "Procedure", "Post-op AR"),
#'     expand = c(0.05, 0.05)
#'   ) +
#'   ggplot2::labs(y = "Patients (n)",
#'                 title = "AV Regurgitation: Pre- to Post-operative") +
#'   hvti_theme("manuscript")
#'
#' # --- Fill flows by procedure with RColorBrewer palette -------------------
#' alluvial_plot(dta, axes = axes, y_col = "freq", fill_col = "procedure") +
#'   ggplot2::scale_fill_brewer(palette = "Set2", name = "Procedure") +
#'   ggplot2::scale_colour_brewer(palette = "Set2", guide = "none") +
#'   ggplot2::scale_x_continuous(
#'     breaks = 1:3,
#'     labels = c("Pre-op AR", "Procedure", "Post-op AR"),
#'     expand = c(0.05, 0.05)
#'   ) +
#'   ggplot2::labs(y = "Patients (n)") +
#'   hvti_theme("manuscript")
#'
#' # --- Two-axis (before / after) with annotation ---------------------------
#' alluvial_plot(
#'   dta, axes = c("pre_ar", "post_ar"), y_col = "freq",
#'   fill_col = "pre_ar", axis_labels = c("Pre-operative", "Post-operative")
#' ) +
#'   ggplot2::scale_fill_brewer(palette = "RdYlGn", direction = -1,
#'                              name = "AR Grade") +
#'   ggplot2::scale_colour_brewer(palette = "RdYlGn", direction = -1,
#'                                guide = "none") +
#'   ggplot2::annotate("text", x = 1.5, y = 250,
#'                     label = "Improvement after surgery",
#'                     size = 3.5, fontface = "italic") +
#'   ggplot2::labs(y = "Patients (n)",
#'                 title = "AV Regurgitation Before and After Surgery") +
#'   hvti_theme("manuscript")
#'
#' # --- Save ----------------------------------------------------------------
#' \dontrun{
#' p <- alluvial_plot(dta, axes = axes, y_col = "freq", fill_col = "pre_ar") +
#'   ggplot2::scale_fill_brewer(palette = "RdYlGn", direction = -1) +
#'   ggplot2::scale_colour_brewer(palette = "RdYlGn", direction = -1,
#'                                guide = "none") +
#'   hvti_theme("manuscript")
#' ggplot2::ggsave("sankey.pdf", p, width = 8, height = 6)
#' }
#'
#' @importFrom ggalluvial geom_alluvium geom_stratum StatStratum
#' @importFrom ggplot2 ggplot aes geom_text scale_x_continuous after_stat
#' @importFrom rlang sym syms inject
#' @export
alluvial_plot <- function(data,
                        axes,
                        y_col         = "freq",
                        fill_col      = NULL,
                        axis_labels   = NULL,
                        stratum_fill  = "grey80",
                        stratum_width = 1 / 4,
                        flow_width    = 1 / 6,
                        alpha         = 0.8,
                        knot_pos      = 0.4,
                        show_labels   = TRUE) {

  # --- Validation -----------------------------------------------------------
  .check_df(data)
  if (!(is.character(axes) && length(axes) >= 2L))
    stop("`axes` must be a character vector of at least 2 column names.",
         call. = FALSE)
  .check_cols(data, axes)
  .check_col(data, y_col)
  if (!is.null(fill_col))
    .check_col(data, fill_col)
  if (!(is.null(axis_labels) ||
          (is.character(axis_labels) &&
           length(axis_labels) == length(axes))))
    stop(paste("`axis_labels` must be NULL or a character vector the same",
               "length as `axes`."), call. = FALSE)
  .check_alpha(alpha)

  if (is.null(axis_labels)) axis_labels <- axes

  # --- Build dynamic aes() -------------------------------------------------
  # axis1 = axes[1], axis2 = axes[2], ... constructed without hard-coding
  axis_syms <- rlang::syms(axes)
  axis_list <- stats::setNames(axis_syms, paste0("axis", seq_along(axes)))

  base_mapping <- rlang::inject(
    ggplot2::aes(y = !!rlang::sym(y_col), !!!axis_list)
  )

  # Flow mapping: fill + colour if fill_col given
  if (!is.null(fill_col)) {
    fill_sym     <- rlang::sym(fill_col)
    flow_mapping <- rlang::inject(
      ggplot2::aes(fill = !!fill_sym, colour = !!fill_sym)
    )
  } else {
    flow_mapping <- ggplot2::aes()
  }

  # --- Build plot -----------------------------------------------------------
  p <- ggplot2::ggplot(data, base_mapping) +
    ggalluvial::geom_alluvium(
      mapping  = flow_mapping,
      width    = flow_width,
      alpha    = alpha,
      knot.pos = knot_pos
    ) +
    ggalluvial::geom_stratum(
      width = stratum_width,
      fill  = stratum_fill
    ) +
    ggplot2::scale_x_continuous(
      breaks = seq_along(axes),
      labels = axis_labels,
      expand = c(0.05, 0.05)
    )

  if (show_labels) {
    p <- p + ggplot2::geom_text(
      stat = ggalluvial::StatStratum,
      ggplot2::aes(label = ggplot2::after_stat(stratum))
    )
  }

  p
}

utils::globalVariables("stratum")
