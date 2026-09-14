# Plot an hv_correlation_matrix object

Bare scatter-plot matrix: points only, free scales per panel, variable
names in the strips. Decorate with a `theme_hv_*()` theme.

## Usage

``` r
# S3 method for class 'hv_correlation_matrix'
plot(x, alpha = 0.3, point_size = 0.6, ...)
```

## Arguments

- x:

  An `hv_correlation_matrix` object.

- alpha:

  Point transparency; large cohorts need it low.

- point_size:

  Point size.

- ...:

  Ignored.

## Value

A `ggplot` object.
