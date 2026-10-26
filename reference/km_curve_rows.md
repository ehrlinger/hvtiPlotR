# Rows and geometry for a step or a line curve

A step curve uses every row. A line curve joins the events alone: it
keeps each stratum's first row (time zero, or on the log-log scale the
first row with a defined logarithm), each row with an event, and each
stratum's last row, so a censored time between two events puts no corner
where the estimate did not change, and the line still runs to the end of
follow-up.

## Usage

``` r
km_curve_rows(km_df, curve)

km_curve_geom(curve, alpha)
```

## Arguments

- km_df:

  Tidy KM data frame.

- curve:

  `"step"` or `"line"`.

- alpha:

  Line transparency.

## Value

`km_curve_rows()`, the rows to draw; `km_curve_geom()`, the layer that
draws them.
