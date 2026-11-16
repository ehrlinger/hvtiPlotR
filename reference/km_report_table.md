# Build report table at specified time points

For each stratum and report time, extracts the survival estimate and CI
bounds at the last observed time \\\le\\ the report time. A report time
past a stratum's last observed time has no estimate, so its `surv`,
`lower`, `upper` and `n.event` are `NA` rather than the final row
carried forward. `n.risk` is taken from the risk table, the number still
under observation at the report time itself, so the two tables agree.

## Usage

``` r
km_report_table(km_df, report_times, risk_tbl)
```

## Arguments

- km_df:

  Tidy KM data frame from `km_extract_tidy`.

- report_times:

  Numeric vector of time points.

- risk_tbl:

  Risk table from `km_risk_table`.

## Value

A data frame with columns `strata`, `report_time`, `surv`, `lower`,
`upper`, `n.risk`, `n.event`.
