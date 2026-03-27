#' Parametric survival estimates
#'
#' A dataset containing parametric competing-risk survival estimates used for
#' examples in the package vignettes.  It was originally produced by a Weibull
#' parametric survival model fitted to an aortic-valve surgery cohort and
#' exported from SAS via `tp.hp.dead.sas`.
#'
#' The three outcomes tracked are:
#' \describe{
#'   \item{init}{Re-operation (re-initialisation)}
#'   \item{death}{Death}
#'   \item{strk}{Stroke}
#' }
#' Each outcome suffix maps to: `se*` = survival estimate; `sl*/su*` = lower /
#' upper 95 % CI on the survival estimate; `he*` = hazard rate estimate;
#' `hl*/hu*` = lower / upper 95 % CI on the hazard; `ve*` = variance of the
#' survival estimate; `no*` = cumulative incidence (percent); `cl*/cu*` = lower
#' / upper 95 % CI on the cumulative incidence; `no1*` = probability of
#' entering the state at exactly time t; `tx*/tx1*` = cumulative hazard
#' integral (Weibull model output, used internally).
#'
#' @format A data frame with 2001 rows (fine time grid) and 41 columns:
#' \describe{
#'   \item{years}{Follow-up time in years.}
#'   \item{months}{Follow-up time in months (\code{years} * 12).}
#'   \item{time}{Follow-up time in years (same as \code{years}; retained for SAS compatibility).}
#'   \item{lag_time}{Lagged follow-up time (equals \code{time} for standard output).}
#'   \item{dt}{Time increment between consecutive time points.}
#'   \item{sedeath}{Parametric survival estimate: freedom from death (percent).}
#'   \item{sldeath}{Lower 95 % confidence limit for \code{sedeath}.}
#'   \item{sudeath}{Upper 95 % confidence limit for \code{sedeath}.}
#'   \item{hedeath}{Instantaneous hazard rate estimate for death.}
#'   \item{hldeath}{Lower 95 % confidence limit for \code{hedeath}.}
#'   \item{hudeath}{Upper 95 % confidence limit for \code{hedeath}.}
#'   \item{vedeath}{Variance of the death survival estimate.}
#'   \item{nodeath}{Cumulative probability of death by time t (percent).}
#'   \item{cldeath}{Lower 95 % confidence limit for \code{nodeath}.}
#'   \item{cudeath}{Upper 95 % confidence limit for \code{nodeath}.}
#'   \item{no1death}{Probability of entering the death state at exactly time t.}
#'   \item{tx1death}{Cumulative hazard integral for death (Weibull model internal).}
#'   \item{txdeath}{Cumulative hazard for death (same scale as \code{tx1death}).}
#'   \item{sestrk}{Parametric survival estimate: freedom from stroke (percent).}
#'   \item{slstrk}{Lower 95 % confidence limit for \code{sestrk}.}
#'   \item{sustrk}{Upper 95 % confidence limit for \code{sestrk}.}
#'   \item{hestrk}{Instantaneous hazard rate estimate for stroke.}
#'   \item{hlstrk}{Lower 95 % confidence limit for \code{hestrk}.}
#'   \item{hustrk}{Upper 95 % confidence limit for \code{hestrk}.}
#'   \item{vestrk}{Variance of the stroke survival estimate.}
#'   \item{nostrk}{Cumulative probability of stroke by time t (percent).}
#'   \item{clstrk}{Lower 95 % confidence limit for \code{nostrk}.}
#'   \item{custrk}{Upper 95 % confidence limit for \code{nostrk}.}
#'   \item{no1strk}{Probability of entering the stroke state at exactly time t.}
#'   \item{tx1strk}{Cumulative hazard integral for stroke (Weibull model internal).}
#'   \item{txstrk}{Cumulative hazard for stroke (same scale as \code{tx1strk}).}
#'   \item{cestrk}{Complement: probability of surviving stroke-free to time t (percent).}
#'   \item{noinit}{Parametric estimate of freedom from re-operation (percent).}
#'   \item{clinit}{Lower 95 % confidence limit for \code{noinit}.}
#'   \item{cuinit}{Upper 95 % confidence limit for \code{noinit}.}
#'   \item{no1init}{Probability of entering the re-operated state at exactly time t.}
#'   \item{z}{Log-hazard estimate for the pooled Weibull model.}
#'   \item{sez}{Standard error of \code{z}.}
#'   \item{cllz}{Lower 95 % confidence limit for \code{z} (log-hazard scale).}
#'   \item{cluz}{Upper 95 % confidence limit for \code{z} (log-hazard scale).}
#'   \item{check}{Row sum of \code{noinit}, \code{nodeath}, \code{nostrk}, and \code{cestrk}; should equal 100.}
#' }
#'
#' @docType data
#' @keywords datasets
#' @name parametric
#' @seealso [nonparametric], [hvti_hazard()]
NULL
