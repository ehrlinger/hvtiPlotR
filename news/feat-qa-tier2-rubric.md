* Argument names follow the hvtiR API rubric. Every old name keeps working, with a warning once per session (class `hvtiPlotR_deprecated`), until 2.9.0. Passing both the old and the new name is an error.
  - Every argument that names a column ends in `_col`. In `hv_atrisk()`, `time`, `status` and `group` become `time_col`, `event_col` and `group_col`. In `hv_rmst_contrast()`, `estimator`, `diff`, `lo` and `hi` become `estimator_col`, `diff_col`, `lo_col` and `hi_col`. In `hv_rmst_curves()`, `facet`, `arm`, `time` and `surv` become `facet_col`, `arm_col`, `time_col` and `surv_col`.
  - The data frame comes first, as `data`. That replaces `curve_data` in `hv_hazard()`, `hazard_plot()`, `hv_nonparametric()` and `hv_ordinal()`; `diff_data` in `hv_survival_difference()` and `survival_difference_plot()`; `nnt_data` in `hv_nnt()` and `nnt_plot()`; `curves` in `hv_rmst_curves()`; and `x` in `hv_atrisk()`.
  - `save_ppt()`'s `powerpoint` becomes `file`.
  - `line_width` becomes `linewidth`, ggplot2's name, in `hazard_plot()`, `survival_difference_plot()`, `nnt_plot()` and the `plot()` methods for `hv_hazard`, `hv_survival_difference`, `hv_nnt`, `hv_nonparametric`, `hv_ordinal` and `hv_spaghetti`.
  - `hv_consort_start()` takes the ID column as a string, `patient_id_col`. An unquoted name, named `patient_id` or passed by position, still works.
  - `plot.hv_sankey()`'s deprecated `alpha` now warns once per session, like the others, instead of printing a message that quiet mode would hide.

* `hv_followup()` puts each time column before its status column, as `survival::Surv(time, event)` does: `death_time_col, death_col`, then `event_time_col, event_col`. A status column must now be logical, 0/1 or `"TRUE"`/`"FALSE"` text, so a positional call written for the old order is an error rather than a silent swap.

* Informational messages go through the family quiet mode: `options(hvti.quiet = TRUE)` silences them. Warnings and errors are unaffected.

* Errors a caller may want to catch carry `hvtiPlotR_<condition>` classes: `hvtiPlotR_missing_column`, `hvtiPlotR_missing_package`, `hvtiPlotR_role_palette_capacity` and `hvtiPlotR_group_palette_capacity`. The palette errors keep their old classes, `hv_role_palette_capacity` and `hv_group_palette_capacity`, until 2.9.0.

* `provenance_footnote()` gains `record`, which reads the hvtiR seven-field provenance record. The record supplies the commit (its `sha`), the producing package's version and the time; it adds the seed when the seed is not `NA`, and prints `"commit unknown"` when the `sha` is `NA`.

* Messages and errors touched here name their function, as `fn(): `.
