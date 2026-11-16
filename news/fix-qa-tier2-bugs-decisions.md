* `hv_survival()`'s `$tables$report` no longer carries the last estimate past the end of follow-up. A report time beyond a stratum's last observed time now gives `NA` for `surv`, `lower`, `upper` and `n.event`, and `n.risk` is taken from `$tables$risk`, so the two tables agree at every report time. Before, `n.risk` was the count at the last event at or before the report time, one or more too high.

* `hv_survival()`'s `life` and `proplife` keep the SAS `%kaplan` formula `Δt(3S − S_prev)/2` for SAS parity, and the documentation now says what it is. It was described as a trapezoid; it is not. It falls short of the exact step-function area `Δt·S_prev` by `1.5·Δt·(S_prev − S)` at each event, so it understates the restricted mean survival time. `hvtiRpropensity::ps_rmst()` computes the exact RMST. Flagged for a later look in [#258](https://github.com/ehrlinger/hvtiPlotR/issues/258).

* `hv_survival()`'s documentation now says that `cumhaz` is the Nelson-Aalen estimate under either `method`, not `-log S(t)`, and that `log_cumhaz` is built on it. The `"nelson-aalen"` method's "log" interval is on the survival scale, a plain Wald interval on `H(t)`.

* `hv_mirror_hist()`'s `effective_n_by_group` is now Kish's effective sample size, `(Σw)²/Σw²`, the one meaning effective N has across the hvtiR family. It was the plain weight total, which moves to a new `sum_weights` element.

* `hv_correlation_matrix()` defaults to `method = "spearman"`, matching `hvtiRtables::hv_correlation_table()` and the SAS exemplar. Pass `method = "pearson"` for the old coefficient.

* `hv_consort_exclude()` no longer passes through a patient whose value for an exclusion criterion is missing. When no rule matches outright, the patient is excluded as `"Criterion missing: <reason>"` for the first rule it could not be checked against, a separate line in the diagram's side box and a new `n_missing` column in `hv_consort_summary()`.

* `hv_consort_start()` refuses a `patient_id` column with a repeated or missing value.

* Study-specific defaults are deprecated, and from 2.9.0 each argument is required. `hv_followup()`'s `origin_year`, `study_start`, `study_end` and `close_date`, and `hv_mirror_hist()`'s `group_col` (`"tavr"`) and `group_labels` (`"SAVR"`, `"TF-TAVR"`), still fall back to the old values for now, with a warning once per session.

* `make_footnote()` and `makeFootnote()` lose the `getwd()` default for the footnote text, which stamped a filesystem path on the figure. Omitting the text now draws only the prefix and timestamp, with a once-per-session warning, and from 2.9.0 it is an error.

* Supplying only one of `lower_col` and `upper_col` (or `emp_lower_col` and `emp_upper_col`) is now an error in `hv_hazard()`, `hv_survival_difference()`, `hv_nnt()`, `hv_nonparametric()`, `hazard_plot()`, `survival_difference_plot()` and `nnt_plot()`. The band used to vanish without a word.

* `save_manuscript()`'s `draft_file` keeps the deliverable's `scale` and `bg`. A draft in the file's own format takes `device` and every `...` argument; a draft in another format takes the device-independent ones.

* `hv_atrisk()`, `hv_rmst_contrast()` and `hv_rmst_curves()` no longer swallow arguments they do not use: a misspelled argument is now R's "unused argument" error.

* `hv_panel_box(mode)` is deprecated. It never had an effect, and it is removed in 2.9.0.

* `hv_mirror_hist()`'s dropped-rows message names `hv_mirror_hist()`, not the old `mirror_histogram`.

* The deprecated theme aliases name the release that removes them, 2.9.0. `hazard_plot()`, `survival_difference_plot()` and `nnt_plot()` say they are superseded, not deprecated, with no removal scheduled.

* Deprecation warnings carry the class `hvtiPlotR_deprecated`.
