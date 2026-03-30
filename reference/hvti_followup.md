# Prepare goodness-of-follow-up data for plotting

Validates dates, builds per-patient follow-up frames, and returns an
`hvti_followup` object containing the data for both the death panel
(`type = "followup"`) and, optionally, the event panel
(`type = "event"`). Call
[`plot.hvti_followup`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hvti_followup.md)
on the result to obtain a bare `ggplot2` object.

## Usage

``` r
hvti_followup(
  data,
  iv_opyrs_col = "iv_opyrs",
  death_col = "dead",
  death_time_col = "iv_dead",
  event_col = NULL,
  event_time_col = NULL,
  death_for_event_col = NULL,
  origin_year = 1990,
  study_start = as.Date("1990-01-01"),
  study_end = as.Date("2019-12-31"),
  close_date = as.Date("2021-08-06"),
  tolower_names = TRUE,
  death_levels = c("Alive", "Dead"),
  event_levels = c("No event", "Non-fatal event", "Death"),
  segment_drop = 0.2
)
```

## Arguments

- data:

  A data frame with one row per patient. See
  [`sample_goodness_followup_data`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_goodness_followup_data.md).

- iv_opyrs_col:

  Name of the operation-year column. Default `"iv_opyrs"`.

- death_col:

  Name of the binary death-indicator column. Default `"dead"`.

- death_time_col:

  Name of the time-to-death column. Default `"iv_dead"`.

- event_col:

  Name of the non-fatal event indicator column. Required to compute the
  event panel (`type = "event"`). Default `NULL` (event panel
  unavailable).

- event_time_col:

  Name of the time-to-event column. Required when `event_col` is
  supplied. Default `NULL`.

- death_for_event_col:

  Name of the death column to use specifically in the event panel
  (defaults to `death_col` when `NULL`).

- origin_year:

  Integer; calendar year used as the y-axis origin. Default `1990`.

- study_start:

  Start of study period. Default `as.Date("1990-01-01")`.

- study_end:

  End of study enrolment. Default `as.Date("2019-12-31")`.

- close_date:

  Data close date. Must be \\\geq\\ `study_end`. Default
  `as.Date("2021-08-06")`.

- tolower_names:

  Logical; whether to lower-case column names when materialising the
  data. Default `TRUE`.

- death_levels:

  Length-2 character vector labelling the two death states (alive
  first). Default `c("Alive", "Dead")`.

- event_levels:

  Length-3 character vector for the event panel (event-free, non-fatal
  event, death). Default `c("No event", "Non-fatal event", "Death")`.

- segment_drop:

  Numeric; vertical offset (years) for the segment endpoint below the
  follow-up point. Default `0.2`.

## Value

An object of class `c("hvti_followup", "hvti_data")`:

- `$data`:

  Per-patient data frame for the death panel.

- `$meta`:

  Column names, date parameters, state levels, `has_event` flag.

- `$tables`:

  Named list with `diagonal` (the study-period reference diagonal) and,
  when event columns are supplied, `event_data`.

## See also

[`plot.hvti_followup`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hvti_followup.md),
[`sample_goodness_followup_data`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_goodness_followup_data.md)

## Examples

``` r
dta <- sample_goodness_followup_data()

# Death panel only
gf <- hvti_followup(dta)
plot(gf) +
  ggplot2::scale_color_manual(
    values = c("Alive" = "steelblue", "Dead" = "firebrick"),
    name = NULL
  ) +
  ggplot2::labs(x = "Operation Date", y = "Follow-up (years)") +
  hvti_theme("manuscript")


# With event panel
gf2 <- hvti_followup(dta, event_col = "ev_event", event_time_col = "iv_event")
plot(gf2, type = "event") +
  ggplot2::scale_color_manual(
    values = c("No event" = "blue", "Non-fatal event" = "green3",
               "Death" = "red"),
    name = NULL
  ) +
  ggplot2::scale_shape_manual(values = c(1, 2, 4), name = NULL) +
  ggplot2::labs(x = "Operation Date", y = "Follow-up (years)") +
  hvti_theme("manuscript")

```
