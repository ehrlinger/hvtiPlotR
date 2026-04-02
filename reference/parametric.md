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

  Probability of entering the death state at exactly time t.

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

  Probability of entering the stroke state at exactly time t.

- tx1strk:

  Cumulative hazard integral for stroke (Weibull model internal).

- txstrk:

  Cumulative hazard for stroke (same scale as `tx1strk`).

- cestrk:

  Complement: probability of surviving stroke-free to time t (percent).

- noinit:

  Parametric estimate of freedom from re-operation (percent).

- clinit:

  Lower 95 % confidence limit for `noinit`.

- cuinit:

  Upper 95 % confidence limit for `noinit`.

- no1init:

  Probability of entering the re-operated state at exactly time t.

- z:

  Log-hazard estimate for the pooled Weibull model.

- sez:

  Standard error of `z`.

- cllz:

  Lower 95 % confidence limit for `z` (log-hazard scale).

- cluz:

  Upper 95 % confidence limit for `z` (log-hazard scale).

- check:

  Row sum of `noinit`, `nodeath`, `nostrk`, and `cestrk`; should equal
  100.

## Details

The three outcomes tracked are:

- init:

  Re-operation (re-initialisation)

- death:

  Death

- strk:

  Stroke

Each outcome suffix maps to: `se*` = survival estimate; `sl*/su*` =
lower / upper 95 % CI on the survival estimate; `he*` = hazard rate
estimate; `hl*/hu*` = lower / upper 95 % CI on the hazard; `ve*` =
variance of the survival estimate; `no*` = cumulative incidence
(percent); `cl*/cu*` = lower / upper 95 % CI on the cumulative
incidence; `no1*` = probability of entering the state at exactly time t;
`tx*/tx1*` = cumulative hazard integral (Weibull model output, used
internally).

## See also

[nonparametric](https://ehrlinger.github.io/hvtiPlotR/reference/nonparametric.md),
[`hv_hazard()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_hazard.md)
