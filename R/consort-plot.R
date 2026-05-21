###############################################################################
## consort-plot.R
##
## CONSORT patient-flow tracking and diagram for hvtiPlotR.
##
## Two S3 classes:
##   hv_consort_tracker  -- patient-level building object (built incrementally)
##   hv_consort          -- rendered grid diagram (from consort::consort_plot())
##
## Public API:
##   hv_consort_start()      -- initialise tracker
##   hv_consort_exclude()    -- add exclusion stage (pipe-friendly)
##   hv_consort_summary()    -- stage-level summary tibble
##   hv_consort_patients()   -- audit: patient IDs at a stage or by reason
##   hv_consort()            -- build diagram from tracker
##   plot.hv_consort()       -- render (grid.draw)
##   print.hv_consort()      -- one-screen summary
##   print.hv_consort_tracker() -- stage-by-stage summary
###############################################################################

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

# Convert a label string to a safe snake_case column name.
# E.g. "Screened" -> "screened", "Eligible patients" -> "eligible_patients"
ct_snakify <- function(x) {
  x <- tolower(trimws(x))
  x <- gsub("[^a-z0-9]+", "_", x)
  x <- gsub("^_|_$", "", x)
  x
}

# Return the include (boolean) column name for the current (last) stage.
ct_current_include <- function(tracker) {
  n <- length(tracker$stages)
  tracker$stages[[n]]$include_col
}

# Validate that x is an hv_consort_tracker.
ct_validate_tracker <- function(x, arg = "tracker") {
  if (!inherits(x, "hv_consort_tracker"))
    stop(
      sprintf("`%s` must be an `hv_consort_tracker` object created by `hv_consort_start()`.", arg),
      call. = FALSE
    )
  invisible(x)
}

# ---------------------------------------------------------------------------
# hv_consort_tracker constructor
# ---------------------------------------------------------------------------

#' Initialise a CONSORT patient-flow tracker
#'
#' Creates an `hv_consort_tracker` object with one row per patient and a
#' boolean column indicating that every patient is in the initial (screened)
#' population.  Build the tracker incrementally with [hv_consort_exclude()],
#' then convert to a diagram with [hv_consort()].
#'
#' @param data       A data frame — one row per patient.
#' @param patient_id <[`data-masking`][rlang::args_data_masking]> Unquoted
#'   name of the unique patient identifier column.
#' @param label      Character label for the initial population box.
#'   Default `"Screened"`.
#' @param pass_col   Column name for the initial boolean column.  Defaults to
#'   `ct_snakify(label)` (e.g. `"screened"` when `label = "Screened"`).
#'
#' @return An `hv_consort_tracker` object — a list with:
#' \describe{
#'   \item{`$data`}{Patient-level data frame with boolean/character columns appended per stage.}
#'   \item{`$stages`}{Ordered list of stage descriptors (`label`, `include_col`, `excl_col`, `excl_label`).}
#'   \item{`$patient_id_col`}{Column name of the patient identifier.}
#' }
#'
#' @seealso [hv_consort_exclude()], [hv_consort()]
#'
#' @examples
#' cohort  <- data.frame(mrn = paste0("P", 1:100), age = sample(15:80, 100, TRUE))
#' tracker <- hv_consort_start(cohort, patient_id = mrn)
#' print(tracker)
#'
#' @export
hv_consort_start <- function(data, patient_id, label = "Screened",
                              pass_col = NULL) {
  .check_df(data)
  patient_id_col <- as.character(substitute(patient_id))
  .check_cols(data, patient_id_col)

  if (is.null(pass_col)) pass_col <- ct_snakify(label)
  if (!nzchar(pass_col))
    stop("`pass_col` / `label` produced an empty column name.", call. = FALSE)

  dat <- as.data.frame(data, stringsAsFactors = FALSE)
  dat[[pass_col]] <- TRUE

  structure(
    list(
      data           = dat,
      patient_id_col = patient_id_col,
      stages         = list(
        list(
          label       = label,
          include_col = pass_col,
          excl_col    = NULL,
          excl_label  = NULL
        )
      )
    ),
    class = "hv_consort_tracker"
  )
}


#' Print an hv_consort_tracker object
#'
#' @param x   An `hv_consort_tracker` from [hv_consort_start()].
#' @param ... Ignored.
#' @return `x`, invisibly.
#' @export
print.hv_consort_tracker <- function(x, ...) {
  cat("<hv_consort_tracker>\n")
  cat(sprintf("  Patients   : %d\n", nrow(x$data)))
  cat(sprintf("  ID column  : %s\n", x$patient_id_col))
  cat(sprintf("  Stages     : %d\n", length(x$stages)))
  for (s in x$stages) {
    n_in <- sum(x$data[[s$include_col]], na.rm = TRUE)
    cat(sprintf("    [%s] %s — N = %d\n", s$include_col, s$label, n_in))
    if (!is.null(s$excl_col)) {
      n_excl <- sum(!is.na(x$data[[s$excl_col]]), na.rm = TRUE)
      cat(sprintf("      → excl [%s]: %d\n", s$excl_col, n_excl))
    }
  }
  invisible(x)
}
