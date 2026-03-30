# Plot an hvti_stacked object

Draws a stacked (or proportional fill) histogram for the grouped numeric
variable stored in the `hvti_stacked` object.

## Usage

``` r
# S3 method for class 'hvti_stacked'
plot(x, ...)
```

## Arguments

- x:

  An `hvti_stacked` object.

- ...:

  Ignored; present for S3 consistency.

## Value

A bare [`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object. Add scales, labels, and themes with the usual `+` operator.

## See also

[`hvti_stacked`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_stacked.md),
[`hvti_theme`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md)

## Examples

``` r
dta <- sample_stacked_histogram_data()

# Count histogram
plot(hvti_stacked(dta, x_col = "year", group_col = "category")) +
  ggplot2::scale_fill_brewer(palette = "Set1", name = "Category") +
  ggplot2::scale_color_brewer(palette = "Set1", name = "Category") +
  ggplot2::labs(x = "Year", y = "Count") +
  hvti_theme("manuscript")


# Proportional (fill) histogram with manual colours
plot(hvti_stacked(dta, x_col = "year", group_col = "category",
                  position = "fill")) +
  ggplot2::scale_fill_manual(
    values = c("1" = "pink", "2" = "cyan", "3" = "orangered"),
    labels = c("1" = "Group A", "2" = "Group B", "3" = "Group C"),
    name   = "Category"
  ) +
  ggplot2::scale_color_manual(
    values = c("1" = "pink", "2" = "cyan", "3" = "orangered"),
    guide  = "none"
  ) +
  ggplot2::labs(x = "Year", y = "Proportion") +
  hvti_theme("manuscript")

```
