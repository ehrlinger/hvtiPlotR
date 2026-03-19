# Goodness of Follow-Up — Event Panel

Produces the event follow-up panel: each patient is plotted at their
operation date (x) and follow-up time (y), with a three-level `state`
factor driving colour and shape: event-free, non-fatal event, or death.
Compose with
[`scale_color_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html),
[`scale_shape_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html),
[`labs()`](https://ggplot2.tidyverse.org/reference/labs.html), and
[`hvti_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md).

## Usage

``` r
goodness_event_plot(
  data,
  event_col,
  event_time_col,
  death_for_event_col = NULL,
  event_levels = c("No event", "Non-fatal event", "Death"),
  iv_opyrs_col = "iv_opyrs",
  death_col = "dead",
  origin_year = 1990,
  study_start = as.Date("1990-01-01"),
  study_end = as.Date("2019-12-31"),
  close_date = as.Date("2021-08-06"),
  tolower_names = TRUE,
  alpha = 0.8,
  segment_drop = 0.2,
  diagonal_color = "orange",
  diagonal_linetype = "dashed",
  diagonal_linewidth = 0.6
)
```

## Arguments

- data:

  Data frame. See
  [`sample_goodness_followup_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_goodness_followup_data.md).

- event_col:

  Name of the non-fatal event indicator column (required, no default).

- event_time_col:

  Name of the time-to-event column (required, no default).

- death_for_event_col:

  Name of the death column to use for the event panel, or `NULL` to use
  the default `death_col`. Default `NULL`.

- event_levels:

  Character vector of exactly three labels: event-free, non-fatal event,
  death. Default `c("No event", "Non-fatal event", "Death")`.

- iv_opyrs_col:

  Column name holding the numeric interval (in years) from `origin_year`
  to the operation date.

- death_col:

  Logical (or coercible) indicator for death. Used for the death panel
  and, by default, for the death component of the event panel.

- origin_year:

  Reference calendar year that matches zero in `iv_opyrs_col`.

- study_start, study_end, close_date:

  Dates that define the diagonal potential follow-up line.

- tolower_names:

  When `TRUE`, column names are converted to lower case prior to
  processing.

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

A
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object (event panel).

## See also

[`goodness_followup()`](https://ehrlinger.github.io/hvtiPlotR/reference/goodness_followup.md),
[`sample_goodness_followup_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_goodness_followup_data.md)

## Examples

``` r
dta <- sample_goodness_followup_data()

goodness_event_plot(
  dta,
  event_col      = "ev_event",
  event_time_col = "iv_event"
) +
  ggplot2::scale_color_manual(
    values = c("No event" = "blue", "Non-fatal event" = "green3",
               "Death" = "red"),
    name = NULL
  ) +
  ggplot2::scale_shape_manual(values = c(1, 2, 4), name = NULL) +
  ggplot2::labs(x = "Operation Date", y = "Follow-up (years)") +
  hvti_theme("manuscript")

```
