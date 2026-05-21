# Generate a sample CONSORT tracker for demos and testing

Simulates a cardiac surgery cohort and builds a three-stage
`hv_consort_tracker` suitable for testing
[`hv_consort()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_consort.md)
and demonstrating the tracker API.

## Usage

``` r
sample_consort_data(n = 300L, seed = 42L)
```

## Arguments

- n:

  Integer. Total number of simulated patients. Default `300`.

- seed:

  Integer random seed for reproducibility. Default `42`.

## Value

An `hv_consort_tracker` with three stages: *Screened* -\> *Eligible*
(excl: age \< 18, no STS procedure) -\> *Analyzed* (excl: missing
echocardiogram, prior trial).

## Examples

``` r
tracker <- sample_consort_data()
print(tracker)
#> <hv_consort_tracker>
#>   Patients   : 300
#>   ID column  : patient_id
#>   Stages     : 3
#>     [screened] Screened -- N = 300
#>       -> excl [excl_screen]: 73
#>     [eligible] Eligible -- N = 227
#>       -> excl [excl_eligible]: 41
#>     [analyzed] Analyzed -- N = 186
hv_consort_summary(tracker)
#>      label include_col n_included      excl_col n_excluded
#> 1 Screened    screened        300   excl_screen         73
#> 2 Eligible    eligible        227 excl_eligible         41
#> 3 Analyzed    analyzed        186          <NA>         NA
if (FALSE) { # \dontrun{
  hv_consort(tracker) |> plot()
} # }
```
