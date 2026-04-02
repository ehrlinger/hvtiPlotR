# eda-plots.R
#
# EDA barplot / scatterplot for one variable at a time.
# Ports Function_DataPlotting() from
# tp.dp.EDA_barplots_scatterplots.R / Barplot_Scatterplot_Function.R
# and tp.dp.EDA_barplots_scatterplots_varnames.R to ggplot2,
# replacing base-R graphics with composable ggplot objects.
#
# Key differences from the templates:
#  - Returns a single hv_eda object per call (caller loops over variables)
#  - Variable type auto-detected by eda_classify_var(); callable independently
#  - eda_select_vars() replaces Order_Variables() + Mod_Data <- dta[, Order_Var]
#  - y_label parameter replaces the var_labels / var.names override pattern
#  - No hard-coded colours: examples use scale_fill_manual() / scale_fill_brewer()
#  - No explicit theme: examples apply hv_theme("poster")
#  - NA values shown as an explicit bar segment; colour set by scale_fill_*
#  - Continuous: geom_smooth() + geom_rug() replace base-R loess + rug()
# ---------------------------------------------------------------------------

#' Classify a Variable as Continuous or Categorical
#'
#' Replicates the type-detection logic from `Barplot_Scatterplot_Function.R`:
#' a numeric column is treated as categorical when all non-missing values are
#' non-negative whole numbers with no more than `unique_limit` distinct values.
#'
#' @param x            A vector (one column of a data frame).
#' @param unique_limit Integer threshold. Numeric columns with more distinct
#'   values than this are classified as `"Cont"`. Default `6`.
#'
#' @return A length-1 character: `"Cont"`, `"Cat_Num"`, or `"Cat_Char"`.
#'
#' @examples
#' eda_classify_var(c(0, 1, 1, 0, NA))        # "Cat_Num"
#' eda_classify_var(c(1, 2, 3, 4))            # "Cat_Num"
#' eda_classify_var(rnorm(50))                # "Cont"
#' eda_classify_var(c("A", "B", "A"))         # "Cat_Char"
#' @export
eda_classify_var <- function(x, unique_limit = 6L) {
  if (!is.numeric(x)) return("Cat_Char")
  vals  <- na.omit(x)
  n_unq <- length(unique(vals))
  if (n_unq > unique_limit)                                        return("Cont")
  if (any(vals > unique_limit) || any(vals < 0))                   return("Cont")
  if (!isTRUE(all.equal(vals, as.integer(vals),
                         check.attributes = FALSE)))               return("Cont")
  return("Cat_Num")
}

# ---------------------------------------------------------------------------

