# Build numbers-at-risk table

For each stratum, counts analysed subjects whose observed follow-up time
is greater than or equal to each report time.

## Usage

``` r
km_risk_table(time, report_times, group = NULL)
```

## Arguments

- time:

  Numeric vector of observed follow-up times.

- report_times:

  Numeric vector of time points.

- group:

  Optional stratum vector, or `NULL` for one cohort.

## Value

A data frame with columns `strata`, `report_time`, `n.risk`.
