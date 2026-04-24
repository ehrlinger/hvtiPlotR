# Production Verification — Plot Functions

Each `hv_*()` plot constructor needs a one-time visual verification against
production data — confirming the rendered figure meets the CORR plotting
standard and matches (or improves on) its `plot.sas` predecessor. This is
manual verification work; it is **not gating any release** and runs
independently of the version cycle.

The authoritative tracker is the GitHub milestone:

→ [Production verification — plot functions](https://github.com/ehrlinger/hvtiPlotR/milestone/1) (label: [`production-verification`](https://github.com/ehrlinger/hvtiPlotR/labels/production-verification))

Each row below links to the corresponding issue. Tick the row here when
the issue is closed so this file mirrors milestone progress at a glance.

## Status

| Status | Constructor | Issue | Formerly |
|--------|-------------|-------|----------|
| [ ] | `hv_mirror_hist()`         | [#46](https://github.com/ehrlinger/hvtiPlotR/issues/46) | `mirror_histogram()` |
| [ ] | `hv_stacked()`             | [#47](https://github.com/ehrlinger/hvtiPlotR/issues/47) | `stacked_histogram()` |
| [ ] | `hv_followup()`            | [#48](https://github.com/ehrlinger/hvtiPlotR/issues/48) | `goodness_followup()` + `goodness_event_plot()` |
| [ ] | `hv_balance()`             | [#49](https://github.com/ehrlinger/hvtiPlotR/issues/49) | `covariate_balance()` |
| [ ] | `hv_survival()`            | [#50](https://github.com/ehrlinger/hvtiPlotR/issues/50) | `survival_curve()` |
| [ ] | `hv_nonparametric()`       | [#51](https://github.com/ehrlinger/hvtiPlotR/issues/51) | `nonparametric_curve_plot()` |
| [ ] | `hv_ordinal()`             | [#52](https://github.com/ehrlinger/hvtiPlotR/issues/52) | `nonparametric_ordinal_plot()` |
| [ ] | `hv_eda()`                 | [#53](https://github.com/ehrlinger/hvtiPlotR/issues/53) | `eda_plot()` |
| [ ] | `hv_spaghetti()`           | [#54](https://github.com/ehrlinger/hvtiPlotR/issues/54) | `spaghetti_plot()` |
| [ ] | `hv_trends()`              | [#55](https://github.com/ehrlinger/hvtiPlotR/issues/55) | `trends_plot()` |
| [ ] | `hv_longitudinal()`        | [#56](https://github.com/ehrlinger/hvtiPlotR/issues/56) | `longitudinal_counts_plot()` + `longitudinal_counts_table()` |
| [ ] | `hv_alluvial()`            | [#57](https://github.com/ehrlinger/hvtiPlotR/issues/57) | `alluvial_plot()` |
| [ ] | `hv_sankey()`              | [#58](https://github.com/ehrlinger/hvtiPlotR/issues/58) | `cluster_sankey_plot()` (requires `ggsankey`) |
| [ ] | `hv_upset()`               | [#59](https://github.com/ehrlinger/hvtiPlotR/issues/59) | `upset_plot()` |
| [x] | `hv_hazard()`              | —      | `hazard_plot()` (`tp.hp.dead.*` family) |
| [x] | `hv_survival_difference()` | —      | `survival_difference_plot()` |
| [x] | `hv_nnt()`                 | —      | `nnt_plot()` |

**Verified:** 3 / 17 &nbsp;·&nbsp; **Open:** 14 / 17

## Per-issue acceptance

Each linked issue carries the same checklist:

1. Construct the plot from a production dataset.
2. `plot()` it with `hv_theme("manuscript")` and `hv_theme("ppt")` (where relevant).
3. Visually compare against the `plot.sas` reference (or v1.x reference if no SAS reference).
4. Note defects in the issue; either fix or open a follow-up bug.
5. Tick the row above and close the issue.
