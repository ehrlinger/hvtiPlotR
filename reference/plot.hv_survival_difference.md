# Plot an hv_survival_difference object

Renders a bare
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
survival-difference curve. Compose with `geom_hline(yintercept = 0)`,
[`scale_y_continuous()`](https://ggplot2.tidyverse.org/reference/scale_continuous.html),
[`labs()`](https://ggplot2.tidyverse.org/reference/labs.html), and
[`theme_hv_manuscript()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md).

## Usage

``` r
# S3 method for class 'hv_survival_difference'
plot(x, ci_alpha = 0.2, linewidth = 1, ..., line_width)
```

## Arguments

- x:

  An `hv_survival_difference` object.

- ci_alpha:

  Transparency of the CI ribbon. Default `0.20`.

- linewidth:

  Line width. Default `1.0`.

- ...:

  Ignored.

- line_width:

  Deprecated name of `linewidth`; works with a once-per-session warning
  until hvtiPlotR 2.9.0.

## Value

A
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## See also

[`hv_survival_difference()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_survival_difference.md),
[`hv_nnt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_nnt.md),
[`theme_hv_manuscript()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md)
