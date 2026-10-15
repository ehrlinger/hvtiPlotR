# Stage-level CONSORT summary table

Returns a data frame with one row per stage showing patient counts and
the exclusion column name, suitable for a methods-section table.

## Usage

``` r
hv_consort_summary(tracker)
```

## Arguments

- tracker:

  An `hv_consort_tracker`.

## Value

A data frame with columns `label`, `include_col`, `n_included`,
`excl_col`, `n_excluded`. `n_excluded` and `excl_col` are `NA` for the
final stage (no downstream exclusion defined yet).

## See also

[`hv_consort_patients()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_consort_patients.md)

## Examples

``` r
hv_consort_summary(sample_consort_data())
#>      label include_col n_included      excl_col n_excluded
#> 1 Screened    screened        300   excl_screen         73
#> 2 Eligible    eligible        227 excl_eligible         41
#> 3 Analyzed    analyzed        186          <NA>         NA
```
