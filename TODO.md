# hvtiPlotR 2.0.0 — Production Testing Checklist

Test each plot function with production data before the full 2.0.0 release.
Mark each item complete once the output has been visually verified and any
issues resolved.

## Plot functions

| Status | Constructor / Function | Notes |
|--------|----------------------|-------|
| [ ] | `hvti_mirror()` | formerly `mirror_histogram()` |
| [ ] | `hvti_stacked()` | formerly `stacked_histogram()` |
| [ ] | `hvti_followup()` | formerly `goodness_followup()` + `goodness_event_plot()` |
| [ ] | `hvti_balance()` | formerly `covariate_balance()` |
| [ ] | `hvti_survival()` | formerly `survival_curve()` |
| [ ] | `hvti_nonparametric()` | formerly `nonparametric_curve_plot()` |
| [ ] | `hvti_ordinal()` | formerly `nonparametric_ordinal_plot()` |
| [ ] | `hvti_eda()` | formerly `eda_plot()` |
| [ ] | `hvti_spaghetti()` | formerly `spaghetti_plot()` |
| [ ] | `hvti_trends()` | formerly `trends_plot()` |
| [ ] | `hvti_longitudinal()` | formerly `longitudinal_counts_plot()` + `longitudinal_counts_table()` |
| [ ] | `hvti_alluvial()` | formerly `alluvial_plot()` |
| [ ] | `hvti_sankey()` | formerly `cluster_sankey_plot()`; requires `ggsankey` (GitHub) |
| [ ] | `hvti_upset()` | formerly `upset_plot()` |
| [ ] | `hazard_plot()` | parametric survival; tp.hs.* family |
| [ ] | `survival_difference_plot()` | treatment benefit vs. reference |
| [ ] | `nnt_plot()` | number needed to treat |
