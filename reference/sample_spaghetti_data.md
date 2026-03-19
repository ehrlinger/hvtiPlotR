# Sample Spaghetti / Profile Plot Data

Generates a realistic repeated-measures longitudinal data set for
demonstrating
[`spaghetti_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/spaghetti_plot.md).
Each row is one observation for one patient at one time point, mimicking
serial echocardiographic measurements after cardiac surgery (AV mean
gradient trajectory over follow-up). Patients have an irregular number
of follow-up measurements and a group indicator (e.g. sex), matching the
`b_echo.xpt` structure in the template.

## Usage

``` r
sample_spaghetti_data(
  n_patients = 150,
  max_obs = 6,
  groups = c(Female = 0.45, Male = 0.55),
  seed = 42L
)
```

## Arguments

- n_patients:

  Number of unique patients. Default `150`.

- max_obs:

  Maximum number of observations per patient. Default `6`.

- groups:

  Named character vector of group labels and their sampling
  probabilities (summing to 1). Default `c(Female = 0.45, Male = 0.55)`.

- seed:

  Random seed for reproducibility. Default `42`.

## Value

A data frame with columns:

- `id` — patient identifier (integer)

- `time` — years from index procedure (numeric)

- `value` — continuous outcome (numeric; AV mean gradient in mmHg)

- `group` — group label (factor)

## See also

[`spaghetti_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/spaghetti_plot.md)

## Examples

``` r
dta <- sample_spaghetti_data(n_patients = 100, seed = 42)
head(dta)
#>   id time value  group
#> 1  1 0.58 24.09 Female
#> 2  1 0.89 17.44 Female
#> 3  1 2.60 19.86 Female
#> 4  1 4.06 25.13 Female
#> 5  2 0.77 10.25 Female
#> 6  2 1.67 11.34 Female
table(dta$group)
#> 
#> Female   Male 
#>    193    189 
```
