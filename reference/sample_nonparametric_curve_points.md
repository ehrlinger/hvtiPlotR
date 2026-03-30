# Sample Nonparametric Curve Data Points

Returns only the binned patient-level data summary points from
[`sample_nonparametric_curve_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_nonparametric_curve_data.md).
Accepts the same parameters and returns a plain `data.frame`.

## Usage

``` r
sample_nonparametric_curve_points(
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

A data frame with columns `time`, `value`, and (if `groups` is not
`NULL`) `group`.

## See also

[`sample_nonparametric_curve_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_nonparametric_curve_data.md),
[`hvti_nonparametric()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_nonparametric.md)

## Examples

``` r
# Single-group data summary points
pts <- sample_nonparametric_curve_points(n = 500, time_max = 12)
head(pts)
#>        time value
#> 1 0.6202065  0.28
#> 2 1.6528452  0.46
#> 3 2.8063860  0.38
#> 4 4.1162936  0.34
#> 5 5.2520883  0.40
#> 6 6.2975341  0.42
names(pts)           # "time", "value"
#> [1] "time"  "value"

# Two-group points
pts2 <- sample_nonparametric_curve_points(
  n            = 400,
  time_max     = 7,
  groups       = c("Ozaki" = 0.7, "CE-Pericardial" = 1.3),
  outcome_type = "continuous"
)
levels(pts2$group)
#> [1] "Ozaki"          "CE-Pericardial"
```
