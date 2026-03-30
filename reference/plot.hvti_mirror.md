# Plot an hvti_mirror object

Builds a bare mirrored-histogram `ggplot2` object from an
[`hvti_mirror`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_mirror.md)
data object. Bars for the treated group appear above the x-axis; bars
for the control group appear below. Matched patients are shown in a
lighter shade. Add scales, labels, and a theme with `+`.

## Usage

``` r
# S3 method for class 'hvti_mirror'
plot(x, alpha = 0.8, ...)
```

## Arguments

- x:

  An `hvti_mirror` object.

- alpha:

  Bar transparency in \\\[0,1\]\\. Default `0.8`.

- ...:

  Ignored; present for S3 consistency.

## Value

A bare [`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## See also

[`hvti_mirror`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_mirror.md),
[`hvti_theme`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md)

## Examples

``` r
dta <- sample_mirror_histogram_data(n = 500)
mh  <- hvti_mirror(dta)
#> mirror_histogram diagnostics: n=1000  dropped=0  [see $tables$diagnostics]

plot(mh) +
  ggplot2::labs(x = "Propensity Score (%)", y = "Count") +
  hvti_theme("manuscript")

```
