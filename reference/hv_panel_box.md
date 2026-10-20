# Standard slide panel rectangle for a slide format

The one fixed panel rectangle every plot slide of a slide format anchors
its plotting panel to, in inches. The slide format is the slide's aspect
ratio: `"wide"` is 16:9, 13.333 by 7.5 in, the size of every bundled
HVTI template; `"standard"` is 4:3, 10 by 7.5 in. The color template
does not matter: the dark, light and slate templates get the same
rectangle.
[`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md)
and
[`hv_add_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_add_plot.md)
read the format from the template's slide size and use this rectangle by
default. Axis text, axis titles, facet strips and plot titles flow
outside it;
[`hv_fit_location()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_fit_location.md)
keeps them on the slide and out of the slide title.

## Usage

``` r
hv_panel_box(
  mode = c("dark", "light", "slate"),
  format = c("wide", "standard")
)
```

## Arguments

- mode:

  `"dark"`, `"light"` or `"slate"`. Kept for backward compatibility:
  every color template gets the same rectangle, so it has no effect.

- format:

  `"wide"` (16:9, the default) or `"standard"` (4:3, provisional).

## Value

A named list `width`, `height`, `left`, `top`, in inches, ready for the
`panel_box` argument of
[`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md)
and
[`hv_add_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_add_plot.md).

## Details

The wide rectangle is 9.98 by 4.15 in, 2.9 in from the left edge and
1.85 in from the top. The numbers leave room for the chrome around the
panel:

- 2.9 in on the left for long y-axis labels and the rotated y-axis
  title;

- about 0.45 in above the panel, below the title placeholder that ends
  at 1.33 in, for facet strips and plot titles;

- 1.5 in below the panel (7.5 - 1.85 - 4.15), or 1.45 in inside the 0.05
  in slide edge, for the x-axis chrome of
  [`theme_hv_ppt_dark()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md),
  [`theme_hv_ppt_light()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md)
  and
  [`theme_hv_ppt_slate()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md):
  their 32 pt x-axis text and 40 pt x-axis title with its margin need
  about 1.43 in, so a plot in these themes fits at full size.

The standard (4:3) rectangle is **provisional**: no 4:3 template is
bundled, and the rectangle has not yet been checked on a real 4:3 deck.
It follows the same rules, assuming the 4:3 title placeholder also ends
near 1.33 in: the same top (1.85 in) and height (4.15 in), 2.3 in on the
left for y labels and 0.45 in on the right, so 7.25 by 4.15 in at 2.3 in
left.

Through hvtiPlotR 2.8.13 the rectangle was 8.79 by 3.9 in at 2.67 in
left, 1.6 in top. Pass
`panel_box = list(width = 8.79, height = 3.9, left = 2.67, top = 1.6)`
to
[`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md)
or
[`hv_add_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_add_plot.md)
to rebuild an old deck at its old geometry.

## See also

[`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md),
[`hv_add_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_add_plot.md),
[`hv_fit_location()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_fit_location.md),
[`hv_ph_location()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ph_location.md)

## Examples

``` r
hv_panel_box()
#> $width
#> [1] 9.98
#> 
#> $height
#> [1] 4.15
#> 
#> $left
#> [1] 2.9
#> 
#> $top
#> [1] 1.85
#> 
hv_panel_box(format = "standard")
#> $width
#> [1] 7.25
#> 
#> $height
#> [1] 4.15
#> 
#> $left
#> [1] 2.3
#> 
#> $top
#> [1] 1.85
#> 
```
