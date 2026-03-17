# hvtiPlotR Plot Generic

Provides a single entry point for generating hvtiPlotR plots.

## Usage

``` r
hvti_plot(type = c("mirror_histogram", "stacked_histogram"), ...)
```

## Arguments

- type:

  Character keyword identifying the plot type. Supported values are
  \`"mirror_histogram"\` and \`"stacked_histogram"\`.

- ...:

  Additional arguments passed to the underlying plotting function.

## Value

The object produced by the requested plotting function (e.g., a list
containing plot elements and diagnostics, or a ggplot object).
