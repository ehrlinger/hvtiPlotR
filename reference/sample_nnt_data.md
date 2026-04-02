# Sample Number Needed to Treat Data

Computes the number needed to treat (NNT) and absolute risk reduction
(ARR) over time from a two-group survival difference, matching the
output of `tp.hp.numtreat.survdiff.matched.sas`.

## Usage

``` r
sample_nnt_data(
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

A data frame with columns `time`, `arr`, `arr_lower`, `arr_upper`,
`nnt`, `nnt_lower`, `nnt_upper`.

## Details

**SAS column mapping:**

- `time` ← prediction grid (years)

- `arr` ← absolute risk reduction (survival difference, %)

- `arr_lower` / `arr_upper` ← CI on ARR

- `nnt` ← number needed to treat (= 100 / ARR)

- `nnt_lower` / `nnt_upper` ← CI on NNT (inverted from ARR CI)

## See also

[`hv_nnt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_nnt.md),
[`hv_survival_difference()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_survival_difference.md)

## Examples

``` r
nnt_dat <- sample_nnt_data(
  groups = c("Control" = 1.0, "Treatment" = 0.7)
)
head(nnt_dat)
#>         time         arr   arr_lower  arr_upper nnt nnt_lower nnt_upper
#> 1 0.01000000 0.001831068 -0.03739885 0.04106099  NA        NA        NA
#> 2 0.03002004 0.009522643 -0.08737593 0.10642122  NA  939.6622        NA
#> 3 0.05004008 0.020489267 -0.13072627 0.17170481  NA  582.3949        NA
#> 4 0.07006012 0.033934691 -0.17121839 0.23908777  NA  418.2564        NA
#> 5 0.09008016 0.049459769 -0.21006489 0.30898443  NA  323.6409        NA
#> 6 0.11010020 0.066810699 -0.24784775 0.38146915  NA  262.1444        NA
```
