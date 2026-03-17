# Build goodness-of-follow-up plots

Converts raw follow-up extracts (either in-memory data frames or SAS
transport files) into tidy frames, then draws the classic HVI goodness
of follow-up visualizations. The function always produces a death panel
(`death_plot`). When `event_col` is supplied it additionally produces a
non-fatal event panel (`event_plot`) that encodes a three-level outcome
state: no event / non-fatal event / death before event.

## Usage

``` r
goodness_followup(
  data,
  iv_opyrs_col = "iv_opyrs",
  death_col = "dead",
  death_time_col = "iv_dead",
  origin_year = 1990,
  study_start = as.Date("1990-01-01"),
  study_end = as.Date("2019-12-31"),
  close_date = as.Date("2021-08-06"),
  tolower_names = TRUE,
  death_levels = c("Alive", "Dead"),
  event_col = NULL,
  event_time_col = NULL,
  death_for_event_col = NULL,
  event_levels = c("No event", "Non-fatal event", "Death"),
  alpha = 0.8,
  segment_drop = 0.2,
  diagonal_color = "orange",
  diagonal_linetype = "dashed",
  diagonal_linewidth = 0.6
)
```

## Arguments

- data:

  Data frame or path to a SAS transport (`.xpt`) file containing the
  follow-up data.

- iv_opyrs_col:

  Column name holding the numeric interval (in years) from `origin_year`
  to the operation date.

- death_col:

  Logical (or coercible) indicator for death. Used for the death panel
  and, by default, for the death component of the event panel.

- death_time_col:

  Column containing follow-up time to death (or censoring) expressed in
  years.

- origin_year:

  Reference calendar year that matches zero in `iv_opyrs_col`.

- study_start, study_end, close_date:

  Dates that define the diagonal potential follow-up line.

- tolower_names:

  When `TRUE`, column names are converted to lower case prior to
  processing.

- death_levels:

  Length-2 character vector naming the "alive" and "dead" states for the
  death panel. Default `c("Alive", "Dead")`.

- event_col:

  Column name for the non-fatal event indicator (logical or 0/1). When
  `NULL` (default) the event panel is skipped.

- event_time_col:

  Column containing follow-up time to the non-fatal event or censoring,
  expressed in years. Required when `event_col` is supplied.

- death_for_event_col:

  Death indicator column used to classify deaths within the event panel.
  Defaults to `death_col` when `NULL`. Supplying a separate column (e.g.
  `"deads"` for systematic/active follow-up) allows the two panels to
  use different death ascertainment strategies.

- event_levels:

  Length-3 character vector naming the three outcome states in the event
  panel: no event / non-fatal event / death before event. Default
  `c("No event", "Non-fatal event", "Death")`.

- alpha:

  Transparency passed to the point and segment layers.

- segment_drop:

  Amount (in years) subtracted from each follow-up value to draw the
  short vertical tick beneath each point.

- diagonal_color:

  Color of the potential follow-up reference line. Default `"orange"`.

- diagonal_linetype:

  Line type of the reference line. Default `"dashed"`.

- diagonal_linewidth:

  Line width of the reference line. Default `0.6`.

## Value

A list containing:

- `death_plot`: ggplot object — death follow-up panel.

- `death_data`: transformed data frame used in `death_plot`.

- `event_plot`: ggplot object — non-fatal event panel, or `NULL` when
  `event_col` is not supplied.

- `event_data`: transformed data frame used in `event_plot`, or `NULL`.

- `diagonal`: reference line data frame shared by both panels.

## Details

The function focuses on preparing the data, mapping states to
aesthetics, and drawing the scaffolding geoms; callers are expected to
finish the styling via standard `ggplot2` modifiers (`scale_*()`,
[`labs()`](https://ggplot2.tidyverse.org/reference/labs.html),
`theme_*()`), keeping the plotting workflow flexible.

**Death panel** — each patient is plotted at their operation date (x)
and follow-up time (y). A binary `state` factor (alive / dead) drives
colour and shape.

**Event panel** — same scaffold, but `state` is a three-level factor:

1.  `event_levels[1]` — alive and event-free at censoring.

2.  `event_levels[2]` — non-fatal event occurred first.

3.  `event_levels[3]` — died before the non-fatal event.

The coding mirrors the `ev_evnt` variable constructed in the legacy
`tp.dp.gfup.R` template.

## Examples

``` r
dta <- sample_goodness_followup_data()

# Death panel only
result <- goodness_followup(dta, alpha = 0.8)
result$death_plot +
  ggplot2::scale_color_manual(
    values = c("Alive" = "blue", "Dead" = "red"), name = NULL
  ) +
  ggplot2::scale_shape_manual(values = c(1, 4), name = NULL) +
  ggplot2::labs(x = "Operation Date", y = "Follow-up (years)")


# Death panel + non-fatal event panel
result2 <- goodness_followup(
  dta,
  event_col           = "ev_event",
  event_time_col      = "iv_event",
  death_for_event_col = "deads",
  event_levels        = c("No event", "Relapse", "Death"),
  alpha               = 0.8
)
result2$event_plot +
  ggplot2::scale_color_manual(
    values = c("No event" = "blue", "Relapse" = "green3", "Death" = "red"),
    name   = NULL
  ) +
  ggplot2::scale_shape_manual(values = c(1, 2, 4), name = NULL) +
  ggplot2::labs(x = "Operation Date", y = "Follow-up (years)")

```
