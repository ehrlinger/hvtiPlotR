## The hvtiPlotR package

ggplot2 themes and plot functions for creating publication-quality
graphics in R, conforming to the standards of Cardiovascular Outcomes
Registries and Research (CORR) within The Heart & Vascular Institute at
the Cleveland Clinic. This package is the modern R replacement for the
historical `plot.sas` macro.

## Quick Start

Install from GitHub using
[remotes](https://CRAN.R-project.org/package=remotes):

``` r
remotes::install_github("ehrlinger/hvtiPlotR")
```

Apply an HVI theme to any ggplot2 figure in one line:

``` r
library(ggplot2)
library(hvtiPlotR)

ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) +
  geom_point() +
  hvti_theme("manuscript")
```

Export the result directly to an editable PowerPoint slide:

``` r
p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + hvti_theme("ppt")

save_ppt(
  object     = p,
  template   = system.file("ClevelandClinic.pptx", package = "hvtiPlotR"),
  powerpoint = "outputs/figure1.pptx"
)
```

## Themes

Use
[`hvti_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md)
to apply any supported style, or call the named aliases directly:

| Style key              | Alias(es)                                                                                                                                                                                   | Best for                            |
|------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------|
| `"manuscript"`         | [`theme_manuscript()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_manuscript.md), [`theme_man()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_manuscript.md) | Journal figures, white background   |
| `"ppt"` / `"dark_ppt"` | [`theme_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_dark_ppt.md), [`theme_dark_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_dark_ppt.md)       | Dark-background PowerPoint slides   |
| `"light_ppt"`          | [`theme_light_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_light_ppt.md)                                                                                              | Light/transparent PowerPoint slides |
| `"poster"`             | [`theme_poster()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme_poster.md)                                                                                                    | Conference posters                  |

``` r
p + hvti_theme("manuscript")   # via generic
p + theme_man()                # direct alias
p + hvti_theme("ppt")          # dark PPT
p + hvti_theme("light_ppt")    # light PPT
p + hvti_theme("poster")       # poster
```

## Plot Function Gallery

**hvtiPlotR 2.0 uses a two-step API.** A constructor (`hvti_*()`) shapes
the data and returns an S3 object;
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) renders a bare
`ggplot`. Add `scale_*`,
[`labs()`](https://ggplot2.tidyverse.org/reference/labs.html),
[`annotate()`](https://ggplot2.tidyverse.org/reference/annotate.html),
and a theme with the usual `+` operator.

``` r
km <- hvti_survival(sample_survival_data())
plot(km) + hvti_theme("manuscript")
km$tables$risk                         # risk-table data frame
```

### Propensity Score & Balance

| Constructor                                                                         | Description                                                                                                            |
|-------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------|
| [`hvti_mirror()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_mirror.md)   | Mirrored histograms showing propensity score distributions for two groups, before and after matching or IPTW weighting |
| [`hvti_stacked()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_stacked.md) | Stacked or proportional-fill histogram of a numeric variable by group                                                  |
| [`hvti_balance()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_balance.md) | Standardised mean difference dot-plot for assessing propensity matching or weighting quality                           |

``` r
mh <- hvti_mirror(sample_mirror_histogram_data(n = 2000),
                  group_labels = c("SAVR", "TF-TAVR"))
plot(mh) + hvti_theme("manuscript")
```

### Survival & Time-to-Event

| Constructor                                                                                                 | Description                                                                                                                                               |
|-------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------|
| [`hvti_survival()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_survival.md)                       | Kaplan-Meier and Nelson-Aalen analysis. `plot(km, type = ...)` renders survival, cumulative hazard, hazard, log-log, or life/RMST; tables via `km$tables` |
| [`hvti_nonparametric()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_nonparametric.md)             | Nonparametric survival or event-rate curve with optional confidence intervals                                                                             |
| [`hvti_ordinal()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_ordinal.md)                         | Nonparametric curves for ordinal outcomes (e.g. severity grades)                                                                                          |
| [`hvti_hazard()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_hazard.md)                           | Parametric hazard/survival curves from Weibull or other models, with optional KM overlay                                                                  |
| [`hvti_survival_difference()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_survival_difference.md) | Absolute treatment benefit vs. a reference group over time                                                                                                |
| [`hvti_nnt()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_nnt.md)                                 | Number needed to treat derived from survival difference estimates                                                                                         |
| [`hvti_followup()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_followup.md)                       | Goodness-of-follow-up scatter: actual vs. potential follow-up by operation year; `plot(gf, type = "event")` for non-fatal competing events                |

### Longitudinal & Repeated Measures

| Constructor                                                                                   | Description                                                                              |
|-----------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------|
| [`hvti_trends()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_trends.md)             | Temporal trend: annual means/medians with LOESS smooth, by group                         |
| [`hvti_spaghetti()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_spaghetti.md)       | Individual subject trajectories over time with optional per-group LOESS overlay          |
| [`hvti_longitudinal()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_longitudinal.md) | Pre-aggregated patient and measurement counts; `plot(lc, type = "table")` for text table |

### Exploratory & Multivariate

| Constructor                                                                           | Description                                                                                                                                                   |
|---------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [`hvti_eda()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_eda.md)           | Exploratory plot for a single variable. Auto-detects type: scatter + LOESS for continuous, stacked bar for categorical. Missing values shown as `"(Missing)"` |
| [`hvti_upset()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_upset.md)       | UpSet diagram for visualising procedure co-occurrences or set memberships                                                                                     |
| [`hvti_alluvial()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_alluvial.md) | Sankey/alluvial diagram for patient flow across categorical stages                                                                                            |
| [`hvti_sankey()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_sankey.md)     | Cluster stability Sankey showing patient transitions across cluster solutions                                                                                 |

### Utilities

| Function                                                                              | Description                                                           |
|---------------------------------------------------------------------------------------|-----------------------------------------------------------------------|
| `hvti_theme(style)`                                                                   | Generic dispatcher returning the named ggplot2 theme                  |
| [`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md)           | Export a ggplot to an editable PowerPoint slide using an HVI template |
| [`make_footnote()`](https://ehrlinger.github.io/hvtiPlotR/reference/make_footnote.md) | Add a footnote annotation to the current figure                       |

## Vignettes

Four vignettes ship with the package and are available after
installation:

``` r
vignette("hvtiPlotR",        package = "hvtiPlotR")  # SAS migration guide
vignette("plot-functions",   package = "hvtiPlotR")  # per-function reference with worked examples
vignette("plot-decorators",  package = "hvtiPlotR")  # composition: scale_*, labs(), themes, saving
vignette("contributing",     package = "hvtiPlotR")  # guide for adding new plot functions
```

The online reference is at <https://ehrlinger.github.io/hvtiPlotR/>.

## Migrating from plot.sas

If you are moving existing SAS analyses to R, see the SAS migration
vignette
([`vignette("hvtiPlotR")`](https://ehrlinger.github.io/hvtiPlotR/articles/hvtiPlotR.md)).
It maps each `plot.sas` macro call to the equivalent R recipe and shows
side-by-side code comparisons.

The `inst/plot.README` and `inst/plot.sas` files are preserved for
historical reference.

## Contributing

Pull requests are welcome! Please read
[CONTRIBUTING.md](https://ehrlinger.github.io/hvtiPlotR/CONTRIBUTING.md)
for the full guide, which covers:

- **Track A** — porting a SAS template (for biostatisticians and
  analysts adding a new plot function or sample-data generator)
- **Track B** — package infrastructure (for R developers working on
  dependencies, CI, testing, and CRAN compliance)

Quick-start:

``` r
devtools::install_deps(dependencies = TRUE)
devtools::load_all()
devtools::check()
```

Open an [issue](https://github.com/ehrlinger/hvtiPlotR/issues) to
discuss a new port before writing code, and tag `@ehrlinger` for review
on all pull requests.

## Code of Conduct

This project adheres to the [Contributor
Covenant](https://www.contributor-covenant.org/version/2/1/code_of_conduct/).
By participating, you are expected to uphold this code.
