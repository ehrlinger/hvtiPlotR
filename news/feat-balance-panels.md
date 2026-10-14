* `hv_balance()` now takes a `cobalt::bal.tab()` result (built with
  `binary = "std"` and `continuous = "std"`), a multi-category `bal.tab`
  (one facet row per pairwise comparison), an hvtiRpropensity `ps_match()`
  or `ps_weight()` object, or a list of any one of those, one per
  imputation, averaged: SMD and KS take the arithmetic mean, the variance
  ratio the geometric mean. It multiplies SMDs by 100 itself. When a
  `bal.tab` was built with `un = FALSE` (cobalt's default with weights),
  only the adjusted group is drawn and a message says to re-run with
  `un = TRUE` (#219).
* `hv_balance(stats = c("smd", "variance_ratio", "ks"))` draws variance-ratio
  and KS panels beside the SMD panel, so distributional imbalance that exact
  mean balance hides is visible. Data frames select panels with `stat_col`
  and facet by comparison with `pair_col` (#219).
* New `hv_balance_height()` suggests a figure height for the number of
  covariate rows; `hv_balance()` stores it in `$meta$suggested_height` (#219).
