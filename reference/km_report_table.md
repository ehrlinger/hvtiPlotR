# Build report table at specified time points

For each stratum and report time, extracts the survival estimate (and CI
bounds, n.risk, and n.event) at the last observed time \\\le\\ the
report time.

## Usage

``` r
km_report_table(km_df, report_times)
```

## Arguments

- km_df:

  Tidy KM data frame from `km_extract_tidy`.

- report_times:

  Numeric vector of time points.

## Value

A data frame with columns `strata`, `report_time`, `surv`, `lower`,
`upper`, `n.risk`, `n.event`.
