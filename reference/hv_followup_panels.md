# Prepare a set of goodness-of-follow-up panels

Checks a set of death and event panels against the data, works out the
study window they share, and prepares one
[`hv_followup()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_followup.md)
object per panel. Call
[`plot.hv_followup_panels()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_followup_panels.md)
on the result for the figures.

## Usage

``` r
hv_followup_panels(
  data,
  opyrs_col = "iv_opyrs",
  origin_year,
  panels,
  events = list(),
  close_date = NULL
)
```

## Arguments

- data:

  Data frame; one row per patient.

- opyrs_col:

  Name of the years-since-origin interval to the operation. Default
  `"iv_opyrs"`.

- origin_year:

  The calendar year `opyrs_col` counts from, a whole number.

- panels:

  Named list of death panels. Each entry is a list with `status`, the
  1/0 death indicator, `time`, its follow-up in years, and optionally
  `title`.

- events:

  Named list of non-fatal event panels, possibly empty. Each entry is a
  list with `event` and `time`, the event's indicator and interval,
  `death` and `death_time`, the death it competes with, and optionally
  `label`. A flagged event counts only when it strictly precedes death.

- close_date:

  `NULL` to estimate, or one date (a `Date` or a string
  [`as.Date()`](https://rdrr.io/r/base/as.Date.html) reads), on or after
  the last operation.

## Value

An object of class `c("hv_followup_panels", "hv_data")`:

- `$data`:

  One row per panel, in order, death panels first: `panel`, `type`
  (`"followup"` or `"event"`), `title`, `n_drawn` and `n_excluded`.

- `$meta`:

  Named list: `opyrs_col`, `origin_year`, `study_start`, `study_end`,
  `first_operation`, `close_date`, `close_source`, `n_obs` and
  `n_opyrs_missing`.

- `$tables`:

  `panels`, a named list of
  [`hv_followup()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_followup.md)
  objects.

## Details

**The study window starts on 1 January of `origin_year`**, because
[`hv_followup()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_followup.md)
draws its potential-follow-up diagonal from `origin_year` whatever
`study_start` is. It ends at the latest operation in the data.

**The close date** is `close_date` when given. When `NULL` it is
estimated as the latest operation plus follow-up in the data: the date
follow-up is known to reach, which is not necessarily the date it was
closed. `meta$close_source` says which, so a report can too.

Every check runs before any panel is built. Every column named anywhere
is checked at once, and the error lists all that are missing. A panel
name is also its figure's name, so a name used twice, within `panels` or
across `panels` and `events`, is an error. The origin is checked for
plausibility: an operation before the origin, or operation years outside
1900 to next year, is the wrong-origin mistake, which otherwise slides
every point along the x-axis without any other symptom.

## See also

[`plot.hv_followup_panels()`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_followup_panels.md),
[`hv_followup()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_followup.md)

## Examples

``` r
dta <- sample_goodness_followup_data()
fp <- hv_followup_panels(
  dta, origin_year = 1990,
  panels = list(all = list(status = "dead", time = "iv_dead", title = "All deaths")),
  events = list(ev = list(event = "ev_event", time = "iv_event", death = "deads",
                          death_time = "iv_dead", label = "Non-fatal event"))
)
fp
#> <hv_followup_panels>
#>   Panels      : all, ev
#>   Operations  : 1990-01-02 to 2019-10-02 (origin 1990)
#>   Close date  : 2021-08-06 (estimated: the latest operation plus follow-up in the data)
#>   N obs       : 300
fp$meta$close_source
#> [1] "estimated: the latest operation plus follow-up in the data"
```
