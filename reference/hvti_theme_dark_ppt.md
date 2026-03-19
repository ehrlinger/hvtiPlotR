# Dark PowerPoint Theme (default PPT theme)

A large-font theme with a **black panel background and white text**,
suited to dark-mode PowerPoint slides. This is the default hvtiPlotR PPT
theme — `hvti_theme_ppt()` and `theme_ppt()` are aliases for this
function. For a light-background variant use
[`hvti_theme_light_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_light_ppt.md).
Removes grid lines and panel borders.

## Usage

``` r
hvti_theme_dark_ppt(
  base_size = 32,
  base_family = "",
  header_family = NULL,
  base_line_size = base_size/22,
  base_rect_size = base_size/22,
  ink = "white",
  paper = "transparent",
  accent = "#3366FF"
)

theme_dark_ppt(
  base_size = 32,
  base_family = "",
  header_family = NULL,
  base_line_size = base_size/22,
  base_rect_size = base_size/22,
  ink = "white",
  paper = "transparent",
  accent = "#3366FF"
)

theme_ppt(
  base_size = 32,
  base_family = "",
  header_family = NULL,
  base_line_size = base_size/22,
  base_rect_size = base_size/22,
  ink = "white",
  paper = "transparent",
  accent = "#3366FF"
)

hvti_theme_ppt(
  base_size = 32,
  base_family = "",
  header_family = NULL,
  base_line_size = base_size/22,
  base_rect_size = base_size/22,
  ink = "white",
  paper = "transparent",
  accent = "#3366FF"
)
```

## Arguments

- base_size:

  Base font size in points. Default `32`.

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

  Foreground (text and line) colour. Default `"white"`.

- paper:

  Background colour. Default `"transparent"`.

- accent:

  Accent colour used by some
  [`theme_grey()`](https://ggplot2.tidyverse.org/reference/ggtheme.html)
  elements. Default `"#3366FF"`.

## Value

A
[`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html)
object.

## See also

[`hvti_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md),
[`hvti_theme_light_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_light_ppt.md),
[`theme_man()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_manuscript.md),
[`theme_poster()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_poster.md)
