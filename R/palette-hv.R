# Role colors for EDA and follow-up figures: hv_role_palette() and the
# scale_color_hv() / scale_fill_hv() scales that apply it panel by panel.
# The rule and its reasoning: dev/specs/2026-09-27-hv-palette-design.md.

# Paul Tol's vibrant red and blue, not Okabe-Ito's vermilion and blue: readers
# asked for a red that reads as red. Beside the rotation's bluish green the
# colorblind margin narrows a little (deutan 47, protan 34 CIELAB, against 53
# and 37 for vermilion; colorspace::deutan()/protan()).
.HV_ROLE_EVENT <- "#CC3311"
.HV_ROLE_CENSORED <- "#0077BB"
# The rotation's own blue and vermilion, which leave it when a role is present:
# a level in either would read as censored or as the event.
.HV_ROLE_LOOKALIKES <- c("#0072B2", "#D55E00")
.HV_ROLE_MISSING <- "#CCCCCC"
# Paul Tol's muted palette less sand #DDCC77 and cyan #88CCEE, which fall
# under 2:1 against white. Rose comes first so it is the one to drop when a
# role is present: it reads as the event.
.HV_TOL_MUTED <- c("#CC6677", "#332288", "#117733", "#882255", "#44AA99", "#999933", "#AA4499")
# Paul Tol's vibrant palette less orange and gray, reordered to lead with its
# red and blue, the role colors above: hv_group_palette()'s colors for compared
# groups, where red and blue carry no role.
.HV_TOL_VIBRANT <- c(.HV_ROLE_EVENT, .HV_ROLE_CENSORED, "#009988", "#EE3377", "#33BBEE")
# The full nine for filled areas such as Sankey nodes, where sand and cyan
# carry no thin line and their low contrast against white is no bar.
# hv_sankey() uses it as the default node fill. The order is not Tol's: it was
# searched to keep the colors any three positions apart as distinct as
# possible under normal, deuteranopic and protanopic vision (CIELAB distance,
# colorspace::deutan()/protan()), because neighboring Sankey nodes sit near
# one another. Tol's own order put purple three places after wine, and the two
# read as one under the flows' transparency.
.HV_TOL_MUTED_9 <- c("#AA4499", "#CC6677", "#999933", "#88CCEE", "#882255",
                     "#332288", "#DDCC77", "#117733", "#44AA99")

#' The house palette for categorical groups
#'
#' @description
#' Colors for categorical groups in a manuscript, poster or light-background
#' slide figure: the Okabe-Ito colors, ordered for a white background, with
#' every one clearing 3:1 contrast against white. Hand it to a manual scale,
#' `scale_color_manual(values = hv_palette())`.
#'
#' @details
#' This is the categorical half of the house color rule. Ordered and diverging
#' scales take ColorBrewer `"RdBu"` or `"PuOr"` through
#' [ggplot2::scale_color_brewer()], and sequential scales take `"Blues"`.
#' Avoid `"Set1"` and `"RdYlGn"`: their red against green fails for a reader
#' with deuteranopia.
#'
#' The colors are those of `hv_ppt_palette("light")`, under a name that does
#' not tie a manuscript figure to slides. For a dark slide, use
#' `hv_ppt_palette("dark")`. Six colors are supplied, and asking for more is an
#' error rather than a silently recycled palette.
#'
#' @param n Number of colors to return, or `NULL` (default) for all six.
#'
#' @return A character vector of hex colors, in group order.
#'
#' @seealso [hv_ppt_palette()] for the slide orderings,
#'   [hv_role_palette()] when levels carry a role such as event or censored.
#'
#' @examples
#' hv_palette()
#' hv_palette(n = 3)
#' @export
hv_palette <- function(n = NULL) {
  hv_ppt_palette("light", n = n)
}

