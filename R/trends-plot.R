# trends-plot.R
#
# Temporal trend plot with LOESS smoother and annual summary points.
# Ports the pattern from five SAS/R templates to hvtiPlotR:
#
#   tp.rp.trends.sas          — single continuous outcome vs operation year
#                               (Tricuspid valve replacement, 1968-2000)
#   tp.lp.trends.sas          — binary % outcomes, x 1970-2000 by 10,
#                               y 0-100 by 10 (Post-infarct VSD, 1969-2000)
#   tp.lp.trends.age.sas      — binary % vs patient age (not year),
#                               x 25-85 by 10 (Mitral valve, 1990-1999)
#   tp.lp.trends.polytomous.sas — polytomous groups, x 1990-1999 by 1
#                               (Tricuspid repair types, 1990-1999)
#   tp.dp.trends.R            — NYHA %, LV mass, %CHF, case volume, LOS
#                               (Mitral degeneration, 1985-2015)
#
# Key differences from the templates:
#  - Long format with a group column replaces one geom_smooth() call per group
#  - Annual summary statistic (mean or median) computed in hv_trends()
#    constructor and stored in $tables$summary; plot() retrieves it
#  - groups = NULL supported in sample_trends_data() for single-group figures
#  - No hard-coded colours; examples demonstrate scale_colour_manual() and
#    scale_colour_brewer()
#  - Theme applied via + hv_theme("manuscript") in examples
# ---------------------------------------------------------------------------

#' Sample Temporal Trend Data
#'
#' Generates a realistic patient-level longitudinal data set for demonstrating
#' [hv_trends()]. Each row is one patient with a surgery year, continuous
#' outcome (`value`), and a grouping variable (`group`). Trend patterns are
#' modelled so that group means diverge over time — matching the multi-group
#' NYHA / LV-mass / LOS pattern in the SAS template.
#'
#' @param n          Total number of patients. Default `600`.
#' @param year_range Integer vector `c(start, end)` for the x-axis range
#'   (surgery year, or patient age when used with `tp.lp.trends.age.sas`
#'   patterns). Default `c(1990, 2020)`.
#' @param groups     Character vector of group labels, or `NULL` for a
#'   single-group figure (no `group` column returned; use with
#'   `hv_trends(..., group_col = NULL)`). Default
#'   `c("Group I", "Group II", "Group III", "Group IV")`.
#' @param seed       Random seed for reproducibility. Default `42`.
#'
#' @return A data frame with columns:
#'   - `year`  — x-axis value (integer; surgery year or patient age)
#'   - `value` — continuous outcome (numeric)
#'   - `group` — group label (factor, ordered by `groups`); absent when
#'     `groups = NULL`
#'
#' @seealso [hv_trends()]
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

  single_group <- is.null(groups)
  if (single_group) groups <- "Group I"

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

  df <- data.frame(
    year  = as.integer(year_obs),
    value = round(value, 2)
  )
  if (!single_group) {
    df$group <- factor(groups[group_id], levels = groups)
  }
  df
}

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

