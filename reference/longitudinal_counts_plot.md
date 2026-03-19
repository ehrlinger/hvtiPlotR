# Longitudinal Participation Counts Bar Chart

Produces a grouped bar chart showing how many patients and measurements
are available at each discrete follow-up time point. Pair with
[`longitudinal_counts_table()`](https://ehrlinger.github.io/hvtiPlotR/reference/longitudinal_counts_table.md)
via `patchwork` for the full two-panel layout.

## Usage

``` r
longitudinal_counts_plot(
  data,
  x_col = "time_label",
  count_col = "count",
  group_col = "series",
  position = "dodge"
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

- position:

  Bar position: `"dodge"` (default) or `"stack"`.

## Value

A bare
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## See also

[`longitudinal_counts_table()`](https://ehrlinger.github.io/hvtiPlotR/reference/longitudinal_counts_table.md),
[`sample_longitudinal_counts_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_longitudinal_counts_data.md)

## Examples

``` r
library(ggplot2)
dta <- sample_longitudinal_counts_data(n_patients = 300, seed = 42L)

longitudinal_counts_plot(dta) +
  scale_fill_manual(
    values = c(Patients = "steelblue", Measurements = "firebrick"),
    name   = NULL
  ) +
  scale_y_continuous(labels = scales::comma,
                     breaks = seq(0, 2000, 500),
                     expand = c(0, 0)) +
  coord_cartesian(ylim = c(0, 2200)) +
  labs(x = "Follow-up Window", y = "Count (n)") +
  hvti_theme("manuscript") +
  theme(legend.position = c(0.85, 0.85))

```
