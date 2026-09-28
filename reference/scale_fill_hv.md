# Colour and fill scales that apply the role rule to each panel

Discrete scales that colour each panel by
[`hv_role_palette()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_role_palette.md):
event vermillion, censored blue, missing light grey, and
colourblind-safe colours for everything else. Add one to a page of
panels with `&` and every panel is coloured from its own levels, so a
panel without the event still draws its levels from blue.

## Usage

``` r
scale_fill_hv(
  event = NULL,
  censored = NULL,
  missing = "(Missing)",
  na.value = .HV_ROLE_MISSING,
  ...
)

scale_colour_hv(
  event = NULL,
  censored = NULL,
  missing = "(Missing)",
  na.value = .HV_ROLE_MISSING,
  ...
)
```

## Arguments

- event, censored:

  Level names that take the event or the censored colour, or `NULL` for
  none. Names not in `levels` are ignored.

- missing:

  Level name that stands for missing values. `"(Missing)"` is the
  explicit level
  [`hv_eda()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_eda.md)
  adds.

- na.value:

  Colour for a real `NA`. The default is the missing grey, so an `NA`
  and a `"(Missing)"` level look the same.

- ...:

  Passed to
  [`ggplot2::discrete_scale()`](https://ggplot2.tidyverse.org/reference/discrete_scale.html):
  `name`, `labels`, `guide` and so on.

## Value

A discrete ggplot2 scale for the `colour` or `fill` aesthetic.

## Details

Colours stay the caller's choice: no constructor or
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) method in this
package applies these scales for you.

A panel with more levels than the colourblind-safe palettes hold is
drawn in ggplot2's default hue palette instead, with a warning naming
its level count, so one variable with many levels does not stop a
report. Call
[`hv_role_palette()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_role_palette.md)
directly to get an error in that case.

## See also

[`hv_role_palette()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_role_palette.md)
for the rule itself.

## Examples

``` r
dta <- data.frame(status = c("Alive", "Dead", "Alive", "(Missing)"))
ggplot2::ggplot(dta, ggplot2::aes(status, fill = status)) +
  ggplot2::geom_bar() +
  scale_fill_hv(event = "Dead", censored = "Alive")
```
