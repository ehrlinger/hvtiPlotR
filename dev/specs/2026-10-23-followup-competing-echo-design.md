# hv_followup(): N competing non-fatal events and an echo layer (design)

Branch: `feat/followup-competing-echo`. Delivered as **one PR**.
Consumer: the dc-gfup template in hvtiRtemplates, which draws through `hv_followup_panels()`.

## Problem

The goodness-of-follow-up event panel takes exactly one non-fatal event, so a study with several
(reoperation, endocarditis, stroke) needs one panel per event and can't show which came first.
There's also no way to show echo ascertainment: when each echo happened along a patient's follow-up.

## Facts verified before design (2026-10-23)

- `gf_build_event_frame()` sets the state by comparing the event time against the death time.
  The event counts only when it strictly precedes death, so ties go to death. y is the event
  interval for every state.
- `hv_followup()` requires `length(event_levels) == 3`. `hv_followup_panels()` builds
  `event_levels = c("No event", label, "Death")` and refuses a label equal to either end.
- The template reads with `read_job_data(..., one_row_per_patient = TRUE)`, so a JOIN of
  `bdecho_day` arrives reduced to one echo per patient. An every-echo layer needs a second read
  without REDUCE. That read is template work. `JOIN_VARS` carries cohort columns, including
  `iv_opyrs`, onto every joined row, so the echo frame can be placed without an identifier.
- The labels for a two-level non-fatal panel are template-only, so this PR doesn't touch them.

## Decisions

| question | decision |
|---|---|
| N events, API | `event_col` and `event_time_col` accept equal-length vectors (N >= 1). `event_levels` has length N + 2: no event, the N events in order, death. |
| Tie between two non-fatal events | **First listed wins.** Death still wins any tie with a non-fatal event, as today. |
| y for a patient with no qualifying event | The first event's interval, which is what N = 1 does today. |
| Echo layer shape | **Two sources, one layer.** (a) **One echo per patient**: `echo_time_col` names a column in `data` itself, which is what the template's JOIN + REDUCE already delivers. (b) **Every echo**: `echo` is a separate long data frame, one row per echo, carrying the operation interval and the echo interval. Neither source uses or needs an identifier. |
| Echo columns | `echo_time_col = NULL` (no layer, the default, so existing calls are unchanged). With `echo = NULL` the column is read from `data`. With `echo` given, it's read from `echo`, placed by `echo_opyrs_col`, which defaults to `iv_opyrs_col`. |
| Echo missing data | One echo per patient: a missing echo time means no echo recorded, not an incomplete record, so that patient gets no tick, with no warning. Patients with an echo are counted in `meta$n_echo` and patients without one in `meta$n_no_echo`. They are still drawn in the panel. Every echo: rows missing either column are excluded with a warning (`.exclude_incomplete()`), counted in `meta$n_echo` / `meta$n_echo_excluded`. |
| Echo storage | `$tables$echo_data`: `operation_year`, `follow_up`. Drawn on both panel types. |
| Echo drawing | `plot.hv_followup()` gains `echo = TRUE` (set it to `FALSE` to suppress), `echo_shape = 95` (a short horizontal tick), `echo_size = 4` and `echo_color = "grey40"`. These are fixed geoms, set the way `diagonal_*` already are, so they stay out of the color scale and the legend. |
| API surface | **Both.** `hv_followup_panels()` events entries accept vector `event` / `time` / `label` (scalar `death` / `death_time`); a top-level `echo`, `echo_time_col` and `echo_opyrs_col` apply to every panel. |
| Validation | Vectors of unequal length, a label repeated or equal to `"No event"` / `"Death"`, and missing echo columns all stop with a message naming the problem. |

Backward compatibility: every existing call (scalar event, length-3 levels, no echo) produces an
identical object and plot. `meta$event_col` becomes a vector when N > 1. No class, element or column
name changes.

## Documentation (in scope)

- Roxygen for `hv_followup()`, `plot.hv_followup()`, `hv_followup_panels()`: the new arguments, the
  first-listed tie rule, the y rule, and the echo frame's shape. Add a competing-events example and
  an echo example.
- `sample_goodness_followup_data()`: a second event (`ev_event2`, `iv_event2`) is **not** added to
  the returned frame, because that would change an exported generator's columns. Examples derive
  one inline. An echo frame comes from a new internal helper used only by the examples and tests,
  or inline in the examples, whichever is shorter.
- `vignettes/plot-functions.qmd`, follow-up section: one subsection on competing events, one on the
  echo layer, each with a rendered figure.
- `news/feat-followup-competing-echo.md` fragment.

## Tests (data-carrying, `helper-plot-data.R`)

- N = 1 regression: the object and the layers are unchanged versus `main`.
- N = 2: state assignment table covering event A first, B first, an A/B tie (A wins), an event tied
  with death (death wins), death first, and neither.
- Echo, one per patient: one tick per patient with an echo time. A missing time gives no tick and
  no warning and is counted in `n_no_echo`. The death and event panels keep every patient.
- Echo, every echo: the layer carries one row per complete echo, excluded rows warn and are
  counted, and `echo = FALSE` drops the layer.
- Both sources produce `$tables$echo_data` with the same columns.
- `hv_followup_panels()`: vector entries pass through, validation errors fire, and echo reaches
  every panel.

## Out of scope / follow-ups

- Template: wiring `echo_time_col` to its existing JOIN (one per patient works with no new read);
  a second, unreduced read only for the every-echo option; and colors for more than three event levels in
  `status_colors()` (hvtiRtemplates).
- Flagging echoes recorded after a patient's follow-up ends.
