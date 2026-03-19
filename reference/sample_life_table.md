# Sample Population Life Table Data

Generates age-group-specific population survival curves using Gompertz
mortality, matching the US population life table overlays used in
`tp.hp.dead.age_with_population_life_table.sas` and
`tp.hp.dead.uslife.stratifed.sas`.

## Usage

``` r
sample_life_table(
  age_groups = c("<65", "65-80", "≥80"),
  age_mids = c(55, 72, 85),
  time_max = 10,
  n_points = 100
)
```

## Arguments

- age_groups:

  Character vector of age group labels. Default
  `c("<65", "65-80", "\u226580")`.

- age_mids:

  Numeric vector of representative ages (years) for each group, same
  length as `age_groups`. Default `c(55, 72, 85)`.

- time_max:

  Upper end of the time axis (years). Default `10`.

- n_points:

  Number of time points. Default `100`.

## Value

A data frame with columns `time`, `survival`, and `group`.

## Details

**SAS column mapping:**

- `time` ← prediction time grid (years)

- `survival` ← `SMATCHED` (age-group-specific survivorship, 0–100 %)

- `group` ← age group label (e.g. `"<65"`, `"65-80"`, `"\u226580"`)

## See also

[`hazard_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/hazard_plot.md),
[`sample_hazard_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_hazard_data.md)

## Examples

``` r
lt <- sample_life_table(time_max = 10)
head(lt)
#>        time  survival group
#> 1 0.0000000 100.00000   <65
#> 2 0.1010101  99.94562   <65
#> 3 0.2020202  99.89081   <65
#> 4 0.3030303  99.83555   <65
#> 5 0.4040404  99.77985   <65
#> 6 0.5050505  99.72370   <65
```
