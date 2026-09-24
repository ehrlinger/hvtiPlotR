# Plot an hv_rmst_curves object

Builds a bare `ggplot2` object from an
[`hv_rmst_curves()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_rmst_curves.md)
object: weighted Kaplan-Meier step curves, one facet per estimator,
coloured by arm. When `tau` was supplied, the area under each curve up
to `tau` is shaded
([`geom_ribbon()`](https://ggplot2.tidyverse.org/reference/geom_ribbon.html)
over a staircase polygon, so the shading follows the steps exactly) and
a vertical line marks `tau`. When `estimates` was supplied, the top
right of each facet carries the RMST difference and interval. Colour and
fill both map to arm: set them together with `scale_colour_*()` and
`scale_fill_*()`.

## Usage

``` r
# S3 method for class 'hv_rmst_curves'
plot(
  x,
  shade_alpha = 0.2,
  linewidth = 0.6,
  tau_linetype = "dashed",
  label_size = 3,
  ...
)
```

## Arguments

- x:

  An `hv_rmst_curves` object.

- shade_alpha:

  Transparency of the shaded area. Default `0.2`.

- linewidth:

  Step line width. Default `0.6`.

- tau_linetype:

  Linetype of the vertical `tau` line. Default `"dashed"`.

- label_size:

  Text size of the facet annotations. Default `3`.

- ...:

  Ignored; present for S3 consistency.

## Value

A bare
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## See also

[`hv_rmst_curves()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_rmst_curves.md)

Other Propensity Score & Matching:
[`hv_mirror_hist()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_mirror_hist.md),
[`hv_rmst_contrast()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_rmst_contrast.md),
[`hv_rmst_curves()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_rmst_curves.md),
[`plot.hv_mirror_hist()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_mirror_hist.md),
[`plot.hv_rmst_contrast()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_rmst_contrast.md),
[`sample_covariate_balance_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_covariate_balance_data.md)

## Examples

``` r
curves <- data.frame(
  estimator = rep(c("IPTW", "Overlap"), each = 6),
  arm       = rep(rep(c("treated", "control"), each = 3), 2),
  time      = rep(c(0, 200, 500), 4),
  surv      = c(1, .9, .7, 1, .8, .5, 1, .92, .75, 1, .85, .6)
)
plot(hv_rmst_curves(curves, tau = 365), shade_alpha = 0.3)

```
