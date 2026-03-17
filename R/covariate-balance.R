###############################################################################
## Covariate balance plot for propensity score matching / IPTW analyses.
## Adapted from the tp.lp.propen.cov_balance.R template.
###############################################################################

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

cb_validate_input <- function(data, variable_col, group_col, std_diff_col) {
  if (!is.data.frame(data))
    stop("`data` must be a data.frame.", call. = FALSE)
  missing_cols <- setdiff(
    c(variable_col, group_col, std_diff_col), names(data)
  )
  if (length(missing_cols))
    stop(
      sprintf("Missing required column(s): %s",
              paste(missing_cols, collapse = ", ")),
      call. = FALSE
    )
  if (!is.numeric(data[[std_diff_col]]))
    stop(sprintf("`%s` must be numeric.", std_diff_col), call. = FALSE)
}

#' @importFrom rlang .data
#' @importFrom ggplot2 ggplot aes geom_vline geom_hline geom_point
#'   scale_y_continuous
cb_build_plot <- function(data, std_diff_col, group_col, var_levels,
                          threshold, point_size,
                          hline_linetype, hline_linewidth,
                          vline_linewidth, threshold_linetype) {
  n_vars <- length(var_levels)

  ggplot2::ggplot(data) +
    # Solid centre reference at zero
    ggplot2::geom_vline(
      xintercept = 0,
      linewidth = vline_linewidth, color = "black"
    ) +
    # Dotted threshold reference lines
    ggplot2::geom_vline(
      xintercept = threshold,
      linetype = threshold_linetype, color = "black"
    ) +
    ggplot2::geom_vline(
      xintercept = -threshold,
      linetype = threshold_linetype, color = "black"
    ) +
    # Dashed horizontal guides, one per covariate row
    ggplot2::geom_hline(
      yintercept = seq_len(n_vars),
      linetype   = hline_linetype,
      linewidth  = hline_linewidth,
      color      = "black"
    ) +
    # Points — shape and colour mapped to group; no defaults applied
    ggplot2::geom_point(
      ggplot2::aes(
        x      = .data[[std_diff_col]],
        y      = .data[["cb_index"]],
        shape  = .data[[group_col]],
        colour = .data[[group_col]]
      ),
      size = point_size
    ) +
    # Y-axis: integer positions labelled with covariate names
    ggplot2::scale_y_continuous(
      limits = c(0, n_vars + 1.75),
      breaks = seq_len(n_vars),
      labels = var_levels
    )
}

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

