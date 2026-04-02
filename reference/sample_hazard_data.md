# Sample Parametric Hazard Model Predictions

Simulates parametric survival, hazard, and cumulative-hazard predictions
on a fine time grid, matching the structure of the SAS `predict` dataset
produced by `tp.hp.dead.sas` and its variants after fitting a Weibull
model with `PROC LIFEREG`.

## Usage

``` r
sample_hazard_data(
  n = 500,
  time_max = 10,
  n_points = 500,
  groups = NULL,
  shape = 1.5,
  scale = 8,
  ci_level = 0.95,
  seed = 42L
)
```

## Arguments

- n:

  Number of patients used to scale confidence-limit width. Default
  `500`.

- time_max:

  Upper end of the time axis (years). Default `10`.

- n_points:

  Number of time points in the prediction grid. Default `500`.

- groups:

  `NULL` for a single curve, or a named numeric vector of hazard
  multipliers, e.g. `c("Control" = 1.0, "Treatment" = 0.7)`. A
  multiplier \< 1 means lower hazard (better survival). Analogous to the
  group indicator in `tp.hp.dead.tkdn.stratified.sas`.

- shape:

  Weibull shape parameter. `shape > 1` gives increasing hazard (late
  mortality); `shape < 1` gives decreasing hazard (early operative
  mortality). Default `1.5`.

- scale:

  Weibull scale parameter (characteristic time in years, i.e. the time
  at which `S = exp(-1) ≈ 37%`). Default `8.0`.

- ci_level:

  Confidence level for the CI bands. Default `0.95`.

- seed:

  Random seed (unused for deterministic Weibull predictions; kept for
  API consistency with other sample functions). Default `42`.

## Value

A data frame with columns `time`, `survival`, `surv_lower`,
`surv_upper`, `hazard`, `haz_lower`, `haz_upper`, `cumhaz`, and (when
`groups` is not `NULL`) `group`.

## Details

**SAS column mapping:**

- `time` ← `YEARS` / `iv_dead` (prediction grid)

- `survival` ← `SSURVIV` (predicted survival, 0–100 %)

- `surv_lower` ← `SCLLSURV` (lower confidence limit on survival)

- `surv_upper` ← `SCLUSURV` (upper confidence limit on survival)

- `hazard` ← predicted hazard rate (%/year)

- `haz_lower` ← lower confidence limit on hazard

- `haz_upper` ← upper confidence limit on hazard

- `cumhaz` ← cumulative hazard (%; corresponds to `-log(S)*100`)

- `group` ← group stratification variable (when `groups` is not `NULL`)

## See also

[`hv_hazard()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_hazard.md),
[`sample_hazard_empirical()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_hazard_empirical.md),
[`sample_life_table()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_life_table.md)

## Examples

``` r
# Single-group predictions (tp.hp.dead.sas)
dat <- sample_hazard_data(n = 500, time_max = 10)
head(dat)
#>         time survival surv_lower surv_upper    hazard haz_lower haz_upper
#> 1 0.01000000 99.99558   99.93731        100 0.6629126 0.3996474  1.099602
#> 2 0.03002004 99.97702   99.84413        100 1.1485818 0.6924408  1.905203
#> 3 0.05004008 99.95054   99.75561        100 1.4829116 0.8939968  2.459770
#> 4 0.07006012 99.91808   99.66720        100 1.7546549 1.0578216  2.910523
#> 5 0.09008016 99.88059   99.57770        100 1.9896233 1.1994760  3.300275
#> 6 0.11010020 99.83868   99.48662        100 2.1996335 1.3260840  3.648628
#>        cumhaz cumhaz_lower cumhaz_upper
#> 1 0.004419417            0    0.5871202
#> 2 0.022986980            0    1.3519229
#> 3 0.049470012            0    1.9990187
#> 4 0.081954223            0    2.5912321
#> 5 0.119483723            0    3.1493081
#> 6 0.161453396            0    3.6834317

# Two-group predictions (tp.hp.dead.tkdn.stratified.sas)
dat2 <- sample_hazard_data(
  n = 400, time_max = 10,
  groups = c("No Takedown" = 1.0, "Takedown" = 0.65)
)
head(dat2)
#>         time survival surv_lower surv_upper    hazard haz_lower haz_upper
#> 1 0.01000000 99.99558   99.93043        100 0.6629126 0.3764745  1.167285
#> 2 0.03002004 99.97702   99.82844        100 1.1485818 0.6522907  2.022473
#> 3 0.05004008 99.95054   99.73260        100 1.4829116 0.8421599  2.611175
#> 4 0.07006012 99.91808   99.63759        100 1.7546549 0.9964855  3.089672
#> 5 0.09008016 99.88059   99.54194        100 1.9896233 1.1299263  3.503415
#> 6 0.11010020 99.83868   99.44507        100 2.1996335 1.2491932  3.873210
#>        cumhaz cumhaz_lower cumhaz_upper       group
#> 1 0.004419417            0    0.6558987 No Takedown
#> 2 0.022986980            0    1.5087825 No Takedown
#> 3 0.049470012            0    2.2291318 No Takedown
#> 4 0.081954223            0    2.8874122 No Takedown
#> 5 0.119483723            0    3.5069304 No Takedown
#> 6 0.161453396            0    4.0991449 No Takedown
```
