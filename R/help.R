###############################################################################
# Package documentation
###############################################################################
#' @title hviciPlotting package for plotting standard graphics for manuscripts
#' and presentations using \code{R} and the \code{ggplot2} package.
#' 
#' @description hviciPlotting is a replacement package for the \code{plot.sas}
#' macro for creating publication quality graphics.
#' 
#' \itemize{ 
#' \item \code{ggplot2} figures: We chose to use the \code{ggplot2} package for our figures. 
#'  The plot functions all return either a single \code{ggplot2} object, or a list of 
#'  \code{ggplot2} objects. 
#'  The user can then use additional \code{ggplot2} functions to modify and customise the 
#'  figures to their liking. 
#' }
#'
#' The hviciPlotting package contains the following functions:
#' \itemize{
#' \item \code{\link{theme_man}}: 
#' \item \code{\link{theme_ppt}}:
#' \item \code{\link{save.hviplot}}: 
#' }
#' 
#' All functions have an associated plotting function that returns ggplot2 graphics, either 
#' individually or as a list, that can be further customised using standard ggplot2 commands.
#'  
#' @references
#' Wickham, H. ggplot2: elegant graphics for data analysis. Springer New York, 2009.
#' 
#' @docType package
#' @name hviciPlotting
#' 
################
NULL
