# Build bare survival curve ggplot

Returns a `ggplot` with a
[`geom_step()`](https://ggplot2.tidyverse.org/reference/geom_path.html)
for the KM estimate, an optional
[`geom_ribbon()`](https://ggplot2.tidyverse.org/reference/geom_ribbon.html)
for the CI, and a `geom_hline` at zero. The y-axis is expressed as 0–100
(i.e., `surv * 100`). Color and fill are mapped to `strata` so
single-group plots display "All" as the group name; callers can suppress
the legend if desired.

## Usage

``` r
km_build_survival_plot(km_df, conf_int, alpha)
```

## Arguments

- km_df:

  Tidy KM data frame.

- conf_int:

  Logical; draw CI ribbon when `TRUE`.

## Value

A bare `ggplot` object.
