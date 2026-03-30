# Print an hvti_data object

Default print method for any `hvti_data` subclass. Subclasses may
override this with a more informative implementation (see
[`print.hvti_survival()`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hvti_survival.md)
for an example), but all fall back to this when no specific method is
registered.

## Usage

``` r
# S3 method for class 'hvti_data'
print(x, ...)
```

## Arguments

- x:

  An `hvti_data` object.

- ...:

  Ignored; present for S3 consistency.

## Value

`x`, invisibly.
