# Numbers-at-risk table panel

Renders a numbers-at-risk table as a bare ggplot2 panel, ready to stack
under a survival curve with
[`hv_atrisk_compose`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_atrisk_compose.md).

## Usage

``` r
hv_atrisk(
  x,
  time = NULL,
  status = NULL,
  group = NULL,
  report_times = NULL,
  size = NULL,
  strata_labels = NULL,
  ...
)
```

## Arguments

- x:

  One of: an `hv_data` object that carries `$tables$risk` (e.g. from
  [`hv_survival`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_survival.md));
  a precomputed risk data frame with `strata`, `report_time` (or
  `time`), and `n.risk` (or `n`) columns; or a subject-level data frame
  supplied together with the `time` (and optional `status`/`group`)
  column names, from which counts are computed.

- time, status, group:

  Column names in `x` when `x` is a subject-level data frame. `time`
  triggers the raw-data path; `status` is reserved and currently unused;
  `group` splits the table into strata. Pass `group` as a factor to
  control the stratum row order (its levels set the order); a character
  column orders rows alphabetically. Default `NULL`.

- report_times:

  Numeric time points for the columns. `NULL` (default) uses the table's
  own points, or – on the raw-data path – an even spread derived from
  the observed time range. On the object and precomputed-table paths a
  non-`NULL` value *selects* which of the table's existing times to
  show; the counts are not recomputed, and any requested time not in the
  table is ignored with a warning. To use arbitrary times for a
  Kaplan-Meier object, rebuild it with
  `hv_survival(..., report_times = )` or pass the subject-level data.

- size:

  Text size for the counts. Default `NULL` (3.5).

- strata_labels:

  Optional named character vector remapping stratum row labels. Default
  `NULL`.

- ...:

  Ignored; present for S3 consistency.

## Value

A bare [`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object: one text label per stratum and report time, strata as y rows
(first stratum on top), time on a continuous x with axis text blanked
(the curve carries the axis).

## See also

Worked recipe with rendered output:
<https://ehrlinger.github.io/hvti_graphics/survival.html>.

[`hv_atrisk_compose`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_atrisk_compose.md),
[`hv_survival`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_survival.md)

## Examples

``` r
km <- hv_survival(sample_survival_data(n = 200, seed = 1))
hv_atrisk(km)

```
