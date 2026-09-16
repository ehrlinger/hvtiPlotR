# Parametric survival estimates

A dataset containing parametric competing-risk survival estimates used
for examples in the package vignettes. It was originally produced by a
Weibull parametric survival model fitted to an aortic-valve surgery
cohort and exported from SAS via `tp.hp.dead.sas`.

## Format

A data frame with 2001 rows (fine time grid) and 41 columns:

- years:

  Follow-up time in years.

- months:

  Follow-up time in months (`years` \* 12).

- time:

  Follow-up time in years (same as `years`; retained for SAS
  compatibility).

- lag_time:

  Lagged follow-up time (equals `time` for standard output).

- dt:

  Time increment between consecutive time points.

- sedeath:

  Parametric survival estimate: freedom from death (percent).

- sldeath:

  Lower 95 % confidence limit for `sedeath`.

- sudeath:

  Upper 95 % confidence limit for `sedeath`.

- hedeath:

  Instantaneous hazard rate estimate for death.

- hldeath:

  Lower 95 % confidence limit for `hedeath`.

- hudeath:

  Upper 95 % confidence limit for `hedeath`.

- vedeath:

  Variance of the death survival estimate.

- nodeath:

  Cumulative probability of death by time t (percent).

- cldeath:

  Lower 95 % confidence limit for `nodeath`.

- cudeath:

  Upper 95 % confidence limit for `nodeath`.

- no1death:

  Identical to `nodeath` in this extract.

- tx1death:

  Cumulative hazard integral for death (Weibull model internal).

- txdeath:

  Cumulative hazard for death (same scale as `tx1death`).

- sestrk:

  Parametric survival estimate: freedom from stroke (percent).

- slstrk:

  Lower 95 % confidence limit for `sestrk`.

- sustrk:

  Upper 95 % confidence limit for `sestrk`.

- hestrk:

  Instantaneous hazard rate estimate for stroke.

- hlstrk:

  Lower 95 % confidence limit for `hestrk`.

- hustrk:

  Upper 95 % confidence limit for `hestrk`.

- vestrk:

  Variance of the stroke survival estimate.

- nostrk:

  Cumulative probability of stroke by time t (percent).

- clstrk:

  Lower 95 % confidence limit for `nostrk`.

- custrk:

  Upper 95 % confidence limit for `nostrk`.

- no1strk:

  Identical to `nostrk` in this extract.

- tx1strk:

  Cumulative hazard integral for stroke (Weibull model internal).

- txstrk:

  Cumulative hazard for stroke (same scale as `tx1strk`).

- cestrk:

  Percent free of stroke, `100 - nostrk`.

- noinit:

  Percent event-free (still in the initial state).

- clinit:

  Lower 95 % confidence limit for `noinit`.

- cuinit:

  Upper 95 % confidence limit for `noinit`.

- no1init:

  Identical to `noinit` in this extract.

- z:

  Log-hazard estimate for the pooled Weibull model.

- sez:

  Standard error of `z`.

- cllz:

  Lower 95 % confidence limit for `z` (log-hazard scale).

- cluz:

  Upper 95 % confidence limit for `z` (log-hazard scale).

- check:

  Row sum of `noinit`, `nodeath` and `nostrk`; about 100.

## Details

The three states tracked are competing risks; at every time point the
percentages in the three states sum to 100 (see `check`):

- init:

  Event-free (still in the initial state)

- death:

  Death

- strk:

  Stroke

Each outcome suffix maps to: `se*` = survival estimate; `sl*/su*` =
lower / upper 95 % CI on the survival estimate; `he*` = hazard rate
estimate; `hl*/hu*` = lower / upper 95 % CI on the hazard; `ve*` =
variance of the survival estimate; `no*` = cumulative incidence
(percent); `cl*/cu*` = lower / upper 95 % CI on the cumulative
incidence; `no1*` = identical to `no*` in this extract; `tx*/tx1*` =
cumulative hazard integral (Weibull model output, used internally).

## See also

[nonparametric](https://ehrlinger.github.io/hvtiPlotR/reference/nonparametric.md),
[`hv_hazard()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_hazard.md)
