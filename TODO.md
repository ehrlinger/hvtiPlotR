# hvtiPlotR 2.0.0 — Production Testing Checklist

Test each plot function with production data before the full 2.0.0
release. Mark each item complete once the output has been visually
verified and any issues resolved.

## Plot functions

| Status | Function                                                                                                        | Notes                                |
|--------|-----------------------------------------------------------------------------------------------------------------|--------------------------------------|
| \[ \]  | [`mirror_histogram()`](https://ehrlinger.github.io/hvtiPlotR/reference/mirror_histogram.md)                     |                                      |
| \[ \]  | [`stacked_histogram()`](https://ehrlinger.github.io/hvtiPlotR/reference/stacked_histogram.md)                   |                                      |
| \[ \]  | [`goodness_followup()`](https://ehrlinger.github.io/hvtiPlotR/reference/goodness_followup.md)                   |                                      |
| \[ \]  | [`goodness_event_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/goodness_event_plot.md)               |                                      |
| \[ \]  | [`covariate_balance()`](https://ehrlinger.github.io/hvtiPlotR/reference/covariate_balance.md)                   |                                      |
| \[ \]  | [`survival_curve()`](https://ehrlinger.github.io/hvtiPlotR/reference/survival_curve.md)                         |                                      |
| \[ \]  | [`nonparametric_curve_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/nonparametric_curve_plot.md)     |                                      |
| \[ \]  | [`nonparametric_ordinal_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/nonparametric_ordinal_plot.md) |                                      |
| \[ \]  | [`eda_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/eda_plot.md)                                     |                                      |
| \[ \]  | [`spaghetti_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/spaghetti_plot.md)                         |                                      |
| \[ \]  | [`trends_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/trends_plot.md)                               |                                      |
| \[ \]  | [`longitudinal_counts_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/longitudinal_counts_plot.md)     |                                      |
| \[ \]  | [`alluvial_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/alluvial_plot.md)                           | formerly `sankey_plot()`             |
| \[ \]  | [`cluster_sankey_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/cluster_sankey_plot.md)               | requires `ggsankey` (GitHub)         |
| \[ \]  | [`upset_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/upset_plot.md)                                 |                                      |
| \[ \]  | [`hazard_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/hazard_plot.md)                               | parametric survival; tp.hs.\* family |
| \[ \]  | [`survival_difference_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/survival_difference_plot.md)     | treatment benefit vs. reference      |
| \[ \]  | [`nnt_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/nnt_plot.md)                                     | number needed to treat               |
