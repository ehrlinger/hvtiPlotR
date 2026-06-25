# Plot an hv_alluvial object

Draws a Sankey (alluvial) diagram using
[`geom_alluvium`](http://corybrunson.github.io/ggalluvial/reference/geom_alluvium.md)
and
[`geom_stratum`](http://corybrunson.github.io/ggalluvial/reference/geom_stratum.md).

## Usage

``` r
# S3 method for class 'hv_alluvial'
plot(
  x,
  stratum_fill = "grey80",
  stratum_width = 1/4,
  flow_width = 1/6,
  alpha = 0.8,
  knot_pos = 0.4,
  show_labels = TRUE,
  show_yaxis = TRUE,
  ...
)
```

## Arguments

- x:

  An `hv_alluvial` object.

- stratum_fill:

  Fill colour for the stratum bars. Default `"grey80"`.

- stratum_width:

  Width of the stratum bars as a fraction of axis spacing. Default
  `1/4`.

- flow_width:

  Width of the alluvium flows. Default `1/6`.

- alpha:

  Transparency of the flows, \\\[0,1\]\\. Default `0.8`.

- knot_pos:

  Curvature of the flow ribbons, \\\[0,1\]\\. Default `0.4`.

- show_labels:

  Logical; if TRUE, each stratum is labelled. Default `TRUE`.

- show_yaxis:

  Logical; if FALSE, the y-axis title, text, ticks, and line are blanked
  for a clean milestone patient-flow look (the alluvium/stratum geometry
  is untouched). Default `TRUE` (counts shown). Note the blanking is a
  [`theme()`](https://ggplot2.tidyverse.org/reference/theme.html) layer,
  so a *complete* theme added afterward (e.g.
  [`theme_hv_manuscript()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md))
  re-asserts the axis it styles; add the theme first and re-blank, or
  blank the y elements yourself after it, when you want both the house
  theme and a clean axis.

- ...:

  Ignored; present for S3 consistency.

## Value

A bare [`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## See also

[`hv_alluvial`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_alluvial.md),
[`theme_hv_manuscript`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md)

## Examples

``` r
dta  <- sample_alluvial_data(n = 300, seed = 42)
axes <- c("pre_ar", "procedure", "post_ar")

# Fill flows by procedure
plot(hv_alluvial(dta, axes = axes, y_col = "freq",
                   fill_col = "procedure")) +
  ggplot2::scale_fill_brewer(palette = "Set2", name = "Procedure") +
  ggplot2::scale_colour_brewer(palette = "Set2", guide = "none") +
  ggplot2::labs(y = "Patients (n)") +
  theme_hv_poster()
#> Warning: Some strata appear at multiple axes.
#> Warning: Some strata appear at multiple axes.
#> Warning: Some strata appear at multiple axes.


# Two-axis (before / after)
plot(hv_alluvial(
  dta, axes = c("pre_ar", "post_ar"), y_col = "freq",
  fill_col = "pre_ar",
  axis_labels = c("Pre-operative", "Post-operative")
)) +
  ggplot2::scale_fill_brewer(palette = "RdYlGn", direction = -1,
                             name = "AR Grade") +
  ggplot2::scale_colour_brewer(palette = "RdYlGn", direction = -1,
                               guide = "none") +
  ggplot2::labs(y = "Patients (n)") +
  theme_hv_poster()
#> Warning: Some strata appear at multiple axes.
#> Warning: Some strata appear at multiple axes.
#> Warning: Some strata appear at multiple axes.

```
