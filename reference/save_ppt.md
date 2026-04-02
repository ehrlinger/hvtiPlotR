# Save ggplot Objects to an Editable PowerPoint Presentation

Writes one ggplot per slide into a PowerPoint file using
[`officer::ph_with()`](https://davidgohel.github.io/officer/reference/ph_with.html)
and [`rvg::dml()`](https://davidgohel.github.io/rvg/reference/dml.html)
so that every plot lands as an **editable DrawingML vector graphic** —
shapes, lines, and text remain selectable in PowerPoint. Plots are
placed via
[`officer::ph_location()`](https://davidgohel.github.io/officer/reference/ph_location.html)
for pixel-exact positioning; titles go into the designated title
placeholder via
[`officer::ph_location_type()`](https://davidgohel.github.io/officer/reference/ph_location_type.html).

## Usage

``` r
save_ppt(
  object,
  template = "../graphs/RD.pptx",
  powerpoint = "../graphs/pptExample.pptx",
  slide_titles = "Plot",
  layout = "Title and Content",
  master = NULL,
  width = 10.1,
  height = 5.8,
  left = 0,
  top = 1.2
)
```

## Arguments

- object:

  A single ggplot object **or** a named/unnamed list of ggplot objects.
  Each element produces one slide.

- template:

  Path to an existing `.pptx` file used as the slide template. Default
  `"../graphs/RD.pptx"`.

- powerpoint:

  Output path for the new `.pptx` file. Default
  `"../graphs/pptExample.pptx"`.

- slide_titles:

  A character vector of slide titles. Recycled to the number of plots:
  supply one string for all slides, or one per plot. Default `"Plot"`.

- layout:

  PowerPoint slide layout name from the template. Default
  `"Title and Content"`.

- master:

  PowerPoint master name from the template, or `NULL` to use the
  template's first available master. Default `NULL`.

- width:

  Plot width in inches within the slide. Default `10.1`.

- height:

  Plot height in inches within the slide. Default `5.8`.

- left:

  Distance in inches from the left edge of the slide. Default `0.0`.

- top:

  Distance in inches from the top of the slide. Default `1.2` (below a
  standard title bar).

## Value

Invisibly returns the path given by `powerpoint`.

## See also

[`rvg::dml()`](https://davidgohel.github.io/rvg/reference/dml.html),
[`officer::ph_with()`](https://davidgohel.github.io/officer/reference/ph_with.html),
[`officer::ph_location()`](https://davidgohel.github.io/officer/reference/ph_location.html),
[`hv_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme.md)

## Examples

``` r
if (FALSE) { # \dontrun{
library(ggplot2)

# Single plot — dark PPT theme matches a black-background slide
p1 <- ggplot(mtcars, aes(x = wt, y = mpg)) +
  geom_point() +
  labs(x = "Weight", y = "Miles per gallon", title = "Fuel economy") +
  hv_theme("dark_ppt")

save_ppt(
  object       = p1,
  template     = "graphs/RD.pptx",
  powerpoint   = "graphs/fuel_economy.pptx",
  slide_titles = "Fuel Economy by Weight"
)

# List of plots — one slide per plot, individual titles
p2 <- ggplot(mtcars, aes(x = factor(cyl), y = mpg)) +
  geom_boxplot() +
  labs(x = "Cylinders", y = "Miles per gallon") +
  hv_theme("dark_ppt")

save_ppt(
  object       = list(p1, p2),
  template     = "graphs/RD.pptx",
  powerpoint   = "graphs/deck.pptx",
  slide_titles = c("Scatter: fuel economy", "Box: mpg by cylinder count")
)

# Manuscript (white background) for AATS-style presentations
pm <- ggplot(mtcars, aes(x = wt, y = mpg)) +
  geom_point() +
  labs(x = "Weight", y = "Miles per gallon") +
  hv_theme("manuscript")

save_ppt(
  object       = pm,
  template     = "graphs/RD-white.pptx",
  powerpoint   = "graphs/manuscript.pptx",
  slide_titles = "Fuel Economy"
)
} # }
```
