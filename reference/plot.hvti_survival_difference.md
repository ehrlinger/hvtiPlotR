# Plot an hvti_survival_difference object

Renders a bare
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
survival-difference curve. Compose with `geom_hline(yintercept = 0)`,
[`scale_y_continuous()`](https://ggplot2.tidyverse.org/reference/scale_continuous.html),
[`labs()`](https://ggplot2.tidyverse.org/reference/labs.html), and
[`hvti_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md).

## Usage

``` r
# S3 method for class 'hvti_survival_difference'
plot(x, ci_alpha = 0.2, line_width = 1, ...)
```

## Arguments

- x:

  An `hvti_survival_difference` object.

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

[`hvti_survival_difference()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_survival_difference.md),
[`hvti_nnt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_nnt.md),
[`hvti_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md)
