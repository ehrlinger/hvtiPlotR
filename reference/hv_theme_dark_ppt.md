# Dark PowerPoint Theme (default PPT theme)

A large-font theme with a **black panel background and white text**,
suited to dark-mode PowerPoint slides. This is the default hvtiPlotR PPT
theme — `hv_theme_ppt()` and `theme_ppt()` are aliases for this
function. For a light-background variant use
[`hv_theme_light_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme_light_ppt.md).
Removes grid lines and panel borders.

## Usage

``` r
hv_theme_dark_ppt(
  base_size = 32,
  base_family = "",
  header_family = NULL,
  base_line_size = base_size/22,
  base_rect_size = base_size/22,
  ink = "white",
  paper = "transparent",
  accent = "#3366FF",
  bold = FALSE
)

theme_dark_ppt(
  base_size = 32,
  base_family = "",
  header_family = NULL,
  base_line_size = base_size/22,
  base_rect_size = base_size/22,
  ink = "white",
  paper = "transparent",
  accent = "#3366FF",
  bold = FALSE
)

theme_ppt(
  base_size = 32,
  base_family = "",
  header_family = NULL,
  base_line_size = base_size/22,
  base_rect_size = base_size/22,
  ink = "white",
  paper = "transparent",
  accent = "#3366FF",
  bold = FALSE
)

hv_theme_ppt(
  base_size = 32,
  base_family = "",
  header_family = NULL,
  base_line_size = base_size/22,
  base_rect_size = base_size/22,
  ink = "white",
  paper = "transparent",
  accent = "#3366FF",
  bold = FALSE
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

- bold:

  If `TRUE`, axis text and axis titles are rendered with
  `face = "bold"`. Default `FALSE`.

## Value

A
[`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html)
object.

## Details

Legend is hidden by default since PowerPoint figures are typically
annotated directly on the panel; add
`+ theme(legend.position = "right")` (or similar) to override. Axis-text
and axis-title margins are scaled from `base_size` via ggplot2's
`half_line = base_size / 2` convention, so the spacing stays
proportional when `base_size` changes.

## See also

[`hv_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme.md),
[`hv_theme_light_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme_light_ppt.md),
[`theme_man()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme_manuscript.md),
[`theme_poster()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme_poster.md)

## Examples

``` r
library(ggplot2)
p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) + geom_point()

# Dark PPT theme — large font, white text, black panel
p + hv_theme_dark_ppt()


# Via alias
p + theme_ppt()


# Bold axis text/titles
p + hv_theme_dark_ppt(bold = TRUE)


# Override the default hidden legend
p + hv_theme_dark_ppt() + theme(legend.position = "right")


if (FALSE) { # \dontrun{
# Best viewed against a dark slide background
p + hv_theme_dark_ppt() +
  ggplot2::theme(plot.background = ggplot2::element_rect(fill = "navy"))
} # }
```
