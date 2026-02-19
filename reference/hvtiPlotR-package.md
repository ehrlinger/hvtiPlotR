# hvtiPlotR package for plotting standard graphics for manuscripts and presentations using `R` and the `ggplot2` package.

hvtiPlotR is a replacement package for the `plot.sas` macro for creating
publication quality graphics.

- `ggplot2` figures: We chose to use the `ggplot2` package for our
  figures. The plot functions all return either a single `ggplot2`
  object, or a list of `ggplot2` objects. The user can then use
  additional `ggplot2` functions to modify and customise the figures to
  their liking.

The hvtiPlotR package contains the following functions:

- [`theme_man`](http://ehrlinger.github.io/hviPlotR/reference/hvti_theme_manuscript.md):
  Theme for manuscript figures

- [`theme_ppt`](http://ehrlinger.github.io/hviPlotR/reference/hvti_theme_ppt.md):
  Theme for PowerPoint presentation figures

- [`theme_dark_ppt`](http://ehrlinger.github.io/hviPlotR/reference/hvti_theme_dark_ppt.md):
  Dark theme for PowerPoint presentations

- [`theme_poster`](http://ehrlinger.github.io/hviPlotR/reference/hvti_theme_poster.md):
  Theme for poster figures

- [`save_ppt`](http://ehrlinger.github.io/hviPlotR/reference/save_ppt.md):
  Save ggplot objects to PowerPoint presentations

- [`makeFootnote`](http://ehrlinger.github.io/hviPlotR/reference/makeFootnote.md):
  Add footnotes to graphics

All functions have an associated plotting function that returns ggplot2
graphics, either individually or as a list, that can be further
customised using standard ggplot2 commands.

## References

Wickham, H. ggplot2: elegant graphics for data analysis. Springer New
York, 2009.
