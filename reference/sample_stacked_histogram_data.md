# Generate Sample Data for Stacked Histogram

Creates a minimal data frame suitable for demonstrating or testing
[`hvti_stacked`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_stacked.md).

## Usage

``` r
sample_stacked_histogram_data(
  n_years = 20,
  start_year = 2000,
  n_categories = 3,
  seed = 42L
)
```

## Arguments

- n_years:

  Integer. Number of consecutive years to simulate starting from
  `start_year`. Defaults to `20`.

- start_year:

  Integer. First calendar year in the sequence. Defaults to `2000`.

- n_categories:

  Integer. Number of distinct groups. Defaults to `3`.

- seed:

  Integer passed to [`set.seed`](https://rdrr.io/r/base/Random.html) for
  reproducibility. Defaults to `42`.

## Value

A data frame with columns `year` (integer) and `category` (integer, 1 to
`n_categories`).

## Examples

``` r
dta <- sample_stacked_histogram_data()
head(dta)
#>   year category
#> 1 2000        1
#> 2 2000        1
#> 3 2000        2
#> 4 2000        2
#> 5 2000        2
#> 6 2000        1
table(dta$year, dta$category)
#>       
#>         1  2  3
#>   2000 11  8  7
#>   2001  4  8  4
#>   2002  8  7  5
#>   2003  8  9  4
#>   2004 11  5  2
#>   2005  8  9  7
#>   2006  4 15  5
#>   2007  7  8  3
#>   2008 14  6 12
#>   2009  9  4  6
#>   2010  4  7  4
#>   2011  5  8  5
#>   2012  6  7  7
#>   2013  8 10 10
#>   2014  9  7  6
#>   2015  4  7  8
#>   2016  6 12  6
#>   2017  6  6  3
#>   2018  9  8  9
#>   2019  2  6  6
```
