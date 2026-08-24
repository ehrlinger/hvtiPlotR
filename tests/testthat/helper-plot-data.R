# tests/testthat/helper-plot-data.R
#
# Helpers for asserting that ggplot objects rendered by the package actually
# contain data. These deliberately drive ggplot2's internal pipeline
# (`ggplot_build()`) so a plot that "renders" but has zero rows in every data
# layer is caught — we get the same protection as a visual review without
# requiring a graphics device.

# Geoms that draw nothing and exist only to extend a scale. Their layer data is
# legitimately allowed to be empty, so they are exempt from the row check.
.empty_geoms <- c("GeomBlank")

# Geoms whose row count is decoration rather than observations — one row per
# reference line. These are exempt from `min_rows`: a single yintercept is not
# evidence that the *plotted* dataset has rows. They are NOT exempt from having
# to draw something. Exempting them by geom class alone hides a real failure,
# because a reference line can be mapped to the data and so can collapse to
# zero rows — `plot.hv_sankey()` draws `geom_vline(aes(xintercept = ...))`,
# which carries one row per observation. A decoration that drew nothing is a
# defect whether the geom was given a literal intercept or an `aes()`.
.decorator_geoms <- c("GeomHline", "GeomVline", "GeomAbline")

# Any other geom found in a hvtiPlotR plot must carry observation rows.

#' Row counts per built layer of a ggplot.
#'
#' @param p A ggplot object.
#' @return Integer vector with one entry per layer (after `ggplot_build()`).
layer_row_counts <- function(p) {
  built <- ggplot2::ggplot_build(p)
  vapply(built$data, NROW, integer(1))
}

#' Geom class names per layer of a ggplot, parallel to `layer_row_counts()`.
geom_classes <- function(p) {
  vapply(p$layers, function(l) class(l$geom)[1], character(1))
}

#' Assert that a plot is a ggplot AND has at least one data layer with rows.
#'
#' Optional arguments tighten the contract:
#' - `min_rows`: every non-decorator layer must have at least this many rows.
#'               Reference-line layers are held to one row, not `min_rows`.
#' - `geoms`:    each name in this vector must appear among the plot's geoms.
#' - `min_groups`: at least one non-decorator layer must split into this many
#'                 distinct `group` values (catches plots where stratification
#'                 silently collapsed to a single group).
expect_plot_has_data <- function(p,
                                 min_rows   = 1L,
                                 geoms      = NULL,
                                 min_groups = NULL,
                                 label      = deparse(substitute(p))) {
  testthat::expect_s3_class(p, "ggplot")

  built  <- ggplot2::ggplot_build(p)
  rows   <- vapply(built$data, NROW, integer(1))
  geoms_present <- geom_classes(p)
  data_idx <- which(!geoms_present %in% c(.decorator_geoms, .empty_geoms))
  deco_idx <- which(geoms_present %in% .decorator_geoms)

  testthat::expect_true(
    length(data_idx) > 0L,
    info = sprintf(
      "%s: plot has only decorator geoms (%s) — no observation data",
      label, paste(geoms_present, collapse = ", ")
    )
  )

  bad <- data_idx[rows[data_idx] < min_rows]
  testthat::expect_true(
    length(bad) == 0L,
    info = sprintf(
      "%s: data layers with < %d rows: idx=%s geoms=%s rows=%s",
      label, min_rows,
      paste(bad, collapse = ","),
      paste(geoms_present[bad], collapse = ","),
      paste(rows[bad], collapse = ",")
    )
  )

  bad_deco <- deco_idx[rows[deco_idx] < 1L]
  testthat::expect_true(
    length(bad_deco) == 0L,
    info = sprintf(
      "%s: reference-line layers that drew nothing: idx=%s geoms=%s",
      label,
      paste(bad_deco, collapse = ","),
      paste(geoms_present[bad_deco], collapse = ",")
    )
  )

  if (!is.null(geoms)) {
    missing <- setdiff(geoms, geoms_present)
    testthat::expect_true(
      length(missing) == 0L,
      info = sprintf(
        "%s: missing expected geom(s): %s (got %s)",
        label, paste(missing, collapse = ","),
        paste(geoms_present, collapse = ",")
      )
    )
  }

  if (!is.null(min_groups)) {
    n_groups <- vapply(data_idx, function(i) {
      d <- built$data[[i]]
      if ("group" %in% names(d)) length(unique(d$group)) else 0L
    }, integer(1))
    testthat::expect_true(
      any(n_groups >= min_groups),
      info = sprintf(
        "%s: no data layer carries >= %d groups (got %s)",
        label, min_groups, paste(n_groups, collapse = ",")
      )
    )
  }

  invisible(p)
}
