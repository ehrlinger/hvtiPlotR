## The hvtiPlotR package ##
<!-- badges: start -->
[![DOI](https://zenodo.org/badge/5745/ehrlinger/hvtiPlotR.png)](http://dx.doi.org/10.5281/zenodo.11780)

![active](http://www.repostatus.org/badges/latest/active.svg)
[![Build Status](https://travis-ci.org/ehrlinger/hvtiPlotR.svg?branch=master)](https://travis-ci.org/ehrlinger/hvtiPlotR)
[![R-CMD-check](https://github.com/ehrlinger/hvtiPlotR/actions/workflows/ci.yml/badge.svg)](https://github.com/ehrlinger/hvtiPlotR/actions/workflows/ci.yml)
[![Codecov test coverage](https://codecov.io/gh/ehrlinger/hvtiPlotR/graph/badge.svg)](https://app.codecov.io/gh/ehrlinger/hvtiPlotR)
<!-- badges: end -->
ggplot2 themes and methodology documentation for creating publication quality graphics in *R* conforming to the standards of the clinical investigations statistics group within The Heart \& Vascular Institute at the Cleveland Clinic.

The *hvtiPlotR* package is the modern *R* implementation of the historical *plot.sas* macro. It provides:

- A cohesive ggplot2 theme family accessible through the `hvti_theme()` generic (e.g., `hvti_theme("ppt")`, `hvti_theme("manuscript")`).
- Presentation-ready mirrored propensity score visualizations via `hvti_plot("mirror_histogram", ...)`.
- Helpers for exporting plots to PowerPoint (powered by `officer`) and adding consistent figure footers.

## Installation

Install from GitHub using [remotes](https://CRAN.R-project.org/package=remotes):

```r
remotes::install_github("ehrlinger/hvtiPlotR")
```

Then load the package in your R session:

```r
library(hvtiPlotR)
```

## Usage Overview

### Themes

Use the unified theme generic to apply styles aligned with HVI publication standards:

```r
library(ggplot2)
p <- ggplot(mtcars, aes(wt, mpg, color = factor(cyl))) + geom_point()
p + hvti_theme("ppt")
p + hvti_theme("manuscript", base_size = 14)
```

### Mirrored Propensity Score Histograms

```r
data <- sample_mirror_histogram_data(120)
mirror <- hvti_plot(
	"mirror_histogram",
	data = data,
	group_labels = c("SAVR", "TF-TAVR"),
	output_file = "plots/mirror.pdf"
)
mirror$plot  # ggplot object
mirror$diagnostics  # SMD + summary tables
```

### PowerPoint Export

```r
save_ppt(
	object = mirror$plot,
	template = "inst/templates/HVI.pptx",
	powerpoint = "outputs/analysis.pptx",
	slide_title = "Propensity Balance"
)
```

## Development Workflow

1. Clone the repo and install dependencies: `renv::restore()` or `pak::pak()` (optional).
2. Run the unit tests:

```r
devtools::test()
```

3. Check the package:

```r
devtools::check()
```

### Test Coverage Highlights

- `tests/testthat/test_mirror_histogram.R`: validates helper calculations, diagnostics, error handling, and `hvti_plot()` dispatch.
- `tests/testthat/test_save_ppt.R`: covers happy paths plus all validation and failure scenarios for PowerPoint exports.
- `tests/testthat/test_footnote.R`: ensures `makeFootnote()` works across plotting contexts and rejects invalid inputs.

## Vignettes and Extended Docs

- See `vignettes/hvtiPlotR.qmd` for end-to-end recipes mirroring the original HVI guidelines.
- Historical SAS macro documentation remains under `inst/plot.README` for reference; all modern workflows live in the R package.

## Contributing

Pull requests are welcome! Please:

1. Create a feature branch from `master`.
2. Add tests for any new functionality.
3. Run `devtools::check()` locally.
4. Update the NEWS file if you change user-facing behavior.

## Code of Conduct

This project adheres to the [Contributor Covenant](https://www.contributor-covenant.org/version/2/1/code_of_conduct/). By participating, you are expected to uphold this code.