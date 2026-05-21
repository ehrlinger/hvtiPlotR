# Build a CONSORT flow diagram from a tracker

Reads the stage metadata stored in an `hv_consort_tracker`, auto-derives
the `orders` and `side_box` arguments for
[`consort::consort_plot()`](https://rdrr.io/pkg/consort/man/consort_plot.html),
and returns an `hv_consort` object wrapping the grid diagram.

## Usage

``` r
hv_consort(
  tracker,
  side_box = "all",
  cex = 0.9,
  width = NULL,
  height = NULL,
  ...
)
```

## Arguments

- tracker:

  An `hv_consort_tracker` with at least two stages (call
  [`hv_consort_exclude()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_consort_exclude.md)
  at least once after
  [`hv_consort_start()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_consort_start.md)).

- side_box:

  Character vector of exclusion-reason column names to display as side
  boxes, or `"all"` (default) to include every exclusion column.

- cex:

  Numeric; text size scaling passed to
  [`consort::consort_plot()`](https://rdrr.io/pkg/consort/man/consort_plot.html).
  Default `0.9`.

- width:

  Diagram width in inches. Defaults to `7`.

- height:

  Diagram height in inches. Defaults to `2 + n_stages * 1.2`, where
  `n_stages` is the number of stages in the tracker.

- ...:

  Additional arguments forwarded to
  [`consort::consort_plot()`](https://rdrr.io/pkg/consort/man/consort_plot.html).

## Value

An `hv_consort` object – a list with:

- `$plot`:

  The grid object returned by
  [`consort::consort_plot()`](https://rdrr.io/pkg/consort/man/consort_plot.html).

- `$meta`:

  Named list: `n_stages`, `width`, `height`, `orders`, `side_box`.

- `$tracker`:

  The original `hv_consort_tracker`.

## See also

[`hv_consort_start()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_consort_start.md),
[`hv_consort_exclude()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_consort_exclude.md),
[`plot.hv_consort()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_consort.md)

## Examples

``` r
cohort <- data.frame(
  mrn  = paste0("P", 1:100),
  age  = sample(15:80, 100, TRUE),
  echo = sample(c(TRUE, FALSE), 100, TRUE, prob = c(0.9, 0.1))
)
tracker <- hv_consort_start(cohort, patient_id = mrn) |>
  hv_consort_exclude(label = "Eligible", col = "excl_screen",
                      age < 18 ~ "Age < 18") |>
  hv_consort_exclude(label = "Analyzed", col = "excl_eligible",
                      !echo ~ "Missing echocardiogram")
fig <- hv_consort(tracker)
if (FALSE) plot(fig) # \dontrun{}
```
