# Sample Nonparametric Curve Data

Simulates pre-computed curve output matching what SAS produces after
fitting a two-phase nonparametric temporal trend model and averaging
patient-specific profiles with `PROC SUMMARY`. The output is suitable
for direct use with
[`hv_nonparametric()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_nonparametric.md).

## Usage

``` r
sample_nonparametric_curve_data(
  n = 500,
  time_max = 12,
  n_points = 500,
  groups = NULL,
  outcome_type = c("probability", "continuous"),
  ci_level = 0.68,
  n_bins = 10,
  seed = 42L
)
```

## Arguments

- n:

  Number of simulated patients (used for binned data points and CI
  width). Default `500`.

- time_max:

  Upper end of the time axis (same units as the SAS `iv_echo` /
  `iv_wristm` variable). Default `12`.

- n_points:

  Number of time points on the fine prediction grid. Default `500`
  (matches the SAS `inc=(max-min)/499.9` loop).

- groups:

  `NULL` for a single average curve, or a named numeric vector of
  group-specific hazard multipliers, e.g.
  `c("Ozaki" = 0.8, "CE-Pericardial" = 1.2)`.

- outcome_type:

  `"probability"` (binary outcome, 0-1 scale) or `"continuous"`. Default
  `"probability"`.

- ci_level:

  Confidence level for bootstrap-style CI bands. Default `0.68`.

- n_bins:

  Number of equal-sized data-summary bins. Default `10`.

- seed:

  Random seed. Default `42`.

## Value

A data frame with columns `time`, `estimate`, `lower`, `upper`, and (if
`groups` is not `NULL`) `group`.

## Details

**SAS context:** In the SAS templates this dataset corresponds to
`mean_curv` (estimate column) plus `boots_ci` (lower/upper columns).
Export those datasets to CSV and read them with
[`read.csv()`](https://rdrr.io/r/utils/read.table.html) to use your own
model output instead of this sample function.

## See also

[`hv_nonparametric()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_nonparametric.md),
[`sample_nonparametric_curve_points()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_nonparametric_curve_points.md)

## Examples

``` r
# Single average curve
dat <- sample_nonparametric_curve_data(n = 500, time_max = 12)
head(dat)
#>         time  estimate     lower     upper
#> 1 0.05000000 0.2395042 0.2148392 0.2660414
#> 2 0.05055219 0.2395916 0.2149201 0.2661351
#> 3 0.05111048 0.2396798 0.2150019 0.2662297
#> 4 0.05167493 0.2397690 0.2150845 0.2663253
#> 5 0.05224562 0.2398592 0.2151680 0.2664220
#> 6 0.05282261 0.2399503 0.2152524 0.2665196

# Two-group comparison
dat2 <- sample_nonparametric_curve_data(
  n = 400, time_max = 7,
  groups = c("Ozaki" = 0.7, "CE-Pericardial" = 1.3),
  outcome_type = "continuous"
)
head(dat2)
#>         time estimate    lower    upper group
#> 1 0.05000000 40.42056 39.08636 41.75477 Ozaki
#> 2 0.05049761 40.42456 39.09036 41.75877 Ozaki
#> 3 0.05100018 40.42860 39.09439 41.76280 Ozaki
#> 4 0.05150775 40.43267 39.09846 41.76687 Ozaki
#> 5 0.05202037 40.43677 39.10257 41.77098 Ozaki
#> 6 0.05253809 40.44092 39.10671 41.77512 Ozaki
```
