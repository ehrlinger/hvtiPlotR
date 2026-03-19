# Sample Longitudinal Counts Data

Builds a pre-aggregated summary data frame of patient and measurement
counts at discrete follow-up time windows. The counts are derived by
binning the continuous `time` column from
[`sample_spaghetti_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_spaghetti_data.md),
so the two functions share the same underlying simulation.

## Usage

``` r
sample_longitudinal_counts_data(n_patients = 300, max_obs = 6, seed = 42L)
```

## Arguments

- n_patients:

  Number of unique patients passed to
  [`sample_spaghetti_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_spaghetti_data.md).
  Default `300`.

- max_obs:

  Maximum observations per patient passed to
  [`sample_spaghetti_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_spaghetti_data.md).
  Default `6`.

- seed:

  Random seed. Default `42`.

## Value

A data frame in long format with columns:

- `time_label` — ordered factor of follow-up windows

- `series` — `"Patients"` or `"Measurements"`

- `count` — integer count

## See also

[`longitudinal_counts_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/longitudinal_counts_plot.md),
[`sample_spaghetti_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_spaghetti_data.md)

## Examples

``` r
dta <- sample_longitudinal_counts_data(n_patients = 300, seed = 42)
dta
#>    time_label       series count
#> 1     ≥0 Days     Patients    19
#> 2    ≥1 Month     Patients    47
#> 3   ≥3 Months     Patients    49
#> 4   ≥6 Months     Patients   100
#> 5     ≥1 Year     Patients   159
#> 6    ≥2 Years     Patients   101
#> 7  ≥2.5 Years     Patients   276
#> 8     ≥0 Days Measurements    19
#> 9    ≥1 Month Measurements    50
#> 10  ≥3 Months Measurements    56
#> 11  ≥6 Months Measurements   118
#> 12    ≥1 Year Measurements   217
#> 13   ≥2 Years Measurements   113
#> 14 ≥2.5 Years Measurements   620
```
