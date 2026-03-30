# Sample Sankey / Alluvial Data

Generates a realistic cardiac-surgery data set suitable for
demonstrating
[`hvti_alluvial()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_alluvial.md).
Each row represents a unique combination of pre-operative AV
regurgitation grade, surgical procedure type, and post-operative AV
regurgitation grade, together with the patient count (`freq`) for that
combination. The co-occurrence structure reflects realistic clinical
patterns: more severe pre-operative disease is more likely to improve
post-operatively following valve surgery.

## Usage

``` r
sample_alluvial_data(n = 300, seed = 42L)
```

## Arguments

- n:

  Total number of simulated patients before aggregation. Default `300`.

- seed:

  Random seed for reproducibility. Default `42`.

## Value

A data frame with columns: `pre_ar` (factor), `procedure` (factor),
`post_ar` (factor), `freq` (integer count). Rows with `freq == 0` are
excluded.

## See also

[`hvti_alluvial()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_alluvial.md)

## Examples

``` r
dta <- sample_alluvial_data(n = 300, seed = 42)
head(dta)
#>     pre_ar   procedure post_ar freq
#> 1     Mild      Repair    Mild    3
#> 2 Moderate      Repair    Mild    7
#> 4   Severe      Repair    Mild    5
#> 5     Mild Replacement    Mild    3
#> 6 Moderate Replacement    Mild   25
#> 8   Severe Replacement    Mild   17
# Axes in order: pre-op grade → procedure → post-op grade
with(dta, tapply(freq, list(pre_ar, post_ar), sum, default = 0))
#>          None Mild Moderate Severe
#> None       69    0        0      0
#> Mild       99    9        0      0
#> Moderate   45   35        5      0
#> Severe      0   23       10      5
```
