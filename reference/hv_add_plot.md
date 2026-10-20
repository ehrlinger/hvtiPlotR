# Place one plot on the current slide, fitted around the standard panel

Adds `plot` to the current slide of an officer presentation with its
panel anchored to `panel_box`, so every plot slide of a slide format
puts its panel in the same place. With `fit = TRUE` the plot's text
sizes and text margins are reduced together by
[`hv_fit_location()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_fit_location.md)
until axis text, axis titles, facet strips and plot titles lie on the
slide and below its title.

## Usage

``` r
hv_add_plot(
  doc,
  plot,
  panel_box = hv_panel_box(format = .hv_doc_format(doc)),
  fit = TRUE,
  png_fallback = TRUE,
  dpi = 300,
  ...
)
```

## Arguments

- doc:

  An `rpptx` object from
  [`officer::read_pptx()`](https://davidgohel.github.io/officer/reference/read_pptx.html)
  whose current slide receives the plot.

- plot:

  A ggplot or patchwork object.

- panel_box:

  Named list `list(width, height, left, top)`, in inches. Defaults to
  [`hv_panel_box()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_panel_box.md)
  for the slide format of `doc`, read from its slide size: 16:9 (every
  bundled template) or 4:3. A deck of any other size needs an explicit
  `panel_box`.

- fit:

  `TRUE` (the default) to reduce the plot's text until the figure fits
  on the slide. `FALSE` places the plot at its own sizes and warns if it
  runs off the slide or into the title.

- png_fallback:

  `TRUE` (the default) to place a PNG when the vector insert fails.
  `FALSE` lets the error through.

- dpi:

  Resolution of the fallback PNG. Default `300`.

- ...:

  Further arguments to
  [`hv_fit_location()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_fit_location.md):
  `title_bottom`, `edge`, `min_scale`, `step`. The slide size is read
  from `doc`.

## Value

`doc`, with the plot added, carrying an attribute `"hv_fit"`: a list
`scale` (the text scale used), `fits` (whether the figure lies inside
the slide limits), `png` (whether the PNG fallback was used) and
`location` (the placement, in inches). A message reports reduced text; a
warning reports a figure that still does not fit.

## Details

The plot goes in as an editable DrawingML vector graphic via
[`rvg::dml()`](https://davidgohel.github.io/rvg/reference/dml.html). A
dense point cloud can overflow libxml2 and make that insert fail; with
`png_fallback = TRUE` the plot is then rendered to a transparent PNG at
exactly the fitted location's size and placed at the same location, so
the panel still lands on `panel_box`.

Add the slide and its title first, with
[`officer::add_slide()`](https://davidgohel.github.io/officer/reference/add_slide.html)
and
[`officer::ph_with()`](https://davidgohel.github.io/officer/reference/ph_with.html);
[`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md)
does all of this for a list of plots.

## See also

[`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md),
[`hv_fit_location()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_fit_location.md),
[`hv_panel_box()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_panel_box.md).

## Examples

``` r
# \donttest{
p <- ggplot2::ggplot(mtcars, ggplot2::aes(hp, mpg)) +
  ggplot2::geom_point() +
  ggplot2::labs(x = "Horsepower", y = "Miles per gallon") +
  theme_hv_ppt_dark()

template <- system.file("extdata", "hv_ppt_template.pptx",
                        package = "hvtiPlotR")
doc <- officer::read_pptx(template)
doc <- officer::add_slide(doc, layout = hv_ppt_layout("figure"))
doc <- officer::ph_with(doc, "Fuel economy",
                        location = officer::ph_location_type("title"))
doc <- hv_add_plot(doc, p)
attr(doc, "hv_fit")$scale
#> [1] 1
print(doc, target = file.path(tempdir(), "fitted.pptx"))
# }
```