#' Prepare temporal trend data for plotting
#'
#' Validates a patient-level data frame, computes per-x-value summary
#' statistics (mean or median), and returns an \code{hv_trends} object.
#' Call \code{\link{plot.hv_trends}} on the result to obtain a bare
#' \code{ggplot2} trend plot (LOESS smooth + annual summary points) that you
#' can decorate with colour scales, axis limits, and \code{\link{hv_theme}}.
#'
#' @param data        Patient-level data frame (one row per patient).
#' @param x_col       Name of the numeric/integer time column (e.g. surgery
#'   year). Default \code{"year"}.
#' @param y_col       Name of the continuous outcome column. Default \code{"value"}.
#' @param group_col   Name of the grouping column, or \code{NULL} for a single
#'   group. Default \code{"group"}.
#' @param summary_fn  Function used to compute the per-x-point estimate:
#'   \code{"mean"} or \code{"median"}. Default \code{"mean"}.
#'
#' @return An object of class \code{c("hv_trends", "hv_data")}; call
#'   \code{plot()} on the result to render the figure — see
#'   \code{\link{plot.hv_trends}}. The list contains:
#' \describe{
#'   \item{\code{$data}}{The original patient-level data frame.}
#'   \item{\code{$meta}}{Named list: \code{x_col}, \code{y_col},
#'     \code{group_col}, \code{summary_fn}, \code{n_obs},
#'     \code{n_groups}.}
#'   \item{\code{$tables}}{List with one element: \code{summary} — a data
#'     frame of per-x (per-group) summary statistics used for the point
#'     overlay.}
#' }
#'
#' @seealso \code{\link{plot.hv_trends}} to render as a ggplot2 figure,
#'   \code{\link{hv_theme}} for the publication theme,
#'   \code{\link{sample_trends_data}} for example data.
#'
#' @family Temporal trends
#'
#' @examples
#' dta <- sample_trends_data(n = 600, year_range = c(1985L, 2015L),
#'   groups = c("I", "II", "III", "IV"))
#' tr  <- hv_trends(dta, summary_fn = "median")
#' tr   # prints observation and group counts
#'
#' plot(tr) +
#'   ggplot2::scale_colour_manual(
#'     values = c(I = "steelblue", II = "firebrick",
#'                III = "forestgreen", IV = "goldenrod3"),
#'     name = "NYHA Class"
#'   ) +
#'   ggplot2::scale_x_continuous(limits = c(1985, 2015),
#'                               breaks = seq(1985, 2015, 5)) +
#'   ggplot2::scale_y_continuous(limits = c(0, 80),
#'                               breaks = seq(0, 80, 20)) +
#'   ggplot2::coord_cartesian(xlim = c(1985, 2015), ylim = c(0, 80)) +
#'   ggplot2::labs(x = "Years", y = "%") +
#'   hv_theme("manuscript")
#'
#' @importFrom rlang .data
#' @importFrom stats median
#' @export
hv_trends <- function(data,
                        x_col      = "year",
                        y_col      = "value",
                        group_col  = "group",
                        summary_fn = c("mean", "median")) {
  .check_df(data)
  .check_cols(data, c(x_col, y_col))
  if (!is.null(group_col))
    .check_col(data, group_col)

  summary_fn <- match.arg(summary_fn)
  sfn <- if (summary_fn == "mean") {
    function(x) base::mean(x, na.rm = TRUE)
  } else {
    function(x) stats::median(x, na.rm = TRUE)
  }

  # --- Compute per-x (per-group) summary statistics -------------------------
  if (!is.null(group_col)) {
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
      levels = if (is.factor(data[[group_col]])) levels(data[[group_col]])
               else unique(data[[group_col]])
    )
    n_groups <- length(unique(data[[group_col]]))
  } else {
    agg      <- tapply(data[[y_col]], data[[x_col]], sfn)
    ann_data <- data.frame(
      x = as.numeric(names(agg)),
      y = as.numeric(agg)
    )
    names(ann_data) <- c(x_col, y_col)
    n_groups <- 1L
  }

  new_hv_data(
    data = as.data.frame(data),
    meta = list(
      x_col      = x_col,
      y_col      = y_col,
      group_col  = group_col,
      summary_fn = summary_fn,
      n_obs      = nrow(data),
      n_groups   = n_groups
    ),
    tables   = list(summary = ann_data),
    subclass = "hv_trends"
  )
}


#' Print an hv_trends object
#'
#' @param x   An \code{hv_trends} object from \code{\link{hv_trends}}.
#' @param ... Ignored.
#' @return \code{x}, invisibly.
#' @export
print.hv_trends <- function(x, ...) {
  m <- x$meta
  cat("<hv_trends>\n")
  cat(sprintf("  N obs       : %d  (%d groups)\n", m$n_obs, m$n_groups))
  cat(sprintf("  x / y       : %s / %s\n", m$x_col, m$y_col))
  if (!is.null(m$group_col))
    cat(sprintf("  Group col   : %s\n", m$group_col))
  cat(sprintf("  Summary fn  : %s\n", m$summary_fn))
  invisible(x)
}


