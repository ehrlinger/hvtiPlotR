* `plot.hv_survival()` gains `curve = c("step", "line")`. `"line"` joins the
  events with straight lines, as the SAS `%kaplan` figures do, on the
  `"survival"`, `"cumhaz"` and `"loglog"` plots: it draws time zero, each event
  and each stratum's last row, and skips the censored rows between, so a
  censoring time puts no corner in the line. The CI ribbon follows the same
  rows. The default, `"step"`, draws exactly as before.
