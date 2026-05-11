# Produce a ggplot from an hv_data object (`autoplot` generic)

Re-exports ggplot2's
[`ggplot2::autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
for `hv_data` objects so callers who prefer the ggplot2-ecosystem verb
(`broom` / `ggfortify` / `ggsurvfit` all use it) can write
`autoplot(km)` interchangeably with `plot(km)`.

## Usage

``` r
# S3 method for class 'hv_data'
autoplot(object, ...)
```

## Arguments

- object:

  An `hv_data` object.

- ...:

  Forwarded to the subclass's
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html) method.

## Value

A `ggplot` object (or a `patchwork` composite when the underlying
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) method returns
one, e.g. for `hv_upset`).

## Details

Dispatches to the registered `plot.<subclass>()` method, so any args
that work with [`plot()`](https://rdrr.io/r/graphics/plot.default.html)
work with
[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html).
