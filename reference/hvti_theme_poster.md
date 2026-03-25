# Theme for Poster Figures

A medium-font theme with a white panel background and visible axis
lines, suited to conference posters produced via PowerPoint. Removes
grid lines.

## Usage

``` r
hvti_theme_poster(
  base_size = 16,
  base_family = "",
  header_family = NULL,
  base_line_size = base_size/22,
  base_rect_size = base_size/22,
  ink = "black",
  paper = "white",
  accent = "#3366FF"
)

theme_poster(
  base_size = 16,
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

  Base font size in points. Default `16`.

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

## See also

[`hvti_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md),
[`theme_man()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_manuscript.md),
[`theme_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_dark_ppt.md),
[`theme_dark_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_dark_ppt.md)

## Examples

``` r
library(ggplot2)
p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) + geom_point()

# Default poster theme (16 pt base font)
p + hvti_theme_poster()


# Larger font for a wide-format poster
p + hvti_theme_poster(base_size = 20)


# Via alias
p + theme_poster()

```
