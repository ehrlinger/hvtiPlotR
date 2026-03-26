###############################################################################
## hvti-data.R
##
## Base class infrastructure for hvtiPlotR data objects.
##
## Every hvtiPlotR data-preparation function returns an object of a specific
## subclass (e.g. "hvti_survival", "hvti_mirror") that also inherits from the
## common base class "hvti_data".  This file defines:
##
##   new_hvti_data()     -- internal constructor used by every hvti_*() function
##   print.hvti_data()   -- default print for any hvti_data subclass
##   plot.hvti_data()    -- fallback that gives a clear error instead of
##                          silently calling plot.default()
##   is_hvti_data()      -- lightweight predicate for user code and tests
##
## Object structure (guaranteed for every hvti_data subclass):
##
##   $data    <data.frame>  Primary tidy data frame ready for ggplot2.
##   $meta    <list>        Column names used, method parameters, computed
##                          statistics -- anything needed to reconstruct or
##                          describe the object without re-running the model.
##   $tables  <list>        Accessory tables (risk table, report table, ...).
##                          May be an empty list when there are no tables.
##
## Individual subclasses may add further named elements beyond these three,
## but $data, $meta, and $tables are always present.
##
###############################################################################


# ---------------------------------------------------------------------------
# Internal constructor
# ---------------------------------------------------------------------------

#' Construct a validated hvti_data object
#'
#' This is the single internal entry point used by every `hvti_*()` function
#' to create its return value.  It enforces the three-slot contract
#' (`$data`, `$meta`, `$tables`) and attaches the two-level S3 class vector.
#'
#' @param data     A data frame -- the primary tidy data ready for ggplot2.
#' @param meta     A named list of metadata (column names, method choices,
#'   computed statistics, etc.).
#' @param tables   A named list of accessory data frames (may be `list()`).
#' @param subclass A single string naming the specific subclass
#'   (e.g. `"hvti_survival"`).
#'
#' @return A named list of class `c(subclass, "hvti_data")`.
#' @keywords internal
new_hvti_data <- function(data, meta, tables = list(), subclass) {
  stopifnot(is.data.frame(data))
  stopifnot(is.list(meta))
  stopifnot(is.list(tables))
  stopifnot(is.character(subclass), length(subclass) == 1L, nzchar(subclass))

  structure(
    list(data = data, meta = meta, tables = tables),
    class = c(subclass, "hvti_data")
  )
}


# ---------------------------------------------------------------------------
# Base class S3 methods
# ---------------------------------------------------------------------------

#' Print an hvti_data object
#'
#' Default print method for any `hvti_data` subclass.  Subclasses may
#' override this with a more informative implementation (see
#' `print.hvti_survival()` for an example), but all fall back to this when
#' no specific method is registered.
#'
#' @param x   An `hvti_data` object.
#' @param ... Ignored; present for S3 consistency.
#'
#' @return `x`, invisibly.
#' @export
print.hvti_data <- function(x, ...) {
  cat(sprintf("<%s>\n", class(x)[1L]))
  cat(sprintf("  rows \u00d7 cols : %d \u00d7 %d\n",
              nrow(x$data), ncol(x$data)))
  if (length(x$meta) > 0L)
    cat(sprintf("  meta        : %s\n",
                paste(names(x$meta), collapse = ", ")))
  if (length(x$tables) > 0L)
    cat(sprintf("  tables      : %s\n",
                paste(names(x$tables), collapse = ", ")))
  invisible(x)
}


#' Plot fallback for hvti_data objects
#'
#' Called when `plot()` is dispatched to an `hvti_data` subclass that has no
#' registered `plot.<subclass>()` method.  Issues a clear error rather than
#' silently falling through to [graphics::plot.default()].
#'
#' @param x   An `hvti_data` object.
#' @param ... Ignored.
#'
#' @return Does not return; always signals an error.
#' @export
plot.hvti_data <- function(x, ...) {
  stop(
    sprintf(
      "No plot() method is registered for class '%s'.\n",
      class(x)[1L]
    ),
    "This is likely a bug in hvtiPlotR -- please file an issue.",
    call. = FALSE
  )
}


# ---------------------------------------------------------------------------
# Predicate
# ---------------------------------------------------------------------------

#' Test whether an object is an hvtiPlotR data object
#'
#' @param x Any R object.
#' @return `TRUE` if `x` inherits from `"hvti_data"`, `FALSE` otherwise.
#' @export
is_hvti_data <- function(x) inherits(x, "hvti_data")
