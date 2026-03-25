# eda-plots.R
#
# EDA barplot / scatterplot for one variable at a time.
# Ports Function_DataPlotting() from
# tp.dp.EDA_barplots_scatterplots.R / Barplot_Scatterplot_Function.R
# and tp.dp.EDA_barplots_scatterplots_varnames.R to ggplot2,
# replacing base-R graphics with composable ggplot objects.
#
# Key differences from the templates:
#  - Returns a single bare ggplot object per call (caller loops over variables)
#  - Variable type auto-detected by eda_classify_var(); callable independently
#  - eda_select_vars() replaces Order_Variables() + Mod_Data <- dta[, Order_Var]
#  - y_label parameter replaces the var_labels / var.names override pattern
#  - No hard-coded colours: examples use scale_fill_manual() / scale_fill_brewer()
#  - No explicit theme: examples apply hvti_theme("manuscript")
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
#' [eda_plot()] and [eda_select_vars()]. The data mimics a cardiac surgery
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
#' @seealso [eda_plot()], [eda_classify_var()], [eda_select_vars()]
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
#' @seealso [eda_plot()]
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

#' EDA Barplot / Scatterplot for One Variable
#'
#' Produces an exploratory data analysis plot for a single variable against a
#' reference time axis. Variable type is detected automatically using
#' [eda_classify_var()]:
#'
#' - **Continuous** (`"Cont"`): scatter of `y_col` vs `x_col` with a LOESS
#'   smoother overlay and a rug on the x-axis for observations where `y_col`
#'   is missing.
#' - **Numeric categorical** (`"Cat_Num"`): stacked bar chart of counts (or
#'   proportions when `show_percent = TRUE`) per `x_col` level.
#' - **Character categorical** (`"Cat_Char"`): same stacked bar, colouring
#'   each string level separately.
#'
#' In all cases `NA` values are shown as an explicit fill level labelled
#' `"(Missing)"`, so they can be coloured via `scale_fill_manual()`.
#'
#' Use [eda_select_vars()] to pick a named subset of variables before
#' iterating with `lapply()`.
#'
#' Returns a bare [ggplot2::ggplot()] object. Compose with `scale_fill_*`,
#' `scale_colour_*`, `labs()`, `annotate()`, and [hvti_theme()].
#'
#' @param data         Data frame; one row per observation.
#' @param x_col        Name of the reference (time/grouping) column. Used as
#'   the x-axis for both scatter and bar plots. For barplots it is coerced to
#'   a factor. Default `"year"`.
#' @param y_col        Name of the variable to plot. Default `"ef"`.
#' @param y_label      Optional human-readable label for the variable, used as
#'   the plot title, y-axis label (continuous), and fill-legend name
#'   (categorical). When `NULL` (default), `y_col` is used. Matches the
#'   `var_labels` / `var.names` override in
#'   `tp.dp.EDA_barplots_scatterplots_varnames.R`.
#' @param unique_limit Integer threshold passed to [eda_classify_var()] to
#'   distinguish categorical from continuous numeric columns. Default `6`.
#' @param show_percent Logical; for categorical plots, use proportions
#'   (`position = "fill"`) instead of counts (`position = "stack"`)?
#'   Default `FALSE`.
#' @param smooth_method Smoothing method for continuous plots, passed to
#'   [ggplot2::geom_smooth()]. Default `"loess"`.
#' @param smooth_span  LOESS span. Default `0.8`.
#' @param smooth_se    Logical; show confidence ribbon around smooth?
#'   Default `FALSE`.
#'
#' @return A [ggplot2::ggplot()] object.
#'
#' @seealso [sample_eda_data()], [eda_classify_var()], [eda_select_vars()],
#'   [hvti_theme()]
#'
#' @references R templates: \code{tp.dp.EDA_barplots_scatterplots.R},
#'   \code{tp.dp.EDA_barplots_scatterplots_varnames.R};
#'   helper: \code{Barplot_Scatterplot_Function.R}
#'   (\code{Function_DataPlotting()}, \code{Order_Variables()}).
#'
#' @examples
#' dta <- sample_eda_data(n = 300, seed = 42)
#'
#' # --- Binary categorical: count barplot ------------------------------------
#' # male is 0/1; y_label sets title and fill legend name.
#' eda_plot(dta, x_col = "year", y_col = "male",
#'          y_label = "Sex") +
#'   ggplot2::scale_fill_manual(
#'     values = c("0" = "steelblue", "1" = "firebrick", "(Missing)" = "grey80"),
#'     labels = c("0" = "Female", "1" = "Male", "(Missing)" = "Missing"),
#'     name   = NULL
#'   ) +
#'   ggplot2::scale_x_discrete(breaks = seq(2005, 2020, 5)) +
#'   ggplot2::labs(x = "Surgery Year", y = "Count") +
#'   hvti_theme("manuscript")
#'
#' # --- Binary categorical: percentage barplot -------------------------------
#' eda_plot(dta, x_col = "year", y_col = "cabg",
#'          y_label = "Concomitant CABG", show_percent = TRUE) +
#'   ggplot2::scale_fill_manual(
#'     values = c("0" = "grey70", "1" = "steelblue", "(Missing)" = "grey90"),
#'     labels = c("0" = "No CABG", "1" = "CABG", "(Missing)" = "Missing"),
#'     name   = NULL
#'   ) +
#'   ggplot2::scale_x_discrete(breaks = seq(2005, 2020, 5)) +
#'   ggplot2::scale_y_continuous(labels = scales::percent) +
#'   ggplot2::labs(x = "Surgery Year", y = "Proportion") +
#'   hvti_theme("manuscript")
#'
#' # --- Ordinal categorical (4 levels) with RColorBrewer --------------------
#' eda_plot(dta, x_col = "year", y_col = "nyha",
#'          y_label = "Preoperative NYHA Class") +
#'   ggplot2::scale_fill_brewer(
#'     palette = "RdYlGn", direction = -1,
#'     labels  = c("1" = "I", "2" = "II", "3" = "III", "4" = "IV",
#'                 "(Missing)" = "Missing"),
#'     name    = "NYHA"
#'   ) +
#'   ggplot2::scale_x_discrete(breaks = seq(2005, 2020, 5)) +
#'   ggplot2::labs(x = "Surgery Year", y = "Count") +
#'   hvti_theme("manuscript")
#'
#' # --- Character categorical -----------------------------------------------
#' eda_plot(dta, x_col = "year", y_col = "valve_morph",
#'          y_label = "Valve Morphology") +
#'   ggplot2::scale_fill_manual(
#'     values = c(Bicuspid  = "steelblue",
#'                Tricuspid = "firebrick",
#'                Unicuspid = "goldenrod3",
#'                "(Missing)" = "grey80"),
#'     name = "Morphology"
#'   ) +
#'   ggplot2::scale_x_discrete(breaks = seq(2005, 2020, 5)) +
#'   ggplot2::labs(x = "Surgery Year", y = "Count") +
#'   hvti_theme("manuscript")
#'
#' # --- Continuous: scatter + LOESS -----------------------------------------
#' eda_plot(dta, x_col = "op_years", y_col = "ef",
#'          y_label = "Ejection Fraction (%)") +
#'   ggplot2::scale_colour_manual(values = c("firebrick"), guide = "none") +
#'   ggplot2::scale_x_continuous(breaks = seq(0, 15, 5)) +
#'   ggplot2::scale_y_continuous(limits = c(20, 80),
#'                               breaks = seq(20, 80, 20)) +
#'   ggplot2::labs(x = "Years from First Surgery Year",
#'                 caption = "Tick marks: observations with missing EF") +
#'   hvti_theme("manuscript")
#'
#' # --- Continuous: annotated -----------------------------------------------
#' eda_plot(dta, x_col = "op_years", y_col = "peak_grad",
#'          y_label = "Peak Gradient (mmHg)") +
#'   ggplot2::scale_colour_manual(values = c("steelblue"), guide = "none") +
#'   ggplot2::scale_x_continuous(breaks = seq(0, 15, 5)) +
#'   ggplot2::labs(x = "Years from First Surgery Year") +
#'   ggplot2::annotate("text", x = 12, y = 70,
#'                     label = "LOESS span = 0.8",
#'                     size = 3, colour = "grey40", fontface = "italic") +
#'   hvti_theme("manuscript")
#'
#' # --- Variable selection + labels (varnames template pattern) --------------
#' # Matches Var_CatList / var_labels workflow in
#' # tp.dp.EDA_barplots_scatterplots_varnames.R.
#' # Named vector: names = column names, values = human-readable labels.
#' bin_vars <- c(male = "Sex (Male)", cabg = "Concomitant CABG")
#' sub_bin  <- eda_select_vars(dta, c("year", names(bin_vars)))
#' p_bin <- lapply(names(bin_vars), function(cn) {
#'   eda_plot(sub_bin, x_col = "year", y_col = cn,
#'            y_label = bin_vars[[cn]]) +
#'     ggplot2::scale_fill_brewer(palette = "Set1", direction = -1,
#'                                name = NULL) +
#'     ggplot2::scale_x_discrete(breaks = seq(2005, 2020, 5)) +
#'     ggplot2::labs(x = "Surgery Year", y = "Count") +
#'     hvti_theme("manuscript")
#' })
#' p_bin[[1]]
#' p_bin[[2]]
#'
#' # --- Variable selection: ordinal / multi-level categorical ----------------
#' # Matches Var_CatList with Min_Categories=3, Max_Categories=7.
#' cat_vars <- c(nyha        = "NYHA Class",
#'               valve_morph = "Valve Morphology")
#' sub_cat <- eda_select_vars(dta, c("year", names(cat_vars)))
#' p_cat <- lapply(names(cat_vars), function(cn) {
#'   eda_plot(sub_cat, x_col = "year", y_col = cn,
#'            y_label = cat_vars[[cn]]) +
#'     ggplot2::scale_fill_brewer(palette = "Set2", name = NULL) +
#'     ggplot2::scale_x_discrete(breaks = seq(2005, 2020, 5)) +
#'     ggplot2::labs(x = "Surgery Year", y = "Count") +
#'     hvti_theme("manuscript")
#' })
#' p_cat[[1]]
#'
#' # --- Variable selection: continuous ---------------------------------------
#' # Matches Var_ContList / var_labels workflow.
#' cont_vars <- c(ef        = "Ejection Fraction (%)",
#'                lv_mass   = "LV Mass Index (g/m\u00b2)",
#'                peak_grad = "Peak Gradient (mmHg)")
#' sub_cont <- eda_select_vars(dta, c("op_years", names(cont_vars)))
#' p_cont <- lapply(names(cont_vars), function(cn) {
#'   eda_plot(sub_cont, x_col = "op_years", y_col = cn,
#'            y_label = cont_vars[[cn]]) +
#'     ggplot2::scale_colour_manual(values = c("steelblue"), guide = "none") +
#'     ggplot2::scale_x_continuous(breaks = seq(0, 15, 5)) +
#'     ggplot2::labs(x = "Years from First Surgery Year") +
#'     hvti_theme("manuscript")
#' })
#' p_cont[[1]]
#'
#' # --- Save: multi-page PDF via ggsave + gridExtra -------------------------
#' \dontrun{
#' all_plots <- c(p_bin, p_cat, p_cont)
#' per_page  <- 9L  # 3 x 3 grid
#' for (pg in seq(1, length(all_plots), by = per_page)) {
#'   idx  <- seq(pg, min(pg + per_page - 1L, length(all_plots)))
#'   grob <- gridExtra::marrangeGrob(all_plots[idx], nrow = 3, ncol = 3)
#'   ggplot2::ggsave(
#'     filename = sprintf("eda_page%02d.pdf", ceiling(pg / per_page)),
#'     plot     = grob,
#'     width    = 14, height = 14
#'   )
#' }
#' }
#'
#' @importFrom ggplot2 ggplot aes geom_point geom_smooth geom_rug geom_bar
#'   scale_y_continuous
#' @importFrom rlang .data
#' @importFrom stats na.omit
#' @export
eda_plot <- function(data,
                     x_col         = "year",
                     y_col         = "ef",
                     y_label       = NULL,
                     unique_limit  = 6L,
                     show_percent  = FALSE,
                     smooth_method = "loess",
                     smooth_span   = 0.8,
                     smooth_se     = FALSE) {

  # --- Validation -----------------------------------------------------------
  .check_df(data)
  .check_cols(data, c(x_col, y_col))

  label    <- if (!is.null(y_label)) y_label else y_col
  var_type <- eda_classify_var(data[[y_col]], unique_limit)

  # --- Continuous: scatter + LOESS ------------------------------------------
  if (var_type == "Cont") {
    df     <- data.frame(x = data[[x_col]], y = data[[y_col]])
    df_rug <- df[is.na(df$y), , drop = FALSE]

    p <- ggplot2::ggplot(df, ggplot2::aes(x = .data[["x"]],
                                          y = .data[["y"]])) +
      ggplot2::geom_point(na.rm = TRUE, size = 0.9, alpha = 0.4) +
      ggplot2::geom_smooth(
        method    = smooth_method,
        formula   = y ~ x,
        span      = smooth_span,
        se        = smooth_se,
        linewidth = 1,
        na.rm     = TRUE
      )

    if (nrow(df_rug) > 0L) {
      p <- p + ggplot2::geom_rug(
        data        = df_rug,
        mapping     = ggplot2::aes(x = .data[["x"]]),
        sides       = "b",
        colour      = "grey50",
        inherit.aes = FALSE
      )
    }

    return(p + ggplot2::labs(x = x_col, y = label, title = label))
  }

  # --- Categorical: stacked bar ---------------------------------------------
  # Make NA an explicit factor level so it appears in the fill legend
  yv  <- as.character(data[[y_col]])
  yv[is.na(yv)] <- "(Missing)"

  # Natural sort for Cat_Num; original order + (Missing) last for Cat_Char
  if (var_type == "Cat_Num") {
    base_levels <- as.character(sort(unique(na.omit(data[[y_col]]))))
  } else {
    base_levels <- unique(as.character(na.omit(data[[y_col]])))
  }
  yf <- factor(yv, levels = c(base_levels, "(Missing)"))

  df    <- data.frame(x = factor(data[[x_col]]), fill = yf)
  y_lab <- if (show_percent) "Proportion" else "Count"
  pos   <- if (show_percent) "fill" else "stack"

  p <- ggplot2::ggplot(df, ggplot2::aes(x    = .data[["x"]],
                                        fill = .data[["fill"]])) +
    ggplot2::geom_bar(position = pos) +
    ggplot2::labs(x = x_col, y = y_lab, fill = label, title = label)

  if (show_percent) {
    p <- p + ggplot2::scale_y_continuous(
      labels = if (requireNamespace("scales", quietly = TRUE))
        scales::percent else NULL
    )
  }

  p
}
