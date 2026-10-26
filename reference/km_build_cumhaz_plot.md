# Build bare cumulative hazard ggplot

Build bare cumulative hazard ggplot

## Usage

``` r
km_build_cumhaz_plot(km_df, alpha, curve = "step")
```

## Arguments

- km_df:

  Tidy KM data frame.

- curve:

  `"step"` or `"line"`; see
  [`km_curve_rows()`](https://ehrlinger.github.io/hvtiPlotR/reference/km_curve_rows.md).

## Value

A bare `ggplot` object.
