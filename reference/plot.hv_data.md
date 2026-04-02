# Plot fallback for hv_data objects

Called when [`plot()`](https://rdrr.io/r/graphics/plot.default.html) is
dispatched to an `hv_data` subclass that has no registered
`plot.<subclass>()` method. Issues a clear error rather than silently
falling through to
[`graphics::plot.default()`](https://rdrr.io/r/graphics/plot.default.html).

## Usage

``` r
# S3 method for class 'hv_data'
plot(x, ...)
```

## Arguments

- x:

  An `hv_data` object.

- ...:

  Ignored.

## Value

Does not return; always signals an error.
