# hvtiPlotR 2.0.0 — Production Testing Checklist

Test each plot function with production data before the full 2.0.0
release. Mark each item complete once the output has been visually
verified and any issues resolved.

## Plot functions

| Status | Constructor / Function                                                                                  | Notes                                                                                                                                                 |
|--------|---------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------|
| \[ \]  | [`hv_mirror_hist()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_mirror_hist.md)                 | formerly `mirror_histogram()`                                                                                                                         |
| \[ \]  | [`hv_stacked()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_stacked.md)                         | formerly `stacked_histogram()`                                                                                                                        |
| \[ \]  | [`hv_followup()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_followup.md)                       | formerly `goodness_followup()` + `goodness_event_plot()`                                                                                              |
| \[ \]  | [`hv_balance()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_balance.md)                         | formerly `covariate_balance()`                                                                                                                        |
| \[ \]  | [`hv_survival()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_survival.md)                       | formerly `survival_curve()`                                                                                                                           |
| \[ \]  | [`hv_nonparametric()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_nonparametric.md)             | formerly `nonparametric_curve_plot()`                                                                                                                 |
| \[ \]  | [`hv_ordinal()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ordinal.md)                         | formerly `nonparametric_ordinal_plot()`                                                                                                               |
| \[ \]  | [`hv_eda()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_eda.md)                                 | formerly `eda_plot()`                                                                                                                                 |
| \[ \]  | [`hv_spaghetti()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_spaghetti.md)                     | formerly `spaghetti_plot()`                                                                                                                           |
| \[ \]  | [`hv_trends()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_trends.md)                           | formerly `trends_plot()`                                                                                                                              |
| \[ \]  | [`hv_longitudinal()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_longitudinal.md)               | formerly `longitudinal_counts_plot()` + `longitudinal_counts_table()`                                                                                 |
| \[ \]  | [`hv_alluvial()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_alluvial.md)                       | formerly `alluvial_plot()`                                                                                                                            |
| \[ \]  | [`hv_sankey()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_sankey.md)                           | formerly `cluster_sankey_plot()`; requires `ggsankey` (GitHub)                                                                                        |
| \[ \]  | [`hv_upset()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_upset.md)                             | formerly `upset_plot()`                                                                                                                               |
| \[x\]  | [`hv_hazard()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_hazard.md)                           | parametric survival; replaces [`hazard_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/hazard_plot.md); tp.hp.dead.\* family                 |
| \[x\]  | [`hv_survival_difference()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_survival_difference.md) | treatment benefit vs. reference; replaces [`survival_difference_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/survival_difference_plot.md) |
| \[x\]  | [`hv_nnt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_nnt.md)                                 | number needed to treat; replaces [`nnt_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/nnt_plot.md)                                          |
