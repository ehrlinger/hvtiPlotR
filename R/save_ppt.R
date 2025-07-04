################################################## 
## Creating a PowerPoint presentation, 
## one slide for each graph
##
################################################## 
#' Function for saving a ggplot object, or list of ggplot
#' objects to a powerpoint document for presentations.
#' 
#' @param object ggplot object, or list of ggplot objects
#' @param template a powerpoint presentation, used as a template for creating the output document
#' @param powerpoint filename for saving the powerpoint presentation output 
#' @param slide_title the string used for the slide title
#' @param offx x offset from upper left slide corner
#' @param offy y offset from upper left slide corner
#' @param width graphic object width
#' @param height graphic object height
#'
#' @export save_ppt
#' @importFrom officer read_pptx add_slide body_add_plot
#' 
#' @examples
#' \dontrun{
#' # Create a plot
#' d.plt <- ggplot(plt.dta) + geom_smooth(aes(x=x, y=yhat, color=inductCRT), se=FALSE, width=4)+
#'   scale_color_brewer(palette = "Set3")+
#'   labs(x="", y="")+
#'   theme(legend.position="none")
#'   }
save_ppt <- function(object, 
                     template="../graphs/RD.pptx", 
                     powerpoint= "../graphs/pptExample.pptx",
                     slide_title="Treatment Difference",
                     offx = .75,
                     offy=.8,
                     width=8,
                     height=6){
  
  # Create a powerPoint document.
  doc = officer::read_pptx(template=template)
  
  if(inherits(object,"ggplot")){  
    ##--------
    # For each graph, add_slide. The graphs require the 
    # “Title and Content” template.
    doc = add_slide( doc, 
                     layout="Title and Content",
                     'Title 1'=slide_title )
    
    # Place a title)
    
    doc = body_add_plot( doc=doc, value=object, editable = TRUE,
                   offx=offx, offy=offy, width=width, height=height)
  }else if(inherits(object,"list")){
    # For a list, we want to place one slide per ggplot object
    
    for(ind in 1:length(object)){
      if(inherits(object[[ind]],"ggplot")){  
        ##--------
        # For each graph, add_slide. The graphs require the 
        # “Title and Content” template.
        doc = add_slide(doc, 
                        layout="Title and Content",
                        'Title 1'=slide_title)
        
        doc = body_add_plot( doc=doc, value=object[[ind]], editable = TRUE,
                       offx=offx, offy=offy, width=width, height=height)
      }
    }
  }
  
  # write the powerpoint doc. This will not overwrite an open document.
  print( doc, powerpoint )
  
}