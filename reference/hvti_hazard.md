# Prepare parametric hazard / survival data for plotting

Validates and stores pre-computed parametric curve data — and optional
Kaplan-Meier empirical overlay and population life-table reference — as
an `hvti_hazard` object. Pass the result to
[`plot.hvti_hazard()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hvti_hazard.md)
to render the figure.

## Usage

``` r
hvti_hazard(
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

An S3 object of class `c("hvti_hazard", "hvti_data")`; call
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) on the result
to render — see
[`plot.hvti_hazard()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hvti_hazard.md).
The object contains: `$data` (curve data frame), `$meta` (all
column-name mappings), `$tables$empirical`, `$tables$reference`.

## Details

This constructor covers the complete `tp.hp.dead.*` SAS template family.
All column-name mappings and all three data frames are fixed at
construction time; aesthetic parameters (`ci_alpha`, `line_width`, etc.)
are passed to [`plot()`](https://rdrr.io/r/graphics/plot.default.html).

## See also

[`plot.hvti_hazard()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hvti_hazard.md)
to render as a ggplot2 figure,
[`hvti_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md)
for the publication theme,
[`sample_hazard_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_hazard_data.md),
[`sample_hazard_empirical()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_hazard_empirical.md),
[`sample_life_table()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_life_table.md)
for example data.

Other Hazard plot:
[`plot.hvti_hazard()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hvti_hazard.md)

## Examples

``` r
library(ggplot2)

dat <- sample_hazard_data(n = 500, time_max = 10)
emp <- sample_hazard_empirical(n = 500, time_max = 10, n_bins = 6)

# Basic survival curve with KM overlay
hp <- hvti_hazard(dat,
  lower_col     = "surv_lower", upper_col = "surv_upper",
  empirical     = emp,
  emp_lower_col = "lower",     emp_upper_col = "upper"
)
plot(hp) +
  scale_colour_manual(values = c("steelblue"), guide = "none") +
  scale_fill_manual(values   = c("steelblue"), guide = "none") +
  scale_x_continuous(limits = c(0, 10), breaks = 0:10) +
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 20),
                     labels = function(x) paste0(x, "%")) +
  labs(x = "Years", y = "Survival (%)") +
  hvti_theme("manuscript")


# Stratified groups
dat2 <- sample_hazard_data(
  n = 400, groups = c("No Takedown" = 1.0, "Takedown" = 0.65)
)
hp2 <- hvti_hazard(dat2,
  lower_col = "surv_lower", upper_col = "surv_upper",
  group_col = "group"
)
plot(hp2) +
  scale_colour_manual(
    values = c("No Takedown" = "steelblue", "Takedown" = "firebrick"),
    name   = NULL
  ) +
  labs(x = "Years", y = "Survival (%)") +
  hvti_theme("manuscript")


# --- Global theme + RColorBrewer (set once per session) ------------------
if (FALSE) { # \dontrun{
# Apply manuscript theme globally; use scale_colour_brewer for groups.
old <- ggplot2::theme_set(hvti_theme_manuscript())
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
