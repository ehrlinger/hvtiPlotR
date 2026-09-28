# Colours for a figure's levels, by role

The house colour rule for EDA and follow-up figures, as a named vector
you can check or reuse: an event is vermillion, censored is blue,
missing is light grey, and every other level takes a colourblind-safe
colour in order. To apply the rule to a plot, use
[`scale_fill_hv()`](https://ehrlinger.github.io/hvtiPlotR/reference/scale_fill_hv.md)
or
[`scale_colour_hv()`](https://ehrlinger.github.io/hvtiPlotR/reference/scale_fill_hv.md),
which call this for each panel.

## Usage

``` r
hv_role_palette(levels, event = NULL, censored = NULL, missing = "(Missing)")
```

## Arguments

- levels:

  Character vector of distinct level names, in drawing order.

- event, censored:

  Level names that take the event or the censored colour, or `NULL` for
  none. Names not in `levels` are ignored.

- missing:

  Level name that stands for missing values. `"(Missing)"` is the
  explicit level
  [`hv_eda()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_eda.md)
  adds.

## Value

A character vector of hex colours, named by `levels` and in the same
order.

## Details

Every colour is decided from `levels` alone:

1.  A level named in `event` is `#D55E00`, in `censored` `#0072B2`, and
    in `missing` `#CCCCCC`. These hold even when the level is the only
    one.

2.  Every other level, in `levels` order, takes the light series of
    [`hv_ppt_palette()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ppt_palette.md):
    the Okabe-Ito colours without yellow and sky blue, starting at blue,
    so a sole level with no role is blue.

3.  When any of `levels` is named in `event` or `censored`, blue and
    vermillion leave that series, so no other level can be mistaken for
    the event or for censored. A role name absent from `levels` changes
    nothing, so one call can serve panels that do and do not carry the
    event.

4.  When the other levels outnumber the series, all of them switch to
    Paul Tol's muted palette, without its sand and cyan, and without its
    rose when a role is present. Beyond that there are no more
    colourblind-safe colours, and the function stops with an error of
    class `hv_role_palette_capacity`.

Every colour except the missing grey is at least 2:1 against white. The
grey is fainter on purpose: missing is the one level meant to recede.

## See also

[`scale_fill_hv()`](https://ehrlinger.github.io/hvtiPlotR/reference/scale_fill_hv.md)
and
[`scale_colour_hv()`](https://ehrlinger.github.io/hvtiPlotR/reference/scale_fill_hv.md)
to apply the rule to a plot;
[`hv_ppt_palette()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ppt_palette.md)
for series colours with no role attached.

## Examples

``` r
hv_role_palette(c("No event", "Reoperation", "Death"),
                event = "Death", censored = "No event")
#>    No event Reoperation       Death 
#>   "#0072B2"   "#009E73"   "#D55E00" 
hv_role_palette(c("Female", "Male", "(Missing)"))
#>    Female      Male (Missing) 
#> "#0072B2" "#D55E00" "#CCCCCC" 
```