#' Sample EDA Data
#'
#' Generates a realistic mixed-type patient-level data frame for demonstrating
#' [hv_eda()] and [eda_select_vars()]. The data mimics a cardiac surgery
#' registry with binary, ordinal, character-categorical, and continuous
#' variables, plus a modest proportion of missing values.
#'
#' @param n          Number of patients. Default `300`.
#' @param year_range Integer vector `c(start, end)` for surgery years.
#'   Default `c(2005L, 2020L)`.
#' @param seed       Random seed for reproducibility. Default `42`.
#'
#' @return A data frame with columns:
#'   - `year`        — integer surgery year (discrete x for barplots)
#'   - `op_years`    — continuous years from first year in range (x for
#'     scatterplots)
#'   - `male`        — binary 0/1 (sex)
#'   - `cabg`        — binary 0/1 (concomitant CABG)
#'   - `nyha`        — ordinal 1–4 (NYHA class)
#'   - `valve_morph` — character (valve morphology: Bicuspid / Tricuspid /
#'     Unicuspid)
#'   - `ef`          — continuous ejection fraction (%)
#'   - `lv_mass`     — continuous LV mass index (g/m²)
#'   - `peak_grad`   — continuous peak gradient (mmHg)
#'
#' @seealso [hv_eda()], [eda_classify_var()], [eda_select_vars()]
#'
#' @examples
#' dta <- sample_eda_data()
#' head(dta)
#' sapply(dta, eda_classify_var)
#' @export
sample_eda_data <- function(n          = 300L,
                            year_range = c(2005L, 2020L),
                            seed       = 42L) {
  set.seed(seed)
  years    <- seq(year_range[1L], year_range[2L])
  year     <- sample(years, n, replace = TRUE)
  op_years <- year - year_range[1L] + stats::runif(n, 0, 0.99)

  male        <- stats::rbinom(n, 1L, 0.55)
  cabg        <- stats::rbinom(n, 1L, 0.30)
  nyha        <- sample(1L:4L, n, replace = TRUE,
                        prob = c(0.10, 0.35, 0.40, 0.15))
  valve_morph <- sample(c("Bicuspid", "Tricuspid", "Unicuspid"),
                        n, replace = TRUE, prob = c(0.40, 0.55, 0.05))
  ef         <- pmin(80, pmax(20, stats::rnorm(n, mean = 55, sd = 12)))
  lv_mass    <- pmax(60, stats::rnorm(n, mean = 120, sd = 30))
  peak_grad  <- pmax(0,  stats::rnorm(n, mean = 40,  sd = 15))

  ef[sample(n,        round(n * 0.08))] <- NA
  peak_grad[sample(n, round(n * 0.05))] <- NA

  data.frame(
    year        = as.integer(year),
    op_years    = round(op_years, 2),
    male        = male,
    cabg        = cabg,
    nyha        = nyha,
    valve_morph = valve_morph,
    ef          = round(ef, 1),
    lv_mass     = round(lv_mass, 1),
    peak_grad   = round(peak_grad, 1)
  )
}

# ---------------------------------------------------------------------------

#' Select and Reorder Variables from a Data Frame
#'
#' Returns the subset of `data` containing only the columns named in `vars`,
#' in the order given. Replaces the `Order_Variables()` helper and the
#' `Mod_Data <- dta[, Order_Var]` pattern from
#' `tp.dp.EDA_barplots_scatterplots_varnames.R`.
#'
#' `vars` may be supplied as a character vector or as a single
#' space-separated string (matching the `Var_CatList` / `Var_ContList` style
#' from the template).
#'
#' @param data A data frame.
#' @param vars A character vector of column names, or a single string of
#'   space-separated names, e.g. `"age ht wt bmi"`.
#'
#' @return A data frame containing only the requested columns in the requested
#'   order.
#'
#' @seealso [hv_eda()]
#'
#' @examples
#' dta <- sample_eda_data()
#'
#' # Vector form
#' sub <- eda_select_vars(dta, c("male", "cabg", "nyha"))
#' names(sub)
#'
#' # Space-separated string (matches template Var_CatList style)
#' sub2 <- eda_select_vars(dta, "male cabg nyha valve_morph")
#' names(sub2)
#' @export
eda_select_vars <- function(data, vars) {
  .check_df(data)
  if (is.character(vars) && length(vars) == 1L) {
    vars <- unlist(strsplit(trimws(vars), "\\s+"))
  }
  .check_cols(data, vars)
  data[, vars, drop = FALSE]
}

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

