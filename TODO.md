# hvtiPlotR 2.0.0 — Production Testing Checklist

Test each plot function with production data before the full 2.0.0 release.
Mark each item complete once the output has been visually verified and any
issues resolved.

## Plot functions

| Status | Constructor / Function | Notes |
|--------|----------------------|-------|
| [ ] | `hv_mirror_hist()` | formerly `mirror_histogram()` |
| [ ] | `hv_stacked()` | formerly `stacked_histogram()` |
| [ ] | `hv_followup()` | formerly `goodness_followup()` + `goodness_event_plot()` |
| [ ] | `hv_balance()` | formerly `covariate_balance()` |
| [ ] | `hv_survival()` | formerly `survival_curve()` |
| [ ] | `hv_nonparametric()` | formerly `nonparametric_curve_plot()` |
| [ ] | `hv_ordinal()` | formerly `nonparametric_ordinal_plot()` |
| [ ] | `hv_eda()` | formerly `eda_plot()` |
| [ ] | `hv_spaghetti()` | formerly `spaghetti_plot()` |
| [ ] | `hv_trends()` | formerly `trends_plot()` |
| [ ] | `hv_longitudinal()` | formerly `longitudinal_counts_plot()` + `longitudinal_counts_table()` |
| [ ] | `hv_alluvial()` | formerly `alluvial_plot()` |
| [ ] | `hv_sankey()` | formerly `cluster_sankey_plot()`; requires `ggsankey` (GitHub) |
| [ ] | `hv_upset()` | formerly `upset_plot()` |
| [x] | `hv_hazard()` | parametric survival; replaces `hazard_plot()`; tp.hp.dead.* family |
| [x] | `hv_survival_difference()` | treatment benefit vs. reference; replaces `survival_difference_plot()` |
| [x] | `hv_nnt()` | number needed to treat; replaces `nnt_plot()` |
