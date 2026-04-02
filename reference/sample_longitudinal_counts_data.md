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

[`hv_longitudinal()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_longitudinal.md),
[`sample_spaghetti_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_spaghetti_data.md)

## Examples

``` r
dta <- sample_longitudinal_counts_data(n_patients = 300, seed = 42)
str(dta)                # time_label (factor), series, count
#> 'data.frame':    14 obs. of  3 variables:
#>  $ time_label: Factor w/ 7 levels "≥0 Days","≥1 Month",..: 1 2 3 4 5 6 7 1 2 3 ...
#>  $ series    : chr  "Patients" "Patients" "Patients" "Patients" ...
#>  $ count     : int  19 47 49 100 159 101 276 19 50 56 ...
levels(dta$time_label)  # 7 discrete follow-up windows
#> [1] "≥0 Days"    "≥1 Month"   "≥3 Months"  "≥6 Months"  "≥1 Year"   
#> [6] "≥2 Years"   "≥2.5 Years"

# Inspect patient counts at each window
subset(dta, series == "Patients")
#>   time_label   series count
#> 1    ≥0 Days Patients    19
#> 2   ≥1 Month Patients    47
#> 3  ≥3 Months Patients    49
#> 4  ≥6 Months Patients   100
#> 5    ≥1 Year Patients   159
#> 6   ≥2 Years Patients   101
#> 7 ≥2.5 Years Patients   276

# Larger cohort
dta2 <- sample_longitudinal_counts_data(n_patients = 1000, seed = 7)
max(dta2$count)         # peak observation count
#> [1] 2006
```