#' Prepare EDA data for a single variable
#'
#' Classifies \code{y_col} using \code{\link{eda_classify_var}}, pre-processes
#' categorical levels (adding an explicit \code{"(Missing)"} level), and
#' returns an \code{hv_eda} object.  Call \code{\link{plot.hv_eda}} on the
#' result to obtain a bare \code{ggplot2} barplot or scatter plot that you can
#' decorate with colour scales and \code{\link{hv_theme}}.
#'
#' Iterate over variables with \code{lapply()} after selecting columns with
#' \code{\link{eda_select_vars}}.
#'
#' @param data         Data frame; one row per observation.
#' @param x_col        Name of the reference (time/grouping) column.  Used as
#'   the x-axis for both scatter and bar plots.  Default \code{"year"}.
#' @param y_col        Name of the variable to plot.  Default \code{"ef"}.
#' @param y_label      Optional human-readable label for the variable, used as
#'   the plot title, y-axis label (continuous), and fill-legend name
#'   (categorical).  When \code{NULL} (default), \code{y_col} is used.
#' @param unique_limit Integer threshold passed to \code{\link{eda_classify_var}}
#'   to distinguish categorical from continuous numeric columns.  Default \code{6}.
#' @param show_percent Logical; for categorical plots, use proportions
#'   (\code{position = "fill"}) instead of counts (\code{position = "stack"})?
#'   Default \code{FALSE}.
#'
#' @return An object of class \code{c("hv_eda", "hv_data")}:
#' \describe{
#'   \item{\code{$data}}{Pre-processed data frame ready for plotting.  For
#'     continuous variables: two columns \code{x} and \code{y}.  For
#'     categorical variables: columns \code{x} (factor) and \code{fill}
#'     (factor with \code{"(Missing)"} as explicit level).}
#'   \item{\code{$meta}}{Named list: \code{x_col}, \code{y_col},
#'     \code{y_label}, \code{var_type} (\code{"Cont"}, \code{"Cat_Num"}, or
#'     \code{"Cat_Char"}), \code{show_percent}, \code{n_obs}.}
#'   \item{\code{$tables}}{For continuous variables: \code{rug_data} — rows
#'     where \code{y_col} is \code{NA}, used for the rug layer.  Empty list
#'     for categorical variables.}
#' }
#'
#' @seealso \code{\link{plot.hv_eda}}, \code{\link{sample_eda_data}},
#'   \code{\link{eda_classify_var}}, \code{\link{eda_select_vars}}
#'
#' @references R templates: \code{tp.dp.EDA_barplots_scatterplots.R},
#'   \code{tp.dp.EDA_barplots_scatterplots_varnames.R};
#'   helper: \code{Barplot_Scatterplot_Function.R}
#'   (\code{Function_DataPlotting()}, \code{Order_Variables()}).
#'
#' @examples
#' dta <- sample_eda_data(n = 300, seed = 42)
#'
#' # 1. Build data object (binary categorical)
#' ed <- hv_eda(dta, x_col = "year", y_col = "male", y_label = "Sex")
#' ed  # prints var_type and observation count
#'
#' # 2. Bare plot -- undecorated ggplot returned by plot.hv_eda
#' p <- plot(ed)
#'
#' # 3. Decorate: fill palette, x-axis breaks, labels, theme
#' p +
#'   ggplot2::scale_fill_manual(
#'     values = c("0" = "steelblue", "1" = "firebrick", "(Missing)" = "grey80"),
#'     labels = c("0" = "Female", "1" = "Male", "(Missing)" = "Missing"),
#'     name   = NULL
#'   ) +
#'   ggplot2::scale_x_discrete(breaks = seq(2005, 2020, 5)) +
#'   ggplot2::labs(x = "Surgery Year", y = "Count") +
#'   hv_theme("poster")
#'
#' # Continuous variable -- same 3-step pattern
#' ed2 <- hv_eda(dta, x_col = "op_years", y_col = "ef",
#'                 y_label = "Ejection Fraction (%)")
#' plot(ed2) +
#'   ggplot2::scale_colour_manual(values = c("firebrick"), guide = "none") +
#'   ggplot2::scale_x_continuous(breaks = seq(0, 15, 5)) +
#'   ggplot2::labs(x = "Years from First Surgery Year") +
#'   hv_theme("poster")
#'
#' # Variable selection + lapply (varnames template pattern)
#' cont_vars <- c(ef = "Ejection Fraction (%)",
#'                lv_mass = "LV Mass Index (g/m\u00b2)",
#'                peak_grad = "Peak Gradient (mmHg)")
#' sub_cont <- eda_select_vars(dta, c("op_years", names(cont_vars)))
#' p_cont <- lapply(names(cont_vars), function(cn) {
#'   plot(hv_eda(sub_cont, x_col = "op_years", y_col = cn,
#'                y_label = cont_vars[[cn]])) +
#'     ggplot2::scale_colour_manual(values = c("steelblue"), guide = "none") +
#'     ggplot2::scale_x_continuous(breaks = seq(0, 15, 5)) +
#'     ggplot2::labs(x = "Years from First Surgery Year") +
#'     hv_theme("poster")
#' })
#' p_cont[[1]]
#'
#' @importFrom rlang .data
#' @importFrom stats na.omit
#' @export
hv_eda <- function(data,
                     x_col        = "year",
                     y_col        = "ef",
                     y_label      = NULL,
                     unique_limit = 6L,
                     show_percent = FALSE) {
  .check_df(data)
  .check_cols(data, c(x_col, y_col))

  label    <- if (!is.null(y_label)) y_label else y_col
  var_type <- eda_classify_var(data[[y_col]], unique_limit)

  if (var_type == "Cont") {
    # --- Continuous: rename columns for predictable plotting -----------------
    plot_data <- data.frame(x = data[[x_col]], y = data[[y_col]])
    rug_data  <- plot_data[is.na(plot_data$y), , drop = FALSE]
    tables    <- list(rug_data = rug_data)

  } else {
    # --- Categorical: explicit (Missing) level --------------------------------
    yv  <- as.character(data[[y_col]])
    yv[is.na(yv)] <- "(Missing)"

    if (var_type == "Cat_Num") {
      base_levels <- as.character(sort(unique(na.omit(data[[y_col]]))))
    } else {
      base_levels <- unique(as.character(na.omit(data[[y_col]])))
    }
    yf <- factor(yv, levels = c(base_levels, "(Missing)"))

    plot_data <- data.frame(x = factor(data[[x_col]]), fill = yf)
    tables    <- list()
  }

  new_hv_data(
    data = plot_data,
    meta = list(
      x_col        = x_col,
      y_col        = y_col,
      y_label      = label,
      var_type     = var_type,
      show_percent = show_percent,
      n_obs        = nrow(data)
    ),
    tables   = tables,
    subclass = "hv_eda"
  )
}


