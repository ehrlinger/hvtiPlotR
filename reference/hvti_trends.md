# Prepare temporal trend data for plotting

Validates a patient-level data frame, computes per-x-value summary
statistics (mean or median), and returns an `hvti_trends` object. Call
[`plot.hvti_trends`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hvti_trends.md)
on the result to obtain a bare `ggplot2` trend plot (LOESS smooth +
annual summary points) that you can decorate with colour scales, axis
limits, and
[`hvti_theme`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md).

## Usage

``` r
hvti_trends(
  data,
  x_col = "year",
  y_col = "value",
  group_col = "group",
  summary_fn = c("mean", "median")
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

  Function used to compute the per-x-point estimate: `"mean"` or
  `"median"`. Default `"mean"`.

## Value

An object of class `c("hvti_trends", "hvti_data")`:

- `$data`:

  The original patient-level data frame.

- `$meta`:

  Named list: `x_col`, `y_col`, `group_col`, `summary_fn`, `n_obs`,
  `n_groups`.

- `$tables`:

  List with one element: `summary` — a data frame of per-x (per-group)
  summary statistics used for the point overlay.

## See also

[`plot.hvti_trends`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hvti_trends.md),
[`sample_trends_data`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_trends_data.md)

## Examples

``` r
dta <- sample_trends_data(n = 600, year_range = c(1985L, 2015L),
  groups = c("I", "II", "III", "IV"))
tr  <- hvti_trends(dta, summary_fn = "median")
tr   # prints observation and group counts
#> <hvti_trends>
#>   N obs       : 600  (4 groups)
#>   x / y       : year / value
#>   Group col   : group
#>   Summary fn  : median

plot(tr) +
  ggplot2::scale_colour_manual(
    values = c(I = "steelblue", II = "firebrick",
               III = "forestgreen", IV = "goldenrod3"),
    name = "NYHA Class"
  ) +
  ggplot2::scale_x_continuous(limits = c(1985, 2015),
                              breaks = seq(1985, 2015, 5)) +
  ggplot2::scale_y_continuous(limits = c(0, 80),
                              breaks = seq(0, 80, 20)) +
  ggplot2::coord_cartesian(xlim = c(1985, 2015), ylim = c(0, 80)) +
  ggplot2::labs(x = "Years", y = "%") +
  hvti_theme("manuscript")

```
