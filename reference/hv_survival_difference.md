# Prepare survival difference (life-gained) data for plotting

Stores pre-computed survival difference data as an
`hv_survival_difference` object. Pass the result to
[`plot.hv_survival_difference()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_survival_difference.md)
to render the plot. Covers `tp.hp.dead.life-gained.sas` and the
survival-difference component of `tp.hp.numtreat.survdiff.matched.sas`.

## Usage

``` r
hv_survival_difference(
  diff_data,
  x_col = "time",
  estimate_col = "difference",
  lower_col = NULL,
  upper_col = NULL,
  group_col = NULL
)
```

## Arguments

- diff_data:

  Data frame of pre-computed survival differences. See
  [`sample_survival_difference_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_survival_difference_data.md).

- x_col:

  Name of the time column. Default `"time"`.

- estimate_col:

  Name of the difference column. Default `"difference"`.

- lower_col:

  Lower CI column, or `NULL`. Default `NULL`.

- upper_col:

  Upper CI column, or `NULL`. Default `NULL`.

- group_col:

  Grouping column for multiple comparisons, or `NULL`. Default `NULL`.

## Value

An S3 object of class `c("hv_survival_difference", "hv_data")`.

## See also

[`plot.hv_survival_difference()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_survival_difference.md),
[`sample_survival_difference_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_survival_difference_data.md),
[`hv_nnt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_nnt.md)

## Examples

``` r
library(ggplot2)

diff_dat <- sample_survival_difference_data(
  groups = c("Control" = 1.0, "Treatment" = 0.70)
)

sd <- hv_survival_difference(diff_dat,
  lower_col = "diff_lower", upper_col = "diff_upper"
)
plot(sd) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey50") +
  scale_x_continuous(limits = c(0, 10), breaks = 0:10) +
  scale_y_continuous(limits = c(-5, 30),
                     labels = function(x) paste0(x, "%")) +
  labs(x = "Years", y = "Survival Difference (%)") +
  hv_theme("poster")

```
