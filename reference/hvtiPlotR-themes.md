# hvtiPlotR ggplot2 themes

Drop-in replacements for
[`ggplot2::theme_bw()`](https://ggplot2.tidyverse.org/reference/ggtheme.html)
and friends, carrying the Cardiovascular Outcomes, Registries and
Research (CORR) house style for four publication contexts:

## Usage

``` r
theme_hv_manuscript(
  base_size = 12,
  base_family = "",
  header_family = NULL,
  base_line_size = base_size/22,
  base_rect_size = base_size/22,
  ink = "black",
  paper = "white",
  accent = "#3366FF",
  ...
)

theme_hv_poster(
  base_size = 16,
  base_family = "",
  header_family = NULL,
  base_line_size = base_size/22,
  base_rect_size = base_size/22,
  ink = "black",
  paper = "white",
  accent = "#3366FF",
  ...
)

theme_hv_ppt_dark(
  base_size = 32,
  base_family = "",
  header_family = NULL,
  base_line_size = base_size/22,
  base_rect_size = base_size/22,
  ink = "white",
  paper = "transparent",
  accent = "#3366FF",
  ...
)

theme_hv_ppt_light(
  base_size = 32,
  base_family = "",
  header_family = NULL,
  base_line_size = base_size/22,
  base_rect_size = base_size/22,
  ink = "black",
  paper = "transparent",
  accent = "#3366FF",
  ...
)

hv_theme_manuscript(...)

theme_manuscript(...)

theme_man(...)

hv_theme_poster(...)

theme_poster(...)

hv_theme_dark_ppt(...)

theme_dark_ppt(...)

hv_theme_ppt(...)

theme_ppt(...)

hv_theme_light_ppt(...)

theme_light_ppt(...)
```

## Arguments

- base_size:

  Base font size in points.

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

  Foreground (text and line) colour.

- paper:

  Background colour.

- accent:

  Accent colour used by some
  [`theme_grey()`](https://ggplot2.tidyverse.org/reference/ggtheme.html)
  elements. Default `"#3366FF"`.

- ...:

  Additional named theme elements forwarded to a final
  [`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html)
  call. Use this to override any theme element from the call site, e.g.
  `legend.position = "right"`.

## Value

A
[`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html)
object.

## Details

- `theme_hv_manuscript()` - clean white background for journal figures

- `theme_hv_poster()` - medium-font theme with visible axis lines for
  posters

- `theme_hv_ppt_dark()` - dark panel background, white text, large font

- `theme_hv_ppt_light()` - light/transparent panel background, black
  text

Each theme follows the
[`theme_bw()`](https://ggplot2.tidyverse.org/reference/ggtheme.html)
contract: pass `base_size` / `base_family` to control global typography,
then chain a `+ theme(...)` call to override anything else.
Additionally, any extra named argument is forwarded straight into a
final
[`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html)
call so callers can tweak elements inline:

    theme_hv_manuscript(legend.position = "right")
    theme_hv_ppt_dark(axis.text.y = element_text(family = "mono"))

Caller-supplied elements override the hvtiPlotR defaults.

`theme_hv_ppt_dark()` is the default PPT theme: a black panel with white
text suited to dark slide backgrounds. Use `theme_hv_ppt_light()` when
the slide template is light. Both PPT themes hide the legend by default
– override with `legend.position = "right"` (or chain `+ theme(...)`).

Margins on axis text/title are scaled from `base_size` via the standard
`half_line = base_size / 2` convention, so spacing stays proportional
when `base_size` changes.
