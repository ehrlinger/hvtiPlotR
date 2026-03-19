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
  `c("Ozaki" = 0.8, "CE-Pericardial" = 1.2)` — analogous to the
  indicator variable effect in `tp.np.avpkgrad_ozak_ind_mtwt.sas`.

- outcome_type:

  `"probability"` (binary outcome, 0-1 scale; e.g. AF prevalence, TR
  grade prevalence) or `"continuous"` (e.g. FEV1, AV peak gradient).
  Default `"probability"`.

- ci_level:

  Confidence level for bootstrap-style CI bands. Use `0.68` for the 68%
  CI shown in the SAS templates (one standard error), or `0.95` for the
  95% CI. Default `0.68`.

- n_bins:

  Number of equal-sized data-summary bins (analogous to the SAS
  `quint = _nobs_/12` / `decile = _nobs_/10` grouping). Default `10`.

- seed:

  Random seed. Default `42`.

## Value

A data frame with columns `time`, `value`, and (if `groups` is not
`NULL`) `group`.

## See also

[`sample_nonparametric_curve_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_nonparametric_curve_data.md),
[`nonparametric_curve_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/nonparametric_curve_plot.md)

## Examples

``` r
pts <- sample_nonparametric_curve_points(n = 500, time_max = 12)
head(pts)
#>        time value
#> 1 0.6202065  0.28
#> 2 1.6528452  0.46
#> 3 2.8063860  0.38
#> 4 4.1162936  0.34
#> 5 5.2520883  0.40
#> 6 6.2975341  0.42
```
