# Package index

## Package Overview

Package-level documentation and the base S3 class shared by all
hvtiPlotR data objects.

- [`hvtiPlotR-package`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-package.md)
  [`hvtiPlotR`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-package.md)
  : hvtiPlotR: Publication-Quality Graphics for Clinical Manuscripts
- [`is_hvti_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/is_hvti_data.md)
  : Test whether an object is an hvtiPlotR data object

## Themes

Apply publication-quality themes to any ggplot2 object. Use
[`hvti_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md)
as the single entry point; the lower-level `hvti_theme_*()` functions
are also exported for direct use.

- [`hvti_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md)
  : hvtiPlotR Theme Generic
- [`hvti_theme_manuscript()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_manuscript.md)
  [`theme_manuscript()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_manuscript.md)
  [`theme_man()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_manuscript.md)
  : Theme for Manuscript Figures
- [`hvti_theme_dark_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_dark_ppt.md)
  [`theme_dark_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_dark_ppt.md)
  [`theme_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_dark_ppt.md)
  [`hvti_theme_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_dark_ppt.md)
  : Dark PowerPoint Theme (default PPT theme)
- [`hvti_theme_light_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_light_ppt.md)
  [`theme_light_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_light_ppt.md)
  : Light PowerPoint Theme
- [`hvti_theme_poster()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_poster.md)
  [`theme_poster()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_poster.md)
  : Theme for Poster Figures

## Survival & Hazard

Kaplan-Meier survival curves, parametric hazard plots, survival
differences, and number-needed-to-treat. Use
[`hvti_survival()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_survival.md)
for non-parametric KM estimates;
[`hvti_hazard()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_hazard.md),
[`hvti_survival_difference()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_survival_difference.md),
and
[`hvti_nnt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_nnt.md)
for pre-fitted parametric model output.

