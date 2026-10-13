# Figure dimensions for a faceted plot

Chooses
[`ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html)
dimensions from a plot's facet layout, so a faceted figure keeps panels
of a readable size however many there are. A plot with one panel gets
the standard 6 by 4 inch figure. A plot with several gets 3 by 2 inch
panels, half the standard figure in each direction, plus the space its
axes, titles, strips and legend need, measured by
[`hv_ggsave_dims()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ggsave_dims.md).

## Usage

``` r
hv_panel_size(
  plot,
  max_width = NULL,
  max_height = NULL,
  units = c("in", "cm", "mm")
)
```

## Arguments

- plot:

  A ggplot object. Faceted with
  [`ggplot2::facet_wrap()`](https://ggplot2.tidyverse.org/reference/facet_wrap.html)
  or
  [`ggplot2::facet_grid()`](https://ggplot2.tidyverse.org/reference/facet_grid.html),
  or not faceted at all. A patchwork is refused: its panels sit in
  nested tables the function cannot count.

- max_width:

  The widest figure allowed, in `units`. `NULL`, the default, is 6.5
  inches, a journal's text width, converted to `units`.

- max_height:

  The tallest figure allowed, in `units`. `NULL`, the default, is 9
  inches, converted to `units`; with the 6.5 inch width it fits a page.

- units:

  One of `"in"`, `"cm"`, `"mm"`. Default `"in"`.

## Value

A named list with elements `width`, `height` and `units`, shaped to
splat into
[`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html)
via [`do.call()`](https://rdrr.io/r/base/do.call.html), as
[`hv_ggsave_dims()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ggsave_dims.md)
returns.

## Details

When those panels, with the gutters and interior strips between them,
would make the figure wider than `max_width` or taller than
`max_height`, every panel shrinks by the same factor, so each keeps its
3:2 shape. A panel narrower than 1.6 inches leaves no room for 12 pt
tick labels, so below that the function stops: the facets do not fit on
one page, and
[`ggforce::facet_wrap_paginate()`](https://ggforce.data-imaginist.com/reference/facet_wrap_paginate.html)
splits them across several. A paginated plot is sized by the one page it
draws.

The panel block is measured, not the whole figure, because the chrome
around it varies: a long axis title or a legend at the top would
otherwise come out of every panel.

## See also

[`hv_ggsave_dims()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ggsave_dims.md),
which measures the chrome.

## Examples

``` r
# \donttest{
p <- ggplot2::ggplot(mtcars, ggplot2::aes(hp, mpg)) +
  ggplot2::geom_point() +
  ggplot2::facet_wrap(~cyl)
dims <- hv_panel_size(p)
do.call(
  ggplot2::ggsave,
  c(list(filename = file.path(tempdir(), "facets.pdf"), plot = p), dims)
)
# }
```
