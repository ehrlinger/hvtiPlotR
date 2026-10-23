# Prepare goodness-of-follow-up data for plotting

Validates dates, builds per-patient follow-up frames, and returns an
`hv_followup` object containing the data for both the death panel
(`type = "followup"`) and, optionally, the event panel
(`type = "event"`). Call
[`plot.hv_followup`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_followup.md)
on the result to obtain a bare `ggplot2` object.

## Usage

``` r
hv_followup(
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
  segment_drop = 0,
  echo = NULL,
  echo_time_col = NULL,
  echo_opyrs_col = NULL
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

  Name of the non-fatal event indicator column, or a vector of names for
  competing non-fatal events drawn in one panel. Required to compute the
  event panel (`type = "event"`). Default `NULL` (event panel
  unavailable). The flag alone does not decide the state: each event
  time is compared against `death_time_col`, and a flagged event is only
  counted as non-fatal when it strictly precedes death. Ties go to
  death. Among the events that qualify, the earliest sets the state, and
  a tie between two goes to the one listed first.

- event_time_col:

  Name of the time-to-event column, or a vector the same length as
  `event_col`, one interval per event. Required when `event_col` is
  supplied. Default `NULL`. A patient is drawn at the winning event's
  interval; with no qualifying event, at the first event's interval.

- death_for_event_col:

  Name of the death column to use specifically in the event panel
  (defaults to `death_col` when `NULL`).

- origin_year:

  Integer; calendar year used as the y-axis origin. Default `1990`.

- study_start:

  Start of study period. Default `as.Date("1990-01-01")`.

- study_end:

  End of study enrollment. Default `as.Date("2019-12-31")`.

- close_date:

  Data close date. Must be \\\geq\\ `study_end`. Default
  `as.Date("2021-08-06")`.

- tolower_names:

  Logical; if TRUE, column names are lower-cased when materialising the
  data. Default `TRUE`.

- death_levels:

  Length-2 character vector labeling the two death states (alive first).
  Default `c("Alive", "Dead")`.

- event_levels:

  Character vector of distinct labels for the event panel: event-free,
  one per non-fatal event in the order of `event_col`, then death. Its
  length is the number of events plus two. Default
  `c("No event", "Non-fatal event", "Death")`.

- segment_drop:

  Numeric; vertical offset (years) for the segment endpoint below the
  follow-up point. Default `0` (no segment drawn). Set to a positive
  value to restore the legacy stem below each point.

- echo:

  Optional data frame with one row per echo, for the echo layer. Each
  row carries the operation interval (`echo_opyrs_col`) and the echo
  interval (`echo_time_col`), so no patient identifier is needed; a
  cohort column carried onto each joined echo row is enough. Default
  `NULL`: with `echo_time_col` set, the echo is read from `data`
  instead, one per patient.

- echo_time_col:

  Name of the echo interval column, in years since the operation.
  Default `NULL`, which draws no echo layer. With `echo = NULL` it names
  a column of `data`, the shape a join reduced to one echo per patient
  delivers.

- echo_opyrs_col:

  Name of the operation interval column in `echo`. Default `NULL`,
  meaning `iv_opyrs_col`.

## Value

An object of class `c("hv_followup", "hv_data")`:

- `$data`:

  Per-patient data frame for the death panel.

- `$meta`:

  Column names, date parameters, state levels, `has_event` flag, and the
  cohort counts `n_patients` (analyzed), `n_input`, and `n_excluded`.

- `$tables`:

  Named list with `diagonal` (the study-period reference diagonal),
  `event_data` when event columns are supplied, and `echo_data`
  (`operation_year`, `follow_up`) when `echo_time_col` is.

## Echo layer

The echo layer marks when each echo happened along a patient's
follow-up: a tick at the operation year (x) and the echo interval (y),
drawn on both panels. It has two sources. One echo per patient is a
column of `data`; a missing value there means no echo was recorded, so
the patient gets no tick, is still drawn in the panel, and nothing is
warned. `$meta$n_echo` and `$meta$n_no_echo` count the two. Every echo
is a separate `echo` data frame; a row missing either column is an
incomplete record, excluded with a warning and counted in
`$meta$n_echo_excluded`.

## Missing data

Patients with a missing value in any required column are excluded, with
a warning naming the columns responsible. `$meta$n_patients` reports the
*analyzed* cohort, alongside `$meta$n_input` and `$meta$n_excluded`, so
the reported N always describes the plotted points.

The event panel requires more columns than the death panel, so the two
can have different cohorts: a patient with a complete death record but a
missing event time appears in one panel and not the other. Each panel is
therefore filtered and warned about separately, and the event panel's
counts are reported as `$meta$n_event_patients` and
`$meta$n_event_excluded`.

## See also

Worked recipe with rendered output:
<https://ehrlinger.github.io/hvtiGraphics/balance.html>.

[`plot.hv_followup`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_followup.md),
[`sample_goodness_followup_data`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_goodness_followup_data.md)

## Examples

``` r
dta <- sample_goodness_followup_data()

# 1. Build data object
gf <- hv_followup(dta)
gf  # prints follow-up summary
#> <hv_followup>
#>   N patients  : 300
#>   Study period: 1990-01-01 – 2019-12-31 (close: 2021-08-06)
#>   Death col   : dead / iv_dead
#>   Panels      : followup

# 2. Bare plot -- undecorated ggplot returned by plot.hv_followup
p <- plot(gf)

# 3. Decorate: color palette, axis labels, theme
p +
  ggplot2::scale_color_manual(
    values = c("Alive" = "steelblue", "Dead" = "firebrick"),
    name = NULL
  ) +
  ggplot2::labs(x = "Operation Date", y = "Follow-up (years)") +
  theme_hv_poster()


# With event panel -- same 3-step pattern
gf2 <- hv_followup(dta, event_col = "ev_event", event_time_col = "iv_event")
plot(gf2, type = "event") +
  ggplot2::scale_color_manual(
    values = c("No event" = "blue", "Non-fatal event" = "green3",
               "Death" = "red"),
    name = NULL
  ) +
  ggplot2::scale_shape_manual(values = c(1, 2, 4), name = NULL) +
  ggplot2::labs(x = "Operation Date", y = "Follow-up (years)") +
  theme_hv_poster()


# Two competing non-fatal events in one panel: the first to happen wins
dta$ev_stroke <- !dta$ev_event & seq_len(nrow(dta)) %% 4 == 0
gf3 <- hv_followup(dta, event_col = c("ev_event", "ev_stroke"),
                   event_time_col = c("iv_event", "iv_event"),
                   event_levels = c("No event", "Reoperation", "Stroke", "Death"))
table(gf3$tables$event_data$state)
#> 
#>    No event Reoperation      Stroke       Death 
#>          76         119          31          74 
plot(gf3, type = "event")


# Echo layer, one echo per patient: a column of the patient data
dta$iv_echo <- dta$iv_dead * 0.6
plot(hv_followup(dta, echo_time_col = "iv_echo"))


# Echo layer, every echo: one row per echo, placed by the operation interval
echoes <- data.frame(iv_opyrs = rep(dta$iv_opyrs[1:40], each = 3),
                     iv_echo  = rep(dta$iv_dead[1:40], each = 3) * c(0.1, 0.5, 0.9))
plot(hv_followup(dta, echo = echoes, echo_time_col = "iv_echo"))

```
