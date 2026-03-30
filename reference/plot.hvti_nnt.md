# Plot an hvti_nnt object

Renders a bare
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
NNT (or ARR) curve from an
[`hvti_nnt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_nnt.md)
object.

## Usage

``` r
# S3 method for class 'hvti_nnt'
plot(x, ci_alpha = 0.2, line_width = 1, ...)
```

## Arguments

- x:

  An `hvti_nnt` object from
  [`hvti_nnt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_nnt.md).

- ci_alpha:

  Transparency of the CI ribbon. Default `0.20`.

- line_width:

  Line width. Default `1.0`.

- ...:

  Ignored.

## Value

A
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## See also

[`hvti_nnt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_nnt.md),
[`hvti_survival_difference()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_survival_difference.md),
[`hvti_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md)
