# Colors for the groups compared in an outcome figure

The house colors for the groups of a survival, hazard or other outcome
curve, named by group so each group keeps its color in every figure of a
paper. A single group is black. Two to five groups take Paul Tol's
vibrant palette, led by red and blue: red `#CC3311`, blue `#0077BB`,
teal `#009988`, magenta `#EE3377`, cyan `#33BBEE`.

## Usage

``` r
hv_group_palette(levels)
```

## Arguments

- levels:

  Character vector of distinct group names, in drawing order.

## Value

A character vector of hex colors, named by `levels` and in the same
order, for `ggplot2::scale_color_manual(values = )`.

## Details

Red and blue mean the event and censored only in a figure that draws
those roles, which is
[`hv_role_palette()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_role_palette.md)'s
job. In an outcome curve the colors stand for groups, so the strongest
two go to the first two groups: they stay apart for a reader with
deuteranopia or protanopia (CIELAB distance 104 and 84 under
`colorspace::deutan()` and `protan()`), and they are hues the team's
JTCVS working palette names.

Six or seven groups all switch to Paul Tol's muted palette less sand and
cyan, the overflow
[`hv_role_palette()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_role_palette.md)
uses. Beyond seven there are no more colorblind-safe colors, and the
function stops with an error of class `hv_group_palette_capacity`.

Pass every level of the grouping factor, not only those a figure draws,
so that a figure missing one group does not shift the colors of the
rest.

## See also

[`hv_role_palette()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_role_palette.md)
for figures whose levels are the event, censored or missing;
[`hv_palette()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_palette.md)
for categorical groups that are not compared as outcomes.

## Examples

``` r
hv_group_palette("All")
#>       All 
#> "#000000" 
hv_group_palette(c("Sternotomy", "Robotic", "Thoracotomy"))
#>  Sternotomy     Robotic Thoracotomy 
#>   "#CC3311"   "#0077BB"   "#009988" 
```
