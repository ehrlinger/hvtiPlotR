# Sample Temporal Trend Data

Generates a realistic patient-level longitudinal data set for
demonstrating
[`trends_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/trends_plot.md).
Each row is one patient with a surgery year, continuous outcome
(`value`), and a grouping variable (`group`). Trend patterns are
modelled so that group means diverge over time — matching the
multi-group NYHA / LV-mass / LOS pattern in the SAS template.

## Usage

``` r
sample_trends_data(
  n = 600,
  year_range = c(1990L, 2020L),
  groups = c("Group I", "Group II", "Group III", "Group IV"),
  seed = 42L
)
```

## Arguments

- n:

  Total number of patients. Default `600`.

- year_range:

  Integer vector `c(start, end)` for surgery years. Default
  `c(1990, 2020)`.

- groups:

  Character vector of group labels. Default
  `c("Group I", "Group II", "Group III", "Group IV")`.

- seed:

  Random seed for reproducibility. Default `42`.

## Value

A data frame with columns:

- `year` — surgery year (integer)

- `value` — continuous outcome (numeric)

- `group` — group label (factor, ordered by `groups`)

## See also

[`trends_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/trends_plot.md)

## Examples

``` r
dta <- sample_trends_data(n = 400, seed = 42)
head(dta)
#>   year value    group
#> 1 2005 39.61  Group I
#> 2 1993 57.50  Group I
#> 3 2013 46.23  Group I
#> 4 2010 55.28  Group I
#> 5 2013 20.84 Group II
#> 6 1995 18.90 Group IV
table(dta$year, dta$group)
#>       
#>        Group I Group II Group III Group IV
#>   1990       5        1         3        4
#>   1991       4        3         2        3
#>   1992       3        4         6        1
#>   1993       4        1         2        1
#>   1994       3        3         3        2
#>   1995       2        6         1        5
#>   1996       6        3         4        1
#>   1997       4        3         3        1
#>   1998       5        0         2        2
#>   1999       5        6         5        8
#>   2000       4        2         3        6
#>   2001       3        5         4        0
#>   2002       6        7         5        2
#>   2003       1        3         5        6
#>   2004       2        5         0        3
#>   2005       3        3         2        4
#>   2006       1        1         4        2
#>   2007       2        6         4        2
#>   2008       3        6         2        3
#>   2009       6        5         1        3
#>   2010       2        5         1        4
#>   2011       3        3         2        2
#>   2012       2        8         3        1
#>   2013       5        4         1        3
#>   2014       3        5         2        2
#>   2015       4        4         5        3
#>   2016       4        3         1        3
#>   2017       5        0         3        5
#>   2018       3        4         3        3
#>   2019       4        3         2        2
#>   2020       4        5         1        0
```
