# hvtiPlotR 2.0.0 — Production Testing Checklist

Test each plot function with production data before the full 2.0.0 release.
Mark each item complete once the output has been visually verified and any
issues resolved.

## Plot functions

| Status | Function | Notes |
|--------|----------|-------|
| [ ] | `mirror_histogram()` | |
| [ ] | `stacked_histogram()` | |
| [ ] | `goodness_followup()` | |
| [ ] | `goodness_event_plot()` | |
| [ ] | `covariate_balance()` | |
| [ ] | `survival_curve()` | |
| [ ] | `nonparametric_curve_plot()` | |
| [ ] | `nonparametric_ordinal_plot()` | |
| [ ] | `eda_plot()` | |
| [ ] | `spaghetti_plot()` | |
| [ ] | `trends_plot()` | |
| [ ] | `longitudinal_counts_plot()` | |
| [ ] | `alluvial_plot()` | formerly `sankey_plot()` |
| [ ] | `cluster_sankey_plot()` | requires `ggsankey` (GitHub) |
| [ ] | `upset_plot()` | |
| [ ] | `hazard_plot()` | parametric survival; tp.hs.* family |
| [ ] | `survival_difference_plot()` | treatment benefit vs. reference |
| [ ] | `nnt_plot()` | number needed to treat |
