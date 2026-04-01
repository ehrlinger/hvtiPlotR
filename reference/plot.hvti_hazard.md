# Plot an hvti_hazard object

Renders a bare
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
from an
[`hvti_hazard()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_hazard.md)
object. Compose with `scale_colour_*`,
[`scale_y_continuous()`](https://ggplot2.tidyverse.org/reference/scale_continuous.html),
[`labs()`](https://ggplot2.tidyverse.org/reference/labs.html), and
[`hvti_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md)
to complete the figure.

## Usage

``` r
# S3 method for class 'hvti_hazard'
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

  An `hvti_hazard` object from
  [`hvti_hazard()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_hazard.md).

- ci_alpha:

  Transparency of the CI ribbon. Default `0.20`.

- line_width:

  Width of the parametric curve line. Default `1.0`.

- point_size:

  Size of empirical overlay points. Default `2.0`.

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
[`hvti_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md).

## See also

[`hvti_hazard()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_hazard.md)
to build the data object,
[`hvti_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md)
for the publication theme.

Other Hazard plot:
[`hvti_hazard()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_hazard.md)
