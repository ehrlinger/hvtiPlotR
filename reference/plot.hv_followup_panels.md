# Plot an hv_followup_panels object

Draws one bare goodness-of-follow-up figure per panel, through
[`plot.hv_followup()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_followup.md).
Colours, shapes, labels and themes are left to the caller, as everywhere
in this package; the state levels are `"Alive"` and `"Dead"` for a death
panel, and `"No event"`, the event's label and `"Death"` for an event
panel.

## Usage

``` r
# S3 method for class 'hv_followup_panels'
plot(x, alpha = 0.5, ...)
```

## Arguments

- x:

  An `hv_followup_panels` object.

- alpha:

  Point transparency. Default `0.5`, which keeps a dense cohort readable
  as a distribution.

- ...:

  Passed to
  [`plot.hv_followup()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_followup.md),
  for example `diagonal_color`.

## Value

A named list of bare `ggplot` objects, one per panel, in the order of
`x$data`.

## See also

[`hv_followup_panels()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_followup_panels.md),
[`plot.hv_followup()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_followup.md)

## Examples

``` r
dta <- sample_goodness_followup_data()
fp <- hv_followup_panels(dta, origin_year = 1990,
                         panels = list(all = list(status = "dead", time = "iv_dead")))
plots <- plot(fp)
plots$all +
  ggplot2::scale_colour_manual(values = c(Alive = "#377EB8", Dead = "#E41A1C")) +
  ggplot2::labs(x = "Year of operation", y = "Follow-up (years)")
```
