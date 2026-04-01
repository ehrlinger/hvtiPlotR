# hvtiPlotR: Publication-Quality Graphics for Clinical Manuscripts

`hvtiPlotR` is an R port of the `plot.sas` macro suite used by the
Clinical Investigations Statistics group within the Heart & Vascular
Institute at the Cleveland Clinic. It produces publication-quality
graphics that conform to HVI manuscript and presentation standards using
`ggplot2` and the `officer` package.

All plot functions follow a two-step workflow: call the constructor
(`hvti_*()`) to validate and prepare data, then call
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) on the result
to obtain a bare
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object that you can decorate with additional `ggplot2` layers, scales,
and themes without restriction. Each constructor ships with a
`sample_*()` companion that generates realistic synthetic data for
examples and tests.

### Themes

Use
[`hvti_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md)
as the single entry point. Lower-level functions are also exported for
direct use.

- [`hvti_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md):
  Unified dispatcher — accepts `"manuscript"`, `"poster"`,
  `"light_ppt"`, or `"dark_ppt"`.

- [`hvti_theme_manuscript()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_manuscript.md)
  /
  [`theme_manuscript()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_manuscript.md)
  /
  [`theme_man()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_manuscript.md):
  Clean white-background theme for journal figures.

- [`hvti_theme_dark_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_dark_ppt.md)
  /
  [`theme_dark_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_dark_ppt.md)
  /
  [`theme_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_dark_ppt.md)
  /
  [`hvti_theme_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_dark_ppt.md):
  Large-font theme with a dark panel for PowerPoint slides.

- [`hvti_theme_light_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_light_ppt.md)
  /
  [`theme_light_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_light_ppt.md):
  Large-font theme with a light panel background for PowerPoint slides.

- [`hvti_theme_poster()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_poster.md)
  /
  [`theme_poster()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_poster.md):
  Medium-font theme for conference posters.

### Saving figures

- [`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md):
  Insert one or more ggplot objects into a PowerPoint file as editable
  DrawingML vector graphics via `officer` and `rvg`.

