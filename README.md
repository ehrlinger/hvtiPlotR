## The hvtiPlotR package
<!-- badges: start -->
[![CRAN status](https://img.shields.io/github/r-package/v/ehrlinger/hvtiPlotR?label=hvtiPlotR)](https://github.com/ehrlinger/hvtiPlotR)
[![DOI](https://zenodo.org/badge/5745/ehrlinger/hvtiPlotR.png)](http://dx.doi.org/10.5281/zenodo.11780)
![active](http://www.repostatus.org/badges/latest/active.svg)
[![R-CMD-check](https://github.com/ehrlinger/hvtiPlotR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/ehrlinger/hvtiPlotR/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/ehrlinger/hvtiPlotR/graph/badge.svg)](https://app.codecov.io/gh/ehrlinger/hvtiPlotR)
<!-- badges: end -->

ggplot2 themes and plot functions for creating publication-quality graphics in R, conforming to the standards of Cardiovascular Outcomes Registries and Research (CORR) within The Heart & Vascular Institute at the Cleveland Clinic. This package is the modern R replacement for the historical `plot.sas` macro.

## Installation

```r
remotes::install_github("ehrlinger/hvtiPlotR")
```

## Usage

Apply a theme to any ggplot in one line:

```r
library(ggplot2)
library(hvtiPlotR)

ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) +
  geom_point() +
  hv_theme("manuscript")
```

Export directly to an editable PowerPoint slide:

```r
p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + hv_theme("ppt")

save_ppt(
  object     = p,
  template   = system.file("ClevelandClinic.pptx", package = "hvtiPlotR"),
  powerpoint = "outputs/figure1.pptx"
)
```

Supported themes: `"manuscript"` (journal figures), `"ppt"` / `"dark_ppt"` (dark PowerPoint), `"light_ppt"` (light/transparent PowerPoint), `"poster"` (conference posters). Call via `hv_theme(style)` or as a direct alias — `theme_manuscript()` (`theme_man()`), `theme_ppt()` / `theme_dark_ppt()`, `theme_light_ppt()`, `theme_poster()`.

## Plot functions

hvtiPlotR 2.0 uses a two-step API: a constructor (`hv_*()`) shapes the data and returns an S3 object; `plot()` renders a bare `ggplot` you can extend with `scale_*`, `labs()`, `annotate()`, and a theme.

```r
km <- hv_survival(sample_survival_data())
plot(km) + hv_theme("manuscript")
km$tables$risk                         # risk-table data frame
```

| Function | Category | Description |
|---|---|---|
| `hv_mirror_hist()` | Propensity / balance | Mirrored histograms of propensity scores for two groups, before and after matching or IPTW weighting |
| `hv_stacked()` | Propensity / balance | Stacked or proportional-fill histogram of a numeric variable by group |
| `hv_balance()` | Propensity / balance | Standardised mean difference dot-plot for matching/weighting quality |
| `hv_survival()` | Survival | Kaplan-Meier and Nelson-Aalen; `plot(km, type=…)` for survival, hazard, log-log, or RMST; tables via `km$tables` |
| `hv_nonparametric()` | Survival | Nonparametric survival or event-rate curve with optional confidence intervals |
| `hv_ordinal()` | Survival | Nonparametric curves for ordinal outcomes (e.g. severity grades) |
| `hv_hazard()` | Survival | Parametric hazard/survival curves (Weibull etc.), with optional KM overlay |
| `hv_survival_difference()` | Survival | Absolute treatment benefit vs. a reference group over time |
| `hv_nnt()` | Survival | Number needed to treat derived from survival-difference estimates |
| `hv_followup()` | Survival | Goodness-of-follow-up scatter; `plot(gf, type = "event")` for non-fatal competing events |
| `hv_trends()` | Longitudinal | Annual means/medians with LOESS smooth, by group |
| `hv_spaghetti()` | Longitudinal | Individual subject trajectories over time with optional per-group LOESS overlay |
| `hv_longitudinal()` | Longitudinal | Pre-aggregated patient and measurement counts; `plot(lc, type = "table")` for text table |
| `hv_eda()` | Exploratory | Single-variable EDA; auto-detects type (scatter + LOESS for continuous, stacked bar for categorical) |
| `hv_upset()` | Exploratory | UpSet diagram for procedure co-occurrences or set memberships |
| `hv_alluvial()` | Exploratory | Sankey/alluvial diagram for patient flow across categorical stages |
| `hv_sankey()` | Exploratory | Cluster-stability Sankey across cluster solutions |

Geometry & export helpers:

| Function | Description |
|---|---|
| `save_ppt()` | Export a ggplot to an editable PowerPoint slide; `panel_box = list(width, height, left, top)` anchors the panel to the same slide coordinates on every slide |
| `hv_ggsave_dims()` | Compute `ggsave()` `width`/`height` that preserve a target panel size regardless of axis labels, legend, or title |
| `hv_ph_location()` | Compute `officer::ph_location()` args so a ggplot panel lands at a fixed slide rectangle (called internally by `save_ppt(panel_box=)`) |
| `make_footnote()` | Add a footnote annotation to the current figure |

## Documentation

Five vignettes ship with the package:

- `vignette("installation")` — full install guide (GitHub, Suggests, dev checkout, troubleshooting)
- `vignette("hvtiPlotR")` — SAS migration guide (`plot.sas` → R)
- `vignette("plot-functions")` — per-function reference with worked examples
- `vignette("plot-decorators")` — composition: `scale_*`, `labs()`, themes, saving
- `vignette("contributing")` — guide for adding new plot functions

Online reference: <https://ehrlinger.github.io/hvtiPlotR/>. The historical `plot.sas` macro is preserved in `inst/plot.sas` for reference.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full guide — Track A (porting a SAS template; for biostatisticians and analysts) and Track B (package infrastructure; for R developers). Open an [issue](https://github.com/ehrlinger/hvtiPlotR/issues) to discuss a new port before writing code, and tag `@ehrlinger` on pull requests.

```r
devtools::install_deps(dependencies = TRUE)
devtools::load_all()
devtools::check()
```

This project adheres to the [Contributor Covenant](https://www.contributor-covenant.org/version/2/1/code_of_conduct/).