- [`hvti_survival()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_survival.md)
  : Prepare survival data for plotting
- [`plot(`*`<hvti_survival>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hvti_survival.md)
  : Plot an hvti_survival object
- [`print(`*`<hvti_survival>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hvti_survival.md)
  : Print an hvti_survival object
- [`hvti_hazard()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_hazard.md)
  : Prepare parametric hazard / survival data for plotting
- [`plot(`*`<hvti_hazard>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hvti_hazard.md)
  : Plot an hvti_hazard object
- [`print(`*`<hvti_hazard>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hvti_hazard.md)
  : Print an hvti_hazard object
- [`hvti_survival_difference()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_survival_difference.md)
  : Prepare survival difference (life-gained) data for plotting
- [`plot(`*`<hvti_survival_difference>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hvti_survival_difference.md)
  : Plot an hvti_survival_difference object
- [`print(`*`<hvti_survival_difference>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hvti_survival_difference.md)
  : Print an hvti_survival_difference object
- [`hvti_nnt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_nnt.md)
  : Prepare number-needed-to-treat data for plotting
- [`plot(`*`<hvti_nnt>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hvti_nnt.md)
  : Plot an hvti_nnt object
- [`print(`*`<hvti_nnt>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hvti_nnt.md)
  : Print an hvti_nnt object
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

- [`hvti_nonparametric()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_nonparametric.md)
  : Prepare nonparametric temporal trend curve data for plotting
- [`plot(`*`<hvti_nonparametric>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hvti_nonparametric.md)
  : Plot an hvti_nonparametric object
- [`print(`*`<hvti_nonparametric>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hvti_nonparametric.md)
  : Print an hvti_nonparametric object
- [`hvti_ordinal()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_ordinal.md)
  : Prepare nonparametric ordinal outcome curve data for plotting
- [`plot(`*`<hvti_ordinal>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hvti_ordinal.md)
  : Plot an hvti_ordinal object
- [`print(`*`<hvti_ordinal>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hvti_ordinal.md)
  : Print an hvti_ordinal object
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

- [`hvti_mirror_hist()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_mirror_hist.md)
  : Prepare mirror-histogram data for plotting
- [`plot(`*`<hvti_mirror_hist>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hvti_mirror_hist.md)
  : Plot an hvti_mirror_hist object
- [`print(`*`<hvti_mirror_hist>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hvti_mirror_hist.md)
  : Print an hvti_mirror_hist object
- [`hvti_balance()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_balance.md)
  : Prepare covariate balance data for plotting
- [`plot(`*`<hvti_balance>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hvti_balance.md)
  : Plot an hvti_balance object
- [`print(`*`<hvti_balance>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hvti_balance.md)
  : Print an hvti_balance object
- [`sample_mirror_histogram_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_mirror_histogram_data.md)
  : Generate Sample Data for Mirrored Histogram
- [`sample_covariate_balance_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_covariate_balance_data.md)
  : Generate Sample Covariate Balance Data

## Temporal Trends & Longitudinal

Annual trend lines, individual patient trajectories, and longitudinal
count summaries. Ports `tp.lp.trends.*`, `tp.rp.trends.*`,
`tp.dp.trends.R`, and `tp.dp.spaghetti.echo.R`.

- [`hvti_trends()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_trends.md)
  : Prepare temporal trend data for plotting
- [`plot(`*`<hvti_trends>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hvti_trends.md)
  : Plot an hvti_trends object
- [`print(`*`<hvti_trends>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hvti_trends.md)
  : Print an hvti_trends object
- [`hvti_spaghetti()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_spaghetti.md)
  : Prepare spaghetti / profile data for plotting
- [`plot(`*`<hvti_spaghetti>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hvti_spaghetti.md)
  : Plot an hvti_spaghetti object
- [`print(`*`<hvti_spaghetti>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hvti_spaghetti.md)
  : Print an hvti_spaghetti object
- [`hvti_longitudinal()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_longitudinal.md)
  : Prepare longitudinal participation counts data for plotting
- [`plot(`*`<hvti_longitudinal>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hvti_longitudinal.md)
  : Plot an hvti_longitudinal object
- [`print(`*`<hvti_longitudinal>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hvti_longitudinal.md)
  : Print an hvti_longitudinal object
- [`sample_trends_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_trends_data.md)
  : Sample Temporal Trend Data
- [`sample_spaghetti_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_spaghetti_data.md)
  : Sample Spaghetti / Profile Plot Data
- [`sample_longitudinal_counts_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_longitudinal_counts_data.md)
  : Sample Longitudinal Counts Data

## Study Design & Goodness of Follow-Up

Visualise follow-up completeness. Ports `tp.dp.gfup.R`.

- [`hvti_followup()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_followup.md)
  : Prepare goodness-of-follow-up data for plotting
- [`plot(`*`<hvti_followup>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hvti_followup.md)
  : Plot an hvti_followup object
- [`print(`*`<hvti_followup>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hvti_followup.md)
  : Print an hvti_followup object
- [`sample_goodness_followup_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_goodness_followup_data.md)
  : Generate Sample Goodness-of-Follow-Up Data

## Stacked Histogram

Stacked or filled histogram of a numeric variable by group.

- [`hvti_stacked()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_stacked.md)
  : Prepare stacked histogram data for plotting
- [`plot(`*`<hvti_stacked>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hvti_stacked.md)
  : Plot an hvti_stacked object
- [`print(`*`<hvti_stacked>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hvti_stacked.md)
  : Print an hvti_stacked object
- [`sample_stacked_histogram_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_stacked_histogram_data.md)
  : Generate Sample Data for Stacked Histogram

## Flow Diagrams

Alluvial (Sankey) plots showing patient flow between states or cluster
assignments across K values.

- [`hvti_alluvial()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_alluvial.md)
  : Prepare alluvial / Sankey diagram data for plotting
- [`plot(`*`<hvti_alluvial>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hvti_alluvial.md)
  : Plot an hvti_alluvial object
- [`print(`*`<hvti_alluvial>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hvti_alluvial.md)
  : Print an hvti_alluvial object
- [`hvti_sankey()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_sankey.md)
  : Prepare cluster stability Sankey data for plotting
- [`plot(`*`<hvti_sankey>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hvti_sankey.md)
  : Plot an hvti_sankey object
- [`print(`*`<hvti_sankey>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hvti_sankey.md)
  : Print an hvti_sankey object
- [`sample_alluvial_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_alluvial_data.md)
  : Sample Sankey / Alluvial Data
- [`sample_cluster_sankey_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_cluster_sankey_data.md)
  : Sample Cluster Stability Sankey Data

## Exploratory Data Analysis

Rapid bar charts and scatter plots for variable screening, univariate
summaries, and set-membership visualisation.

- [`hvti_eda()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_eda.md)
  : Prepare EDA data for a single variable
- [`plot(`*`<hvti_eda>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hvti_eda.md)
  : Plot an hvti_eda object
- [`print(`*`<hvti_eda>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hvti_eda.md)
  : Print an hvti_eda object
- [`hvti_upset()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_upset.md)
  : Prepare UpSet co-occurrence data for plotting
- [`plot(`*`<hvti_upset>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/plot.hvti_upset.md)
  : Plot an hvti_upset object
- [`print(`*`<hvti_upset>`*`)`](https://ehrlinger.github.io/hvtiPlotR/reference/print.hvti_upset.md)
  : Print an hvti_upset object
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
- [`make_footnote()`](https://ehrlinger.github.io/hvtiPlotR/reference/make_footnote.md)
  [`makeFootnote()`](https://ehrlinger.github.io/hvtiPlotR/reference/make_footnote.md)
  : Add a Draft Footnote to a Figure
