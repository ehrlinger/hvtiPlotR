# hvtiPlotR Plot Generic

Provides a single entry point for generating hvtiPlotR plots.

## Usage

``` r
hvti_plot(
  type = c("mirror_histogram", "stacked_histogram", "covariate_balance",
    "goodness_followup", "survival_curve", "upset", "alluvial", "trends", "spaghetti",
    "longitudinal_counts", "nonparametric_curve", "nonparametric_ordinal", "hazard",
    "survival_difference", "nnt"),
  ...
)
```

## Arguments

- type:

  Character keyword identifying the plot type. Supported values:
  `"mirror_histogram"`, `"stacked_histogram"`, `"covariate_balance"`,
  `"goodness_followup"`, `"survival_curve"`, `"upset"`,
  `"nonparametric_curve"`, `"nonparametric_ordinal"`.

- ...:

  Additional arguments passed to the underlying plotting function.

## Value

The object produced by the requested plotting function.
