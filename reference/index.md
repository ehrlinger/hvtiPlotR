# Package index

## Package Overview

Package-level documentation and the base S3 class shared by all
hvtiPlotR data objects.

- [`hvtiPlotR-package`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-package.md)
  [`hvtiPlotR`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-package.md)
  : hvtiPlotR: Publication-Quality Graphics for Clinical Manuscripts
- [`is_hv_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/is_hv_data.md)
  : Test whether an object is an hvtiPlotR data object

## Themes

Apply publication-quality themes to any ggplot2 object. Use
[`hv_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme.md)
as the single entry point; the lower-level `hv_theme_*()` functions are
also exported for direct use.

- [`hv_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme.md)
  : hvtiPlotR Theme Generic
- [`hv_theme_manuscript()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme_manuscript.md)
  [`theme_manuscript()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme_manuscript.md)
  [`theme_man()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme_manuscript.md)
  : Theme for Manuscript Figures
- [`hv_theme_dark_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme_dark_ppt.md)
  [`theme_dark_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme_dark_ppt.md)
  [`theme_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme_dark_ppt.md)
  [`hv_theme_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme_dark_ppt.md)
  : Dark PowerPoint Theme (default PPT theme)
- [`hv_theme_light_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme_light_ppt.md)
  [`theme_light_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme_light_ppt.md)
  : Light PowerPoint Theme
- [`hv_theme_poster()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme_poster.md)
  [`theme_poster()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_theme_poster.md)
  : Theme for Poster Figures

## Survival & Hazard

Kaplan-Meier survival curves, parametric hazard plots, survival
differences, and number-needed-to-treat. Use
[`hv_survival()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_survival.md)
for non-parametric KM estimates;
[`hv_hazard()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_hazard.md),
[`hv_survival_difference()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_survival_difference.md),
and
[`hv_nnt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_nnt.md)
for pre-fitted parametric model output.