#' Print an hv_eda object
#'
#' @param x   An \code{hv_eda} object from \code{\link{hv_eda}}.
#' @param ... Ignored.
#' @return \code{x}, invisibly.
#' @export
print.hv_eda <- function(x, ...) {
  m <- x$meta
  cat("<hv_eda>\n")
  cat(sprintf("  Variable    : %s  [%s]\n", m$y_col, m$var_type))
  cat(sprintf("  Label       : %s\n", m$y_label))
  cat(sprintf("  x col       : %s\n", m$x_col))
  cat(sprintf("  N obs       : %d\n", m$n_obs))
  if (m$var_type != "Cont" && m$show_percent)
    cat("  Mode        : proportions\n")
  invisible(x)
}


#' Plot an hv_eda object
#'
#' Draws an exploratory data analysis plot for the variable stored in the
#' \code{hv_eda} object.  Variable type (stored in \code{x$meta$var_type})
#' determines the chart:
#'
#' \describe{
#'   \item{\strong{Continuous} (\code{"Cont"})}{Scatter plot with a LOESS
#'     smoother overlay and a rug on the x-axis for rows where the outcome
#'     is missing.}
#'   \item{\strong{Numeric categorical} (\code{"Cat_Num"})}{Stacked (or filled)
#'     bar chart with counts (or proportions) per x level.}
#'   \item{\strong{Character categorical} (\code{"Cat_Char"})}{Same stacked bar,
#'     colouring each string level separately.}
#' }
#'
#' @param x             An \code{hv_eda} object.
#' @param smooth_method Smoothing method for continuous plots, passed to
#'   \code{\link[ggplot2]{geom_smooth}}. Default \code{"loess"}.
#' @param smooth_span   LOESS span. Default \code{0.8}.
#' @param smooth_se     Logical; show confidence ribbon around smooth?
#'   Default \code{FALSE}.
#' @param ...           Ignored; present for S3 consistency.
#'
#' @return A bare \code{\link[ggplot2]{ggplot}} object.
#'
#' @seealso \code{\link{hv_eda}}, \code{\link{hv_theme}}
#'
#' @examples
#' dta <- sample_eda_data(n = 300, seed = 42)
#'
#' # --- Ordinal categorical: percentage barplot ------------------------------
#' plot(hv_eda(dta, x_col = "year", y_col = "nyha",
#'               y_label = "Preoperative NYHA Class")) +
#'   ggplot2::scale_fill_brewer(
#'     palette = "RdYlGn", direction = -1,
#'     labels  = c("1" = "I", "2" = "II", "3" = "III", "4" = "IV",
#'                 "(Missing)" = "Missing"),
#'     name    = "NYHA"
#'   ) +
#'   ggplot2::scale_x_discrete(breaks = seq(2005, 2020, 5)) +
#'   ggplot2::labs(x = "Surgery Year", y = "Count") +
#'   hv_theme("poster")
#'
#' # --- Continuous: annotated -----------------------------------------------
#' plot(hv_eda(dta, x_col = "op_years", y_col = "peak_grad",
#'               y_label = "Peak Gradient (mmHg)")) +
#'   ggplot2::scale_colour_manual(values = c("steelblue"), guide = "none") +
#'   ggplot2::scale_x_continuous(breaks = seq(0, 15, 5)) +
#'   ggplot2::labs(x = "Years from First Surgery Year") +
#'   ggplot2::annotate("text", x = 12, y = 70,
#'                     label = "LOESS span = 0.8",
#'                     size = 3, colour = "grey40", fontface = "italic") +
#'   hv_theme("poster")
#'
#' @importFrom ggplot2 ggplot aes geom_point geom_smooth geom_rug geom_bar
#'   scale_y_continuous labs
#' @importFrom rlang .data
#' @export
plot.hv_eda <- function(x,
                           smooth_method = "loess",
                           smooth_span   = 0.8,
                           smooth_se     = FALSE,
                           ...) {
  data         <- x$data
  meta         <- x$meta
  var_type     <- meta$var_type
  label        <- meta$y_label
  show_percent <- meta$show_percent
  x_col_name   <- meta$x_col
  y_col_name   <- meta$y_col

  if (var_type == "Cont") {
    rug_data <- x$tables$rug_data

    p <- ggplot2::ggplot(data, ggplot2::aes(x = .data[["x"]],
                                            y = .data[["y"]])) +
      ggplot2::geom_point(na.rm = TRUE, size = 0.9, alpha = 0.4) +
      ggplot2::geom_smooth(
        method    = smooth_method,
        formula   = y ~ x,
        span      = smooth_span,
        se        = smooth_se,
        linewidth = 1,
        na.rm     = TRUE
      ) +
      ggplot2::labs(x = x_col_name, y = label, title = label)

    if (nrow(rug_data) > 0L) {
      p <- p + ggplot2::geom_rug(
        data        = rug_data,
        mapping     = ggplot2::aes(x = .data[["x"]]),
        sides       = "b",
        colour      = "grey50",
        inherit.aes = FALSE
      )
    }

    return(p)
  }

  # --- Categorical bar chart ------------------------------------------------
  y_lab <- if (show_percent) "Proportion" else "Count"
  pos   <- if (show_percent) "fill" else "stack"

  p <- ggplot2::ggplot(data, ggplot2::aes(x    = .data[["x"]],
                                          fill = .data[["fill"]])) +
    ggplot2::geom_bar(position = pos) +
    ggplot2::labs(x = x_col_name, y = y_lab, fill = label, title = label)

  if (show_percent) {
    p <- p + ggplot2::scale_y_continuous(
      labels = if (requireNamespace("scales", quietly = TRUE))
        scales::percent else NULL
    )
  }

  p
}
