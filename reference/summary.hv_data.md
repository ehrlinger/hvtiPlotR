# Summarise an hv_data object

Prints the standard one-screen header (via
[`print.hv_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hv_data.md)
or the subclass override) and then walks the object's `$tables` slot,
printing each named auxiliary table with a header. Lets callers see the
underlying risk tables, report tables, diagnostics, etc. without having
to know the `$tables` accessor path.

## Usage

``` r
# S3 method for class 'hv_data'
summary(object, ...)
```

## Arguments

- object:

  An `hv_data` object.

- ...:

  Forwarded to the underlying
  [`print()`](https://rdrr.io/r/base/print.html) method.

## Value

`object`, invisibly.

## Details

Subclasses can override this with a more curated layout, but the default
implementation is enough for every shipping hv_data subclass.
