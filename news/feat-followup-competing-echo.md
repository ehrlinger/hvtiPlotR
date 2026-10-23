* `hv_followup()` draws competing non-fatal events in one event panel.
  `event_col` and `event_time_col` take vectors, one element per event, and
  `event_levels` takes one label per event between "No event" and "Death".
  The earliest event that strictly precedes death sets the state. A tie
  between two non-fatal events goes to the one listed first, and a tie with
  death still goes to death. A single event draws exactly as before.
* `hv_followup()` gains an echo layer, a gray tick at each echo's interval
  along the patient's follow-up, on both panels. `echo_time_col` alone reads
  one echo per patient from `data`. A missing value there means no echo, not
  an incomplete record, and is counted in `meta$n_no_echo` without a warning.
  `echo`, a data frame with one row per echo, draws every echo instead, and
  incomplete rows are excluded with a warning. `plot.hv_followup()` gains
  `echo`, `echo_shape`, `echo_size` and `echo_color`.
* `hv_followup_panels()` passes both through: an `events` entry accepts
  vector `event`, `time` and `label`, and `echo`, `echo_time_col` and
  `echo_opyrs_col` reach every panel.
