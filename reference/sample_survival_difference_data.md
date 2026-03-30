# Sample Survival Difference (Life-Gained) Data

Computes a group-vs-group survival difference curve and confidence
interval, matching the output of the `HAZDIFL` macro used in
`tp.hp.dead.life-gained.sas`.

## Usage

``` r
sample_survival_difference_data(
  n = 500,
  time_max = 10,
  n_points = 500,
  groups = c(Control = 1, Treatment = 0.7),
  shape = 1.5,
  scale = 8,
  ci_level = 0.95,
  seed = 42L
)
```

## Arguments

- n:

  Number of patients per group (used for CI width). Default `500`.

- time_max:

  Upper end of the time axis (years). Default `10`.

- n_points:

  Number of prediction grid points. Default `500`.

- groups:

  Named numeric vector of length 2; hazard multipliers for groups 1
  and 2. The group with the smaller multiplier has better survival.
  Default `c("Control" = 1.0, "Treatment" = 0.7)`.

- shape:

  Weibull shape. Default `1.5`.

- scale:

  Weibull scale (years). Default `8.0`.

- ci_level:

  Confidence level. Default `0.95`.

- seed:

  Random seed. Default `42`.

## Value

A data frame with columns `time`, `difference`, `diff_lower`,
`diff_upper`, `group1_surv`, `group2_surv`.

## Details

**SAS column mapping:**

- `time` ← prediction grid

- `difference` ← survival(group 2) - survival(group 1) (percentage
  points)

- `diff_lower` ← lower CI on difference

- `diff_upper` ← upper CI on difference

- `group1_surv` ← survival curve for group 1

- `group2_surv` ← survival curve for group 2

## See also

[`hvti_survival_difference()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_survival_difference.md),
[`sample_hazard_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_hazard_data.md)

## Examples

``` r
diff_dat <- sample_survival_difference_data(
  groups = c("Control" = 1.0, "Treatment" = 0.7)
)
head(diff_dat)
#>         time  difference  diff_lower diff_upper group1_surv group2_surv
#> 1 0.01000000 0.001831068 -0.03739885 0.04106099    99.99558    99.99741
#> 2 0.03002004 0.009522643 -0.08737593 0.10642122    99.97702    99.98654
#> 3 0.05004008 0.020489267 -0.13072627 0.17170481    99.95054    99.97103
#> 4 0.07006012 0.033934691 -0.17121839 0.23908777    99.91808    99.95201
#> 5 0.09008016 0.049459769 -0.21006489 0.30898443    99.88059    99.93005
#> 6 0.11010020 0.066810699 -0.24784775 0.38146915    99.83868    99.90549
```
