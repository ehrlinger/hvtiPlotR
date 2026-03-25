## The hvtiPlotR package
<!-- badges: start -->
[![CRAN status](https://img.shields.io/github/r-package/v/ehrlinger/hvtiPlotR?label=hvtiPlotR)](https://github.com/ehrlinger/hvtiPlotR)
[![DOI](https://zenodo.org/badge/5745/ehrlinger/hvtiPlotR.png)](http://dx.doi.org/10.5281/zenodo.11780)
![active](http://www.repostatus.org/badges/latest/active.svg)
[![R-CMD-check](https://github.com/ehrlinger/hvtiPlotR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/ehrlinger/hvtiPlotR/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/ehrlinger/hvtiPlotR/graph/badge.svg)](https://app.codecov.io/gh/ehrlinger/hvtiPlotR)
<!-- badges: end -->

ggplot2 themes and plot functions for creating publication-quality graphics in R, conforming to the standards of Cardiovascular Outcomes Registries and Research (CORR) within The Heart & Vascular Institute at the Cleveland Clinic. This package is the modern R replacement for the historical `plot.sas` macro.

## Quick Start

Install from GitHub using [remotes](https://CRAN.R-project.org/package=remotes):

```r
remotes::install_github("ehrlinger/hvtiPlotR")
```

Apply an HVI theme to any ggplot2 figure in one line:

```r
library(ggplot2)
library(hvtiPlotR)

ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) +
  geom_point() +
  hvti_theme("manuscript")
```

Export the result directly to an editable PowerPoint slide:

```r
p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + hvti_theme("ppt")

save_ppt(
  object     = p,
  template   = system.file("ClevelandClinic.pptx", package = "hvtiPlotR"),
  powerpoint = "outputs/figure1.pptx"
)
```

## Themes

Use `hvti_theme()` to apply any supported style, or call the named aliases directly:

| Style key | Alias(es) | Best for |
|---|---|---|
| `"manuscript"` | `theme_manuscript()`, `theme_man()` | Journal figures, white background |
| `"ppt"` / `"dark_ppt"` | `theme_ppt()`, `theme_dark_ppt()` | Dark-background PowerPoint slides |
| `"light_ppt"` | `theme_light_ppt()` | Light/transparent PowerPoint slides |
| `"poster"` | `theme_poster()` | Conference posters |

```r
p + hvti_theme("manuscript")   # via generic
p + theme_man()                # direct alias
p + hvti_theme("ppt")          # dark PPT
p + hvti_theme("light_ppt")    # light PPT
p + hvti_theme("poster")       # poster
```

## Plot Function Gallery

Every function returns a bare `ggplot` object. Add `scale_*`, `labs()`, `annotate()`, and a theme with the usual `+` operator.

### Propensity Score & Balance

| Function | Description |
|---|---|
| `mirror_histogram()` | Mirrored histograms showing propensity score distributions for two groups, before and after matching or IPTW weighting |
| `stacked_histogram()` | Stacked or proportional-fill histogram of a numeric variable by group |
| `covariate_balance()` | Standardised mean difference dot-plot for assessing propensity matching or weighting quality |

```r
dta <- sample_mirror_histogram_data(n = 2000)
mirror_histogram(dta, group_labels = c("SAVR", "TF-TAVR"))$plot +
  hvti_theme("manuscript")
```

### Survival & Time-to-Event

| Function | Description |
|---|---|
| `survival_curve()` | Kaplan-Meier and Nelson-Aalen analysis. Returns five plot types (survival, cumulative hazard, hazard, log-log, life/RMST) plus risk and report tables |
| `nonparametric_curve_plot()` | Nonparametric survival or event-rate curve with optional confidence intervals |
| `nonparametric_ordinal_plot()` | Nonparametric curves for ordinal outcomes (e.g. severity grades) |
| `hazard_plot()` | Parametric hazard/survival curves from Weibull or other models, with optional KM overlay |
| `survival_difference_plot()` | Absolute treatment benefit vs. a reference group over time |
| `nnt_plot()` | Number needed to treat derived from survival difference estimates |
| `goodness_followup()` | Goodness-of-follow-up scatter: actual vs. potential follow-up by operation year |
| `goodness_event_plot()` | Companion panel for non-fatal competing events in a follow-up assessment |

```r
km <- survival_curve(
  data      = sample_survival_data(),
  time_col  = "time",
  event_col = "status",
  group_col = "group"
)
km + hvti_theme("manuscript")          # km IS the survival ggplot
attr(km, "risk_table")                 # risk-table data frame
```

### Longitudinal & Repeated Measures

| Function | Description |
|---|---|
| `trends_plot()` | Temporal trend: annual means/medians with LOESS smooth, by group |
| `spaghetti_plot()` | Individual subject trajectories over time with optional per-group LOESS overlay |
| `longitudinal_counts_plot()` | Pre-aggregated patient and measurement counts at discrete follow-up windows |

### Exploratory & Multivariate

| Function | Description |
|---|---|
| `eda_plot()` | Exploratory plot for a single variable. Auto-detects type: scatter + LOESS for continuous, stacked bar for categorical. Missing values shown as `"(Missing)"` |
| `upset_plot()` | UpSet diagram for visualising procedure co-occurrences or set memberships |
| `alluvial_plot()` | Sankey/alluvial diagram for patient flow across categorical stages |
| `cluster_sankey_plot()` | Cluster stability Sankey showing patient transitions across cluster solutions |

### Utilities

| Function | Description |
|---|---|
| `hvti_theme(style)` | Generic dispatcher returning the named ggplot2 theme |
| `save_ppt()` | Export a ggplot to an editable PowerPoint slide using an HVI template |
| `make_footnote()` | Add a footnote annotation to the current figure |

## Vignettes

Four vignettes ship with the package and are available after installation:

```r
vignette("hvtiPlotR",        package = "hvtiPlotR")  # SAS migration guide
vignette("plot-functions",   package = "hvtiPlotR")  # per-function reference with worked examples
vignette("plot-decorators",  package = "hvtiPlotR")  # composition: scale_*, labs(), themes, saving
vignette("contributing",     package = "hvtiPlotR")  # guide for adding new plot functions
```

The online reference is at <https://ehrlinger.github.io/hvtiPlotR/>.

## Migrating from plot.sas

If you are moving existing SAS analyses to R, see the SAS migration vignette (`vignette("hvtiPlotR")`). It maps each `plot.sas` macro call to the equivalent R recipe and shows side-by-side code comparisons.

The `inst/plot.README` and `inst/plot.sas` files are preserved for historical reference.

## Contributing

Pull requests are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for
the full guide, which covers:

- **Track A** — porting a SAS template (for biostatisticians and analysts
  adding a new plot function or sample-data generator)
- **Track B** — package infrastructure (for R developers working on
  dependencies, CI, testing, and CRAN compliance)

Quick-start:

```r
devtools::install_deps(dependencies = TRUE)
devtools::load_all()
devtools::check()
```

Open an [issue](https://github.com/ehrlinger/hvtiPlotR/issues) to discuss a
new port before writing code, and tag `@ehrlinger` for review on all pull
requests.

## Code of Conduct

This project adheres to the [Contributor Covenant](https://www.contributor-covenant.org/version/2/1/code_of_conduct/). By participating, you are expected to uphold this code.