- [`hv_survival()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_survival.md)
  : Prepare survival data for plotting
- [`plot(`*`<hv_survival>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_survival.md)
  : Plot an hv_survival object
- [`print(`*`<hv_survival>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hv_survival.md)
  : Print an hv_survival object
- [`hv_hazard()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_hazard.md)
  : Prepare parametric hazard / survival data for plotting
- [`plot(`*`<hv_hazard>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_hazard.md)
  : Plot an hv_hazard object
- [`print(`*`<hv_hazard>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hv_hazard.md)
  : Print an hv_hazard object
- [`hv_survival_difference()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_survival_difference.md)
  : Prepare survival difference (life-gained) data for plotting
- [`plot(`*`<hv_survival_difference>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_survival_difference.md)
  : Plot an hv_survival_difference object
- [`print(`*`<hv_survival_difference>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hv_survival_difference.md)
  : Print an hv_survival_difference object
- [`hv_nnt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_nnt.md)
  : Prepare number-needed-to-treat data for plotting
- [`plot(`*`<hv_nnt>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_nnt.md)
  : Plot an hv_nnt object
- [`print(`*`<hv_nnt>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hv_nnt.md)
  : Print an hv_nnt object
- [`sample_survival_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_survival_data.md)
  : Generate Sample Survival Data
- [`sample_hazard_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_hazard_data.md)
  : Sample Parametric Hazard Model Predictions
- [`sample_hazard_empirical()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_hazard_empirical.md)
  : Sample Kaplan-Meier Empirical Points for Hazard Plot Overlay
- [`sample_life_table()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_life_table.md)
  : Sample Population Life Table Data
- [`sample_survival_difference_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_survival_difference_data.md)
  : Sample Survival Difference (Life-Gained) Data
- [`sample_nnt_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_nnt_data.md)
  : Sample Number Needed to Treat Data
- [`nonparametric`](https://ehrlinger.github.io/hvtiPlotR/reference/nonparametric.md)
  : Nonparametric survival estimates
- [`parametric`](https://ehrlinger.github.io/hvtiPlotR/reference/parametric.md)
  : Parametric survival estimates

## Nonparametric Temporal Curves

Average temporal curves and ordinal outcome trajectories from
decomposition models (`tp.np.*` template family).

- [`hv_nonparametric()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_nonparametric.md)
  : Prepare nonparametric temporal trend curve data for plotting
- [`plot(`*`<hv_nonparametric>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_nonparametric.md)
  : Plot an hv_nonparametric object
- [`print(`*`<hv_nonparametric>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hv_nonparametric.md)
  : Print an hv_nonparametric object
- [`hv_ordinal()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ordinal.md)
  : Prepare nonparametric ordinal outcome curve data for plotting
- [`plot(`*`<hv_ordinal>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_ordinal.md)
  : Plot an hv_ordinal object
- [`print(`*`<hv_ordinal>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hv_ordinal.md)
  : Print an hv_ordinal object
- [`sample_nonparametric_curve_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_nonparametric_curve_data.md)
  : Sample Nonparametric Curve Data
- [`sample_nonparametric_curve_points()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_nonparametric_curve_points.md)
  : Sample Nonparametric Curve Data Points
- [`sample_nonparametric_ordinal_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_nonparametric_ordinal_data.md)
  : Sample Nonparametric Ordinal Curve Data
- [`sample_nonparametric_ordinal_points()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_nonparametric_ordinal_points.md)
  : Sample Nonparametric Ordinal Data Points

## Propensity Score & Matching

Visualise propensity score distributions and covariate balance before
and after propensity matching or IPTW weighting.

- [`hv_mirror_hist()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_mirror_hist.md)
  : Prepare mirror-histogram data for plotting
- [`plot(`*`<hv_mirror_hist>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_mirror_hist.md)
  : Plot an hv_mirror_hist object
- [`print(`*`<hv_mirror_hist>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hv_mirror_hist.md)
  : Print an hv_mirror_hist object
- [`hv_balance()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_balance.md)
  : Prepare covariate balance data for plotting
- [`plot(`*`<hv_balance>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_balance.md)
  : Plot an hv_balance object
- [`print(`*`<hv_balance>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hv_balance.md)
  : Print an hv_balance object
- [`sample_mirror_histogram_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_mirror_histogram_data.md)
  : Generate Sample Data for Mirrored Histogram
- [`sample_covariate_balance_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_covariate_balance_data.md)
  : Generate Sample Covariate Balance Data

## Temporal Trends & Longitudinal

Annual trend lines, individual patient trajectories, and longitudinal
count summaries. Ports `tp.lp.trends.*`, `tp.rp.trends.*`,
`tp.dp.trends.R`, and `tp.dp.spaghetti.echo.R`.

- [`hv_trends()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_trends.md)
  : Prepare temporal trend data for plotting
- [`plot(`*`<hv_trends>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_trends.md)
  : Plot an hv_trends object
- [`print(`*`<hv_trends>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hv_trends.md)
  : Print an hv_trends object
- [`hv_spaghetti()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_spaghetti.md)
  : Prepare spaghetti / profile data for plotting
- [`plot(`*`<hv_spaghetti>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_spaghetti.md)
  : Plot an hv_spaghetti object
- [`print(`*`<hv_spaghetti>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hv_spaghetti.md)
  : Print an hv_spaghetti object
- [`hv_longitudinal()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_longitudinal.md)
  : Prepare longitudinal participation counts data for plotting
- [`plot(`*`<hv_longitudinal>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_longitudinal.md)
  : Plot an hv_longitudinal object
- [`print(`*`<hv_longitudinal>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hv_longitudinal.md)
  : Print an hv_longitudinal object
- [`sample_trends_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_trends_data.md)
  : Sample Temporal Trend Data
- [`sample_spaghetti_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_spaghetti_data.md)
  : Sample Spaghetti / Profile Plot Data
- [`sample_longitudinal_counts_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_longitudinal_counts_data.md)
  : Sample Longitudinal Counts Data

## Study Design & Goodness of Follow-Up

Visualise follow-up completeness. Ports `tp.dp.gfup.R`.

- [`hv_followup()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_followup.md)
  : Prepare goodness-of-follow-up data for plotting
- [`plot(`*`<hv_followup>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_followup.md)
  : Plot an hv_followup object
- [`print(`*`<hv_followup>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hv_followup.md)
  : Print an hv_followup object
- [`sample_goodness_followup_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_goodness_followup_data.md)
  : Generate Sample Goodness-of-Follow-Up Data

## Stacked Histogram

Stacked or filled histogram of a numeric variable by group.

- [`hv_stacked()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_stacked.md)
  : Prepare stacked histogram data for plotting
- [`plot(`*`<hv_stacked>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_stacked.md)
  : Plot an hv_stacked object
- [`print(`*`<hv_stacked>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hv_stacked.md)
  : Print an hv_stacked object
- [`sample_stacked_histogram_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_stacked_histogram_data.md)
  : Generate Sample Data for Stacked Histogram

## Flow Diagrams

Alluvial (Sankey) plots showing patient flow between states or cluster
assignments across K values.

- [`hv_alluvial()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_alluvial.md)
  : Prepare alluvial / Sankey diagram data for plotting
- [`plot(`*`<hv_alluvial>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_alluvial.md)
  : Plot an hv_alluvial object
- [`print(`*`<hv_alluvial>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hv_alluvial.md)
  : Print an hv_alluvial object
- [`hv_sankey()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_sankey.md)
  : Prepare cluster stability Sankey data for plotting
- [`plot(`*`<hv_sankey>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_sankey.md)
  : Plot an hv_sankey object
- [`print(`*`<hv_sankey>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hv_sankey.md)
  : Print an hv_sankey object
- [`sample_alluvial_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_alluvial_data.md)
  : Sample Sankey / Alluvial Data
- [`sample_cluster_sankey_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_cluster_sankey_data.md)
  : Sample Cluster Stability Sankey Data

## Exploratory Data Analysis

Rapid bar charts and scatter plots for variable screening, univariate
summaries, and set-membership visualisation.

- [`hv_eda()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_eda.md)
  : Prepare EDA data for a single variable
- [`plot(`*`<hv_eda>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_eda.md)
  : Plot an hv_eda object
- [`print(`*`<hv_eda>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hv_eda.md)
  : Print an hv_eda object
- [`hv_upset()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_upset.md)
  : Prepare UpSet co-occurrence data for plotting
- [`plot(`*`<hv_upset>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hv_upset.md)
  : Plot an hv_upset object
- [`print(`*`<hv_upset>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hv_upset.md)
  : Print an hv_upset object
- [`eda_classify_var()`](https://ehrlinger.github.io/hvtiPlotR/reference/eda_classify_var.md)
  : Classify a Variable as Continuous or Categorical
- [`eda_select_vars()`](https://ehrlinger.github.io/hvtiPlotR/reference/eda_select_vars.md)
  : Select and Reorder Variables from a Data Frame
- [`sample_eda_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_eda_data.md)
  : Sample EDA Data
- [`sample_upset_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_upset_data.md)
  : Sample Procedure Co-occurrence Data

## Saving & Utilities

Save figures to PowerPoint or PDF. Add draft footnotes during analysis;
omit them for publication-ready output.

- [`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md)
  : Save ggplot Objects to an Editable PowerPoint Presentation

- [`hv_ggsave_dims()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ggsave_dims.md)
  :

  Compute
  [`ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html)
  dimensions for a fixed panel content area

- [`make_footnote()`](https://ehrlinger.github.io/hvtiPlotR/reference/make_footnote.md)
  [`makeFootnote()`](https://ehrlinger.github.io/hvtiPlotR/reference/make_footnote.md)
  : Add a Draft Footnote to a Figure
