#' Nonparametric survival estimates
#'
#' A dataset containing nonparametric competing-risk estimates used for
#' examples in the package vignettes: the empirical companion to
#' [parametric], over the same three states (event-free,
#' death, and stroke). Originally exported from SAS via
#' \code{tp.hp.dead.sas} / \code{tp.np.*.sas}.
#'
#' Column prefixes follow the SAS naming: `sg*` is the estimate, `stl*` and
#' `stu*` its lower and upper confidence limits. The limits are filled only
#' at the handful of times where an error bar is drawn and are `NA` elsewhere,
#' which is how `plot.sas` thins error bars.
#'
#' @format A data frame with 126 rows (one per event time) and 10 columns:
#' \describe{
#'   \item{iv_state}{Follow-up time in years (0 to about 4.9); the x-axis in
#'     the vignette plots.}
#'   \item{sginit}{Percent event-free (still in the initial state).}
#'   \item{stlinit}{Lower confidence limit for \code{sginit}; all `NA` in this
#'     extract.}
#'   \item{stuinit}{Upper confidence limit for \code{sginit}; all `NA` in this
#'     extract.}
#'   \item{sgdead1}{Cumulative percent dead; `NA` at times with no death.}
#'   \item{sgstrk1}{Cumulative percent with stroke; `NA` at times with no
#'     stroke.}
#'   \item{stldead1}{Lower confidence limit for \code{sgdead1} (6 time points).}
#'   \item{studead1}{Upper confidence limit for \code{sgdead1} (6 time points).}
#'   \item{stlstrk1}{Lower confidence limit for \code{sgstrk1} (3 time points).}
#'   \item{stustrk1}{Upper confidence limit for \code{sgstrk1} (3 time points).}
#' }
#'
#' @docType data
#' @keywords datasets
#' @name nonparametric
#' @seealso [parametric], [hv_nonparametric()]
NULL
