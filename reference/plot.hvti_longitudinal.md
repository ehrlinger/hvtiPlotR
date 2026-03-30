# Plot an hvti_longitudinal object

Draws either a grouped bar chart of counts by time point
(`type = "plot"`) or a numeric text-table panel suitable for composing
below the bar chart via patchwork (`type = "table"`).

## Usage

``` r
# S3 method for class 'hvti_longitudinal'
plot(
  x,
  type = c("plot", "table"),
  position = "dodge",
  label_format = NULL,
  ...
)
```

## Arguments

- x:

  An `hvti_longitudinal` object.

- type:

  Which panel to produce: `"plot"` (default) or `"table"`.

- position:

  Bar position for `type = "plot"`: `"dodge"` (default) or `"stack"`.

- label_format:

  Formatting function applied to count values for `type = "table"`.
  `NULL` (default) auto-selects
  [`scales::comma`](https://scales.r-lib.org/reference/comma.html) when
  the scales package is installed, otherwise falls back to
  [`base::as.character`](https://rdrr.io/r/base/character.html). Pass
  `identity` to display counts without formatting.

- ...:

  Ignored; present for S3 consistency.

## Value

A bare [`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## See also

[`hvti_longitudinal`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_longitudinal.md)

## Examples

``` r
library(ggplot2)
dta <- sample_longitudinal_counts_data(n_patients = 300, seed = 42L)
lc  <- hvti_longitudinal(dta)

# Bar chart
plot(lc, type = "plot") +
  scale_fill_manual(
    values = c(Patients = "steelblue", Measurements = "firebrick"),
    name   = NULL
  ) +
  labs(x = "Follow-up Window", y = "Count (n)") +
  hvti_theme("manuscript")


# Text table panel
plot(lc, type = "table") +
  scale_colour_manual(
    values = c(Patients = "steelblue", Measurements = "firebrick"),
    guide  = "none"
  ) +
  hvti_theme("manuscript")


# Compose with patchwork
# p_bar   <- plot(lc, type = "plot")   + <decorators>
# p_table <- plot(lc, type = "table")  + <decorators>
# p_bar / p_table + patchwork::plot_layout(heights = c(3, 1))
```
