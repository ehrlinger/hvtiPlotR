# hvtiPlotR: Publication-Quality Graphics for Clinical Manuscripts

`hvtiPlotR` is an R port of the `plot.sas` macro suite used by the
Clinical Investigations Statistics group within the Heart & Vascular
Institute at the Cleveland Clinic. It produces publication-quality
graphics that conform to HVI manuscript and presentation standards using
[ggplot2::ggplot2](https://ggplot2.tidyverse.org/reference/ggplot2-package.html)
and the
[officer::officer](https://davidgohel.github.io/officer/reference/officer.html)
package.

All plot functions return bare
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
objects (or lists of them) so callers can apply additional `ggplot2`
layers, scales, and themes without restriction.

### Themes

- [`hvti_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md):
  Unified theme dispatcher (`"manuscript"`, `"ppt"`, `"dark_ppt"`,
  `"poster"`).

- [`theme_man()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_manuscript.md)
  / `theme_manuscript`: Theme for manuscript figures.

- [`theme_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_ppt.md):
  Theme for PowerPoint presentation figures.

- [`theme_dark_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_dark_ppt.md):
  Dark theme for PowerPoint presentations.

- [`theme_poster()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_poster.md):
  Theme for poster figures.

### Output helpers

- [`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md):
  Save ggplot objects to a PowerPoint presentation via the
  [officer::officer](https://davidgohel.github.io/officer/reference/officer.html)
  package.

- [`makeFootnote()`](https://ehrlinger.github.io/hvtiPlotR/reference/makeFootnote.md):
  Add footnotes to graphics.

### Plot functions

- [`hvti_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_plot.md):
  Single entry-point dispatcher for all hvtiPlotR plot types
  (`"mirror_histogram"`, `"stacked_histogram"`, `"covariate_balance"`).

- [`mirror_histogram()`](https://ehrlinger.github.io/hvtiPlotR/reference/mirror_histogram.md):
  Side-by-side propensity-score histograms (binary-match or
  IPTW-weighted mode). Ports `plot.sas` mirror histogram output.

- [`stacked_histogram()`](https://ehrlinger.github.io/hvtiPlotR/reference/stacked_histogram.md):
  Stacked (or filled) histogram of a numeric variable faceted by a
  grouping factor.

- [`covariate_balance()`](https://ehrlinger.github.io/hvtiPlotR/reference/covariate_balance.md):
  Dot-plot of standardised mean differences before and after
  propensity-score matching or weighting.

- [`goodness_followup()`](https://ehrlinger.github.io/hvtiPlotR/reference/goodness_followup.md):
  Goodness-of-follow-up scatter plot showing actual vs. potential
  follow-up per operation year. Optionally includes a non-fatal-event
  panel.

- [`survival_curve()`](https://ehrlinger.github.io/hvtiPlotR/reference/survival_curve.md):
  Kaplan-Meier or Nelson-Aalen survival analysis returning up to five
  plot types (survival, cumulative hazard, hazard, log-log, life/RMST)
  plus risk and report tables. Ports the SAS `%kaplan` and `%nelsont`
  macros from `tp.ac.dead.sas`.

### Sample-data generators

Each plot function ships with a companion generator for use in examples
and tests:

- [`sample_mirror_histogram_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_mirror_histogram_data.md):
  Simulates propensity scores via a logistic model with greedy 1:1
  caliper matching and optional IPTW weights.

- [`sample_stacked_histogram_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_stacked_histogram_data.md):
  Simulates year-by-category count data.

- [`sample_covariate_balance_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_covariate_balance_data.md):
  Simulates patient-level covariates with a logistic propensity model
  and caliper matching, returning standardised mean differences before
  and after matching.

- [`sample_goodness_followup_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_goodness_followup_data.md):
  Simulates an operative cohort with operation dates, follow-up times,
  death, and non-fatal events.

- [`sample_survival_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_survival_data.md):
  Simulates exponential survival times with administrative censoring and
  optional treatment strata.

## References

Wickham, H. *ggplot2: Elegant Graphics for Data Analysis*. Springer,
2009.
