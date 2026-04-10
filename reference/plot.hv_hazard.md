# Plot an hv_hazard object

Renders a bare
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
from an
[`hv_hazard()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_hazard.md)
object. Compose with `scale_colour_*`,
[`scale_y_continuous()`](https://ggplot2.tidyverse.org/reference/scale_continuous.html),
[`labs()`](https://ggplot2.tidyverse.org/reference/labs.html), and
[`hv_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme.md)
to complete the figure.

## Usage

``` r
# S3 method for class 'hv_hazard'
plot(
  x,
  ci_alpha = 0.2,
  line_width = 1,
  point_size = 2,
  point_shape = 1L,
  errorbar_width = 0.25,
  ...
)
```

## Arguments

- x:

  An `hv_hazard` object from
  [`hv_hazard()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_hazard.md).

- ci_alpha:

  Transparency of the CI ribbon. Default `0.20`.

- line_width:

  Width of the parametric curve line. Default `1.0`.

- point_size:

  Size of empirical overlay points (used when `emp_geom = "point"` was
  set in
  [`hv_hazard()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_hazard.md)).
  Default `2.0`.

- point_shape:

  Shape code for empirical points (`1` = open circle, `0` = open
  square). Default `1`.

- errorbar_width:

  Width of error bars on empirical points. Default `0.25`.

- ...:

  Ignored; present for S3 consistency.

## Value

A
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object; compose with `+` to add scales, axis limits, labels, and
[`hv_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme.md).

## See also

[`hv_hazard()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_hazard.md)
to build the data object,
[`hv_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme.md)
for the publication theme.

Other Hazard plot:
[`hv_hazard()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_hazard.md)
