# Slide layout contract shared by the bundled templates (spec 2026-10-19).

.hv_layout_roles <- c(figure  = "Title Only",
                      section = "Section Header",
                      title   = "Title Slide",
                      content = "Title and Content",
                      two     = "Two Content",
                      blank   = "Blank")

# Names the light and dark templates used through hvtiPlotR 2.8.11.
.hv_layout_aliases <- c(`Custom Layout`   = "Title Only",
                        `1_Custom Layout` = "Section Header",
                        `1_Title Slide`   = "Title Slide",
                        `1_Title Only`    = "Section Header")

# Old names already reported this session.
.hv_layout_alias_env <- new.env(parent = emptyenv())

#' Slide layout name for a slide role
#'
#' Every template bundled with hvtiPlotR (dark, light and slate) has the same
#' six layouts by the same names, so a deck script runs on any of them. Name
#' the role and pass the result to [save_ppt()]'s `layout` or to
#' [officer::add_slide()].
#'
#' Through hvtiPlotR 2.8.11 the light template named its figure layout
#' "Custom Layout" and its section layout "1_Custom Layout", and the dark
#' template named its section layout "1_Title Only". [save_ppt()] still
#' accepts those names, with a one-time message; calls to
#' [officer::add_slide()] must use the new names.
#'
#' @param role One of `"figure"` (title only, for a plot), `"section"`
#'   (a chapter head), `"title"` (the opening slide), `"content"` (title and
#'   one body), `"two"` (title and two bodies) or `"blank"`.
#' @return A single character string: the layout's name in every bundled
#'   template.
#' @seealso [save_ppt()], [hv_panel_box()].
#' @examples
#' hv_ppt_layout("figure")
#' hv_ppt_layout("section")
#' @export
hv_ppt_layout <- function(role = c("figure", "section", "title", "content",
                                   "two", "blank")) {
  role <- match.arg(role)
  unname(.hv_layout_roles[[role]])
}

# The layout name to request from a template whose layouts are `available`:
# maps an old name to its new one (with a one-time message) or a new name to
# an old one (a live master that still has old names). See the plan's rule.
.hv_resolve_layout <- function(layout, available) {
  if (!(is.character(layout) && length(layout) == 1L) ||
      layout %in% available) {
    return(layout)
  }
  if (layout %in% names(.hv_layout_aliases)) {
    new <- unname(.hv_layout_aliases[[layout]])
    if (new %in% available) {
      if (!isTRUE(.hv_layout_alias_env[[layout]])) {
        .hv_layout_alias_env[[layout]] <- TRUE
        message("hvtiPlotR: layout '", layout, "' is now '", new,
                "' in the bundled templates (hvtiPlotR 2.8.12); using '",
                new, "'. Use hv_ppt_layout() to name layouts by role. ",
                "This message prints once per session.")
      }
      return(new)
    }
  }
  old <- names(.hv_layout_aliases)[.hv_layout_aliases == layout]
  old <- old[old %in% available]
  if (length(old)) return(old[[1L]])
  layout
}
