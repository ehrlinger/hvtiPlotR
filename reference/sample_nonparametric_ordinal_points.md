# Sample Nonparametric Ordinal Data Points

Returns only the binned patient-level data summary points from
[`sample_nonparametric_ordinal_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_nonparametric_ordinal_data.md).
Accepts the same parameters and returns a plain `data.frame`.

## Usage

``` r
sample_nonparametric_ordinal_points(
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
  order. Default `c("Grade 0", "Grade 1", "Grade 2", "Grade 3")`.

- n_bins:

  Number of equal-sized bins for the data summary points. Default `10`.

- seed:

  Random seed. Default `42`.

## Value

A data frame with columns `time`, `value`, `grade`.

## See also

[`sample_nonparametric_ordinal_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_nonparametric_ordinal_data.md),
[`hv_ordinal()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ordinal.md)

## Examples

``` r
# Default: four grade levels
pts <- sample_nonparametric_ordinal_points(n = 800, time_max = 5)
head(pts)
#>        time  value   grade
#> 1 0.2749088 0.7375 Grade 0
#> 2 0.7282107 0.7625 Grade 0
#> 3 1.2073787 0.8375 Grade 0
#> 4 1.7148634 0.9125 Grade 0
#> 5 2.1953343 0.8000 Grade 0
#> 6 2.6358690 0.8000 Grade 0
levels(pts$grade)
#> [1] "Grade 0" "Grade 1" "Grade 2" "Grade 3"

# Clinical AR grade labels
pts2 <- sample_nonparametric_ordinal_points(
  n            = 600,
  time_max     = 7,
  grade_labels = c("None", "Mild", "Moderate", "Severe")
)
table(pts2$grade)
#> 
#>     None     Mild Moderate   Severe 
#>       10       10       10       10 
```
