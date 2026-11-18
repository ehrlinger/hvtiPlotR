* `hv_survival()`: `km$data$life`, and the `plot(km, type = "life")` curve
  drawn from it, is now the exact area under the Kaplan-Meier step curve, the
  restricted mean survival time, matching `hvtiRpropensity::ps_rmst()` and
  `summary.survfit()`'s `rmean`. It used the SAS `%kaplan` formula
  `Δt·(3·S(t) − S(t_prev))/2`, and applied it on censored rows as well as
  event rows, so it matched neither SAS nor the exact area. `life` and
  `proplife` are now larger than before wherever an event has occurred
  (#258).
