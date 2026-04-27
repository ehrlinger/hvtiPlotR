# hvtiPlotR: Publication-Quality Graphics for Clinical Manuscripts and Slides

`hvtiPlotR` is an R port of the `plot.sas` macro suite used by the
Cardiovascular Outcomes, Registries and Research (CORR) statistics group
within the Heart, Vascular and Thoracic Institute at the Cleveland
Clinic. It produces publication-quality graphics that conform to HVTI
manuscript, poster, and presentation standards using `ggplot2` and the
`officer` package.

## Details

### Two-step workflow

Every plot constructor follows the same pattern:

1.  Call `hv_*()` to validate and prepare data — returns an `hv_data` S3
    object that also stores diagnostics (group counts, SMDs, etc.) under
    `$tables`.

2.  Call [`plot()`](https://rdrr.io/r/graphics/plot.default.html) on the
    object to obtain a bare
    [`ggplot2::ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)
    you can decorate with scales, labels, annotations, and themes
    without restriction.

3.  Call [`print()`](https://rdrr.io/r/base/print.html) on the object
    for a concise console summary.

    library(ggplot2)
    library(hvtiPlotR)

    dta <- sample_trends_data(n = 600, seed = 42)
    tr  <- hv_trends(dta)

    plot(tr) +
      scale_colour_brewer(palette = "Set1", name = "Group") +
      labs(x = "Year", y = "Outcome") +
      theme_hv_manuscript()

Every constructor ships with a `sample_*()` companion that generates
realistic synthetic data sized and shaped like the corresponding SAS
dataset export, so examples and unit tests run without PHI.

### Themes

Four `theme_hv_*()` functions follow ggplot2's
[`theme_bw()`](https://ggplot2.tidyverse.org/reference/ggtheme.html)
contract: pass `base_size` / `base_family` to control typography, then
forward any extra named theme element through `...` (e.g.
`theme_hv_manuscript(legend.position = "right")`) or chain a
`+ theme(...)` call.

- [`theme_hv_manuscript()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md):
  Clean white-background theme for journal figures.

- [`theme_hv_poster()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md):
  Medium-font theme with visible axis lines for conference posters.

- [`theme_hv_ppt_dark()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md):
  Large-font theme with a black panel for blue-gradient or dark
  PowerPoint templates.

- [`theme_hv_ppt_light()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvtiPlotR-themes.md):
  Large-font theme with a transparent panel (appears white on
  white-background PowerPoint templates). Add
  `+ theme(panel.background = element_rect(fill = "white"))` if you
  specifically need an opaque white panel on a non-white slide
  background.

Both PPT themes hide the legend by default, use inside-facing axis
ticks, and scale axis-text / axis-title margins from `base_size` via
ggplot2's `half_line` convention.

### Saving figures

- [`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md):
  Insert one or more ggplot objects into a PowerPoint file as editable
  DrawingML vector graphics via `officer` + `rvg`.

- [`make_footnote()`](https://ehrlinger.github.io/hvtiPlotR/reference/make_footnote.md)
  /
  [`makeFootnote()`](https://ehrlinger.github.io/hvtiPlotR/reference/make_footnote.md):
  Add a draft footnote during analysis; omit for publication-ready
  output.

#### Fixed-panel geometry (v2.0.0)

When plots in a set have different axis-label widths (e.g. y-axis ranges
from "1.0" to "4567.2"), the usual
[`ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html) and
[`officer::ph_location()`](https://davidgohel.github.io/officer/reference/ph_location.html)
calls let the **panel content area** drift — which is visually jarring
on PPT decks where the black or white panel box should appear constant
across slides. Two helpers solve this by making the panel size and slide
position the *target*:

- [`hv_ggsave_dims()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ggsave_dims.md):
  Given a target panel width and height, computes the
  [`ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html)
  `width`/`height` that preserve that panel size. Returns a named list —
  splat into
  [`ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html) via
  `do.call(ggplot2::ggsave, c(list(filename = ..., plot = p), dims))`.

- [`hv_ph_location()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ph_location.md):
  Given a target panel rectangle on the slide, computes the
  [`officer::ph_location()`](https://davidgohel.github.io/officer/reference/ph_location.html)
  `width`/`height`/`left`/`top` that anchor the panel to that rectangle
  regardless of axis-label width. Warns if chrome overflows the left or
  top slide edge.

- [`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md)
  accepts
  `panel_box = list(width = ..., height = ..., left = ..., top = ...)`
  to apply
  [`hv_ph_location()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ph_location.md)
  per slide automatically.

### Plot constructors

#### Propensity Score & Matching

- [`hv_mirror_hist()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_mirror_hist.md):
  Prepare propensity-score distributions for a mirrored histogram
  comparing binary-matched or IPTW-weighted cohorts. Ports the
  `tp.lp.mirror-histogram_*` and `tp.lp.mirror_histo_before_after_wt`
  SAS scripts.

- [`hv_balance()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_balance.md):
  Prepare standardised mean difference data for a covariate balance
  dot-plot before and after propensity-score matching or weighting.
  Ports `tp.lp.propen.cov_balance.R`.

- [`hv_stacked()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_stacked.md):
  Prepare grouped count or proportion data for a stacked or filled
  histogram.

#### Survival & Hazard

- [`hv_survival()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_survival.md):
  Fit and prepare Kaplan-Meier or Nelson-Aalen survival curves, risk
  tables, and report tables. Ports the SAS `%kaplan` and `%nelsont`
  macros from `tp.ac.dead.sas`.

- [`hv_hazard()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_hazard.md):
  Prepare parametric hazard / survival curves from pre-fitted model
  output, with optional KM empirical overlay and population life-table
  reference. Ports the `tp.hp.*` template family.

- [`hv_survival_difference()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_survival_difference.md):
  Prepare mean survival difference (life gained) over time between two
  treatment arms, with confidence ribbons. Ports
  `tp.hp.dead.life-gained.sas`.

- [`hv_nnt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_nnt.md):
  Prepare number-needed-to-treat over time derived from the survival
  difference. Ports `tp.hp.numtreat.survdiff.matched.sas`.

#### Nonparametric Temporal Curves

- [`hv_nonparametric()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_nonparametric.md):
  Prepare pre-computed two-phase nonparametric temporal trend curves for
  binary or continuous outcomes with optional 68%/95% CI ribbon and
  binned data summary points. Ports the `tp.np.*` template family.

- [`hv_ordinal()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_ordinal.md):
  Prepare grade-specific probability curves from cumulative
  proportional-odds models (e.g. TR / AR grade). Ports
  `tp.np.tr.ivecho.*` and `tp.np.po_ar.u_multi.ordinal.sas`.

#### Study Design & Goodness of Follow-Up

- [`hv_followup()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_followup.md):
  Prepare per-patient follow-up data for a goodness-of-follow-up scatter
  plot (actual vs. potential follow-up per operation year). Use
  `plot(x, type = "followup")` for the death panel and
  `plot(x, type = "event")` for the non-fatal event panel. Ports
  `tp.dp.gfup.R`.

#### Longitudinal & Repeated Measures

- [`hv_trends()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_trends.md):
  Prepare patient-level data for annual trend lines with optional
  confidence ribbons for multiple groups. Ports the `tp.lp.trends.*`,
  `tp.rp.trends.*`, and `tp.dp.trends.R` families.

- [`hv_spaghetti()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_spaghetti.md):
  Prepare repeated-measures data for individual patient trajectory
  plots, optionally stratified by group. Ports `tp.dp.spaghetti.echo.R`.

- [`hv_longitudinal()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_longitudinal.md):
  Prepare pre-aggregated counts for a grouped bar chart or text table of
  patient and measurement counts at discrete follow-up windows. Use
  `plot(x, type = "plot")` for the bar chart and
  `plot(x, type = "table")` for the numeric table panel.

#### Flow Diagrams

- [`hv_alluvial()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_alluvial.md):
  Prepare patient-flow data for an alluvial (Sankey) diagram showing
  transitions between states across time points. Ports
  `tp.dp.female_bicus_preAR_sankey.R`.

- [`hv_sankey()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_sankey.md):
  Prepare cluster-assignment data for a stability Sankey showing how
  patients redistribute across K values in a PAM analysis.

#### Exploratory Data Analysis

- [`hv_eda()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_eda.md):
  Prepare a single variable for EDA plotting: bar chart (categorical) or
  scatter + LOESS (continuous). Ports
  `tp.dp.EDA_barplots_scatterplots.R`.

- [`eda_classify_var()`](https://ehrlinger.github.io/hvtiPlotR/reference/eda_classify_var.md):
  Classify a vector as `"Cont"`, `"Cat_Num"`, or `"Cat_Char"` using the
  `UniqueLimit` heuristic from `Barplot_Scatterplot_Function.R`.

- [`eda_select_vars()`](https://ehrlinger.github.io/hvtiPlotR/reference/eda_select_vars.md):
  Subset and reorder a data frame by a character vector or
  space-separated column-name string. Replaces `Order_Variables()`.

- [`hv_upset()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_upset.md):
  Prepare binary indicator data for an UpSet intersection plot. Ports
  `tp.complexUpset.R`.

### Legacy single-call plot API

These functions predate the
constructor-and-[`plot()`](https://rdrr.io/r/graphics/plot.default.html)
split and return a ggplot directly. They are retained for backward
compatibility with scripts written before the `hv_*()` redesign. New
code should prefer the constructor form.

- [`hazard_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/hazard_plot.md):
  Single-call parametric hazard/survival plot — combine-step equivalent
  of
  [`hv_hazard()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_hazard.md) +
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html).

- [`survival_difference_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/survival_difference_plot.md):
  Single-call mean-survival-difference plot — equivalent of
  [`hv_survival_difference()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_survival_difference.md) +
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html).

- [`nnt_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/nnt_plot.md):
  Single-call NNT plot — equivalent of
  [`hv_nnt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_nnt.md) +
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html).

### Data class and introspection

All `hv_*()` constructors return objects that inherit from `hv_data`
with a concept-specific subclass (e.g. `hv_survival`, `hv_trends`).

- [`is_hv_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/is_hv_data.md):
  Predicate for the shared base class.

- `inherits(x, "hv_trends")`: Check for a specific constructor's output.

- `x$data`: The canonical long-format data frame used by `plot(x)`.

- `x$meta`: Named list of structural metadata (column names, group
  levels, summary functions).

- `x$tables`: Concept-specific diagnostic or report tables (SMDs, risk
  tables, group counts, etc.).

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

### Scope and versioning

`hvtiPlotR` targets **internal HVTI / CORR use only** — it will not be
submitted to CRAN. GitHub-only dependencies are first-class (`Remotes:`
in DESCRIPTION). Install via:

    remotes::install_github("ehrlinger/hvtiPlotR")

Releases follow straight semantic versioning (2.0.0, 2.0.1, 2.1.0, 3.0.0
…). The `main` branch tracks the most recent release; `engineering`
collects changes staged for the next release. No `.9xxx` pre-release
suffix on development builds. Pin against a specific release tag for
reproducibility, e.g.
`remotes::install_github("ehrlinger/hvtiPlotR@v2.0.0")`.

### Vignettes

- [`vignette("hvtiPlotR")`](https://ehrlinger.github.io/hvtiPlotR/articles/hvtiPlotR.md):
  Introductory tutorial paralleling the SAS `plot.sas` macro, with
  side-by-side SAS and R examples.

- [`vignette("plot-functions")`](https://ehrlinger.github.io/hvtiPlotR/articles/plot-functions.md):
  Worked examples for every `hv_*()` constructor with the three-step
  build/bare-plot/decorate pattern.

- [`vignette("plot-decorators")`](https://ehrlinger.github.io/hvtiPlotR/articles/plot-decorators.md):
  Guide to scales, labels, annotations, coord crops, themes, and
  [`ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html) /
  [`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md)
  patterns, including the `panel_box` fixed-panel workflow.

- [`vignette("sas-migration-guide")`](https://ehrlinger.github.io/hvtiPlotR/articles/sas-migration-guide.md):
  SAS `plot.sas` template name lookup mapping to the corresponding
  `hv_*()` constructor and a worked R example.

## References

Wickham, H. *ggplot2: Elegant Graphics for Data Analysis*. Springer,
2009.

Gohel, D. *officer: Manipulation of Microsoft Word and PowerPoint
Documents*. R package. <https://davidgohel.github.io/officer/>
