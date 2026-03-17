# Build bare log-log survival ggplot (PLOTC extension)

Plots \\\log H(t) = \log(-\log S(t))\\ against \\\log t\\, which
linearises a Weibull survival model and is used to assess the
proportional-hazards assumption — parallel lines indicate proportional
hazards. Corresponds to the SAS `LN_CUMHZ * LN_INT` plot produced when
`PLOTC=1`.

## Usage

``` r
km_build_loglog_plot(km_df, alpha)
```

## Arguments

- km_df:

  Tidy KM data frame from `km_extract_tidy`.

## Value

A bare `ggplot` object.
