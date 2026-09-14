# Sample data for hv_correlation_matrix()

Simulated preoperative labs with a built-in dependence on HbA1c, shaped
like the correlation job it stands in for.

## Usage

``` r
sample_correlation_data(n = 300, seed = 42)
```

## Arguments

- n:

  Number of patients.

- seed:

  Random seed.

## Value

A data frame with numeric `a1c`, `glucose`, `creatinine`, `albumin`, and
a three-level factor `a1c_grp`.

## Examples

``` r
head(sample_correlation_data(n = 10))
#>   a1c glucose creatinine albumin a1c_grp
#> 1 8.1     195       0.91     3.4      >7
#> 2 5.8     173       0.59     3.7      <6
#> 3 6.9     103       0.95     3.7     6-7
#> 4 7.3     139       1.44     3.0      >7
#> 5 7.0     137       1.77     3.5     6-7
#> 6 6.4     144       0.88     2.7     6-7
```
