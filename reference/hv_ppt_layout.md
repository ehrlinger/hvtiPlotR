# Slide layout name for a slide role

Every template bundled with hvtiPlotR (dark, light and slate) has the
same six layouts by the same names, so a deck script runs on any of
them. Name the role and pass the result to
[`officer::add_slide()`](https://davidgohel.github.io/officer/reference/add_slide.html).
[`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md)
sets a slide title, so its `layout` must have a title placeholder: it
works with `"figure"`, `"section"`, `"content"` and `"two"`. `"title"`
(Title Slide has ctrTitle and subTitle placeholders) and `"blank"` (no
placeholders) are for
[`officer::add_slide()`](https://davidgohel.github.io/officer/reference/add_slide.html)
only.

## Usage

``` r
hv_ppt_layout(
  role = c("figure", "section", "title", "content", "two", "blank")
)
```

## Arguments

- role:

  One of `"figure"` (title only, for a plot), `"section"` (a chapter
  head), `"title"` (the opening slide), `"content"` (title and one
  body), `"two"` (title and two bodies) or `"blank"`.

## Value

A single character string: the layout's name in every bundled template.

## Details

Through hvtiPlotR 2.8.11 the light template named its figure layout
"Custom Layout" and its section layout "1_Custom Layout", and the dark
template named its section layout "1_Title Only".
[`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md)
still accepts those names, with a one-time message; calls to
[`officer::add_slide()`](https://davidgohel.github.io/officer/reference/add_slide.html)
must use the new names.

## See also

[`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md),
[`hv_panel_box()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_panel_box.md).

## Examples

``` r
hv_ppt_layout("figure")
#> [1] "Title Only"
hv_ppt_layout("section")
#> [1] "Section Header"
```
