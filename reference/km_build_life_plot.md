# Build bare integrated survivorship ggplot (PLOTL)

Plots the cumulative integral of the survival function (restricted mean
survival time, LIFE) against time, matching the SAS `%kaplan` `PLOTL=1`
output. The proportionate life length (`proplife = LIFE / t`) is also
available in `km_data` for a secondary plot.

## Usage

``` r
km_build_life_plot(km_df, alpha)
```

## Arguments

- km_df:

  Tidy KM data frame from `km_extract_tidy`.

## Value

A bare `ggplot` object.
