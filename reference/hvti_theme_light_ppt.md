# Light PowerPoint Theme

A large-font theme with a **white/transparent background** suited to
light-background PowerPoint slides (e.g. AATS-style). Removes grid lines
and panel borders.

## Usage

``` r
hvti_theme_light_ppt(
  base_size = 32,
  base_family = "",
  header_family = NULL,
  base_line_size = base_size/22,
  base_rect_size = base_size/22,
  ink = "black",
  paper = "transparent",
  accent = "#3366FF"
)

theme_light_ppt(
  base_size = 32,
  base_family = "",
  header_family = NULL,
  base_line_size = base_size/22,
  base_rect_size = base_size/22,
  ink = "black",
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

  Foreground (text and line) colour. Default `"black"`.

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

## Details

For the default dark-background PowerPoint theme use
[`hvti_theme_dark_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_dark_ppt.md)
or its alias
[`hvti_theme_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_dark_ppt.md).

## See also

[`hvti_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md),
[`hvti_theme_dark_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_dark_ppt.md),
[`theme_man()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_manuscript.md),
[`theme_poster()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_poster.md)

## Examples

``` r
library(ggplot2)
p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) + geom_point()

# Light PPT theme — large font, black text, transparent background
p + hvti_theme_light_ppt()


# Via alias
p + theme_light_ppt()


# Via the generic dispatcher
p + hvti_theme("light_ppt")

```
