# Build bare hazard rate ggplot

Plots the instantaneous hazard estimates computed using the SAS
`%kaplan` formula: \\h(t) = \log(S(t\_{prev}) / S(t)) / \Delta t\\,
plotted at the interval midpoint. Only event times with \\\Delta t \>
0\\ and \\S(t) \> 0\\ are shown; censoring rows are excluded. A smoother
(e.g., `geom_smooth`) is typically added by the caller.

## Usage

``` r
km_build_hazard_plot(km_df, alpha)
```

## Arguments

- km_df:

  Tidy KM data frame from `km_extract_tidy`.

## Value

A bare `ggplot` object.
