# Prepare parametric hazard / survival data for plotting

Validates and stores pre-computed parametric curve data — and optional
Kaplan-Meier empirical overlay and population life-table reference — as
an `hv_hazard` object. Pass the result to
[`plot.hv_hazard()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_hazard.md)
to render the figure.

## Usage

``` r
hv_hazard(
  curve_data,
  x_col = "time",
  estimate_col = "survival",
  lower_col = NULL,
  upper_col = NULL,
  group_col = NULL,
  empirical = NULL,
  emp_x_col = x_col,
  emp_estimate_col = "estimate",
  emp_lower_col = NULL,
  emp_upper_col = NULL,
  emp_group_col = group_col,
  emp_geom = c("point", "step"),
  reference = NULL,
  ref_x_col = x_col,
  ref_estimate_col = estimate_col,
  ref_group_col = NULL
)
```

## Arguments

- curve_data:

  Data frame of parametric predictions (fine grid). Typical source: SAS
  `predict` dataset exported to CSV, or
  [`sample_hazard_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_hazard_data.md).

- x_col:

  Name of the time / age column. Default `"time"`.

- estimate_col:

  Name of the predicted-value column: `"survival"`, `"hazard"`, or
  `"cumhaz"`. Default `"survival"`.

- lower_col:

  Lower CI column in `curve_data`, or `NULL` for no ribbon. Default
  `NULL`.

- upper_col:

  Upper CI column in `curve_data`, or `NULL`. Default `NULL`.

- group_col:

  Stratification column in `curve_data`, or `NULL` for a single curve.
  Default `NULL`.

- empirical:

  Optional data frame of KM empirical points (SAS `plout` dataset).
  Stored in `$tables$empirical`. Default `NULL`.

- emp_x_col:

  x column in `empirical`. Defaults to `x_col`.

- emp_estimate_col:

  y column in `empirical`. Default `"estimate"`.

- emp_lower_col:

  Lower error-bar column in `empirical`, or `NULL`. Default `NULL`.

- emp_upper_col:

  Upper error-bar column in `empirical`, or `NULL`. Default `NULL`.

- emp_group_col:

  Group column in `empirical`. Defaults to `group_col`.

- emp_geom:

  Geom used for the empirical overlay: `"point"` (default, open circles)
  or `"step"` (Kaplan-Meier step function).

- reference:

  Optional data frame of population life-table curves (SAS `smatched`
  dataset). Stored in `$tables$reference`. Default `NULL`.

- ref_x_col:

  x column in `reference`. Defaults to `x_col`.

- ref_estimate_col:

  y column in `reference`. Defaults to `estimate_col`.

- ref_group_col:

  Linetype-grouping column in `reference`, or `NULL`. Default `NULL`.

## Value

An S3 object of class `c("hv_hazard", "hv_data")`; call
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) on the result
to render — see
[`plot.hv_hazard()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_hazard.md).
The object contains: `$data` (curve data frame), `$meta` (all
column-name mappings), `$tables$empirical`, `$tables$reference`.

## Details

This constructor covers the complete `tp.hp.dead.*` SAS template family.
All column-name mappings and all three data frames are fixed at
construction time; aesthetic parameters (`ci_alpha`, `line_width`, etc.)
are passed to [`plot()`](https://rdrr.io/r/graphics/plot.default.html).

## See also

[`plot.hv_hazard()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_hazard.md)
to render as a ggplot2 figure,
[`theme_hv_manuscript()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md)
for the publication theme,
[`sample_hazard_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_hazard_data.md),
[`sample_hazard_empirical()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_hazard_empirical.md),
[`sample_life_table()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_life_table.md)
for example data.

Other Hazard plot:
[`plot.hv_hazard()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_hazard.md)

## Examples

``` r
library(ggplot2)

dat <- sample_hazard_data(n = 500, time_max = 10)
emp <- sample_hazard_empirical(n = 500, time_max = 10, n_bins = 6)

# 1. Build data object
hp <- hv_hazard(dat,
  lower_col     = "surv_lower", upper_col = "surv_upper",
  empirical     = emp,
  emp_lower_col = "lower",     emp_upper_col = "upper"
)
hp  # prints CI and empirical flags
#> <hv_hazard>
#>   x col       : time
#>   estimate    : survival
#>   CI          : surv_lower -- surv_upper
#>   $data       : 500 rows × 10 cols
#>   $empirical  : 6 rows

# 2. Bare plot -- undecorated ggplot returned by plot.hv_hazard
p <- plot(hp)

# 3. Decorate: colour/fill palettes, axis scales, labels, theme
p +
  scale_colour_manual(values = c("steelblue"), guide = "none") +
  scale_fill_manual(values   = c("steelblue"), guide = "none") +
  scale_x_continuous(limits = c(0, 10), breaks = 0:10) +
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 20),
                     labels = function(x) paste0(x, "%")) +
  labs(x = "Years", y = "Survival (%)") +
  theme_hv_poster()


# Stratified groups -- colour scale adds clinical meaning
dat2 <- sample_hazard_data(
  n = 400, groups = c("No Takedown" = 1.0, "Takedown" = 0.65)
)
hp2 <- hv_hazard(dat2,
  lower_col = "surv_lower", upper_col = "surv_upper",
  group_col = "group"
)
plot(hp2) +
  scale_colour_manual(
    values = c("No Takedown" = "steelblue", "Takedown" = "firebrick"),
    name   = NULL
  ) +
  labs(x = "Years", y = "Survival (%)") +
  theme_hv_poster()


# --- Global theme + RColorBrewer (set once per session) ------------------
if (FALSE) { # \dontrun{
old <- ggplot2::theme_set(theme_hv_manuscript())
plot(hp2) +
  scale_colour_brewer(palette = "Set1", name = NULL) +
  scale_fill_brewer(palette   = "Set1", guide = "none") +
  scale_x_continuous(limits = c(0, 10), breaks = 0:10) +
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 20),
                     labels = function(x) paste0(x, "%")) +
  labs(x = "Years", y = "Survival (%)")
ggplot2::theme_set(old)
} # }

# See vignette("plot-decorators", package = "hvtiPlotR") for theming,
# colour scales, annotation labels, and saving plots.
```
