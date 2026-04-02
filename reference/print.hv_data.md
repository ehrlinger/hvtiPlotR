# Print an hv_data object

Default print method for any `hv_data` subclass. Subclasses may override
this with a more informative implementation (see
[`print.hv_survival()`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hv_survival.md)
for an example), but all fall back to this when no specific method is
registered.

## Usage

``` r
# S3 method for class 'hv_data'
print(x, ...)
```

## Arguments

- x:

  An `hv_data` object.

- ...:

  Ignored; present for S3 consistency.

## Value

`x`, invisibly.