#' Colors for a figure's levels, by role
#'
#' @description
#' The house color rule for EDA and follow-up figures, as a named vector you
#' can check or reuse: an event is red, censored is blue, missing is
#' light gray, and every other level takes a colorblind-safe color in order.
#' To apply the rule to a plot, use [scale_fill_hv()] or [scale_color_hv()],
#' which call this for each panel.
#'
#' @details
#' Every color is decided from `levels` alone:
#'
#' 1. A level named in `event` is `#CC3311`, in `censored` `#0077BB` (Paul
#'    Tol's vibrant red and blue), and in `missing` `#CCCCCC`. These hold even
#'    when the level is the only one.
#' 2. Every other level, in `levels` order, takes the light series of
#'    [hv_ppt_palette()]: Okabe-Ito blue, vermilion, bluish green and reddish
#'    purple, then a darkened yellow and black, so a sole level with no role
#'    is blue.
#' 3. When any of `levels` is named in `event` or `censored`, blue and
#'    vermilion leave that series, so no other level can be mistaken for the
#'    event or for censored. A role name absent from `levels` changes nothing,
#'    so one call can serve panels that do and do not carry the event.
#' 4. When the other levels outnumber the series, all of them switch to Paul
#'    Tol's muted palette, without its sand and cyan, and without its rose when
#'    a role is present. Beyond that there are no more colorblind-safe
#'    colors, and the function stops with an error of class
#'    `hv_role_palette_capacity`.
#'
#' Every color except the missing gray is at least 2:1 against white. The
#' gray is fainter on purpose: missing is the one level meant to recede.
#'
#' @param levels Character vector of distinct level names, in drawing order.
#' @param event,censored Level names that take the event or the censored
#'   color, or `NULL` for none. Names not in `levels` are ignored.
#' @param missing Level name that stands for missing values. `"(Missing)"` is
#'   the explicit level [hv_eda()] adds.
#'
#' @return A character vector of hex colors, named by `levels` and in the
#'   same order.
#'
#' @seealso [scale_fill_hv()] and [scale_color_hv()] to apply the rule to a
#'   plot; [hv_ppt_palette()] for series colors with no role attached.
#'
#' @examples
#' hv_role_palette(c("No event", "Reoperation", "Death"),
#'                 event = "Death", censored = "No event")
#' hv_role_palette(c("Female", "Male", "(Missing)"))
#' @export
hv_role_palette <- function(levels, event = NULL, censored = NULL, missing = "(Missing)") {
  if (!is.character(levels) || anyNA(levels) || anyDuplicated(levels))
    stop("`levels` must be a character vector of distinct, non-missing names.", call. = FALSE)
  roles <- list(event = event, censored = censored, missing = missing)
  for (nm in names(roles)) {
    if (!is.null(roles[[nm]]) && (!is.character(roles[[nm]]) || anyNA(roles[[nm]])))
      stop(sprintf("`%s` must be NULL or a character vector of level names.", nm), call. = FALSE)
  }
  named <- unlist(lapply(roles, unique), use.names = FALSE)
  clash <- unique(named[duplicated(named)])
  if (length(clash))
    stop("A level is named in more than one role: ", paste(clash, collapse = ", "), ".", call. = FALSE)

  out <- stats::setNames(character(length(levels)), levels)
  is_event <- levels %in% event
  is_censored <- levels %in% censored
  is_missing <- levels %in% missing
  out[is_event] <- .HV_ROLE_EVENT
  out[is_censored] <- .HV_ROLE_CENSORED
  out[is_missing] <- .HV_ROLE_MISSING

  rotation <- hv_ppt_palette("light")
  fallback <- .HV_TOL_MUTED
  if (any(is_event | is_censored)) {
    rotation <- setdiff(rotation, c(.HV_ROLE_EVENT, .HV_ROLE_CENSORED, .HV_ROLE_LOOKALIKES))
    fallback <- fallback[-1L]
  }
  others <- !(is_event | is_censored | is_missing)
  n <- sum(others)
  if (n > length(fallback)) {
    stop(errorCondition(
      sprintf("%d levels need a color, and the colorblind-safe palettes hold %d%s.",
              n, length(fallback), if (any(is_event | is_censored)) " beside the event and censored levels" else ""),
      class = "hv_role_palette_capacity"
    ))
  }
  out[others] <- if (n <= length(rotation)) rotation[seq_len(n)] else fallback[seq_len(n)]
  out
}

#' Colors for the groups compared in an outcome figure
#'
#' @description
#' The house colors for the groups of a survival, hazard or other outcome
#' curve, named by group so each group keeps its color in every figure of a
#' paper. A single group is black. Two to five groups take Paul Tol's vibrant
#' palette, led by red and blue: red `#CC3311`, blue `#0077BB`, teal `#009988`,
#' magenta `#EE3377`, cyan `#33BBEE`.
#'
#' @details
#' Red and blue mean the event and censored only in a figure that draws those
#' roles, which is [hv_role_palette()]'s job. In an outcome curve the colors
#' stand for groups, so the strongest two go to the first two groups: they stay
#' apart for a reader with deuteranopia or protanopia (CIELAB distance 104 and
#' 84 under `colorspace::deutan()` and `protan()`), and they are hues the
#' team's JTCVS working palette names.
#'
#' Six or seven groups all switch to Paul Tol's muted palette less sand and
#' cyan, the overflow [hv_role_palette()] uses. Beyond seven there are no more
#' colorblind-safe colors, and the function stops with an error of class
#' `hv_group_palette_capacity`.
#'
#' Pass every level of the grouping factor, not only those a figure draws, so
#' that a figure missing one group does not shift the colors of the rest.
#'
#' @param levels Character vector of distinct group names, in drawing order.
#'
#' @return A character vector of hex colors, named by `levels` and in the same
#'   order, for `ggplot2::scale_color_manual(values = )`.
#'
#' @seealso [hv_role_palette()] for figures whose levels are the event,
#'   censored or missing; [hv_palette()] for categorical groups that are not
#'   compared as outcomes.
#'
#' @examples
#' hv_group_palette("All")
#' hv_group_palette(c("Sternotomy", "Robotic", "Thoracotomy"))
#' @export
hv_group_palette <- function(levels) {
  if (!is.character(levels) || !length(levels) || anyNA(levels) || anyDuplicated(levels))
    stop("`levels` must be a non-empty character vector of distinct, non-missing names.", call. = FALSE)
  n <- length(levels)
  if (n == 1L) return(stats::setNames("#000000", levels))
  if (n > length(.HV_TOL_MUTED)) {
    stop(errorCondition(
      sprintf("%d groups need a color, and the colorblind-safe palettes hold %d.", n, length(.HV_TOL_MUTED)),
      class = "hv_group_palette_capacity"
    ))
  }
  pal <- if (n <= length(.HV_TOL_VIBRANT)) .HV_TOL_VIBRANT else .HV_TOL_MUTED
  stats::setNames(pal[seq_len(n)], levels)
}

