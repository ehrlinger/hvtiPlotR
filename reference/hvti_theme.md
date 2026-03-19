# hvtiPlotR Theme Generic

Provides a single entry point for obtaining any supported hvtiPlotR
theme.

## Usage

``` r
hvti_theme(
  style = c("ppt", "dark_ppt", "light_ppt", "manuscript", "poster"),
  ...
)
```

## Arguments

- style:

  Character keyword identifying the theme style. Supported values:

  - `"ppt"` / `"dark_ppt"` — dark background, white text
    ([`hvti_theme_dark_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_dark_ppt.md));
    default PPT theme

  - `"light_ppt"` — light/transparent background, black text
    ([`hvti_theme_light_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_light_ppt.md))

  - `"manuscript"` — clean white background for journal figures
    ([`hvti_theme_manuscript()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_manuscript.md))

  - `"poster"` — medium font for conference posters
    ([`hvti_theme_poster()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_poster.md))

- ...:

  Additional parameters forwarded to the underlying theme constructor.

## Value

A
[`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html)
object.
