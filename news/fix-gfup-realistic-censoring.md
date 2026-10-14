* `sample_goodness_followup_data()` now simulates loss to follow-up
  (`loss_rate`, default `0.03` per year), so the goodness-of-follow-up plot
  it feeds looks like real data: lost patients are censored before
  `close_date` and fall below the diagonal. Until now every survivor sat
  exactly on the diagonal, the pattern of follow-up computed to the close
  date rather than to last contact. `loss_rate = 0` gives the old complete
  follow-up. The same seed now returns different `iv_dead`, `dead`,
  `iv_event`, `ev_event` and `deads` values.

* The goodness-of-follow-up passages in the vignettes no longer describe
  points above the diagonal as passive surveillance. `close_date` is the
  date the dataset was frozen, so follow-up past it is a data error, and
  they now say so.