#' Color and fill scales that apply the role rule to each panel
#'
#' @description
#' Discrete scales that color each panel by [hv_role_palette()]: event
#' red, censored blue, missing light gray, and colorblind-safe colors
#' for everything else. Add one to a page of panels with `&` and every panel
#' is colored from its own levels, so a panel without the event still draws
#' its levels from blue.
#'
#' @details
#' `scale_colour_hv()` is an alias of `scale_color_hv()`, the same pairing of
#' British and US names that ggplot2 gives its own color scales.
#'
#' Colors stay the caller's choice: no constructor or `plot()` method in this
#' package applies these scales for you.
#'
#' A panel with more levels than the colorblind-safe palettes hold is drawn in
#' ggplot2's default hue palette instead, with a warning naming its level
#' count, so one variable with many levels does not stop a report. Call
#' [hv_role_palette()] directly to get an error in that case.
#'
#' @inheritParams hv_role_palette
#' @param na.value Color for a real `NA`. The default is the missing gray, so
#'   an `NA` and a `"(Missing)"` level look the same.
#' @param ... Passed to [ggplot2::discrete_scale()]: `name`, `labels`,
#'   `guide` and so on.
#'
#' @return A discrete ggplot2 scale for the `color` or `fill` aesthetic.
#'
#' @seealso [hv_role_palette()] for the rule itself.
#'
#' @examples
#' dta <- data.frame(status = c("Alive", "Dead", "Alive", "(Missing)"))
#' ggplot2::ggplot(dta, ggplot2::aes(status, fill = status)) +
#'   ggplot2::geom_bar() +
#'   scale_fill_hv(event = "Dead", censored = "Alive")
#' @export
scale_fill_hv <- function(event = NULL, censored = NULL, missing = "(Missing)",
                           na.value = .HV_ROLE_MISSING, ...) { # nolint: object_name_linter.
  # na.value keeps its dot: it is ggplot2's name for this argument on every scale.
  .hv_role_scale("fill", event, censored, missing, na.value, ...)
}

#' @rdname scale_fill_hv
#' @export
scale_color_hv <- function(event = NULL, censored = NULL, missing = "(Missing)",
                            na.value = .HV_ROLE_MISSING, ...) { # nolint: object_name_linter.
  # "colour" is ggplot2's internal aesthetic name; its own scale_color_*() pass it too.
  .hv_role_scale("colour", event, censored, missing, na.value, ...)
}

#' @rdname scale_fill_hv
#' @export
scale_colour_hv <- scale_color_hv

# ggplot2's default discrete hue, which is scales::hue_pal()(n); scales is only
# in Suggests, so it is written out here.
.hv_default_hue <- function(n) {
  grDevices::hcl(h = seq(15, 375, length.out = n + 1L)[seq_len(n)], c = 100, l = 65)
}

# A discrete scale whose map() colors from the limits it is given. palette(n)
# sees only a count, so the rule, which depends on level names, lives in map().
# map(self, x, limits) is ggplot2's extension surface, the same in 3.5.0 and
# 4.0.3; test_role_palette.R builds a two-panel page to catch a change.
.hv_role_scale <- function(aesthetics, event, censored, missing, na_value, ...) {
  hv_role_palette(character(), event, censored, missing)  # validate the roles now, not at draw time
  scale <- ggplot2::discrete_scale(aesthetics, palette = .hv_default_hue, na.value = na_value, ...)
  ggplot2::ggproto(
    "ScaleDiscreteHvRole", scale,
    capacity_warned = FALSE,
    map = function(self, x, limits = self$get_limits()) {
      limits <- as.character(limits[!is.na(limits)])
      pal <- tryCatch(
        hv_role_palette(limits, event, censored, missing),
        hv_role_palette_capacity = function(e) {
          if (!self$capacity_warned) {
            self$capacity_warned <- TRUE
            warning(sprintf("A panel with %d levels (%s) has more than the colorblind-safe palettes hold; ",
                            length(limits), paste(utils::head(limits, 4L), collapse = ", ")),
                    "drawing it in ggplot2's default hue.", call. = FALSE)
          }
          stats::setNames(.hv_default_hue(length(limits)), limits)
        }
      )
      out <- unname(pal[as.character(x)])
      # As ggplot2's own map(): na.translate = FALSE leaves NA unmapped, so it is dropped.
      if (isTRUE(self$na.translate)) out[is.na(out)] <- self$na.value
      out
    }
  )
}
