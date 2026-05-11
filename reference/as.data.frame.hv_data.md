# Extract the underlying data frame from an hv_data object

Returns the `$data` slot — the tidy data frame each hv_data subclass
carries for ggplot2 consumption. Lets callers use the standard
[`base::as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) /
[`base::data.frame()`](https://rdrr.io/r/base/data.frame.html) coercion
in tidyverse pipelines instead of reaching for the `$data` accessor.

## Usage

``` r
# S3 method for class 'hv_data'
as.data.frame(x, row.names = NULL, optional = FALSE, ...)
```

## Arguments

- x:

  An `hv_data` object.

- row.names:

  Ignored; present for base-method-signature consistency.

- optional:

  Ignored; present for base-method-signature consistency.

- ...:

  Ignored.

## Value

A `data.frame` — `x$data`.
