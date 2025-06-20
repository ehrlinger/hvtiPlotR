## The hviPlotR package ##
<!-- badges: start -->
[![DOI](https://zenodo.org/badge/5745/ehrlinger/hviPlotR.png)](http://dx.doi.org/10.5281/zenodo.11780)

![active](http://www.repostatus.org/badges/latest/active.svg)
[![Build Status](https://travis-ci.org/ehrlinger/hviPlotR.svg?branch=master)](https://travis-ci.org/ehrlinger/hviPlotR)
[![Codecov test coverage](https://codecov.io/gh/ehrlinger/hviPlotR/graph/badge.svg)](https://app.codecov.io/gh/ehrlinger/hviPlotR)
<!-- badges: end -->
ggplot2 themes and methodology documentation for creating publication quality graphics in *R* conforming to the standards of the clinical investigations statistics group within The Heart \& Vascular Institute at the Cleveland Clinic.

The *hviPlotR* is an *R* implementation of the *plot.sas* macro we currently use in *SAS*.  This package includes a set of themes designed to format those figures for both manuscript and presentation publication targets as well as helper functions to simplify the specific needs of the HVI statistics group.

This package can be installed using the [devtools](https:\\CRAN.R-project.org/package=devtools) using the command `devtools::install_github("ehrlinger/hviPlotR")`.

We include a package vignette which has detailed recipes for generating our standard graphics using *ggplot2* commands and the routines found in this package. The package also uses the *ReporteRs* package, available at (https://github.com/davidgohel/ReporteRs), for figures conforming to the HVI PowerPoint standards. 