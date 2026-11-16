# Plot an hv_nnt object

Renders a bare
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
NNT (or ARR) curve from an
[`hv_nnt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_nnt.md)
object.

## Usage

``` r
# S3 method for class 'hv_nnt'
plot(x, ci_alpha = 0.2, linewidth = 1, ..., line_width)
```

## Arguments

- x:

  An `hv_nnt` object from
  [`hv_nnt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_nnt.md).

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

[`hv_nnt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_nnt.md),
[`hv_survival_difference()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_survival_difference.md),
[`theme_hv_manuscript()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md)
