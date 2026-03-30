# Plot an hvti_alluvial object

Draws a Sankey (alluvial) diagram using
[`geom_alluvium`](http://corybrunson.github.io/ggalluvial/reference/geom_alluvium.md)
and
[`geom_stratum`](http://corybrunson.github.io/ggalluvial/reference/geom_stratum.md).

## Usage

``` r
# S3 method for class 'hvti_alluvial'
plot(
  x,
  stratum_fill = "grey80",
  stratum_width = 1/4,
  flow_width = 1/6,
  alpha = 0.8,
  knot_pos = 0.4,
  show_labels = TRUE,
  ...
)
```

## Arguments

- x:

  An `hvti_alluvial` object.

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

  Logical; whether to label each stratum. Default `TRUE`.

- ...:

  Ignored; present for S3 consistency.

## Value

A bare [`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## See also

[`hvti_alluvial`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_alluvial.md),
[`hvti_theme`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md)

## Examples

``` r
dta  <- sample_alluvial_data(n = 300, seed = 42)
axes <- c("pre_ar", "procedure", "post_ar")

# Fill flows by procedure
plot(hvti_alluvial(dta, axes = axes, y_col = "freq",
                   fill_col = "procedure")) +
  ggplot2::scale_fill_brewer(palette = "Set2", name = "Procedure") +
  ggplot2::scale_colour_brewer(palette = "Set2", guide = "none") +
  ggplot2::labs(y = "Patients (n)") +
  hvti_theme("manuscript")
#> Warning: Some strata appear at multiple axes.
#> Warning: Some strata appear at multiple axes.
#> Warning: Some strata appear at multiple axes.


# Two-axis (before / after)
plot(hvti_alluvial(
  dta, axes = c("pre_ar", "post_ar"), y_col = "freq",
  fill_col = "pre_ar",
  axis_labels = c("Pre-operative", "Post-operative")
)) +
  ggplot2::scale_fill_brewer(palette = "RdYlGn", direction = -1,
                             name = "AR Grade") +
  ggplot2::scale_colour_brewer(palette = "RdYlGn", direction = -1,
                               guide = "none") +
  ggplot2::labs(y = "Patients (n)") +
  hvti_theme("manuscript")
#> Warning: Some strata appear at multiple axes.
#> Warning: Some strata appear at multiple axes.
#> Warning: Some strata appear at multiple axes.

```
