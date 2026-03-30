# Prepare number-needed-to-treat data for plotting

Stores pre-computed NNT (or ARR) data as an `hvti_nnt` object. Rows
where `estimate_col` is `NA` (undefined when ARR is near zero) are
optionally removed during construction via `na_rm`. Pass the result to
[`plot.hvti_nnt()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hvti_nnt.md)
to render the plot. Covers the NNT component of
`tp.hp.numtreat.survdiff.matched.sas`.

## Usage

``` r
hvti_nnt(
  nnt_data,
  x_col = "time",
  estimate_col = "nnt",
  lower_col = NULL,
  upper_col = NULL,
  group_col = NULL,
  na_rm = TRUE
)
```

## Arguments

- nnt_data:

  Data frame of pre-computed NNT estimates. See
  [`sample_nnt_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_nnt_data.md).

- x_col:

  Name of the time column. Default `"time"`.

- estimate_col:

  Name of the NNT (or ARR) column. Default `"nnt"`.

- lower_col:

  Lower CI column, or `NULL`. Default `NULL`.

- upper_col:

  Upper CI column, or `NULL`. Default `NULL`.

- group_col:

  Grouping column for multiple comparisons, or `NULL`. Default `NULL`.

- na_rm:

  Remove rows where `estimate_col` is `NA` before storing in `$data`.
  Applied at construction time. Default `TRUE`.

## Value

An S3 object of class `c("hvti_nnt", "hvti_data")`.

## See also

[`plot.hvti_nnt()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hvti_nnt.md),
[`sample_nnt_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_nnt_data.md),
[`hvti_survival_difference()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_survival_difference.md)

## Examples

``` r
library(ggplot2)

nnt_dat <- sample_nnt_data(
  n = 500, time_max = 20,
  groups = c("SVG" = 1.0, "ITA" = 0.75)
)

# NNT curve over time
nn <- hvti_nnt(nnt_dat, lower_col = "nnt_lower", upper_col = "nnt_upper")
plot(nn) +
  scale_x_continuous(limits = c(0, 20), breaks = seq(0, 20, 5)) +
  scale_y_continuous(limits = c(0, 50), breaks = seq(0, 50, 10)) +
  labs(x = "Years", y = "Number Needed to Treat (NNT)") +
  hvti_theme("manuscript")
#> Warning: Removed 248 rows containing missing values or values outside the scale range
#> (`geom_ribbon()`).
#> Warning: Removed 27 rows containing missing values or values outside the scale range
#> (`geom_line()`).


# ARR curve (same data, different column)
ar <- hvti_nnt(nnt_dat, estimate_col = "arr",
               lower_col = "arr_lower", upper_col = "arr_upper",
               na_rm = FALSE)
plot(ar) +
  scale_y_continuous(limits = c(0, 50),
                     labels = function(x) paste0(x, "%")) +
  labs(x = "Years", y = "Absolute Risk Reduction (%)") +
  hvti_theme("manuscript")
#> Warning: Removed 178 rows containing missing values or values outside the scale range
#> (`geom_ribbon()`).

```
