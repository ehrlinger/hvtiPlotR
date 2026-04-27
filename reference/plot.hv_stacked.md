# Plot an hv_stacked object

Draws a stacked (or proportional fill) histogram for the grouped numeric
variable stored in the `hv_stacked` object.

## Usage

``` r
# S3 method for class 'hv_stacked'
plot(x, ...)
```

## Arguments

- x:

  An `hv_stacked` object.

- ...:

  Ignored; present for S3 consistency.

## Value

A bare [`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object. Add scales, labels, and themes with the usual `+` operator.

## See also

[`hv_stacked`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_stacked.md),
[`theme_hv_manuscript`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md)

## Examples

``` r
dta <- sample_stacked_histogram_data()

# Count histogram
plot(hv_stacked(dta, x_col = "year", group_col = "category")) +
  ggplot2::scale_fill_brewer(palette = "Set1", name = "Category") +
  ggplot2::scale_color_brewer(palette = "Set1", name = "Category") +
  ggplot2::labs(x = "Year", y = "Count") +
  theme_hv_poster()


# Proportional (fill) histogram with manual colours
plot(hv_stacked(dta, x_col = "year", group_col = "category",
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
  theme_hv_poster()

```
