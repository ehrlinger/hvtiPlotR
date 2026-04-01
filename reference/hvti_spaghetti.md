# Prepare spaghetti / profile data for plotting

Validates a long-format repeated-measures data frame and returns an
`hvti_spaghetti` object. Call
[`plot.hvti_spaghetti`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hvti_spaghetti.md)
on the result to obtain a bare `ggplot2` trajectory plot that you can
decorate with colour scales, axis labels, and
[`hvti_theme`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md).

## Usage

``` r
hvti_spaghetti(
  data,
  x_col = "time",
  y_col = "value",
  id_col = "id",
  colour_col = NULL
)
```

## Arguments

- data:

  Data frame; one row per observation per subject.

- x_col:

  Name of the time column. Default `"time"`.

- y_col:

  Name of the outcome column. Default `"value"`.

- id_col:

  Name of the subject-identifier column (used as the `group` aesthetic
  for line continuity). Default `"id"`.

- colour_col:

  Name of the column to map to line colour, or `NULL` for a single
  uniform colour. Default `NULL`.

## Value

An object of class `c("hvti_spaghetti", "hvti_data")`; call
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) on the result
to render the figure — see
[`plot.hvti_spaghetti`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hvti_spaghetti.md).
The list contains:

- `$data`:

  The validated input data frame.

- `$meta`:

  Named list: `x_col`, `y_col`, `id_col`, `colour_col`, `n_subjects`,
  `n_obs`.

- `$tables`:

  Empty list.

## See also

[`plot.hvti_spaghetti`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hvti_spaghetti.md)
to render as a ggplot2 figure,
[`hvti_theme`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md)
for the publication theme,
[`sample_spaghetti_data`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_spaghetti_data.md)
for example data.

Other Spaghetti plot:
[`plot.hvti_spaghetti()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hvti_spaghetti.md)

## Examples

``` r
dta <- sample_spaghetti_data(n_patients = 150, seed = 42)
sp  <- hvti_spaghetti(dta, colour_col = "group")
sp   # prints subject count, observation count, column mapping
#> <hvti_spaghetti>
#>   N subjects  : 150  (594 observations)
#>   x / y / id  : time / value / id
#>   Colour col  : group

plot(sp) +
  ggplot2::scale_colour_manual(
    values = c(Female = "firebrick", Male = "steelblue"), name = NULL
  ) +
  ggplot2::labs(x = "Years after Operation",
                y = "AV Mean Gradient (mmHg)") +
  hvti_theme("manuscript")
#> Warning: No shared levels found between `names(values)` of the manual scale and the
#> data's colour values.
#> Warning: Ignoring empty aesthetic: `colour`.

```
