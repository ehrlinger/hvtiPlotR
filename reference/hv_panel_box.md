# Standard slide panel rectangle for an HVTI template

The fixed panel rectangle
[`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md)
anchors every plot to, in inches, for the 13.33 by 7.5 inch HVTI
templates. The dark (default) template's title bar ends above 1.29 in,
so its panel starts there. The light template's title placeholder runs
to 1.33 in, so its panel starts lower (1.6 in) and is shorter (3.9 in),
leaving room for facet strips under the title and for the 32 pt axis
text and 40 pt axis title of
[`theme_hv_ppt_light()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md)
above the bottom edge. Width and left edge are the same in both, so a
figure's panel sits at the same horizontal position in either deck.

## Usage

``` r
hv_panel_box(mode = c("dark", "light"))
```

## Arguments

- mode:

  `"dark"` (the default template) or `"light"`
  (`hv_ppt_template_light.pptx`).

## Value

A named list `width`, `height`, `left`, `top`, ready for the `panel_box`
argument of
[`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md).

## See also

[`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md),
[`hv_ph_location()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ph_location.md)

## Examples

``` r
hv_panel_box("light")
#> $width
#> [1] 8.79
#> 
#> $height
#> [1] 3.9
#> 
#> $left
#> [1] 2.67
#> 
#> $top
#> [1] 1.6
#> 
```
