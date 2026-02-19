

###############################################################
##                                                           ##
##      R: Good practice - adding footnotes to graphics      ##
##                                                           ##
## Adapted from the blog post:                               ##
## http://ryouready.wordpress.com/2009/02/17/r-good-practice-adding-footnotes-to-graphics/
##
###############################################################
#' Create a footnote for figures.
#'
#' Use grid graphics to add a footnote to a plot.
#'
#' @param footnoteText text to place in footnote. Defaults to
#' the local working directory.
#' @param timestamp should we add the current timestamp.
#' @param color Font color (lightgrey)
#' @param size font size
#'
#' @references
#' http://ryouready.wordpress.com/2009/02/17/r-good-practice-adding-footnotes-to-graphics/
#'
#' @export makeFootnote
#'
#' @examples
#' plot(1:10)
#' makeFootnote()
#'
#' @importFrom grid pushViewport viewport popViewport gpar grid.text unit
#' @importFrom grDevices grey
#'
# scriptName <- "filename.R"
# author <- "mh"
# footnote <- paste(scriptName, format(Sys.time(), "%d %b %Y"),

#                   author, sep=" / ")
makeFootnote <- function(footnoteText = getwd(),
                         size = .7,
                         color = grey(.5),
                         timestamp = TRUE)
{
  assertthat::assert_that(is.character(footnoteText), length(footnoteText) == 1,
                          msg = "`footnoteText` must be a single string.")
  assertthat::assert_that(assertthat::is.number(size), size > 0,
                          msg = "`size` must be a positive number.")
  assertthat::assert_that(length(color) == 1,
                          msg = "`color` must be a length-1 value.")
  assertthat::assert_that(assertthat::is.flag(timestamp),
                          msg = "`timestamp` must be TRUE or FALSE.")
  if (timestamp) {
    footnoteText  <- paste(footnoteText, Sys.time(), sep = " ")
  }
  pushViewport(viewport())
  grid.text(
    label = footnoteText ,
    x = unit(1, "npc") - unit(2, "mm"),
    y = unit(2, "mm"),
    just = c("right", "bottom"),
    gp = gpar(cex = size, col = color)
  )
  popViewport()
}