#' Plot an hv_trends object
#'
#' Draws a LOESS smooth overlaid with per-x-value summary-statistic points
#' (mean or median computed at construction time).
#'
#' @param x            An \code{hv_trends} object.
#' @param smoother     Smoothing method passed to
#'   \code{\link[ggplot2]{geom_smooth}}. Default \code{"loess"}.
#' @param span         Span for LOESS smoother. Default \code{0.75}.
#' @param se           Logical; show confidence ribbon around smooth?
#'   Default \code{FALSE}.
#' @param point_size   Size of the annual summary points. Default \code{2.5}.
#' @param point_shape  Integer shape code for the summary points (single-group
#'   only; ignored when \code{group_col} is set — use
#'   \code{scale_shape_manual()} instead). Default \code{19L}.
#' @param alpha        Transparency of the smooth ribbon when \code{se = TRUE}.
#'   Default \code{0.2}.
#' @param ...          Ignored; present for S3 consistency.
#'
#' @return A bare \code{\link[ggplot2]{ggplot}} object; compose with \code{+}
#'   to add scales, axis limits, labels, and \code{\link{hv_theme}}.
#'
#' @seealso \code{\link{hv_trends}} to build the data object,
#'   \code{\link{hv_theme}} for the publication theme.
#'
#' @family Temporal trends
#'
#' @examples
#' # --- tp.rp.trends.sas: single continuous outcome, 1968-2000 ---------------
#' one <- sample_trends_data(n = 600, year_range = c(1968L, 2000L),
#'                           groups = NULL)
#' plot(hv_trends(one, group_col = NULL)) +
#'   ggplot2::scale_x_continuous(limits = c(1968, 2000),
#'                               breaks = seq(1968, 2000, 4)) +
#'   ggplot2::scale_y_continuous(limits = c(0, 10),
#'                               breaks = seq(0, 10, 2)) +
#'   ggplot2::labs(x = "Year", y = "Cases/year") +
#'   hv_theme("manuscript")
#'
#' # --- tp.lp.trends.sas: binary % outcomes, 1970-2000 by 10 ----------------
#' dta_lp <- sample_trends_data(
#'   n = 800, year_range = c(1970L, 2000L),
#'   groups = c("Shock %", "Pre-op IABP %", "Inotropes %"))
#' plot(hv_trends(dta_lp)) +
#'   ggplot2::scale_colour_manual(
#'     values = c("Shock %" = "steelblue", "Pre-op IABP %" = "firebrick",
#'                "Inotropes %" = "forestgreen"), name = NULL) +
#'   ggplot2::scale_x_continuous(limits = c(1970, 2000),
#'                               breaks = seq(1970, 2000, 10)) +
#'   ggplot2::scale_y_continuous(limits = c(0, 100),
#'                               breaks = seq(0, 100, 10)) +
#'   ggplot2::coord_cartesian(xlim = c(1970, 2000), ylim = c(0, 100)) +
#'   ggplot2::labs(x = "Year", y = "Percent (%)") +
#'   hv_theme("manuscript")
#'
#' # --- tp.lp.trends.age.sas: age on x-axis, 25-85 by 10 -------------------
#' dta_age <- sample_trends_data(
#'   n = 600, year_range = c(25L, 85L),
#'   groups = c("Repair %", "Bioprosthesis %"), seed = 7L)
#' plot(hv_trends(dta_age)) +
#'   ggplot2::scale_x_continuous(limits = c(25, 85),
#'                               breaks = seq(25, 85, 10)) +
#'   ggplot2::scale_y_continuous(limits = c(0, 100),
#'                               breaks = seq(0, 100, 20)) +
#'   ggplot2::coord_cartesian(xlim = c(25, 85), ylim = c(0, 100)) +
#'   ggplot2::labs(x = "Age (years)", y = "Percent (%)") +
#'   hv_theme("manuscript")
#'
#' # --- tp.lp.trends.polytomous.sas: repair types, 1990-1999 by 1 ----------
#' dta_poly <- sample_trends_data(
#'   n = 800, year_range = c(1990L, 1999L),
#'   groups = c("CE", "Cosgrove", "Periguard", "DeVega"), seed = 5L)
#' plot(hv_trends(dta_poly)) +
#'   ggplot2::scale_colour_manual(
#'     values = c(CE = "steelblue", Cosgrove = "firebrick",
#'                Periguard = "forestgreen", DeVega = "goldenrod3"),
#'     name = "Repair type") +
#'   ggplot2::scale_x_continuous(limits = c(1990, 1999),
#'                               breaks = seq(1990, 1999, 1)) +
#'   ggplot2::scale_y_continuous(limits = c(0, 100),
#'                               breaks = seq(0, 100, 10)) +
#'   ggplot2::coord_cartesian(xlim = c(1990, 1999), ylim = c(0, 100)) +
#'   ggplot2::labs(x = "Year", y = "Percent (%)") +
#'   hv_theme("manuscript")
#'
#' # --- Save ----------------------------------------------------------------
#' \dontrun{
#' tr <- hv_trends(
#'   sample_trends_data(n = 800, year_range = c(1985L, 2015L),
#'                      groups = c("I", "II", "III", "IV")),
#'   summary_fn = "median"
#' )
#' p <- plot(tr) +
#'   ggplot2::scale_colour_brewer(palette = "Set1", name = "NYHA Class") +
#'   ggplot2::scale_x_continuous(limits = c(1985, 2015),
#'                               breaks = seq(1985, 2015, 5)) +
#'   ggplot2::labs(x = "Years", y = "%") +
#'   hv_theme("manuscript")
#' ggplot2::ggsave("trends.pdf", p, width = 11.5, height = 8)
#' }
#'
#' # --- Global theme (set once per session) ----------------------------------
#' \dontrun{
#' old <- ggplot2::theme_set(hv_theme_manuscript())
#' plot(hv_trends(dta_poly)) +
#'   ggplot2::scale_colour_brewer(palette = "Dark2", name = "Repair type")
#' ggplot2::theme_set(old)
#' }
#'
#' # See vignette("plot-decorators", package = "hvtiPlotR") for theming,
#' # colour scales, annotation labels, and saving plots.
#'
#' @importFrom ggplot2 ggplot aes geom_smooth geom_point
#' @importFrom rlang .data
#' @export
plot.hv_trends <- function(x,
                              smoother    = "loess",
                              span        = 0.75,
                              se          = FALSE,
                              point_size  = 2.5,
                              point_shape = 19L,
                              alpha       = 0.2,
                              ...) {
  data      <- x$data
  ann_data  <- x$tables$summary
  x_col     <- x$meta$x_col
  y_col     <- x$meta$y_col
  group_col <- x$meta$group_col

  if (!is.null(group_col)) {
    p <- ggplot2::ggplot(data,
           ggplot2::aes(x      = .data[[x_col]],
                        y      = .data[[y_col]],
                        colour = .data[[group_col]],
                        group  = .data[[group_col]])) +
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
        mapping = ggplot2::aes(
          x      = .data[[x_col]],
          y      = .data[[y_col]],
          colour = .data[[group_col]],
          shape  = .data[[group_col]]
        ),
        size        = point_size,
        inherit.aes = FALSE
      )
  } else {
    p <- ggplot2::ggplot(data,
           ggplot2::aes(x = .data[[x_col]], y = .data[[y_col]])) +
      ggplot2::geom_smooth(
        method    = smoother,
        formula   = y ~ x,
        span      = span,
        se        = se,
        alpha     = alpha,
        linewidth = 1
      ) +
      ggplot2::geom_point(
        data        = ann_data,
        mapping     = ggplot2::aes(x = .data[[x_col]], y = .data[[y_col]]),
        size        = point_size,
        shape       = point_shape,
        inherit.aes = FALSE
      )
  }

  p
}