#' Covariate Balance Plot
#'
#' Draws the classic HVI covariate balance figure used to assess propensity
#' score matching or IPTW quality. Each covariate appears as a labelled row;
#' points display the standardized mean difference for each group (e.g. before
#' and after matching). A solid reference line marks zero; dotted reference
#' lines mark a user-supplied imbalance threshold (default +/-10\%).
#'
#' The function returns a bare `ggplot` object with no colour, shape, axis, or
#' theme applied. Callers are expected to add those with the usual `+`
#' operator, keeping the workflow flexible and consistent with the rest of
#' the package.
#'
#' @param data A data frame in **long format** with one row per
#'   covariate x group combination. Wide-format data (one column per group)
#'   must be reshaped before passing, e.g. with [tidyr::pivot_longer()] or
#'   [stats::reshape()].
#' @param variable_col Name of the column containing covariate labels.
#'   Default `"variable"`.
#' @param group_col Name of the column identifying the comparison group
#'   (e.g. `"Before match"` / `"After match"`). Default `"group"`.
#' @param std_diff_col Name of the numeric column holding the standardized
#'   mean difference values. Default `"std_diff"`.
#' @param var_levels Character vector controlling the **display order** of
#'   covariates on the y-axis. The first element appears at the bottom.
#'   Defaults to the order of first appearance in `data[[variable_col]]`.
#' @param threshold Numeric value (absolute) for the dotted imbalance
#'   reference lines drawn at `+/-threshold`. Default `10`.
#' @param point_size Passed to [ggplot2::geom_point()]. Default `3`.
#' @param hline_linetype Linetype for the horizontal covariate guide lines.
#'   Default `"dashed"`.
#' @param hline_linewidth Linewidth for the horizontal guide lines.
#'   Default `0.25`.
#' @param vline_linewidth Linewidth for the solid zero reference line.
#'   Default `0.2`.
#' @param threshold_linetype Linetype for the +/-threshold reference lines.
#'   Default `"dotted"`.
#'
#' @return A bare [ggplot2::ggplot()] object. Layer on
#'   [ggplot2::scale_color_manual()], [ggplot2::scale_shape_manual()],
#'   [ggplot2::scale_x_continuous()], [ggplot2::labs()],
#'   [ggplot2::annotate()], and a theme to complete the figure.
#'
#' @examples
#' library(ggplot2)
#'
#' dta <- sample_covariate_balance_data()
#'
#' # Bare plot
#' covariate_balance(dta)
#'
#' # Add colour, shape, and axis scales
#' covariate_balance(dta) +
#'   scale_color_manual(
#'     values = c("Before match" = "red4", "After match" = "blue3"),
#'     name   = NULL
#'   ) +
#'   scale_shape_manual(
#'     values = c("Before match" = 17L, "After match" = 15L),
#'     name   = NULL
#'   ) +
#'   scale_x_continuous(limits = c(-45, 35), breaks = seq(-40, 30, 10)) +
#'   labs(
#'     x = "Standardized difference: Group A vs Group B (%)",
#'     y = ""
#'   ) +
#'   theme(legend.position = c(0.20, 0.95))
#'
#' # Add directional annotations and theme
#' covariate_balance(dta) +
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
#'   annotate("text", x = -32, y =  0.5,
#'            label = "More likely Group B", size = 4) +
#'   annotate("text", x =  22, y = 13.5,
#'            label = "More likely Group A", size = 4) +
#'   hvtiPlotR::hvti_theme("manuscript")
#'
#' @export
covariate_balance <- function(
  data,
  variable_col       = "variable",
  group_col          = "group",
  std_diff_col       = "std_diff",
  var_levels         = NULL,
  threshold          = 10,
  point_size         = 3,
  hline_linetype     = "dashed",
  hline_linewidth    = 0.25,
  vline_linewidth    = 0.2,
  threshold_linetype = "dotted"
) {
  cb_validate_input(data, variable_col, group_col, std_diff_col)

  if (is.null(var_levels))
    var_levels <- unique(as.character(data[[variable_col]]))

  data[["cb_index"]] <- as.integer(
    factor(data[[variable_col]], levels = var_levels)
  )

  cb_build_plot(
    data               = data,
    std_diff_col       = std_diff_col,
    group_col          = group_col,
    var_levels         = var_levels,
    threshold          = threshold,
    point_size         = point_size,
    hline_linetype     = hline_linetype,
    hline_linewidth    = hline_linewidth,
    vline_linewidth    = vline_linewidth,
    threshold_linetype = threshold_linetype
  )
}

# ---------------------------------------------------------------------------
# Sample data generator
# ---------------------------------------------------------------------------

#' Generate Sample Covariate Balance Data
#'
#' Produces a reproducible long-format data frame suitable for testing and
#' demonstrating [covariate_balance()]. Each covariate gets two rows, one per
#' group level, with plausible standardized mean difference values: larger
#' (more imbalanced) before matching, near-zero after matching.
#'
#' @param n_vars Integer. Number of covariates to generate. Default `12`.
#' @param group_levels Length-2 character vector of group labels. Default
#'   `c("Before match", "After match")`.
#' @param seed Integer random seed for reproducibility. Default `42`.
#'
#' @return A data frame with columns `variable`, `group`, and `std_diff`.
#'
#' @examples
#' dta <- sample_covariate_balance_data()
#' head(dta)
#'
#' dta2 <- sample_covariate_balance_data(
#'   n_vars       = 8,
#'   group_levels = c("Unweighted", "IPTW weighted")
#' )
#'
#' @importFrom stats rnorm
#' @export
sample_covariate_balance_data <- function(
  n_vars       = 12,
  group_levels = c("Before match", "After match"),
  seed         = 42
) {
  if (!is.numeric(n_vars) || length(n_vars) != 1L || n_vars < 1L)
    stop("`n_vars` must be a positive integer scalar.", call. = FALSE)
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

  set.seed(seed)
  before <- round(stats::rnorm(n_vars, mean = 0, sd = 14), 1)
  after  <- round(stats::rnorm(n_vars, mean = 0, sd =  3), 1)

  rbind(
    data.frame(variable = var_names, group = group_levels[1],
               std_diff = before, stringsAsFactors = FALSE),
    data.frame(variable = var_names, group = group_levels[2],
               std_diff = after,  stringsAsFactors = FALSE)
  )
}
