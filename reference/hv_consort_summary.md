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
`excl_col`, `n_excluded`, `n_missing`. `n_missing` is the part of
`n_excluded` excluded because an exclusion criterion was missing (see
[`hv_consort_exclude()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_consort_exclude.md)).
`n_excluded`, `n_missing` and `excl_col` are `NA` for the final stage
(no downstream exclusion defined yet).

## See also

[`hv_consort_patients()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_consort_patients.md)

## Examples

``` r
hv_consort_summary(sample_consort_data())
#>      label include_col n_included      excl_col n_excluded n_missing
#> 1 Screened    screened        300   excl_screen         73         0
#> 2 Eligible    eligible        227 excl_eligible         41         0
#> 3 Analyzed    analyzed        186          <NA>         NA        NA
```
