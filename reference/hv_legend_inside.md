# Place a ggplot legend inside the emptiest panel corner

Inspects a built plot, finds the panel corner with the fewest data
points, and anchors the legend there. When no corner is clear of data
(e.g. dense multi-curve panels), or the plot is faceted, the legend is
sent to an outside position instead. The CORR house convention is
in-panel legends placed in dead space; this automates the corner choice.

## Usage

``` r
hv_legend_inside(
  plot,
  threshold = 0.08,
  box_frac = 0.3,
  pad = 0.02,
  fallback = "right",
  prefer = NULL
)
```

## Arguments

- plot:

  A single-panel `ggplot`.

- threshold:

  Maximum fraction of data points allowed in the chosen corner box for
  an in-panel legend. If the emptiest corner exceeds it, `fallback` is
  used. Default `0.08`.

- box_frac:

  Corner-box size as a fraction of panel width and height (`<= 0.5`).
  Default `0.30`.

- pad:

  Inset of the legend anchor from the panel edge, in npc units. Default
  `0.02`.

- fallback:

  Outside `legend.position` used when no corner is empty enough or the
  plot cannot be reasoned about (facets). One of `"right"`, `"left"`,
  `"top"`, `"bottom"`. Default `"right"`.

- prefer:

  Optional preferred corner: one of `"topright"`, `"topleft"`,
  `"bottomright"`, `"bottomleft"`. When set and that corner is clear
  (its occupancy is within `threshold`), the legend is placed there even
  if another corner is emptier. If the preferred corner is occupied, the
  emptiest-corner logic applies as usual. Default `NULL` (pick the
  emptiest corner).

## Value

The input `plot` with a
[`theme`](https://ggplot2.tidyverse.org/reference/theme.html) layer
added that sets the legend position.

## Details

Apply it *after* the house theme (which sets `legend.position = "none"`)
so its position wins.

## See also

Worked recipe with rendered output:
<https://ehrlinger.github.io/hvti_graphics/legends.html>.

## Examples

``` r
if (requireNamespace("ggplot2", quietly = TRUE)) {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) + geom_point()
  hv_legend_inside(p)
}

```
