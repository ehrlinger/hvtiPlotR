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
# 
# scriptName <- "filename.R"
# author <- "mh"
# footnote <- paste(scriptName, format(Sys.time(), "%d %b %Y"),

#                   author, sep=" / ")
makeFootnote <- function(footnoteText=getwd(),
                         size= .7, color= grey(.5))
{
  require(grid)
  
  footnoteText  <- paste(footnoteText, Sys.time(), sep=" ")
  pushViewport(viewport())
  grid.text(label= footnoteText ,
            x = unit(1,"npc") - unit(2, "mm"),
            y= unit(2, "mm"),
            just=c("right", "bottom"),
            gp=gpar(cex= size, col=color))
  popViewport()
}

