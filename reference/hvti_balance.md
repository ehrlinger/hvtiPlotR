# Prepare covariate balance data for plotting

Validates and orders a long-format standardized-mean-difference data
frame for a covariate balance plot, and returns an `hvti_balance`
object. Call
[`plot.hvti_balance`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hvti_balance.md)
on the result to obtain a bare `ggplot2` object that you can decorate
with colour, shape, axis scales, and
[`hvti_theme`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md).

## Usage

``` r
hvti_balance(
  data,
  variable_col = "variable",
  group_col = "group",
  std_diff_col = "std_diff",
  var_levels = NULL,
  threshold = 10
)
```

## Arguments

- data:

  A data frame in **long format** with one row per covariate \\\times\\
  group combination. Wide-format data must be reshaped first (e.g. with
  [`tidyr::pivot_longer()`](https://tidyr.tidyverse.org/reference/pivot_longer.html)).

- variable_col:

  Name of the column containing covariate labels. Default `"variable"`.

- group_col:

  Name of the column identifying the comparison group (e.g.
  `"Before match"` / `"After match"`). Default `"group"`.

- std_diff_col:

  Name of the numeric column holding standardized mean difference
  values. Default `"std_diff"`.

- var_levels:

  Character vector controlling the display order of covariates on the
  y-axis. The first element appears at the bottom. Defaults to the order
  of first appearance in `data[[variable_col]]`.

- threshold:

  Numeric; absolute SMD value at which dotted reference lines are drawn
  (\\\pm\\`threshold`). Default `10`.

## Value

An object of class `c("hvti_balance", "hvti_data")` — a list with three
elements:

- `$data`:

  The input data frame with a `cb_index` column added for y-axis
  positioning.

- `$meta`:

  Named list: `variable_col`, `group_col`, `std_diff_col`, `var_levels`,
  `threshold`, `n_vars`, `n_groups`.

- `$tables`:

  Empty list (no accessory tables).

## See also

[`plot.hvti_balance`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hvti_balance.md),
[`sample_covariate_balance_data`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_covariate_balance_data.md)

## Examples

``` r
library(ggplot2)
dta <- sample_covariate_balance_data()
cb  <- hvti_balance(dta)
cb                   # prints variable count, group count, threshold
#> <hvti_balance>
#>   Variables   : 12
#>   Groups      : 2 (Before match, After match)
#>   SMD col     : std_diff
#>   Threshold   : ±10

plot(cb) +
  scale_color_manual(
    values = c("Before match" = "red4", "After match" = "blue3"),
    name   = NULL
  ) +
  scale_shape_manual(
    values = c("Before match" = 17L, "After match" = 15L),
    name   = NULL
  ) +
  scale_x_continuous(limits = c(-45, 35), breaks = seq(-40, 30, 10)) +
  labs(x = "Standardized difference (%)", y = "") +
  hvti_theme("manuscript")
#> Warning: Removed 1 row containing missing values or values outside the scale range
#> (`geom_point()`).

```
