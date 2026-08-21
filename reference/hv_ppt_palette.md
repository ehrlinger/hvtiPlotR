# Series colours for a slide or a manuscript figure

The colours
[`hv_ppt_series()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ppt_series.md)
assigns, handed back as a plain character vector. This is the single
definition of the series colours, so reach for it when a figure needs
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

  Number of colours to return, or `NULL` (default) for all six.

## Value

A character vector of hex colours, in series order.

## Details

The colours are the Okabe-Ito colourblind-safe palette, reordered for
the background: high-luminance hues first on a dark slide, darker ones
first on a light slide, so the first series always has the strongest
contrast against the surface it sits on. Black appears only in the light
ordering; on a dark panel it is invisible. These are not CORR brand
colours.

Six colours are supplied. Ask for more than that and you get an error
rather than a silently recycled palette, because two series sharing a
colour is a worse outcome than a stopped script.

## See also

[`hv_ppt_series()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ppt_series.md),
which applies these to a plot. Note that annotation text is drawn in the
theme's ink, matching the axis, rather than in a series colour, so these
are not the values to label a curve with.

## Examples

``` r
hv_ppt_palette("dark")
#> [1] "#F0E442" "#56B4E9" "#E69F00" "#009E73" "#CC79A7" "#D55E00"
hv_ppt_palette("light", n = 4)
#> [1] "#0072B2" "#D55E00" "#009E73" "#CC79A7"
```
