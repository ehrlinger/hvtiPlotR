# Plot an hv_ordinal object

Draws grade-specific probability curves with an optional binned data
summary point overlay.

## Usage

``` r
# S3 method for class 'hv_ordinal'
plot(x, line_width = 1, point_size = 2.5, point_shape = 20L, ...)
```

## Arguments

- x:

  An `hv_ordinal` object.

- line_width:

  Width of grade-specific curve lines. Default `1.0`.

- point_size:

  Size of binned data summary points. Default `2.5`.

- point_shape:

  Integer shape for summary points. Default `20`.

- ...:

  Ignored; present for S3 consistency.

## Value

A bare [`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## See also

[`hv_ordinal`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ordinal.md),
[`hv_theme`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme.md)

## Examples

``` r
dat <- sample_nonparametric_ordinal_data(
  n = 800, time_max = 5,
  grade_labels = c("None", "Mild", "Moderate", "Severe")
)

# Curves only, with RColorBrewer palette
plot(hv_ordinal(dat)) +
  ggplot2::scale_colour_brewer(palette = "RdYlGn", direction = -1,
                               name = "AR Grade") +
  ggplot2::scale_x_continuous(breaks = 0:5) +
  ggplot2::scale_y_continuous(labels = scales::percent) +
  ggplot2::labs(x = "Years after Surgery", y = "Prevalence") +
  hv_theme("poster")


# Subset: show only severe grade
plot(hv_ordinal(dat[dat$grade == "Severe", ])) +
  ggplot2::scale_colour_manual(values = c(Severe = "firebrick"),
                               guide  = "none") +
  ggplot2::scale_y_continuous(limits = c(0, 0.25),
                              labels = scales::percent) +
  ggplot2::labs(x = "Years", y = "P(Severe TR grade)") +
  hv_theme("poster")

```
