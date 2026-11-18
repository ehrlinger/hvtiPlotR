# Build bare integrated survivorship ggplot (PLOTL)

Plots the cumulative integral of the survival function (LIFE, the exact
step-function area documented in `km_extract_tidy`) against time, the
counterpart of the SAS `%kaplan` `PLOTL=1` output. The proportionate
life length (`proplife = LIFE / t`) is also available in `km_data` for a
secondary plot. The integral is piecewise linear between rows, so it is
drawn with
[`geom_line()`](https://ggplot2.tidyverse.org/reference/geom_path.html),
not as steps.

## Usage

``` r
km_build_life_plot(km_df, alpha)
```

## Arguments

- km_df:

  Tidy KM data frame from `km_extract_tidy`.

## Value

A bare `ggplot` object.
