# Series colors for a slide or a manuscript figure

The colors
[`hv_ppt_series()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ppt_series.md)
assigns, handed back as a plain character vector. This is the single
definition of the series colors, so reach for it when a figure needs
them outside the decorator rather than pasting hex codes into a script,
where they drift the first time the palette changes.

## Usage

``` r
hv_ppt_palette(mode = c("dark", "light"), n = NULL)
```

## Arguments

- mode:

  Slide or figure background. `"dark"` pairs with
  [`theme_hv_ppt_dark()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md),
  `"light"` with
  [`theme_hv_ppt_light()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md)
  and
  [`theme_hv_manuscript()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md).

- n:

  Number of colors to return, or `NULL` (default) for all six.

## Value

A character vector of hex colors, in series order.

## Details

The colors are the Okabe-Ito colorblind-safe palette, reordered for the
background: high-luminance hues first on a dark slide, darker ones first
on a light slide. Each ordering leads with its highest-contrast hue,
15.9:1 on a black panel and 5.2:1 on a white slide, but past that first
entry the order is not a contrast ranking and should not be read as one.
Black appears only in the light ordering, and it sits **last** there
despite carrying the highest ratio of anything here (21:1 on white):
house style draws annotation in the theme's ink, so a black series would
be confusable with the label naming it. On a dark panel black is
invisible, which is why that ordering omits it. These are not CORR brand
colors.

Every dark color clears 3:1 against the black panel
[`theme_hv_ppt_dark()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md)
draws, and every light color clears 3:1 on a white slide background,
which is the contrast WCAG 2.2 (success criterion 1.4.11) asks of a
graphical object a reader needs to read the chart.
[`theme_hv_ppt_light()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md)
leaves its panel transparent so the slide shows through, so the light
guarantee holds on a white template, which is what the house light
template is. Check the colors again before using them on a tinted slide.
One color in the light ordering is not Okabe-Ito's own. Their orange,
`#E69F00`, reaches only 2.3:1 on white, so the light ordering uses
`#9D952B` in its place, Okabe-Ito yellow darkened at the same hue until
it clears 3:1. An orange darkened that far would sit too close to
vermilion for a reader with red-green color-vision deficiency.

Six colors are supplied. Ask for more than that and you get an error
rather than a silently recycled palette, because two series sharing a
color is a worse outcome than a stopped script.

## See also

[`hv_ppt_series()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ppt_series.md),
which applies these to a plot. Annotation text is drawn in the theme's
ink, matching the axis, rather than in a series color, so these are not
the values to label a curve with.

## Examples

``` r
hv_ppt_palette("dark")
#> [1] "#F0E442" "#56B4E9" "#E69F00" "#009E73" "#CC79A7" "#D55E00"
hv_ppt_palette("light", n = 4)
#> [1] "#0072B2" "#D55E00" "#009E73" "#CC79A7"
```
