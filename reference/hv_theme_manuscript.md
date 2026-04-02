# Theme for Manuscript Figures

A clean, white-background theme suited to journal submissions. Removes
grid lines, panel borders, and legends; draws solid axis lines.

## Usage

``` r
hv_theme_manuscript(
  base_size = 12,
  base_family = "",
  header_family = NULL,
  base_line_size = base_size/22,
  base_rect_size = base_size/22,
  ink = "black",
  paper = "white",
  accent = "#3366FF"
)

theme_manuscript(
  base_size = 12,
  base_family = "",
  header_family = NULL,
  base_line_size = base_size/22,
  base_rect_size = base_size/22,
  ink = "black",
  paper = "white",
  accent = "#3366FF"
)

theme_man(
  base_size = 12,
  base_family = "",
  header_family = NULL,
  base_line_size = base_size/22,
  base_rect_size = base_size/22,
  ink = "black",
  paper = "white",
  accent = "#3366FF"
)
```

## Arguments

- base_size:

  Base font size in points. Default `12`.

- base_family:

  Base font family. Default `""` (device default).

- header_family:

  Font family for headers, or `NULL` to inherit `base_family`. Default
  `NULL`.

- base_line_size:

  Line size used for axis lines and borders. Default `base_size / 22`.

- base_rect_size:

  Rectangle border size. Default `base_size / 22`.

- ink:

  Foreground (text and line) colour. Default `"black"`.

- paper:

  Background colour. Default `"white"`.

- accent:

  Accent colour used by some
  [`theme_grey()`](https://ggplot2.tidyverse.org/reference/ggtheme.html)
  elements. Default `"#3366FF"`.

## Value

A
[`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html)
object.

## Note

Deprecated. Use
[`hv_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme.md)
with `style = "manuscript"` instead.

## See also

[`hv_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme.md),
[`theme_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme_dark_ppt.md),
[`theme_dark_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme_dark_ppt.md),
[`theme_poster()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme_poster.md)

## Examples

``` r
library(ggplot2)
p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) + geom_point()

# Default manuscript theme
p + hv_theme_manuscript()


# Smaller base font for two-column journal layout
p + hv_theme_manuscript(base_size = 9)


# Via the generic dispatcher
p + hv_theme("manuscript")

```
