###############################################################################
# Package documentation
###############################################################################
#' hvtiPlotR: Publication-Quality Graphics for Clinical Manuscripts
#'
#' @description
#' `hvtiPlotR` is an R port of the `plot.sas` macro suite used by the
#' Clinical Investigations Statistics group within the Heart & Vascular
#' Institute at the Cleveland Clinic. It produces publication-quality
#' graphics that conform to HVI manuscript and presentation standards using
#' [ggplot2] and the [officer] package.
#'
#' All plot functions return bare [ggplot2::ggplot()] objects (or lists of
#' them) so callers can apply additional `ggplot2` layers, scales, and themes
#' without restriction.
#'
#' ## Themes
#'
#' \itemize{
#'   \item [hvti_theme()]: Unified theme dispatcher (`"manuscript"`,
#'     `"ppt"`, `"dark_ppt"`, `"poster"`).
#'   \item [theme_man()] / `theme_manuscript`: Theme for manuscript figures.
#'   \item [theme_ppt()]: Theme for PowerPoint presentation figures.
#'   \item [theme_dark_ppt()]: Dark theme for PowerPoint presentations.
#'   \item [theme_poster()]: Theme for poster figures.
#' }
#'
#' ## Output helpers
#'
#' \itemize{
#'   \item [save_ppt()]: Save ggplot objects to a PowerPoint presentation
#'     via the [officer] package.
#'   \item [makeFootnote()]: Add footnotes to graphics.
#' }
#'
#' ## Plot functions
#'
#' \itemize{
#'   \item [mirror_histogram()]: Side-by-side propensity-score histograms
#'     (binary-match or IPTW-weighted mode). Ports `plot.sas` mirror
#'     histogram output.
#'   \item [stacked_histogram()]: Stacked (or filled) histogram of a numeric
#'     variable faceted by a grouping factor.
#'   \item [covariate_balance()]: Dot-plot of standardised mean differences
#'     before and after propensity-score matching or weighting.
#'   \item [goodness_followup()]: Goodness-of-follow-up scatter plot showing
#'     actual vs. potential follow-up per operation year. Optionally includes
#'     a non-fatal-event panel.
#'   \item [survival_curve()]: Kaplan-Meier or Nelson-Aalen survival analysis
#'     returning up to five plot types (survival, cumulative hazard, hazard,
#'     log-log, life/RMST) plus risk and report tables. Ports the SAS
#'     `%kaplan` and `%nelsont` macros from `tp.ac.dead.sas`.
#' }
#'
#' ## Sample-data generators
#'
#' Each plot function ships with a companion generator for use in examples
#' and tests:
#'
#' \itemize{
#'   \item [sample_mirror_histogram_data()]: Simulates propensity scores via
#'     a logistic model with greedy 1:1 caliper matching and optional IPTW
#'     weights.
#'   \item [sample_stacked_histogram_data()]: Simulates year-by-category
#'     count data.
#'   \item [sample_covariate_balance_data()]: Simulates patient-level
#'     covariates with a logistic propensity model and caliper matching,
#'     returning standardised mean differences before and after matching.
#'   \item [sample_goodness_followup_data()]: Simulates an operative cohort
#'     with operation dates, follow-up times, death, and non-fatal events.
#'   \item [sample_survival_data()]: Simulates exponential survival times
#'     with administrative censoring and optional treatment strata.
#' }
#'
#' @references
#' Wickham, H. *ggplot2: Elegant Graphics for Data Analysis*. Springer, 2009.
#'
#' @name hvtiPlotR-package
#' @aliases hvtiPlotR
################
NULL
