# The house palette for categorical groups

Colors for categorical groups in a manuscript, poster or
light-background slide figure: the Okabe-Ito colors, ordered for a white
background, with every one clearing 3:1 contrast against white. Hand it
to a manual scale, `scale_color_manual(values = hv_palette())`.

## Usage

``` r
hv_palette(n = NULL)
```

## Arguments

- n:

  Number of colors to return, or `NULL` (default) for all six.

## Value

A character vector of hex colors, in group order.

## Details

This is the categorical half of the house color rule. Ordered and
diverging scales take ColorBrewer `"RdBu"` or `"PuOr"` through
[`ggplot2::scale_color_brewer()`](https://ggplot2.tidyverse.org/reference/scale_brewer.html),
and sequential scales take `"Blues"`. Avoid `"Set1"` and `"RdYlGn"`:
their red against green fails for a reader with deuteranopia.

The colors are those of `hv_ppt_palette("light")`, under a name that
does not tie a manuscript figure to slides. For a dark slide, use
`hv_ppt_palette("dark")`. Six colors are supplied, and asking for more
is an error rather than a silently recycled palette.

## See also

[`hv_ppt_palette()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ppt_palette.md)
for the slide orderings,
[`hv_role_palette()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_role_palette.md)
when levels carry a role such as event or censored.

## Examples

``` r
hv_palette()
#> [1] "#0072B2" "#D55E00" "#009E73" "#CC79A7" "#9D952B" "#000000"
hv_palette(n = 3)
#> [1] "#0072B2" "#D55E00" "#009E73"
```
