# trends-plot.R
#
# Temporal trend plot with LOESS smoother and annual summary points.
# Ports the pattern from tp.dp.trends.R (template graph library) to
# hvtiPlotR, replacing hard-coded colours with scale_ composition and
# explicit theme calls with hvtiPlotR themes.
#
# Key differences from the template:
#  - Long format with a group column replaces one geom_smooth() call per group
#  - Annual summary statistic (mean or median) computed inside the function
#    from patient-level data, replacing the manual dplyr pipeline
#  - No hard-coded colours; examples demonstrate scale_color_manual() and
#    scale_color_brewer()
#  - Theme applied via + hvti_theme("manuscript") in examples
# ---------------------------------------------------------------------------

#' Sample Temporal Trend Data
#'
#' Generates a realistic patient-level longitudinal data set for demonstrating
#' [trends_plot()]. Each row is one patient with a surgery year, continuous
#' outcome (`value`), and a grouping variable (`group`). Trend patterns are
#' modelled so that group means diverge over time — matching the multi-group
#' NYHA / LV-mass / LOS pattern in the SAS template.
#'
#' @param n          Total number of patients. Default `600`.
#' @param year_range Integer vector `c(start, end)` for surgery years.
#'   Default `c(1990, 2020)`.
#' @param groups     Character vector of group labels. Default
#'   `c("Group I", "Group II", "Group III", "Group IV")`.
#' @param seed       Random seed for reproducibility. Default `42`.
#'
#' @return A data frame with columns:
#'   - `year`  — surgery year (integer)
#'   - `value` — continuous outcome (numeric)
#'   - `group` — group label (factor, ordered by `groups`)
#'
#' @seealso [trends_plot()]
#'
#' @examples
#' dta <- sample_trends_data(n = 400, seed = 42)
#' head(dta)
#' table(dta$year, dta$group)
#' @export
sample_trends_data <- function(n          = 600,
                               year_range = c(1990L, 2020L),
                               groups     = c("Group I", "Group II",
                                              "Group III", "Group IV"),
                               seed       = 42L) {
  set.seed(seed)

  n_groups <- length(groups)
  years    <- seq(year_range[1], year_range[2])
  n_years  <- length(years)

  # Each group has a baseline mean and a linear drift over time
  baselines <- seq(from = 60, by = -12, length.out = n_groups)
  drifts    <- seq(from = -0.8, by = 0.3, length.out = n_groups)

  group_id <- sample(seq_len(n_groups), n, replace = TRUE)
  year_obs <- sample(years, n, replace = TRUE)

  t_scaled <- (year_obs - year_range[1]) / max(1, diff(year_range))
  mu       <- baselines[group_id] + drifts[group_id] * t_scaled * n_years
  value    <- mu + stats::rnorm(n, sd = 8)

  data.frame(
    year  = as.integer(year_obs),
    value = round(value, 2),
    group = factor(groups[group_id], levels = groups)
  )
}

# ---------------------------------------------------------------------------

