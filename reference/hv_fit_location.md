# Fit a plot's chrome on the slide around a fixed panel

Anchors the plot's panel to `panel_box` with
[`hv_ph_location()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ph_location.md)
and checks that the whole figure, panel plus the axis text, axis titles,
facet strips and plot titles around it, lies on the slide and below the
slide title. If it does not, every text size in the plot's theme is
reduced by `step` (as a fraction of the original size), together with
every text margin set in absolute units, until it fits or reaches
`min_scale`. The panel never moves; only the chrome shrinks.

## Usage

``` r
hv_fit_location(
  plot,
  panel_box,
  slide_width = 13.333,
  slide_height = 7.5,
  title_bottom = 1.38,
  edge = 0.05,
  min_scale = 12/32,
  step = 2/32,
  align = c("panel", "fill"),
  margin = 0.45
)
```

## Arguments

- plot:

  A ggplot or patchwork object.

- panel_box:

  Named list `list(width, height, left, top)`, in inches: the slide
  rectangle for the plot's panel. See
  [`hv_panel_box()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_panel_box.md).

- slide_width, slide_height:

  Slide size, in inches. The defaults are the 16:9 HVTI templates.

- title_bottom:

  The lowest point of the slide title, in inches. The figure must start
  below it. The HVTI title placeholder ends at 1.33 in; the default
  leaves 0.05 in under it.

- edge:

  Margin kept clear on the left, right and bottom slide edges, in
  inches.

- min_scale:

  Smallest text scale tried, as a fraction of the plot's own sizes. The
  default, `12/32`, is 12 pt text at the 32 pt PPT base size.

- step:

  Amount the scale drops at each try. The default, `2/32`, is 2 pt at
  the 32 pt PPT base size.

- align:

  `"panel"` (the default) keeps the panel on `panel_box`, so every slide
  puts its panel in the same place. `"fill"` keeps the panel's height
  and top but sets its left edge and width from the chrome measured
  around it, so the whole figure spans the slide with `margin` clear on
  each side and sits centered. A plot with short y labels then gets a
  wider panel instead of a gap on the left; one with long labels keeps
  about the standard width. Panels no longer line up across slides. Text
  too wide for the margins (a long title) is stepped down as `fit` steps
  down any other overflow.

- margin:

  Space kept clear on the left and right of the figure, in inches, with
  `align = "fill"`. The default, `0.45`, matches the right margin of the
  standard panel box.

## Value

A list with elements

- `plot`: the plot, its text sizes and margins scaled by `scale`;

- `location`: the
  [`hv_ph_location()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ph_location.md)
  result for `panel_box`, a list `width`, `height`, `left`, `top` in
  inches, ready for
  [`officer::ph_location()`](https://davidgohel.github.io/officer/reference/ph_location.html);

- `scale`: the text scale used, `1` when the plot fit as it was;

- `fits`: `TRUE` when the figure lies inside the slide limits. When it
  is `FALSE`, `plot` and `location` are those at `min_scale`.

- `panel_box`: the panel rectangle used, `panel_box` itself unless
  `align = "fill"` moved it.

## Details

At the PPT themes' 32 pt base size the defaults step the text down 2 pt
at a time, to 30, 28, 26 and so on, down to 12 pt.

The figure checked is the placement box plus the actual extent of the
title, subtitle and caption text, placed by its `hjust` (and
`plot.title.position`): a title wider than the slide fails the check
even though its cell fits.

Only sizes and margins set in the theme are scaled. The size of text
drawn by a geom
([`geom_text()`](https://ggplot2.tidyverse.org/reference/geom_text.html),
[`geom_label()`](https://ggplot2.tidyverse.org/reference/geom_text.html))
is an aesthetic, not part of the theme, and is left alone. For a
patchwork, `panel_box` holds the union of its panels and the whole
composition is measured; see
[`hv_ph_location()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ph_location.md).

## See also

[`hv_add_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_add_plot.md),
which places the result on a slide;
[`hv_panel_box()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_panel_box.md),
[`hv_ph_location()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ph_location.md).

## Examples

``` r
# \donttest{
p <- ggplot2::ggplot(mtcars, ggplot2::aes(hp, mpg)) +
  ggplot2::geom_point() +
  ggplot2::labs(x = "Horsepower", y = "Miles per gallon") +
  theme_hv_ppt_dark()
fit <- hv_fit_location(p, hv_panel_box("dark"))
#> Warning: font family 'Arial' not found in PostScript font database
#> Warning: font family 'Arial' not found in PostScript font database
#> Warning: font family 'Arial' not found in PostScript font database
#> Warning: font family 'Arial' not found in PostScript font database
#> Warning: font family 'Arial' not found in PostScript font database
#> Warning: font family 'Arial' not found in PostScript font database
#> Warning: font family 'Arial' not found in PostScript font database
#> Warning: font family 'Arial' not found in PostScript font database
#> Warning: font family 'Arial' not found in PostScript font database
#> Warning: font family 'Arial' not found in PostScript font database
#> Warning: font family 'Arial' not found in PostScript font database
#> Warning: font family 'Arial' not found in PostScript font database
#> Warning: font family 'Arial' not found in PostScript font database
fit$scale
#> [1] 1
fit$location
#> $width
#> [1] 11.46681
#> 
#> $height
#> [1] 5.58348
#> 
#> $left
#> [1] 1.413187
#> 
#> $top
#> [1] 1.85
#> 
# }
```
