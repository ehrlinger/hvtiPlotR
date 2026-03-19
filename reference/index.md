# Package index

## Package Overview

Package-level documentation and overview.

- [`hvtiPlotR-package`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-package.md)
  [`hvtiPlotR`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-package.md)
  : hvtiPlotR: Publication-Quality Graphics for Clinical Manuscripts

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
[`survival_curve()`](https://ehrlinger.github.io/hvtiPlotR/reference/survival_curve.md)
for non-parametric estimates;
[`hazard_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/hazard_plot.md)
for pre-fitted parametric model output.

- [`survival_curve()`](https://ehrlinger.github.io/hvtiPlotR/reference/survival_curve.md)
  : Kaplan-Meier Survival Curve
- [`hazard_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/hazard_plot.md)
  : Parametric Hazard / Survival Plot
- [`survival_difference_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/survival_difference_plot.md)
  : Survival Difference (Life-Gained) Plot
- [`nnt_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/nnt_plot.md)
  : Number Needed to Treat (NNT) Plot
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

- [`nonparametric_curve_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/nonparametric_curve_plot.md)
  : Nonparametric Temporal Trend Curve Plot
- [`nonparametric_ordinal_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/nonparametric_ordinal_plot.md)
  : Nonparametric Ordinal Outcome Curve Plot
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

- [`mirror_histogram()`](https://ehrlinger.github.io/hvtiPlotR/reference/mirror_histogram.md)
  : Plot Mirrored Propensity Score Histogram
- [`covariate_balance()`](https://ehrlinger.github.io/hvtiPlotR/reference/covariate_balance.md)
  : Covariate Balance Plot
- [`sample_mirror_histogram_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_mirror_histogram_data.md)
  : Generate Sample Data for Mirrored Histogram
- [`sample_covariate_balance_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_covariate_balance_data.md)
  : Generate Sample Covariate Balance Data

## Temporal Trends

Annual trend lines with optional confidence ribbons. Ports the
`tp.lp.trends.*`, `tp.rp.trends.*`, and `tp.dp.trends.R` templates.

- [`trends_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/trends_plot.md)
  : Temporal Trend Plot
- [`spaghetti_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/spaghetti_plot.md)
  : Spaghetti / Profile Plot of Repeated Measurements
- [`longitudinal_counts_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/longitudinal_counts_plot.md)
  : Longitudinal Participation Counts Bar Chart
- [`longitudinal_counts_table()`](https://ehrlinger.github.io/hvtiPlotR/reference/longitudinal_counts_table.md)
  : Longitudinal Participation Counts Table Panel
- [`sample_trends_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_trends_data.md)
  : Sample Temporal Trend Data
- [`sample_spaghetti_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_spaghetti_data.md)
  : Sample Spaghetti / Profile Plot Data
- [`sample_longitudinal_counts_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_longitudinal_counts_data.md)
  : Sample Longitudinal Counts Data

## Study Design & Goodness of Follow-Up

Visualise follow-up completeness and goodness-of-fit for event models.
Ports `tp.dp.gfup.R`.

- [`goodness_followup()`](https://ehrlinger.github.io/hvtiPlotR/reference/goodness_followup.md)
  : Build goodness-of-follow-up plots
- [`goodness_event_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/goodness_event_plot.md)
  : Goodness of Follow-Up — Event Panel
- [`sample_goodness_followup_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_goodness_followup_data.md)
  : Generate Sample Goodness-of-Follow-Up Data

## Flow Diagrams

Alluvial (Sankey) plots showing patient flow between states or cluster
assignments across K values.

- [`alluvial_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/alluvial_plot.md)
  : Sankey / Alluvial Plot
- [`cluster_sankey_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/cluster_sankey_plot.md)
  : Cluster Stability Sankey Plot
- [`sample_alluvial_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_alluvial_data.md)
  : Sample Sankey / Alluvial Data
- [`sample_cluster_sankey_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_cluster_sankey_data.md)
  : Sample Cluster Stability Sankey Data

## Exploratory Data Analysis

Rapid bar charts and scatter plots for variable screening and univariate
summaries.

- [`eda_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/eda_plot.md)
  : EDA Barplot / Scatterplot for One Variable
- [`eda_classify_var()`](https://ehrlinger.github.io/hvtiPlotR/reference/eda_classify_var.md)
  : Classify a Variable as Continuous or Categorical
- [`eda_select_vars()`](https://ehrlinger.github.io/hvtiPlotR/reference/eda_select_vars.md)
  : Select and Reorder Variables from a Data Frame
- [`stacked_histogram()`](https://ehrlinger.github.io/hvtiPlotR/reference/stacked_histogram.md)
  : Stacked Histogram
- [`upset_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/upset_plot.md)
  : UpSet Plot for Set Co-occurrence Analysis
- [`sample_eda_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_eda_data.md)
  : Sample EDA Data
- [`sample_stacked_histogram_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_stacked_histogram_data.md)
  : Generate Sample Data for Stacked Histogram
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
