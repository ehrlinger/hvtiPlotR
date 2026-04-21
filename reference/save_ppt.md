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
  top = 1.2,
  panel_box = NULL
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

  Plot width in inches within the slide. Default `10.1`. Ignored when
  `panel_box` is supplied.

- height:

  Plot height in inches within the slide. Default `5.8`. Ignored when
  `panel_box` is supplied.

- left:

  Distance in inches from the left edge of the slide. Default `0.0`.
  Ignored when `panel_box` is supplied.

- top:

  Distance in inches from the top of the slide. Default `1.2` (below a
  standard title bar). Ignored when `panel_box` is supplied.

- panel_box:

  Optional named list `list(width, height, left, top)` describing the
  **panel content area** to anchor on every slide (in inches). When
  supplied, per-plot slide placement is computed via
  [`hv_ph_location()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ph_location.md)
  so the panel lands at the same slide coordinates on every slide
  regardless of axis-label width. When `NULL` (default), the fixed
  `width`/`height`/`left`/`top` arguments are used for every slide
  (legacy behavior).

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

# ----------------------------------------------------------------------
# panel_box: anchor the plot panel to a fixed rectangle on every slide
# ----------------------------------------------------------------------
#
# Problem: when plots in a deck have different y-axis ranges
# (e.g. "1.0" vs "4567.2"), axis-label widths differ and shift the
# panel inside a fixed ph_location(). On dark_ppt the black panel box
# appears to drift between slides — visually jarring.
#
# Solution: pass `panel_box = list(width = ..., height = ..., left = ...,
# top = ...)`. This describes the PANEL CONTENT AREA itself — the rectangle bounded by
# the axis lines, not the outer plot extent. save_ppt() calls
# [hv_ph_location()] for each plot, measures the axis / title / legend
# chrome around the panel, and adjusts per-slide placement so the
# panel lands at the target rectangle on every slide. The plot's
# OUTER dimensions therefore vary per slide (chrome floats around a
# constant panel), analogous to how [hv_ggsave_dims()] drives ggsave's
# width/height from a target panel size.

p_small <- ggplot(mtcars, aes(hp, mpg)) +
  geom_point() +
  scale_y_continuous(labels = function(x) sprintf("%3.1f", x)) +
  labs(x = "Horsepower", y = "MPG") +
  hv_theme("dark_ppt")

p_big <- ggplot(mtcars, aes(hp, mpg)) +
  geom_point() +
  scale_y_continuous(labels = function(x) sprintf("%8.1f", x * 10000)) +
  labs(x = "Horsepower", y = "MPG (x10k)") +
  hv_theme("dark_ppt")

# Without panel_box: panel drifts between slides because the big-number
# labels eat more horizontal space than the small-number labels.
save_ppt(
  object       = list(p_small, p_big),
  template     = "graphs/RD.pptx",
  powerpoint   = "graphs/drifting_deck.pptx",
  slide_titles = c("Small y-axis", "Big y-axis")
)

# With panel_box: target is a 10" x 5" panel at slide coordinates
# (1.5", 1.5"). The panel content area lands at exactly that rectangle
# on both slides; axis labels extend outside it as each plot requires.
save_ppt(
  object       = list(p_small, p_big),
  template     = "graphs/RD.pptx",
  powerpoint   = "graphs/anchored_deck.pptx",
  slide_titles = c("Small y-axis", "Big y-axis"),
  panel_box    = list(width = 10, height = 5, left = 1.5, top = 1.5)
)

# Sizing advice: panel_left and panel_top must be large enough for the
# widest axis labels in the deck. If chrome extends past the left or top
# slide edge, hv_ph_location() emits a warning naming that edge.
} # }
```