#' Temporal Trend Plot
#'
#' Produces a temporal trend plot for one or more groups: a LOESS smooth
#' overlaid with annual summary-statistic points (mean or median). Accepts
#' patient-level data and computes the annual summaries internally, replacing
#' the manual `dplyr` grouping pipeline from the SAS template.
#'
#' Returns a bare ggplot object. Compose with `scale_colour_*`,
#' `scale_shape_*`, `labs()`, `annotate()`, [ggplot2::coord_cartesian()],
#' and [hvti_theme()].
#'
#' @param data        Patient-level data frame (one row per patient).
#' @param x_col       Name of the numeric/integer time column (e.g. surgery
#'   year). Default `"year"`.
#' @param y_col       Name of the continuous outcome column. Default `"value"`.
#' @param group_col   Name of the grouping column, or `NULL` for a single
#'   group. Default `"group"`.
#' @param summary_fn  Function used to compute the annual point estimate:
#'   `"mean"` or `"median"`. Default `"mean"`.
#' @param smoother    Smoothing method passed to [ggplot2::geom_smooth()]:
#'   `"loess"` (default) or any method accepted by `geom_smooth()`.
#' @param span        Span for LOESS smoother. Default `0.75`.
#' @param se          Logical; show confidence ribbon around smooth?
#'   Default `FALSE`.
#' @param point_size  Size of the annual summary points. Default `2.5`.
#' @param point_shape Integer shape code for the summary points, or a named
#'   integer vector (one per group level) for different shapes per group.
#'   Default `19`.
#' @param alpha       Transparency of the smooth ribbon when `se = TRUE`.
#'   Default `0.2`.
#'
#' @return A [ggplot2::ggplot()] object.
#'
#' @seealso [sample_trends_data()], [hvti_theme()]
#' @aliases trend
#'
#' @examples
#' dta <- sample_trends_data(n = 600, seed = 42)
#'
#' # --- Single group (subset to one group) ----------------------------------
#' one <- dta[dta$group == "Group I", ]
#' trends_plot(one, group_col = NULL) +
#'   ggplot2::labs(x = "Surgery Year", y = "Outcome", title = "Group I Trend") +
#'   hvti_theme("manuscript")
#'
#' # --- Multiple groups with scale_color_brewer -----------------------------
#' trends_plot(dta) +
#'   ggplot2::scale_colour_brewer(palette = "Set1", name = "Group") +
#'   ggplot2::scale_shape_manual(
#'     values = c("Group I" = 15, "Group II" = 19,
#'                "Group III" = 17, "Group IV" = 18),
#'     name = "Group"
#'   ) +
#'   ggplot2::labs(x = "Surgery Year", y = "Outcome (%)") +
#'   hvti_theme("manuscript")
#'
#' # --- Median summary statistic + manual colours ---------------------------
#' trends_plot(dta, summary_fn = "median") +
#'   ggplot2::scale_colour_manual(
#'     values = c("Group I"   = "steelblue",
#'                "Group II"  = "firebrick",
#'                "Group III" = "forestgreen",
#'                "Group IV"  = "goldenrod3"),
#'     name = "NYHA Class"
#'   ) +
#'   ggplot2::scale_shape_manual(
#'     values = c("Group I" = 15, "Group II" = 19,
#'                "Group III" = 17, "Group IV" = 18),
#'     name = "NYHA Class"
#'   ) +
#'   ggplot2::coord_cartesian(xlim = c(1990, 2020), ylim = c(0, 80)) +
#'   ggplot2::scale_x_continuous(breaks = seq(1990, 2020, 5)) +
#'   ggplot2::scale_y_continuous(breaks = seq(0, 80, 20)) +
#'   ggplot2::labs(x = "Surgery Year", y = "%",
#'                 title = "Preoperative NYHA Class Over Time") +
#'   ggplot2::annotate("text", x = 2000, y = 75,
#'                     label = "Trend: Preoperative NYHA", size = 4) +
#'   hvti_theme("manuscript")
#'
#' # --- With confidence ribbon ----------------------------------------------
#' trends_plot(dta[dta$group == "Group I", ], group_col = NULL, se = TRUE) +
#'   ggplot2::labs(x = "Surgery Year", y = "Outcome") +
#'   hvti_theme("manuscript")
#'
#' # --- Save ----------------------------------------------------------------
#' \dontrun{
#' p <- trends_plot(dta) +
#'   ggplot2::scale_colour_brewer(palette = "Set1") +
#'   ggplot2::labs(x = "Surgery Year", y = "Outcome (%)") +
#'   hvti_theme("manuscript")
#' ggplot2::ggsave("trends.pdf", p, width = 11.5, height = 8)
#' }
#'
#' @importFrom ggplot2 ggplot aes geom_smooth geom_point
#' @importFrom rlang sym .data
#' @importFrom stats median
#' @export
trends_plot <- function(data,
                        x_col      = "year",
                        y_col      = "value",
                        group_col  = "group",
                        summary_fn = c("mean", "median"),
                        smoother   = "loess",
                        span       = 0.75,
                        se         = FALSE,
                        point_size = 2.5,
                        point_shape = 19L,
                        alpha      = 0.2) {

  summary_fn <- match.arg(summary_fn)

  # --- Validation -----------------------------------------------------------
  assertthat::assert_that(
    is.data.frame(data),
    msg = "`data` must be a data frame."
  )
  for (col in c(x_col, y_col)) {
    assertthat::assert_that(
      col %in% names(data),
      msg = paste0("Column '", col, "' not found in `data`.")
    )
  }
  if (!is.null(group_col)) {
    assertthat::assert_that(
      group_col %in% names(data),
      msg = paste0("`group_col` '", group_col, "' not found in `data`.")
    )
  }

  x_sym <- rlang::sym(x_col)
  y_sym <- rlang::sym(y_col)

  # --- Annual summary -------------------------------------------------------
  sfn <- if (summary_fn == "mean") base::mean else stats::median

  if (!is.null(group_col)) {
    grp_sym  <- rlang::sym(group_col)
    ann_data <- do.call(
      rbind,
      lapply(split(data, data[[group_col]]), function(sub) {
        agg <- tapply(sub[[y_col]], sub[[x_col]], sfn)
        data.frame(
          x     = as.numeric(names(agg)),
          y     = as.numeric(agg),
          group = sub[[group_col]][1L]
        )
      })
    )
    names(ann_data) <- c(x_col, y_col, group_col)
    ann_data[[group_col]] <- factor(
      ann_data[[group_col]],
      levels = levels(data[[group_col]])
    )
  } else {
    agg      <- tapply(data[[y_col]], data[[x_col]], sfn)
    ann_data <- data.frame(
      x = as.numeric(names(agg)),
      y = as.numeric(agg)
    )
    names(ann_data) <- c(x_col, y_col)
  }

  # --- Build plot -----------------------------------------------------------
  if (!is.null(group_col)) {
    grp_sym <- rlang::sym(group_col)

    p <- ggplot2::ggplot(data,
           ggplot2::aes(x = !!x_sym, y = !!y_sym,
                        colour = !!grp_sym, group = !!grp_sym)) +
      ggplot2::geom_smooth(
        method  = smoother,
        formula = y ~ x,
        span    = span,
        se      = se,
        alpha   = alpha,
        linewidth = 1
      ) +
      ggplot2::geom_point(
        data    = ann_data,
        mapping = ggplot2::aes(
          x     = !!x_sym,
          y     = !!y_sym,
          colour = !!grp_sym,
          shape  = !!grp_sym
        ),
        size    = point_size,
        inherit.aes = FALSE
      )
  } else {
    p <- ggplot2::ggplot(data,
           ggplot2::aes(x = !!x_sym, y = !!y_sym)) +
      ggplot2::geom_smooth(
        method    = smoother,
        formula   = y ~ x,
        span      = span,
        se        = se,
        alpha     = alpha,
        linewidth = 1
      ) +
      ggplot2::geom_point(
        data    = ann_data,
        mapping = ggplot2::aes(x = !!x_sym, y = !!y_sym),
        size    = point_size,
        shape   = point_shape,
        inherit.aes = FALSE
      )
  }

  p
}
