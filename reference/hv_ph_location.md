# Compute `officer::ph_location()` args for a fixed-panel slide layout

Given a fitted ggplot and a target panel rectangle
(width/height/left/top on the slide), returns the `width`, `height`,
`left`, `top` values to pass to
[`officer::ph_location()`](https://davidgohel.github.io/officer/reference/ph_location.html)
such that the *panel content area* of the plot lands at the specified
slide coordinates — regardless of how much room the axis labels, axis
titles, legend, plot title, or plot margins consume.

## Usage

``` r
hv_ph_location(
  plot,
  panel_width,
  panel_height,
  panel_left,
  panel_top,
  units = c("in", "cm", "mm")
)
```

## Arguments

- plot:

  A ggplot (or patchwork) object.

- panel_width:

  Target panel width, in `units`.

- panel_height:

  Target panel height, in `units`.

- panel_left:

  Distance from left edge of slide to the left edge of the panel, in
  `units`.

- panel_top:

  Distance from top edge of slide to the top edge of the panel, in
  `units`.

- units:

  One of `"in"`, `"cm"`, `"mm"`. Default `"in"`.

## Value

A named list with elements `width`, `height`, `left`, `top` — all in
`units`. Splat into
[`officer::ph_location()`](https://davidgohel.github.io/officer/reference/ph_location.html)
via [`do.call()`](https://rdrr.io/r/base/do.call.html).

## Details

The panel content area is the rectangular bounding box of the gtable
cells tagged `panel`. Strip grobs that sit inside that bounding box are
part of the target; strips outside it (e.g. `facet_grid` side strips,
the strip row above a single-row `facet_wrap`) are treated as chrome.

Use with
[`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md)
via `panel_box = list(width, height, left, top)` to apply this to every
slide in a deck.

## See also

[`hv_ggsave_dims()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ggsave_dims.md)
for the sizing-only analogue used with
[`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html),
and
[`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md)
which accepts a `panel_box` argument that delegates to this helper.

## Examples

``` r
if (FALSE) { # \dontrun{
p <- ggplot2::ggplot(mtcars, ggplot2::aes(hp, mpg)) +
  ggplot2::geom_point() +
  theme_hv_ppt_dark()

loc <- hv_ph_location(
  p,
  panel_width  = 10, panel_height = 5,
  panel_left   = 0.5, panel_top   = 1.5
)
# doc <- officer::read_pptx(template)
# doc <- officer::add_slide(doc, layout = "Title and Content")
# doc <- officer::ph_with(
#   doc, rvg::dml(ggobj = p),
#   location = do.call(officer::ph_location, loc)
# )
} # }
```
