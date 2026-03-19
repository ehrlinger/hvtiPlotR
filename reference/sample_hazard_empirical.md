# Sample Kaplan-Meier Empirical Points for Hazard Plot Overlay

Simulates patient-level survival data from a Weibull distribution and
returns Kaplan-Meier estimates at a small number of binned time points,
matching the structure of the SAS `plout` dataset used as an empirical
overlay in `tp.hp.dead.sas` and related templates.

## Usage

``` r
sample_hazard_empirical(
  n = 500,
  time_max = 10,
  n_bins = 6,
  groups = NULL,
  shape = 1.5,
  scale = 8,
  ci_level = 0.95,
  seed = 42L
)
```

## Arguments

- n:

  Number of simulated patients. Default `500`.

- time_max:

  Upper end of the follow-up window (years). Default `10`.

- n_bins:

  Number of time points at which KM is evaluated. Analogous to the
  discrete annotation points in the SAS templates. Default `6`.

- groups:

  `NULL` for a single group, or a named numeric vector of hazard
  multipliers matching those passed to
  [`sample_hazard_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_hazard_data.md).

- shape:

  Weibull shape parameter. Default `1.5`.

- scale:

  Weibull scale parameter (years). Default `8.0`.

- ci_level:

  Confidence level. Default `0.95`.

- seed:

  Random seed. Default `42`.

## Value

A data frame with columns `time`, `estimate`, `lower`, `upper`, and
(when `groups` is not `NULL`) `group`.

## Details

**SAS column mapping:**

- `time` ← `IV_DEAD` / `iv_dead` (evaluation time points)

- `estimate` ← `CUM_SURV` (KM survival estimate, 0–100 %)

- `lower` ← `CL_LOWER` (lower 95 % CI)

- `upper` ← `CL_UPPER` (upper 95 % CI)

- `group` ← stratification variable (when `groups` is not `NULL`)

## See also

[`hazard_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/hazard_plot.md),
[`sample_hazard_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_hazard_data.md)

## Examples

``` r
emp <- sample_hazard_empirical(n = 500, time_max = 10, n_bins = 6)
head(emp)
#>        time estimate    lower    upper
#> 1  1.666667 90.00000 87.02011 92.32601
#> 2  3.333333 76.77536 72.74817 80.28954
#> 3  5.000000 63.03903 58.37830 67.32977
#> 4  6.666667 48.42234 43.43337 53.22442
#> 5  8.333333 36.81403 31.76328 41.86537
#> 6 10.000000 26.80533 21.84393 32.00013

emp2 <- sample_hazard_empirical(
  n = 400, time_max = 10,
  groups = c("No Takedown" = 1.0, "Takedown" = 0.65)
)
head(emp2)
#>        time estimate    lower    upper       group
#> 1  1.666667 91.25000 88.02522 93.63770 No Takedown
#> 2  3.333333 75.64891 71.09026 79.59367 No Takedown
#> 3  5.000000 62.09290 56.86556 66.87818 No Takedown
#> 4  6.666667 48.38904 42.87023 53.68082 No Takedown
#> 5  8.333333 32.07913 26.70311 37.56790 No Takedown
#> 6 10.000000 24.43818 19.19470 30.03370 No Takedown
```
