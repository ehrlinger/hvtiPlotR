# Role colours for EDA and follow-up figures: hv_role_palette() and the
# scale_colour_hv() / scale_fill_hv() scales that apply it panel by panel.
# The rule and its reasoning: dev/specs/2026-09-27-hv-palette-design.md.

.HV_ROLE_EVENT <- "#D55E00"
.HV_ROLE_CENSORED <- "#0072B2"
.HV_ROLE_MISSING <- "#CCCCCC"
# Paul Tol's muted palette less sand #DDCC77 and cyan #88CCEE, which fall
# under 2:1 against white. Rose comes first so it is the one to drop when a
# role is present: it reads as the event.
.HV_TOL_MUTED <- c("#CC6677", "#332288", "#117733", "#882255", "#44AA99", "#999933", "#AA4499")

#' Colours for a figure's levels, by role
#'
#' @description
#' The house colour rule for EDA and follow-up figures, as a named vector you
#' can check or reuse: an event is vermillion, censored is blue, missing is
#' light grey, and every other level takes a colourblind-safe colour in order.
#' To apply the rule to a plot, use [scale_fill_hv()] or [scale_colour_hv()],
#' which call this for each panel.
#'
#' @details
#' Every colour is decided from `levels` alone:
#'
#' 1. A level named in `event` is `#D55E00`, in `censored` `#0072B2`, and in
#'    `missing` `#CCCCCC`. These hold even when the level is the only one.
#' 2. Every other level, in `levels` order, takes the light series of
#'    [hv_ppt_palette()]: the Okabe-Ito colours without yellow and sky blue,
#'    starting at blue, so a sole level with no role is blue.
#' 3. When any of `levels` is named in `event` or `censored`, blue and
#'    vermillion leave that series, so no other level can be mistaken for the
#'    event or for censored. A role name absent from `levels` changes nothing,
#'    so one call can serve panels that do and do not carry the event.
#' 4. When the other levels outnumber the series, all of them switch to Paul
#'    Tol's muted palette, without its sand and cyan, and without its rose when
#'    a role is present. Beyond that there are no more colourblind-safe
#'    colours, and the function stops with an error of class
#'    `hv_role_palette_capacity`.
#'
#' Every colour except the missing grey is at least 2:1 against white. The
#' grey is fainter on purpose: missing is the one level meant to recede.
#'
#' @param levels Character vector of distinct level names, in drawing order.
#' @param event,censored Level names that take the event or the censored
#'   colour, or `NULL` for none. Names not in `levels` are ignored.
#' @param missing Level name that stands for missing values. `"(Missing)"` is
#'   the explicit level [hv_eda()] adds.
#'
#' @return A character vector of hex colours, named by `levels` and in the
#'   same order.
#'
#' @seealso [scale_fill_hv()] and [scale_colour_hv()] to apply the rule to a
#'   plot; [hv_ppt_palette()] for series colours with no role attached.
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
    rotation <- setdiff(rotation, c(.HV_ROLE_EVENT, .HV_ROLE_CENSORED))
    fallback <- fallback[-1L]
  }
  others <- !(is_event | is_censored | is_missing)
  n <- sum(others)
  if (n > length(fallback)) {
    stop(errorCondition(
      sprintf("%d levels need a colour, and the colourblind-safe palettes hold %d%s.",
              n, length(fallback), if (any(is_event | is_censored)) " beside the event and censored levels" else ""),
      class = "hv_role_palette_capacity"
    ))
  }
  out[others] <- if (n <= length(rotation)) rotation[seq_len(n)] else fallback[seq_len(n)]
  out
}

#' Colour and fill scales that apply the role rule to each panel
#'
#' @description
#' Discrete scales that colour each panel by [hv_role_palette()]: event
#' vermillion, censored blue, missing light grey, and colourblind-safe colours
#' for everything else. Add one to a page of panels with `&` and every panel
#' is coloured from its own levels, so a panel without the event still draws
#' its levels from blue.
#'
#' @details
#' Colours stay the caller's choice: no constructor or `plot()` method in this
#' package applies these scales for you.
#'
#' A panel with more levels than the colourblind-safe palettes hold is drawn in
#' ggplot2's default hue palette instead, with a warning naming its level
#' count, so one variable with many levels does not stop a report. Call
#' [hv_role_palette()] directly to get an error in that case.
#'
#' @inheritParams hv_role_palette
#' @param na.value Colour for a real `NA`. The default is the missing grey, so
#'   an `NA` and a `"(Missing)"` level look the same.
#' @param ... Passed to [ggplot2::discrete_scale()]: `name`, `labels`,
#'   `guide` and so on.
#'
#' @return A discrete ggplot2 scale for the `colour` or `fill` aesthetic.
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
scale_colour_hv <- function(event = NULL, censored = NULL, missing = "(Missing)",
                             na.value = .HV_ROLE_MISSING, ...) { # nolint: object_name_linter.
  .hv_role_scale("colour", event, censored, missing, na.value, ...)
}

# ggplot2's default discrete hue, which is scales::hue_pal()(n); scales is only
# in Suggests, so it is written out here.
.hv_default_hue <- function(n) {
  grDevices::hcl(h = seq(15, 375, length.out = n + 1L)[seq_len(n)], c = 100, l = 65)
}

# A discrete scale whose map() colours from the limits it is given. palette(n)
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
            warning(sprintf("A panel with %d levels (%s) has more than the colourblind-safe palettes hold; ",
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
