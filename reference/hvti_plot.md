# hvtiPlotR Plot Generic

Provides a single entry point for generating hvtiPlotR plots.

## Usage

``` r
hvti_plot(type = c("mirror_histogram"), ...)
```

## Arguments

- type:

  Character keyword identifying the plot type. Currently only
  "mirror_histogram" is supported.

- ...:

  Additional arguments passed to the underlying plotting function.

## Value

The object produced by the requested plotting function (e.g., a list
containing plot elements and diagnostics).
