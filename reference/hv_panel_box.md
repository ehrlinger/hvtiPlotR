# Standard slide panel rectangle for an HVTI template

The fixed panel rectangle
[`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md)
anchors every plot to, in inches, for the 13.33 by 7.5 inch HVTI
templates. The dark (default), light and slate templates share one
master layout: the title placeholder runs from 0.08 to 1.33 in, at 48
pt. So all get the same rectangle, starting at 1.6 in and 3.9 in tall.
That leaves room for facet strips under the title and for the 32 pt axis
text and 40 pt axis title of
[`theme_hv_ppt_dark()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md),
[`theme_hv_ppt_light()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md)
and
[`theme_hv_ppt_slate()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md)
above the bottom edge, and matches the CORR template's own chart and
table slides, which start at 1.58 in.

## Usage

``` r
hv_panel_box(mode = c("dark", "light", "slate"))
```

## Arguments

- mode:

  `"dark"` (the default template), `"light"`
  (`hv_ppt_template_light.pptx`) or `"slate"`
  (`hv_ppt_template_slate.pptx`). All return the same rectangle; the
  argument is kept so calls name the template they target.

## Value

A named list `width`, `height`, `left`, `top`, ready for the `panel_box`
argument of
[`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md).

## Details

Through hvtiPlotR 2.8.11 the dark rectangle started at 1.29 in and was
4.422 in tall, which put facet strips inside the title placeholder. Pass
`panel_box = list(width = 8.79, height = 4.422, left = 2.67, top = 1.29)`
to
[`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md)
to rebuild an old deck at its old geometry.

## See also

[`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md),
[`hv_ph_location()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ph_location.md)

## Examples

``` r
hv_panel_box("slate")
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
