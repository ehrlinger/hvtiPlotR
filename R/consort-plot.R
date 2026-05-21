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
