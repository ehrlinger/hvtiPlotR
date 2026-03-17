# Build numbers-at-risk table

For each stratum, finds the last observed `n.risk` at or before each
report time.

## Usage

``` r
km_risk_table(km_df, report_times)
```

## Arguments

- km_df:

  Tidy KM data frame from `km_extract_tidy`.

- report_times:

  Numeric vector of time points.

## Value

A data frame with columns `strata`, `report_time`, `n.risk`.
