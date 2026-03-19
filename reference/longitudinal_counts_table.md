# Longitudinal Participation Counts Table Panel

Produces a numeric data table rendered as a ggplot text panel, intended
to be composed below
[`longitudinal_counts_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/longitudinal_counts_plot.md)
via `patchwork`.

## Usage

``` r
longitudinal_counts_table(
  data,
  x_col = "time_label",
  count_col = "count",
  group_col = "series",
  label_format = NULL
)
```

## Arguments

- data:

  Long-format data frame. See
  [`sample_longitudinal_counts_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_longitudinal_counts_data.md).

- x_col:

  Name of the discrete time-label column. Default `"time_label"`.

- count_col:

  Name of the numeric count column. Default `"count"`.

- group_col:

  Name of the series grouping column. Default `"series"`.

- label_format:

  Formatting function applied to count values. `NULL` (default)
  auto-selects: uses
  [scales::comma](https://scales.r-lib.org/reference/comma.html) when
  the `scales` package is installed, otherwise falls back to
  [base::as.character](https://rdrr.io/r/base/character.html). Pass
  `identity` to display counts with no formatting.

## Value

A bare
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object (text table panel).

## See also

[`longitudinal_counts_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/longitudinal_counts_plot.md),
[`sample_longitudinal_counts_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_longitudinal_counts_data.md)

## Examples

``` r
library(ggplot2)
dta <- sample_longitudinal_counts_data(n_patients = 300, seed = 42L)

longitudinal_counts_table(dta) +
  scale_colour_manual(
    values = c(Patients = "steelblue", Measurements = "firebrick"),
    guide  = "none"
  ) +
  hvti_theme("manuscript")

```
