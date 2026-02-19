ensure_officer_available <- function() {
  if (!requireNamespace("officer", quietly = TRUE)) {
    stop("Package `officer` must be installed to use `save_ppt()`.", call. = FALSE)
  }
}

officer_safe_call <- function(expr, action) {
  tryCatch(expr, error = function(e) {
    stop(sprintf("Failed to %s: %s", action, e$message), call. = FALSE)
  })
}

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
  is_plot_list <- is.list(object)
  assertthat::assert_that(
    inherits(object, "ggplot") || is_plot_list,
    msg = "`object` must be a ggplot object or a list of ggplot objects."
  )
  if (is_plot_list) {
    assertthat::assert_that(length(object) > 0, msg = "`object` list cannot be empty.")
    all_plots <- vapply(object, inherits, logical(1), what = "ggplot")
    assertthat::assert_that(all(all_plots), msg = "All elements of `object` must be ggplot objects.")
  }
  assertthat::assert_that(assertthat::is.string(template), file.exists(template),
                          msg = "`template` must be the path to an existing PowerPoint file.")
  assertthat::assert_that(assertthat::is.string(powerpoint),
                          dir.exists(dirname(powerpoint)),
                          msg = "`powerpoint` must be a writable file path.")
  assertthat::assert_that(assertthat::is.string(slide_title),
                          msg = "`slide_title` must be a single string.")
  assertthat::assert_that(assertthat::is.number(offx), assertthat::is.number(offy),
                          offx >= 0, offy >= 0,
                          msg = "`offx` and `offy` must be non-negative numbers.")
  assertthat::assert_that(assertthat::is.number(width), width > 0,
                          assertthat::is.number(height), height > 0,
                          msg = "`width` and `height` must be positive numbers.")
  
  # Create a powerPoint document.
    ensure_officer_available()
    doc <- officer_safe_call(
      officer::read_pptx(template = template),
      action = "open PowerPoint template"
    )
  
  if(inherits(object,"ggplot")){  
    ##--------
    # For each graph, add_slide. The graphs require the 
    # “Title and Content” template.
      doc <- officer_safe_call(
        officer::add_slide(
          doc,
          layout = "Title and Content",
          `'Title 1'` = slide_title
        ),
        action = "add slide to PowerPoint"
      )
    
    # Place a title)
    
      doc <- officer_safe_call(
        officer::body_add_plot(
          doc = doc,
          value = object,
          editable = TRUE,
          offx = offx,
          offy = offy,
          width = width,
          height = height
        ),
        action = "add plot to slide"
      )
  }else if(is_plot_list){
    # For a list, we want to place one slide per ggplot object
    
    for(ind in seq_along(object)){
      if(inherits(object[[ind]],"ggplot")){  
        ##--------
        # For each graph, add_slide. The graphs require the 
        # “Title and Content” template.
        doc <- officer_safe_call(
          officer::add_slide(
            doc,
            layout = "Title and Content",
            `'Title 1'` = slide_title
          ),
          action = "add slide to PowerPoint"
        )
        
        doc <- officer_safe_call(
          officer::body_add_plot(
            doc = doc,
            value = object[[ind]],
            editable = TRUE,
            offx = offx,
            offy = offy,
            width = width,
            height = height
          ),
          action = "add plot to slide"
        )
      }
    }
  }
  
  # write the powerpoint doc. This will not overwrite an open document.
  officer_safe_call(
    officer::print(doc, target = powerpoint),
    action = "write PowerPoint file"
  )
  
}