# Temporal Trend Plot

Produces a temporal trend plot for one or more groups: a LOESS smooth
overlaid with annual summary-statistic points (mean or median). Accepts
patient-level data and computes the annual summaries internally,
replacing the manual `dplyr` grouping pipeline from the SAS template.

## Usage

``` r
trends_plot(
  data,
  x_col = "year",
  y_col = "value",
  group_col = "group",
  summary_fn = c("mean", "median"),
  smoother = "loess",
  span = 0.75,
  se = FALSE,
  point_size = 2.5,
  point_shape = 19L,
  alpha = 0.2
)
```

## Arguments

- data:

  Patient-level data frame (one row per patient).

- x_col:

  Name of the numeric/integer time column (e.g. surgery year). Default
  `"year"`.

- y_col:

  Name of the continuous outcome column. Default `"value"`.

- group_col:

  Name of the grouping column, or `NULL` for a single group. Default
  `"group"`.

- summary_fn:

  Function used to compute the annual point estimate: `"mean"` or
  `"median"`. Default `"mean"`.

- smoother:

  Smoothing method passed to
  [`ggplot2::geom_smooth()`](https://ggplot2.tidyverse.org/reference/geom_smooth.html):
  `"loess"` (default) or any method accepted by
  [`geom_smooth()`](https://ggplot2.tidyverse.org/reference/geom_smooth.html).

- span:

  Span for LOESS smoother. Default `0.75`.

- se:

  Logical; show confidence ribbon around smooth? Default `FALSE`.

- point_size:

  Size of the annual summary points. Default `2.5`.

- point_shape:

  Integer shape code for the summary points, or a named integer vector
  (one per group level) for different shapes per group. Default `19`.

- alpha:

  Transparency of the smooth ribbon when `se = TRUE`. Default `0.2`.

## Value

A
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Details

Returns a bare ggplot object. Compose with `scale_colour_*`,
`scale_shape_*`,
[`labs()`](https://ggplot2.tidyverse.org/reference/labs.html),
[`annotate()`](https://ggplot2.tidyverse.org/reference/annotate.html),
[`ggplot2::coord_cartesian()`](https://ggplot2.tidyverse.org/reference/coord_cartesian.html),
and
[`hvti_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md).

## See also

[`sample_trends_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_trends_data.md),
[`hvti_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md)

## Examples

``` r
# --- tp.rp.trends.sas: single continuous outcome, 1968-2000 by 4 ----------
one <- sample_trends_data(n = 600, year_range = c(1968L, 2000L),
                          groups = NULL)
trends_plot(one, group_col = NULL) +
  ggplot2::scale_x_continuous(limits = c(1968, 2000),
                              breaks = seq(1968, 2000, 4)) +
  ggplot2::scale_y_continuous(limits = c(0, 10),
                              breaks = seq(0, 10, 2)) +
  ggplot2::labs(x = "Year", y = "Cases/year") +
  hvti_theme("manuscript")
#> Warning: Removed 600 rows containing non-finite outside the scale range
#> (`stat_smooth()`).
#> Warning: Removed 33 rows containing missing values or values outside the scale range
#> (`geom_point()`).


# --- tp.lp.trends.sas: binary % outcomes, 1970-2000 by 10 ---------------
dta_lp <- sample_trends_data(
  n = 800, year_range = c(1970L, 2000L),
  groups = c("Shock %", "Pre-op IABP %", "Inotropes %"))
trends_plot(dta_lp) +
  ggplot2::scale_colour_manual(
    values = c("Shock %" = "steelblue", "Pre-op IABP %" = "firebrick",
               "Inotropes %" = "forestgreen"), name = NULL) +
  ggplot2::scale_x_continuous(limits = c(1970, 2000),
                              breaks = seq(1970, 2000, 10)) +
  ggplot2::scale_y_continuous(limits = c(0, 100),
                              breaks = seq(0, 100, 10)) +
  ggplot2::coord_cartesian(xlim = c(1970, 2000), ylim = c(0, 100)) +
  ggplot2::labs(x = "Year", y = "Percent (%)") +
  hvti_theme("manuscript")


# --- tp.lp.trends.age.sas: age on x-axis, 25-85 by 10 -------------------
dta_age <- sample_trends_data(
  n = 600, year_range = c(25L, 85L),
  groups = c("Repair %", "Bioprosthesis %"), seed = 7L)
trends_plot(dta_age) +
  ggplot2::scale_x_continuous(limits = c(25, 85),
                              breaks = seq(25, 85, 10)) +
  ggplot2::scale_y_continuous(limits = c(0, 100),
                              breaks = seq(0, 100, 20)) +
  ggplot2::coord_cartesian(xlim = c(25, 85), ylim = c(0, 100)) +
  ggplot2::labs(x = "Age (years)", y = "Percent (%)") +
  hvti_theme("manuscript")
#> Warning: Removed 1 row containing non-finite outside the scale range (`stat_smooth()`).


# --- tp.lp.trends.polytomous.sas: repair types, 1990-1999 by 1 ----------
dta_poly <- sample_trends_data(
  n = 800, year_range = c(1990L, 1999L),
  groups = c("CE", "Cosgrove", "Periguard", "DeVega"), seed = 5L)
trends_plot(dta_poly) +
  ggplot2::scale_colour_manual(
    values = c(CE = "steelblue", Cosgrove = "firebrick",
               Periguard = "forestgreen", DeVega = "goldenrod3"),
    name = "Repair type") +
  ggplot2::scale_x_continuous(limits = c(1990, 1999),
                              breaks = seq(1990, 1999, 1)) +
  ggplot2::scale_y_continuous(limits = c(0, 100),
                              breaks = seq(0, 100, 10)) +
  ggplot2::coord_cartesian(xlim = c(1990, 1999), ylim = c(0, 100)) +
  ggplot2::labs(x = "Year", y = "Percent (%)") +
  hvti_theme("manuscript")


# --- tp.dp.trends.R: NYHA classes, 1985-2015 by 5 -----------------------
dta_nyha <- sample_trends_data(n = 800, year_range = c(1985L, 2015L),
  groups = c("I", "II", "III", "IV"))
trends_plot(dta_nyha, summary_fn = "median") +
  ggplot2::scale_colour_manual(
    values = c(I = "steelblue", II = "firebrick",
               III = "forestgreen", IV = "goldenrod3"),
    name = "NYHA Class") +
  ggplot2::scale_x_continuous(limits = c(1985, 2015),
                              breaks = seq(1985, 2015, 5)) +
  ggplot2::scale_y_continuous(limits = c(0, 80),
                              breaks = seq(0, 80, 20)) +
  ggplot2::coord_cartesian(xlim = c(1985, 2015), ylim = c(0, 80)) +
  ggplot2::labs(x = "Years", y = "%") +
  hvti_theme("manuscript")


# --- tp.dp.trends.R: LV mass index, 1995-2015 by 5 ----------------------
dta_lv <- sample_trends_data(n = 800, year_range = c(1995L, 2015L),
                             groups = NULL, seed = 3L)
trends_plot(dta_lv, group_col = NULL) +
  ggplot2::scale_x_continuous(limits = c(1995, 2015),
                              breaks = seq(1995, 2015, 5)) +
  ggplot2::scale_y_continuous(limits = c(0, 200),
                              breaks = seq(0, 200, 50)) +
  ggplot2::coord_cartesian(xlim = c(1995, 2015), ylim = c(0, 200)) +
  ggplot2::labs(x = "Years", y = "LV Mass Index") +
  hvti_theme("manuscript")


# --- tp.dp.trends.R: LOS with annotation, 1985-2015 by 5 ----------------
dta_los <- sample_trends_data(n = 800, year_range = c(1985L, 2015L),
                              groups = NULL, seed = 11L)
trends_plot(dta_los, group_col = NULL) +
  ggplot2::scale_x_continuous(limits = c(1985, 2015),
                              breaks = seq(1985, 2015, 5)) +
  ggplot2::scale_y_continuous(limits = c(0, 20),
                              breaks = seq(0, 20, 5)) +
  ggplot2::coord_cartesian(xlim = c(1985, 2015), ylim = c(0, 20)) +
  ggplot2::annotate("text", x = 1995, y = 18,
                    label = "Trend: Hospital Length of Stay", size = 4.5) +
  ggplot2::labs(x = "Years", y = "Hospital LOS (Days)") +
  hvti_theme("manuscript")
#> Warning: Removed 797 rows containing non-finite outside the scale range
#> (`stat_smooth()`).
#> Warning: span too small.   fewer data values than degrees of freedom.
#> Warning: pseudoinverse used at 2009
#> Warning: neighborhood radius 5.03
#> Warning: reciprocal condition number  0
#> Warning: There are other near singularities as well. 1.0609
#> Warning: Removed 31 rows containing missing values or values outside the scale range
#> (`geom_point()`).


# --- Save ----------------------------------------------------------------
if (FALSE) { # \dontrun{
p <- trends_plot(dta_nyha) +
  ggplot2::scale_colour_brewer(palette = "Set1", name = "NYHA Class") +
  ggplot2::scale_x_continuous(limits = c(1985, 2015),
                              breaks = seq(1985, 2015, 5)) +
  ggplot2::labs(x = "Years", y = "%") +
  hvti_theme("manuscript")
ggplot2::ggsave("trends.pdf", p, width = 11.5, height = 8)
} # }
```