- [`make_footnote()`](https://ehrlinger.github.io/hvtiPlotR/reference/make_footnote.md)
  /
  [`makeFootnote()`](https://ehrlinger.github.io/hvtiPlotR/reference/make_footnote.md):
  Add a draft footnote to a figure during analysis; omit for
  publication-ready output.

### Plot constructors

Each constructor returns an `hvti_data` S3 object; call
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) on it to
produce a ggplot.

#### Propensity Score & Matching

- [`hvti_mirror_hist()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_mirror_hist.md):
  Prepare propensity-score distributions for a mirrored histogram
  comparing binary-matched or IPTW-weighted cohorts. Ports the
  `tp.lp.mirror-histogram_*` and `tp.lp.mirror_histo_before_after_wt`
  SAS scripts.

- [`hvti_balance()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_balance.md):
  Prepare standardised mean difference data for a covariate balance
  dot-plot before and after propensity-score matching or weighting.
  Ports `tp.lp.propen.cov_balance.R`.

- [`hvti_stacked()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_stacked.md):
  Prepare grouped count or proportion data for a stacked or filled
  histogram.

#### Survival & Hazard

- [`hvti_survival()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_survival.md):
  Fit and prepare Kaplan-Meier or Nelson-Aalen survival curves, risk
  tables, and report tables. Ports the SAS `%kaplan` and `%nelsont`
  macros from `tp.ac.dead.sas`.

- [`hvti_hazard()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_hazard.md):
  Prepare parametric hazard/survival curves from pre-fitted model
  output, with optional KM empirical overlay and population life-table
  reference. Ports the `tp.hp.*` template family.

- [`hvti_survival_difference()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_survival_difference.md):
  Prepare mean survival difference (life gained) over time between two
  treatment arms, with confidence ribbons. Ports
  `tp.hp.dead.life-gained.sas`.

- [`hvti_nnt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_nnt.md):
  Prepare number-needed-to-treat over time derived from the survival
  difference. Ports `tp.hp.numtreat.survdiff.matched.sas`.

#### Nonparametric Temporal Curves

- [`hvti_nonparametric()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_nonparametric.md):
  Prepare pre-computed two-phase nonparametric temporal trend curves for
  binary or continuous outcomes with optional 68%/95% CI ribbon and
  binned data summary points. Ports the `tp.np.*` template family.

- [`hvti_ordinal()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_ordinal.md):
  Prepare grade-specific probability curves from cumulative
  proportional-odds models (e.g. TR/AR grade). Ports `tp.np.tr.ivecho.*`
  and `tp.np.po_ar.u_multi.ordinal.sas`.

#### Study Design & Goodness of Follow-Up

- [`hvti_followup()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_followup.md):
  Prepare per-patient follow-up data for a goodness-of-follow-up scatter
  plot (actual vs. potential follow-up per operation year). Use
  `plot(x, type = "followup")` for the death panel and
  `plot(x, type = "event")` for the non-fatal event panel. Ports
  `tp.dp.gfup.R`.

#### Longitudinal & Repeated Measures

- [`hvti_trends()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_trends.md):
  Prepare patient-level data for annual trend lines with optional
  confidence ribbons for multiple groups. Ports the `tp.lp.trends.*`,
  `tp.rp.trends.*`, and `tp.dp.trends.R` families.

- [`hvti_spaghetti()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_spaghetti.md):
  Prepare repeated-measures data for individual patient trajectory
  plots, optionally stratified by group. Ports `tp.dp.spaghetti.echo.R`.

- [`hvti_longitudinal()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_longitudinal.md):
  Prepare pre-aggregated counts for a grouped bar chart or text table of
  patient and measurement counts at discrete follow-up windows. Use
  `plot(x, type = "plot")` for the bar chart and
  `plot(x, type = "table")` for the numeric table panel.

#### Flow Diagrams

- [`hvti_alluvial()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_alluvial.md):
  Prepare patient-flow data for an alluvial (Sankey) diagram showing
  transitions between states across time points. Ports
  `tp.dp.female_bicus_preAR_sankey.R`.

- [`hvti_sankey()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_sankey.md):
  Prepare cluster-assignment data for a stability Sankey showing how
  patients redistribute across K values in a PAM analysis.

#### Exploratory Data Analysis

- [`hvti_eda()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_eda.md):
  Prepare a single variable for EDA plotting: bar chart (categorical) or
  scatter + LOESS (continuous). Ports
  `tp.dp.EDA_barplots_scatterplots.R`.

- [`eda_classify_var()`](https://ehrlinger.github.io/hvtiPlotR/reference/eda_classify_var.md):
  Classify a vector as `"Cont"`, `"Cat_Num"`, or `"Cat_Char"` using the
  `UniqueLimit` heuristic from `Barplot_Scatterplot_Function.R`.

- [`eda_select_vars()`](https://ehrlinger.github.io/hvtiPlotR/reference/eda_select_vars.md):
  Subset and reorder a data frame by a character vector or
  space-separated column-name string. Replaces `Order_Variables()`.

- [`hvti_upset()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_upset.md):
  Prepare binary indicator data for an UpSet intersection plot. Ports
  `tp.complexUpset.R`.

### Sample-data generators

Each generator produces realistic synthetic data sized and structured to
match the corresponding SAS dataset exports.

- [`sample_mirror_histogram_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_mirror_histogram_data.md):
  Propensity scores via a logistic model with greedy 1:1 caliper
  matching and optional IPTW weights.

- [`sample_covariate_balance_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_covariate_balance_data.md):
  Standardised mean differences before and after propensity matching.

- [`sample_stacked_histogram_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_stacked_histogram_data.md):
  Year-by-category count data.

- [`sample_survival_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_survival_data.md):
  Exponential survival times with administrative censoring and optional
  treatment strata.

- [`sample_hazard_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_hazard_data.md):
  Weibull parametric survival predictions on a fine time grid, matching
  the `predict` dataset from `%hazpred`.

- [`sample_hazard_empirical()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_hazard_empirical.md):
  Binned Kaplan-Meier empirical points matching the `plout` / `acpdms`
  dataset.

- [`sample_life_table()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_life_table.md):
  Age-group-specific Gompertz survivorship curves matching US population
  life-table SAS overlays.

- [`sample_survival_difference_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_survival_difference_data.md):
  Mean survival difference between two parametric arms with confidence
  bands.

- [`sample_nnt_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_nnt_data.md):
  Number-needed-to-treat derived from survival difference data.

- [`sample_nonparametric_curve_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_nonparametric_curve_data.md):
  Two-phase nonparametric curve predictions (binary or continuous
  outcome) on a fine time grid.

- [`sample_nonparametric_curve_points()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_nonparametric_curve_points.md):
  Binned patient-level data summary points matching the SAS `means`
  dataset.

- [`sample_nonparametric_ordinal_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_nonparametric_ordinal_data.md):
  Grade-specific cumulative proportional-odds probability curves.

- [`sample_nonparametric_ordinal_points()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_nonparametric_ordinal_points.md):
  Binned ordinal data summary points per grade level.

- [`sample_goodness_followup_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_goodness_followup_data.md):
  Operative cohort with operation dates, follow-up times, death, and
  non-fatal events.

- [`sample_trends_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_trends_data.md):
  Multi-group annual trend data with confidence ribbons.

- [`sample_spaghetti_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_spaghetti_data.md):
  Patient-level longitudinal measurements over time.

- [`sample_longitudinal_counts_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_longitudinal_counts_data.md):
  Pre-aggregated patient and measurement counts at discrete follow-up
  windows.

- [`sample_alluvial_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_alluvial_data.md):
  Patient flow between states across multiple time points in wide
  format.

- [`sample_cluster_sankey_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_cluster_sankey_data.md):
  Cluster assignments across K values for a PAM stability analysis.

- [`sample_eda_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_eda_data.md):
  Mixed-type cardiac-surgery registry simulation (binary, ordinal,
  character-categorical, and continuous variables).

- [`sample_upset_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_upset_data.md):
  Binary indicator columns for UpSet intersection analysis.

## References

Wickham, H. *ggplot2: Elegant Graphics for Data Analysis*. Springer,
2009.

Gohel, D. *officer: Manipulation of Microsoft Word and PowerPoint
Documents*. R package. <https://davidgohel.github.io/officer/>
