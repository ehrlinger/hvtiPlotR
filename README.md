## The hvtiPlotR package
<!-- badges: start -->
[![R package version](https://img.shields.io/github/r-package/v/ehrlinger/hvtiPlotR)](https://github.com/ehrlinger/hvtiPlotR)

[![active](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/badges/latest/active.svg)

[![R-CMD-check](https://github.com/ehrlinger/hvtiPlotR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/ehrlinger/hvtiPlotR/actions/workflows/R-CMD-check.yaml)
[![lint](https://github.com/ehrlinger/hvtiPlotR/actions/workflows/lint.yaml/badge.svg)](https://github.com/ehrlinger/hvtiPlotR/actions/workflows/lint.yaml)
[![pkgdown](https://github.com/ehrlinger/hvtiPlotR/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/ehrlinger/hvtiPlotR/actions/workflows/pkgdown.yaml)
[![Codecov test coverage](https://codecov.io/gh/ehrlinger/hvtiPlotR/graph/badge.svg)](https://app.codecov.io/gh/ehrlinger/hvtiPlotR)

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.11780.svg)](https://doi.org/10.5281/zenodo.11780)
<!-- badges: end -->

hvtiPlotR packages the ggplot2 themes and plot functions we use in Cardiovascular Outcomes Registries and Research (CORR) at the Cleveland Clinic Heart & Vascular Institute. If you are migrating from the `plot.sas` macro, this is its R successor.

Worked, rendered examples for every constructor and theme live in the companion [**HVTI ggplot graphics recipes**](https://ehrlinger.github.io/hvti_graphics/) book.

## Quick Start

Install from GitHub using [remotes](https://CRAN.R-project.org/package=remotes):

```r
remotes::install_github("ehrlinger/hvtiPlotR")
```

Apply an HVTI theme to a ggplot2 figure in one line:

```r
library(ggplot2)
library(hvtiPlotR)

ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) +
  geom_point() +
  theme_hv_manuscript()
```

Export the result directly to an editable PowerPoint slide. A small dark CORR
template ships with the package, so you can save without supplying your own:

```r
p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_hv_ppt_dark()

save_ppt(
  object     = p,
  template   = system.file("extdata", "hv_ppt_template.pptx", package = "hvtiPlotR"),
  powerpoint = "outputs/figure1.pptx"
)
```

## Themes

Four themes cover the publication contexts we use. Each follows the
`theme_bw()` contract — pass `base_size` / `base_family`, or chain `+ theme(...)`,
to override anything:

| Theme | Best for |
|---|---|
| `theme_hv_manuscript()` | Journal figures, white background |
| `theme_hv_poster()` | Conference posters |
| `theme_hv_ppt_dark()` | Dark-background PowerPoint slides (black panel, white text) |
| `theme_hv_ppt_light()` | Light/transparent PowerPoint slides |

```r
p + theme_hv_manuscript()   # journal figure
p + theme_hv_ppt_dark()     # dark PPT slide
p + theme_hv_ppt_light()    # light PPT slide
p + theme_hv_poster()       # poster
```

The two PPT themes default to **Arial 32 Bold** axis tick labels and **Arial 40
Bold** axis titles, matching the standard CORR slide deck.

> The earlier alias functions — `theme_man()`, `theme_ppt()`, `theme_dark_ppt()`,
> `theme_light_ppt()`, `theme_poster()`, and the `hv_theme_*()` family — still
> work but are **deprecated** (one-time warning); prefer the `theme_hv_*()` names
> above. The old `hv_theme("...")` string dispatcher has been removed.

## Plot Function Gallery

**hvtiPlotR 2.0 uses a two-step API.** A constructor (`hv_*()`) shapes the
data and returns an S3 object; `plot()` renders a bare `ggplot`. Add
`scale_*`, `labs()`, `annotate()`, and a theme with the usual `+` operator.

```r
km <- hv_survival(sample_survival_data())
plot(km) + theme_hv_manuscript()
km$tables$risk                         # risk-table data frame
```

### Propensity Score & Balance

| Constructor | Description |
|---|---|
| `hv_mirror_hist()` | Mirrored histograms showing propensity score distributions for two groups, before and after matching or IPTW weighting |
| `hv_stacked()` | Stacked or proportional-fill histogram of a numeric variable by group |
| `hv_balance()` | Standardised mean difference dot-plot for assessing propensity matching or weighting quality |

```r
mh <- hv_mirror_hist(sample_mirror_histogram_data(n = 2000),
                  group_labels = c("SAVR", "TF-TAVR"))
plot(mh) + theme_hv_manuscript()
```

### Survival & Time-to-Event

| Constructor | Description |
|---|---|
| `hv_survival()` | Kaplan-Meier and Nelson-Aalen analysis. `plot(km, type = ...)` renders survival, cumulative hazard, hazard, log-log, or life/RMST; tables via `km$tables` |
| `hv_nonparametric()` | Nonparametric survival or event-rate curve with optional confidence intervals |
| `hv_ordinal()` | Nonparametric curves for ordinal outcomes (e.g. severity grades) |
| `hv_hazard()` | Parametric hazard/survival curves from Weibull or other models, with optional KM overlay |
| `hv_survival_difference()` | Absolute treatment benefit vs. a reference group over time |
| `hv_nnt()` | Number needed to treat derived from survival difference estimates |
| `hv_followup()` | Goodness-of-follow-up scatter: actual vs. potential follow-up by operation year; `plot(gf, type = "event")` for non-fatal competing events |
| `hv_atrisk()` / `hv_atrisk_compose()` | Numbers-at-risk table panel, and a composer that stacks a survival curve over it with aligned time axes |

### Longitudinal & Repeated Measures

| Constructor | Description |
|---|---|
| `hv_trends()` | Temporal trend: annual means/medians with LOESS smooth, by group |
| `hv_spaghetti()` | Individual subject trajectories over time with optional per-group LOESS overlay |
| `hv_longitudinal()` | Pre-aggregated patient and measurement counts; `plot(lc, type = "table")` for text table |

### Exploratory & Multivariate

| Constructor | Description |
|---|---|
| `hv_eda()` | Exploratory plot for a single variable. Auto-detects type: scatter + LOESS for continuous, stacked bar for categorical. Missing values shown as `"(Missing)"` |
| `hv_upset()` | UpSet diagram for visualising procedure co-occurrences or set memberships |
| `hv_venn()` | Venn diagram of 2-3 overlapping set memberships, with a region-count table; the small-set-count companion to `hv_upset()` |
| `hv_alluvial()` | Sankey/alluvial diagram for patient flow across categorical stages |
| `hv_sankey()` | Cluster stability Sankey showing patient transitions across cluster solutions |

### Utilities

| Function | Description |
|---|---|
| `theme_hv_manuscript()` / `theme_hv_poster()` / `theme_hv_ppt_dark()` / `theme_hv_ppt_light()` | The four publication themes — see [Themes](#themes) |
| `save_ppt()` | Export a ggplot to an editable PowerPoint slide using an HVTI template; `panel_box = list(width = ..., height = ..., left = ..., top = ...)` (on by default) anchors the panel content area to the same slide coordinates on every slide |
| `hv_ggsave_dims()` | Compute `ggsave()` `width`/`height` that preserve a target panel content area regardless of axis-label, legend, or title size |
| `hv_ph_location()` | Compute `officer::ph_location()` args so a ggplot's panel lands at a fixed slide rectangle — the per-slide worker that `save_ppt(panel_box=)` calls |
| `make_footnote()` | Add a footnote annotation to the current figure |

## Vignettes

Five vignettes ship with the package. After installation, call any of them from the R console:

```r
vignette("hvtiPlotR",           package = "hvtiPlotR")  # package tutorial: generating plot.sas-style figures in R
vignette("sas-migration-guide", package = "hvtiPlotR")  # SAS template -> hvtiPlotR migration mapping
vignette("plot-functions",      package = "hvtiPlotR")  # per-function reference with worked examples
vignette("plot-decorators",     package = "hvtiPlotR")  # composition: scale_*, labs(), themes, saving
vignette("contributing",        package = "hvtiPlotR")  # guide for adding new plot functions
```

The online reference is at <https://ehrlinger.github.io/hvtiPlotR/>.

## Slides

A short PowerPoint presentation covering the v2.x redesign (the two-step S3 API,
renamed theme functions, and `save_ppt(panel_box =)`) ships with the package
as a Quarto source file:

```r
system.file("slides/hvtiPlotR-whats-new.qmd", package = "hvtiPlotR")
```

Render it to `.pptx` with `quarto render` or `quarto::quarto_render()`. The slides condense what you will find in `vignette("plot-decorators")` and `vignette("hvtiPlotR")`.

## Migrating from plot.sas

If you are moving existing SAS analyses to R, the SAS migration vignette (`vignette("sas-migration-guide")`) maps each `plot.sas` macro call to its R equivalent.

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

This project follows the [Contributor Covenant](https://www.contributor-covenant.org/version/2/1/code_of_conduct/) code of conduct.
