# Sample Nonparametric Ordinal Curve Data

Simulates pre-computed grade-specific probability curves matching what
SAS produces after fitting a cumulative proportional-odds nonparametric
temporal trend model. Covers the ordinal TR / AR grade patterns from:

- `tp.np.tr.ivecho.average_curv.ordinal.sas` (p0, p1, p2, p3 individual
  probs)

- `tp.np.po_ar.u_multi.ordinal.sas` (multi-scenario ordinal, p34 =
  p3+p4)

## Usage

``` r
sample_nonparametric_ordinal_data(
  n = 1000,
  time_max = 5,
  n_points = 500,
  grade_labels = c("Grade 0", "Grade 1", "Grade 2", "Grade 3"),
  n_bins = 10,
  seed = 42L
)
```

## Arguments

- n:

  Number of simulated patients (controls CI width and data-point
  variability). Default `1000`.

- time_max:

  Upper end of the time axis (years). Default `5`.

- n_points:

  Number of time points on the prediction grid. Default `500`.

- grade_labels:

  Character vector of grade labels, one per grade level in ascending
  order. Corresponds to the SAS grade levels (e.g.
  `c("None", "Mild", "Moderate", "Severe")` for AR grade, or
  `c("0", "1", "2", "3+")` for TR grade). Default
  `c("Grade 0", "Grade 1", "Grade 2", "Grade 3")`.

- n_bins:

  Number of equal-sized bins for the data summary points (analogous to
  SAS `decile = _nobs_/10`). Default `10`.

- seed:

  Random seed. Default `42`.

## Value

A long-format data frame: `time`, `estimate`, `grade` (factor).
Individual grade probabilities sum to 1 at each time point.

## Details

**SAS context:** The SAS `predict` dataset has one column per grade
(`p0`, `p1`, `p2`, `p3`) after computing individual probabilities from
cumulative probabilities (`cp0 = co0/(1+co0)`, etc.). Export it to CSV
and reshape to long format to use your own model output.

## See also

[`nonparametric_ordinal_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/nonparametric_ordinal_plot.md),
[`sample_nonparametric_curve_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_nonparametric_curve_data.md),
[`sample_nonparametric_ordinal_points()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_nonparametric_ordinal_points.md)

## Examples

``` r
dat <- sample_nonparametric_ordinal_data(n = 800, time_max = 5)
head(dat)
#>         time  estimate   grade
#> 1 0.01000000 0.6276258 Grade 0
#> 2 0.01012532 0.6276898 Grade 0
#> 3 0.01025221 0.6277545 Grade 0
#> 4 0.01038069 0.6278200 Grade 0
#> 5 0.01051078 0.6278864 Grade 0
#> 6 0.01064250 0.6279535 Grade 0
# verify probabilities sum to 1 at each time point
tapply(dat$estimate[dat$time == dat$time[1]],
       dat$grade[dat$time == dat$time[1]], sum)
#>    Grade 0    Grade 1    Grade 2    Grade 3 
#> 0.62762585 0.22076622 0.10053344 0.05107449 
```
