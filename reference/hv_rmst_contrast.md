# Prepare RMST contrast data for plotting

Validates a table of restricted mean survival time (RMST) differences,
one row per weighting estimator, and returns an `hv_rmst_contrast`
object. Call
[`plot.hv_rmst_contrast()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_rmst_contrast.md)
on the result for a bare dot-and-whisker `ggplot2` object: one point per
estimator, a whisker for its interval, and a vertical reference line at
zero.

## Usage

``` r
hv_rmst_contrast(
  data,
  estimator = "estimator",
  diff = "diff_days",
  lo = "lo_days",
  hi = "hi_days",
  ...
)
```

## Arguments

- data:

  A data frame with one row per estimator, or a `ps_rmst` object (any
  list whose `$tables$estimates` is a data frame).

- estimator:

  Name of the column holding estimator labels. Default `"estimator"`. If
  it is a factor, its levels set the display order; otherwise the order
  of first appearance is used.

- diff:

  Name of the numeric column with the RMST difference (in days). Default
  `"diff_days"`.

- lo, hi:

  Names of the numeric columns with the lower and upper interval limits
  (in days). Defaults `"lo_days"` and `"hi_days"`.

- ...:

  Ignored; present for S3 consistency.

## Value

An object of class `c("hv_rmst_contrast", "hv_data")`: a list with

- `$data`:

  The estimates data frame, with the estimator column as supplied.

- `$meta`:

  Named list: `estimator`, `diff`, `lo`, `hi` (column names),
  `estimator_levels`, `n_estimators`, `n_missing`.

- `$tables`:

  Empty list.

## Details

The input follows the `tables$estimates` contract of
`hvtiRpropensity::ps_rmst()`: columns `estimator`, `subset`,
`weighting`, `n`, `ess_treated`, `ess_control`, `rmst_treated`,
`rmst_control`, `diff`, `diff_days`, `lo_days`, `hi_days` and
`n_failed`, where a positive `diff` favours the treated arm. Only the
estimator, difference and interval columns are used here.
hvtiRpropensity is not required: pass a plain data frame, or the
`ps_rmst` object itself and its `$tables$estimates` is read.

## See also

[`plot.hv_rmst_contrast()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_rmst_contrast.md),
[`hv_rmst_curves()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_rmst_curves.md)

Other Propensity Score & Matching:
[`hv_mirror_hist()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_mirror_hist.md),
[`hv_rmst_curves()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_rmst_curves.md),
[`plot.hv_mirror_hist()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_mirror_hist.md),
[`plot.hv_rmst_contrast()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_rmst_contrast.md),
[`plot.hv_rmst_curves()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_rmst_curves.md),
[`sample_covariate_balance_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_covariate_balance_data.md)

## Examples

``` r
est <- data.frame(
  estimator = factor(c("IPTW", "Overlap", "Matching"),
                     levels = c("IPTW", "Overlap", "Matching")),
  diff_days = c(41, 35, 28),
  lo_days   = c(-5, 2, -14),
  hi_days   = c(87, 68, 70)
)
rc <- hv_rmst_contrast(est)
rc
#> <hv_rmst_contrast>
#>   Estimators : 3 (IPTW, Overlap, Matching)
#>   Difference : diff_days [lo_days, hi_days]

plot(rc) +
  ggplot2::labs(y = NULL) +
  theme_hv_manuscript()

```
