# inform.R
# The family quiet mode (hvtiR API rubric, "Quiet mode"). Every informational
# message goes through .hvti_inform(), so options(hvti.quiet = TRUE) silences
# them all at once. Warnings and errors are never silenced by it. Each hvtiR
# package carries its own copy of these few lines rather than importing them.
.hvti_inform <- function(...) {
  if (!isTRUE(getOption("hvti.quiet"))) message(...)
  invisible()
}
