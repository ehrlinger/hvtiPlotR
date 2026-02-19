# hvtiPlotR Theme Generic

Provides a single entry point for obtaining any supported hvtiPlotR
theme.

## Usage

``` r
hvti_theme(style = c("ppt", "dark_ppt", "manuscript", "poster"), ...)
```

## Arguments

- style:

  Character keyword identifying the theme style. Supported values are
  "ppt", "dark_ppt", "manuscript", and "poster".

- ...:

  Additional parameters forwarded to the underlying theme constructor.

## Value

A ggplot2 theme object.
